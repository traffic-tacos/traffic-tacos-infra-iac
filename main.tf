module "vpc" {
  source = "./modules/vpc"
}

module "eks" {
  source             = "./modules/eks"
  private_subnet_ids = module.vpc.app_subnet
  vpc_id             = module.vpc.vpc_id
  vpc_cidr           = module.vpc.vpc_cidr
  bastion_host_ip    = module.ec2.bastion_host_ip
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

module "acm" {
  source = "./modules/acm"

  providers = {
    aws           = aws
    aws.us_east_1 = aws.us_east_1
  }

  domain_name               = var.domain_name
  subject_alternative_names = ["api.${var.domain_name}", "www.${var.domain_name}", "*.${var.domain_name}"]
  project_name              = var.project_name
  validation_record_fqdns   = [for record in module.route53.api_record_name : record if record != ""]
}

module "route53" {
  source = "./modules/route53"

  domain_name                               = var.domain_name
  project_name                              = var.project_name
  acm_certificate_domain_validation_options = module.acm.domain_validation_options

  # Will be populated after ALB and CloudFront are created
  api_alb_dns_name                    = var.api_alb_dns_name
  api_alb_zone_id                     = var.api_alb_zone_id
  cloudfront_distribution_domain_name = try(module.cloudfront.distribution_domain_name, "")
  cloudfront_distribution_zone_id     = try(module.cloudfront.distribution_hosted_zone_id, "Z2FDTNDATAQYW2")
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
  acm_certificate_arn            = module.acm.cloudfront_certificate_arn
  project_name                   = var.project_name
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
  auth_token                 = var.redis_auth_token

  automatic_failover_enabled = var.redis_automatic_failover_enabled
  multi_az_enabled           = var.redis_multi_az_enabled
}