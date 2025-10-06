variable "bucket_name" {
  description = "Name of the S3 bucket"
  type        = string
}

variable "s3_bucket_regional_domain_name" {
  description = "Regional domain name of the S3 bucket"
  type        = string
}

variable "domain_name" {
  description = "Domain name for the CloudFront distribution"
  type        = string
}

variable "aliases" {
  description = "Aliases for the CloudFront distribution"
  type        = list(string)
  default     = []
}

variable "acm_certificate_arn" {
  description = "ARN of the ACM certificate"
  type        = string
}

variable "project_name" {
  description = "Project name for tagging"
  type        = string
  default     = "traffic-tacos"
}

variable "default_root_object" {
  description = "Default root object for CloudFront"
  type        = string
  default     = "index.html"
}

variable "error_document" {
  description = "Error document for the website (SPA should use index.html)"
  type        = string
  default     = "index.html"
}

variable "price_class" {
  description = "Price class for CloudFront distribution"
  type        = string
  default     = "PriceClass_100"
}

variable "waf_web_acl_arn" {
  description = "ARN of the WAF Web ACL to associate with CloudFront"
  type        = string
  default     = null
}