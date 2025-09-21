module "vpc" {
  source = "./modules/vpc"
}

module "eks" {
  source             = "./modules/eks"
  private_subnet_ids = module.vpc.app_subnet
  vpc_id             = module.vpc.vpc_id
  vpc_cidr           = module.vpc.vpc_cidr
  bastion_host_ip    = module.ec2.bastion_host_ip

  # Gateway API configuration
  enable_gateway_api    = true
  domain_name          = var.domain_name
  acm_certificate_arn  = aws_acm_certificate_validation.main.certificate_arn
  aws_region           = var.region

  depends_on = [aws_acm_certificate_validation.main]
}

module "ec2" {
  source        = "./modules/ec2"
  vpc_id        = module.vpc.vpc_id
  public_subnet = module.vpc.public_subnet
}

module "dynamodb" {
  source = "./modules/dynamodb"

  tables = [
    # Ticket service tables
    {
      name      = "tickets"
      hash_key  = "pk"
      range_key = "sk"
      attributes = [
        { name = "pk", type = "S" },
        { name = "sk", type = "S" },
        { name = "gsi1pk", type = "S" },
        { name = "gsi1sk", type = "S" }
      ]
      global_secondary_indexes = [
        {
          name            = "GSI1"
          hash_key        = "gsi1pk"
          range_key       = "gsi1sk"
          projection_type = "ALL"
        }
      ]
    },
    {
      name      = "ticket-events"
      hash_key  = "pk"
      range_key = "sk"
      attributes = [
        { name = "pk", type = "S" },
        { name = "sk", type = "S" }
      ]
    },
    # Reservation service tables
    {
      name      = "reservation-reservations"
      hash_key  = "pk"
      range_key = "sk"
      attributes = [
        { name = "pk", type = "S" },
        { name = "sk", type = "S" },
        { name = "gsi1pk", type = "S" },
        { name = "gsi1sk", type = "S" }
      ]
      global_secondary_indexes = [
        {
          name            = "GSI1"
          hash_key        = "gsi1pk"
          range_key       = "gsi1sk"
          projection_type = "ALL"
        }
      ]
    },
    {
      name      = "reservation-orders"
      hash_key  = "pk"
      range_key = "sk"
      attributes = [
        { name = "pk", type = "S" },
        { name = "sk", type = "S" },
        { name = "gsi1pk", type = "S" },
        { name = "gsi1sk", type = "S" }
      ]
      global_secondary_indexes = [
        {
          name            = "GSI1"
          hash_key        = "gsi1pk"
          range_key       = "gsi1sk"
          projection_type = "ALL"
        }
      ]
    },
    {
      name          = "reservation-idempotency"
      hash_key      = "pk"
      ttl_enabled   = true
      ttl_attribute = "ttl"
      attributes = [
        { name = "pk", type = "S" }
      ]
    },
    {
      name      = "reservation-outbox"
      hash_key  = "pk"
      range_key = "sk"
      attributes = [
        { name = "pk", type = "S" },
        { name = "sk", type = "S" }
      ]
    }
  ]
}

module "eventbridge" {
  source              = "./modules/eventbridge"
  dynamodb_table_arns = values(module.dynamodb.table_arns)
}

module "awsgrafana" {
  source       = "./modules/awsgrafana"
  grafana_name = "tacos-grafana"
}

module "awsprometheus" {
  source = "./modules/awsprometheus"
}

# Reference existing manually created hosted zone
module "route53" {
  source = "./modules/route53"

  domain_name  = var.domain_name
  project_name = var.project_name
}

module "acm" {
  source = "./modules/acm"

  providers = {
    aws           = aws
    aws.us_east_1 = aws.us_east_1
  }

  domain_name               = var.domain_name
  subject_alternative_names = ["api.${var.domain_name}", "www.${var.domain_name}", "*.${var.domain_name}"]
  project_name              = var.project_name
  validation_record_fqdns   = []
}

resource "aws_route53_record" "acm_validation" {
  for_each = {
    for dvo in module.acm.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = module.route53.zone_id
}

resource "aws_acm_certificate_validation" "main" {
  certificate_arn         = module.acm.certificate_arn
  validation_record_fqdns = [for record in aws_route53_record.acm_validation : record.fqdn]
}

resource "aws_acm_certificate_validation" "cloudfront" {
  provider                = aws.us_east_1
  certificate_arn         = module.acm.cloudfront_certificate_arn
  validation_record_fqdns = [for record in aws_route53_record.acm_validation : record.fqdn]
}

module "s3_static" {
  source = "./modules/s3-static"

  bucket_name                 = "${var.domain_name}-static-website"
  project_name                = var.project_name
  cloudfront_distribution_arn = try(module.cloudfront.distribution_arn, "")
  cors_allowed_origins        = ["https://${var.domain_name}", "https://www.${var.domain_name}"]
}

module "cloudfront" {
  source = "./modules/cloudfront"

  bucket_name                    = module.s3_static.bucket_id
  s3_bucket_regional_domain_name = module.s3_static.bucket_regional_domain_name
  domain_name                    = var.domain_name
  aliases                        = ["www.${var.domain_name}"]
  acm_certificate_arn            = aws_acm_certificate_validation.cloudfront.certificate_arn
  project_name                   = var.project_name

  depends_on = [aws_acm_certificate_validation.cloudfront]
}

# Create WWW record after CloudFront is available
resource "aws_route53_record" "www" {
  zone_id = module.route53.zone_id
  name    = "www.${var.domain_name}"
  type    = "A"

  alias {
    name                   = module.cloudfront.distribution_domain_name
    zone_id                = module.cloudfront.distribution_hosted_zone_id
    evaluate_target_health = false
  }

  depends_on = [module.cloudfront]
}

# Create API record automatically from Gateway ALB
resource "aws_route53_record" "api" {
  count = module.eks.alb_hostname != "" ? 1 : 0

  zone_id = module.route53.zone_id
  name    = "api.${var.domain_name}"
  type    = "A"

  alias {
    name                   = module.eks.alb_hostname
    zone_id                = module.eks.alb_zone_id
    evaluate_target_health = true
  }

  depends_on = [module.eks]
}

# Create Bastion record for SSH access
resource "aws_route53_record" "bastion" {
  zone_id = module.route53.zone_id
  name    = "bastion.${var.domain_name}"
  type    = "A"
  ttl     = 300
  records = [module.ec2.bastion_host_public_ip]

  depends_on = [module.ec2]
}

module "elasticache" {
  source = "./modules/elasticache"

  cluster_name       = "${var.project_name}-redis"
  project_name       = var.project_name
  vpc_id             = module.vpc.vpc_id
  vpc_cidr           = module.vpc.vpc_cidr
  private_subnet_ids = module.vpc.db_subnet

  node_type          = var.redis_node_type
  num_cache_clusters = var.redis_num_cache_clusters
  engine_version     = var.redis_engine_version

  at_rest_encryption_enabled = var.redis_at_rest_encryption_enabled
  transit_encryption_enabled = var.redis_transit_encryption_enabled
  auth_token_secret_name     = var.redis_auth_token_secret_name

  automatic_failover_enabled = var.redis_automatic_failover_enabled
  multi_az_enabled           = var.redis_multi_az_enabled
}