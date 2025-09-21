variable "domain_name" {
  description = "Primary domain name for the certificate"
  type        = string
}

variable "subject_alternative_names" {
  description = "Subject alternative names for the certificate"
  type        = list(string)
  default     = []
}

variable "project_name" {
  description = "Project name for tagging"
  type        = string
  default     = "traffic-tacos"
}

variable "validation_record_fqdns" {
  description = "List of FQDNs for DNS validation records"
  type        = list(string)
  default     = []
}