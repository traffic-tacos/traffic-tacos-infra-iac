output "distribution_id" {
  description = "The identifier for the distribution"
  value       = aws_cloudfront_distribution.static_website.id
}

output "distribution_arn" {
  description = "The ARN for the distribution"
  value       = aws_cloudfront_distribution.static_website.arn
}

output "distribution_domain_name" {
  description = "The domain name corresponding to the distribution"
  value       = aws_cloudfront_distribution.static_website.domain_name
}

output "distribution_hosted_zone_id" {
  description = "The CloudFront Route 53 zone ID"
  value       = aws_cloudfront_distribution.static_website.hosted_zone_id
}

output "distribution_status" {
  description = "The current status of the distribution"
  value       = aws_cloudfront_distribution.static_website.status
}