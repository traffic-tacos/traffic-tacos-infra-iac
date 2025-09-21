# Route53 Outputs
output "hosted_zone_id" {
  description = "The hosted zone ID for the domain"
  value       = module.route53.zone_id
}

output "hosted_zone_name_servers" {
  description = "Name servers for the hosted zone"
  value       = module.route53.name_servers
}

output "api_record_fqdn" {
  description = "FQDN of the API record"
  value       = try(aws_route53_record.api[0].fqdn, "")
}

output "www_record_fqdn" {
  description = "FQDN of the WWW record"
  value       = aws_route53_record.www.fqdn
}

output "bastion_record_fqdn" {
  description = "FQDN of the Bastion record"
  value       = aws_route53_record.bastion.fqdn
}

# ACM Certificate Outputs
output "acm_certificate_arn" {
  description = "ARN of the ACM certificate for ALB"
  value       = module.acm.certificate_arn
}

output "acm_cloudfront_certificate_arn" {
  description = "ARN of the ACM certificate for CloudFront"
  value       = module.acm.cloudfront_certificate_arn
}

# S3 Static Website Outputs
output "s3_bucket_name" {
  description = "Name of the S3 bucket for static website"
  value       = module.s3_static.bucket_id
}

output "s3_website_endpoint" {
  description = "S3 website endpoint"
  value       = module.s3_static.website_endpoint
}

# CloudFront Outputs
output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID"
  value       = module.cloudfront.distribution_id
}

output "cloudfront_distribution_domain_name" {
  description = "CloudFront distribution domain name"
  value       = module.cloudfront.distribution_domain_name
}

# EKS Outputs
output "eks_cluster_id" {
  description = "EKS cluster ID"
  value       = module.eks.cluster_id
}

output "eks_cluster_endpoint" {
  description = "EKS cluster endpoint"
  value       = module.eks.cluster_endpoint
}

output "eks_cluster_name" {
  description = "EKS cluster name"
  value       = module.eks.cluster_name
}

# Redis ElastiCache Outputs
output "redis_replication_group_id" {
  description = "ID of the ElastiCache replication group"
  value       = module.elasticache.replication_group_id
}

output "redis_primary_endpoint" {
  description = "Primary endpoint address for Redis"
  value       = module.elasticache.primary_endpoint_address
}

output "redis_reader_endpoint" {
  description = "Reader endpoint address for Redis"
  value       = module.elasticache.reader_endpoint_address
}

output "redis_port" {
  description = "Port number for Redis connections"
  value       = module.elasticache.port
}

output "redis_security_group_id" {
  description = "Security group ID for Redis"
  value       = module.elasticache.security_group_id
}

output "redis_auth_token_secret_name" {
  description = "Name of the Secrets Manager secret containing Redis AUTH token"
  value       = module.elasticache.auth_token_secret_name
}