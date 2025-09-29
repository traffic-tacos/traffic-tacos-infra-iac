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

  ingress {
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [var.cluster_sg]
    description     = "Redis access from EKS Cluster Security Group"
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

# Secrets Manager에서 AUTH token 가져오기
data "aws_secretsmanager_secret" "redis_auth" {
  name = var.auth_token_secret_name
}

data "aws_secretsmanager_secret_version" "redis_auth" {
  secret_id = data.aws_secretsmanager_secret.redis_auth.id
}

locals {
  # Secrets Manager에서 가져온 값이 JSON 형식인 경우를 처리
  redis_auth_value = try(
    jsondecode(data.aws_secretsmanager_secret_version.redis_auth.secret_string).password,
    data.aws_secretsmanager_secret_version.redis_auth.secret_string
  )

  # auth_token은 영숫자만 허용하므로 base64로 인코딩
  # base64 인코딩된 값에서 특수문자 제거 (=, +, / 제거)
  redis_auth_token = replace(replace(replace(
    base64encode(local.redis_auth_value),
    "=", ""),
    "+", ""),
    "/", ""
  )
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
  auth_token                 = local.redis_auth_token
  auth_token_update_strategy = "ROTATE"

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