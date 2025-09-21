resource "aws_elasticache_subnet_group" "redis" {
  name       = "${var.cluster_name}-redis-subnet-group"
  subnet_ids = var.private_subnet_ids

  tags = {
    Name      = "${var.cluster_name}-redis-subnet-group"
    Project   = var.project_name
    ManagedBy = "terraform"
  }
}

resource "aws_security_group" "redis" {
  name_prefix = "${var.cluster_name}-redis-"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 6379
    to_port     = 6379
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
    description = "Redis access from VPC"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "All outbound traffic"
  }

  tags = {
    Name      = "${var.cluster_name}-redis-sg"
    Project   = var.project_name
    ManagedBy = "terraform"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_elasticache_parameter_group" "redis" {
  family = var.parameter_group_family
  name   = "${var.cluster_name}-redis-params"

  dynamic "parameter" {
    for_each = var.parameters
    content {
      name  = parameter.value.name
      value = parameter.value.value
    }
  }

  tags = {
    Name      = "${var.cluster_name}-redis-params"
    Project   = var.project_name
    ManagedBy = "terraform"
  }
}

resource "aws_elasticache_replication_group" "redis" {
  replication_group_id = var.cluster_name
  description          = "Redis cluster for ${var.project_name}"

  node_type            = var.node_type
  port                 = 6379
  parameter_group_name = aws_elasticache_parameter_group.redis.name

  num_cache_clusters = var.num_cache_clusters

  engine         = "redis"
  engine_version = var.engine_version

  subnet_group_name  = aws_elasticache_subnet_group.redis.name
  security_group_ids = [aws_security_group.redis.id]

  at_rest_encryption_enabled = var.at_rest_encryption_enabled
  transit_encryption_enabled = var.transit_encryption_enabled
  auth_token                 = var.auth_token

  automatic_failover_enabled = var.automatic_failover_enabled
  multi_az_enabled           = var.multi_az_enabled

  snapshot_retention_limit = var.snapshot_retention_limit
  snapshot_window          = var.snapshot_window
  maintenance_window       = var.maintenance_window

  notification_topic_arn = var.notification_topic_arn

  apply_immediately = var.apply_immediately

  tags = {
    Name      = "${var.cluster_name}-redis"
    Project   = var.project_name
    ManagedBy = "terraform"
  }
}