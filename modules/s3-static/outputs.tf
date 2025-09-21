output "bucket_id" {
  description = "The name of the bucket"
  value       = aws_s3_bucket.static_website.id
}

output "bucket_arn" {
  description = "ARN of the bucket"
  value       = aws_s3_bucket.static_website.arn
}

output "bucket_domain_name" {
  description = "The bucket domain name"
  value       = aws_s3_bucket.static_website.bucket_domain_name
}

output "bucket_regional_domain_name" {
  description = "The bucket region-specific domain name"
  value       = aws_s3_bucket.static_website.bucket_regional_domain_name
}

output "website_endpoint" {
  description = "The website endpoint"
  value       = aws_s3_bucket_website_configuration.static_website.website_endpoint
}

output "website_domain" {
  description = "The website domain"
  value       = aws_s3_bucket_website_configuration.static_website.website_domain
}