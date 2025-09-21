variable "domain_name" {
  description = "The domain name for the hosted zone"
  type        = string
}

variable "project_name" {
  description = "Project name for tagging"
  type        = string
  default     = "traffic-tacos"
}

variable "api_alb_dns_name" {
  description = "DNS name of the EKS ALB"
  type        = string
  default     = ""
}

variable "api_alb_zone_id" {
  description = "Zone ID of the EKS ALB"
  type        = string
  default     = ""
}

variable "cloudfront_distribution_domain_name" {
  description = "Domain name of the CloudFront distribution"
  type        = string
  default     = ""
}

variable "cloudfront_distribution_zone_id" {
  description = "Zone ID of the CloudFront distribution"
  type        = string
  default     = "Z2FDTNDATAQYW2"
}

variable "acm_certificate_domain_validation_options" {
  description = "Domain validation options from ACM certificate"
  type = list(object({
    domain_name           = string
    resource_record_name  = string
    resource_record_type  = string
    resource_record_value = string
  }))
  default = []
}