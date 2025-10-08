variable "cluster_name" {
  description = "Name of the ElastiCache cluster"
  type        = string
  default     = "traffic-tacos-redis"
}

variable "project_name" {
  description = "Project name for tagging"
  type        = string
  default     = "traffic-tacos"
}

variable "vpc_id" {
  description = "VPC ID where ElastiCache will be deployed"
  type        = string
}

variable "vpc_cidr" {
  description = "VPC CIDR block for security group rules"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for ElastiCache subnet group"
  type        = list(string)
}

variable "node_type" {
  description = "Instance type for ElastiCache nodes"
  type        = string
  default     = "cache.t3.micro"
}

variable "num_cache_clusters" {
  description = "Number of cache clusters (nodes) in the replication group (only for non-cluster mode)"
  type        = number
  default     = null
}

variable "cluster_mode_enabled" {
  description = "Enable Redis Cluster mode (sharding). If true, uses num_node_groups and replicas_per_node_group instead of num_cache_clusters"
  type        = bool
  default     = false
}

variable "num_node_groups" {
  description = "Number of node groups (shards) for Redis Cluster mode. Recommended: 3-5 for write-heavy workload"
  type        = number
  default     = 3
}

variable "replicas_per_node_group" {
  description = "Number of replica nodes per shard in cluster mode"
  type        = number
  default     = 1
}

variable "engine_version" {
  description = "Redis engine version"
  type        = string
  default     = "7.0"
}

variable "parameter_group_family" {
  description = "Redis parameter group family"
  type        = string
  default     = "redis7"
}

variable "parameters" {
  description = "List of ElastiCache parameters to apply"
  type = list(object({
    name  = string
    value = string
  }))
  default = [
    {
      name  = "maxmemory-policy"
      value = "allkeys-lru"
    }
  ]
}

variable "at_rest_encryption_enabled" {
  description = "Whether to enable encryption at rest"
  type        = bool
  default     = true
}

variable "transit_encryption_enabled" {
  description = "Whether to enable encryption in transit"
  type        = bool
  default     = true
}

variable "auth_token_secret_name" {
  description = "Name of the Secrets Manager secret containing Redis AUTH token"
  type        = string
  default     = "traffic-tacos/redis/auth-token"
}

variable "automatic_failover_enabled" {
  description = "Whether automatic failover is enabled"
  type        = bool
  default     = true
}

variable "multi_az_enabled" {
  description = "Whether Multi-AZ is enabled"
  type        = bool
  default     = true
}

variable "snapshot_retention_limit" {
  description = "Number of days to retain automatic snapshots"
  type        = number
  default     = 1
}

variable "snapshot_window" {
  description = "Daily time range during which automated backups are created"
  type        = string
  default     = "03:00-04:00"
}

variable "maintenance_window" {
  description = "Weekly time range during which system maintenance can occur"
  type        = string
  default     = "sun:04:00-sun:05:00"
}

variable "notification_topic_arn" {
  description = "ARN of SNS topic for ElastiCache notifications"
  type        = string
  default     = null
}

variable "apply_immediately" {
  description = "Whether to apply changes immediately"
  type        = bool
  default     = false
}

variable "cluster_sg" {
  type = string
}

# Auto Scaling variables
variable "enable_auto_scaling" {
  description = "Enable auto scaling for Redis Cluster mode"
  type        = bool
  default     = false
}

variable "min_node_groups" {
  description = "Minimum number of node groups (shards) for auto scaling"
  type        = number
  default     = 12
}

variable "max_node_groups" {
  description = "Maximum number of node groups (shards) for auto scaling"
  type        = number
  default     = 20
}

variable "target_cpu_utilization" {
  description = "Target CPU utilization percentage for auto scaling (recommended: 50-70)"
  type        = number
  default     = 70
}