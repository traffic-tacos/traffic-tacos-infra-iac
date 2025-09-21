output "replication_group_id" {
  description = "ID of the ElastiCache replication group"
  value       = aws_elasticache_replication_group.redis.replication_group_id
}

output "primary_endpoint_address" {
  description = "Address of the endpoint for the primary node in the replication group"
  value       = aws_elasticache_replication_group.redis.primary_endpoint_address
}

output "reader_endpoint_address" {
  description = "Address of the endpoint for the reader node in the replication group"
  value       = aws_elasticache_replication_group.redis.reader_endpoint_address
}

output "configuration_endpoint_address" {
  description = "Configuration endpoint address for Redis cluster mode"
  value       = aws_elasticache_replication_group.redis.configuration_endpoint_address
}

output "port" {
  description = "Port number on which each of the cache nodes will accept connections"
  value       = aws_elasticache_replication_group.redis.port
}

output "security_group_id" {
  description = "ID of the security group for Redis"
  value       = aws_security_group.redis.id
}

output "subnet_group_name" {
  description = "Name of the ElastiCache subnet group"
  value       = aws_elasticache_subnet_group.redis.name
}

output "parameter_group_name" {
  description = "Name of the ElastiCache parameter group"
  value       = aws_elasticache_parameter_group.redis.name
}

output "auth_token_enabled" {
  description = "Whether auth token is enabled"
  value       = var.auth_token != null
}