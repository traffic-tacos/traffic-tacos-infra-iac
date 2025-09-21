resource "aws_route53_zone" "main" {
  name = var.domain_name

  tags = {
    Name      = "${var.domain_name}-zone"
    Project   = var.project_name
    ManagedBy = "terraform"
  }
}

# API record will be created in main.tf when ALB is available

# WWW record will be created later when CloudFront is available
# resource "aws_route53_record" "www" {
#   count = var.cloudfront_distribution_domain_name != "" ? 1 : 0

#   zone_id = aws_route53_zone.main.zone_id
#   name    = "www.${var.domain_name}"
#   type    = "A"

#   alias {
#     name                   = var.cloudfront_distribution_domain_name
#     zone_id                = var.cloudfront_distribution_zone_id
#     evaluate_target_health = false
#   }
# }

# ACM validation records will be created in main.tf to avoid circular dependency