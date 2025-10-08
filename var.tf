variable "region" {
  type    = string
  default = "ap-northeast-2"
}

variable "profile" {
  type    = string
  default = "tacos"
}

variable "domain_name" {
  description = "The primary domain name for the hosted zone"
  type        = string
  default     = "traffictacos.store"
}

variable "project_name" {
  description = "Project name for resource tagging"
  type        = string
  default     = "traffic-tacos"
}

# Legacy variables - now handled automatically by Gateway API
# variable "api_alb_dns_name" {
#   description = "DNS name of the EKS ALB for API subdomain"
#   type        = string
#   default     = ""
# }

# variable "api_alb_zone_id" {
#   description = "Zone ID of the EKS ALB for API subdomain"
#   type        = string
#   default     = ""
# }

# Redis ElastiCache Variables
variable "redis_node_type" {
  description = "Instance type for ElastiCache Redis nodes"
  type        = string
  # Options for write-heavy workload (ElastiCache supported types):
  # - cache.m7g.xlarge: Graviton3 (4 vCPU, 14.12GB) + Enhanced I/O Multiplexing ⭐ BEST
  # - cache.m6i.xlarge: Intel Xeon (4 vCPU, 12.93GB) - Good alternative
  # - cache.m7g.large: Graviton3 (2 vCPU, 6.81GB) - NO Enhanced I/O Multiplexing
  default = "cache.m7g.xlarge" # Graviton3 with Enhanced I/O Multiplexing for write-heavy workload
}

variable "redis_num_cache_clusters" {
  description = "Number of cache clusters (nodes) in the replication group"
  type        = number
  default     = 2
}

variable "redis_engine_version" {
  description = "Redis engine version (7.1+ required for Enhanced I/O Multiplexing)"
  type        = string
  default     = "7.1" # Required for Enhanced I/O Multiplexing with cache.m7g.xlarge
}

variable "redis_at_rest_encryption_enabled" {
  description = "Whether to enable encryption at rest for Redis"
  type        = bool
  default     = true
}

variable "redis_transit_encryption_enabled" {
  description = "Whether to enable encryption in transit for Redis"
  type        = bool
  default     = true
}

variable "redis_auth_token_secret_name" {
  description = "Name of the Secrets Manager secret containing Redis AUTH token"
  type        = string
  default     = "traffic-tacos/redis/auth-token"
}

variable "redis_automatic_failover_enabled" {
  description = "Whether automatic failover is enabled for Redis"
  type        = bool
  default     = true
}

variable "redis_multi_az_enabled" {
  description = "Whether Multi-AZ is enabled for Redis"
  type        = bool
  default     = true
}