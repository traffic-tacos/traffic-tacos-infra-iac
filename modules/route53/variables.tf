variable "domain_name" {
  description = "The domain name for the existing hosted zone"
  type        = string
}

variable "project_name" {
  description = "Project name for tagging"
  type        = string
  default     = "traffic-tacos"
}