output "event_bus_name" {
  description = "EventBridge 커스텀 버스 이름"
  value       = aws_cloudwatch_event_bus.custom_bus.name
}

output "event_bus_arn" {
  description = "EventBridge 커스텀 버스 ARN"
  value       = aws_cloudwatch_event_bus.custom_bus.arn
}

output "rule_arns" {
  description = "EventBridge 규칙 ARN 목록"
  value       = { for k, rule in aws_cloudwatch_event_rule.rules : k => rule.arn }
}

output "rule_names" {
  description = "EventBridge 규칙 이름 목록"
  value       = { for k, rule in aws_cloudwatch_event_rule.rules : k => rule.name }
}

output "dlq_url" {
  description = "Dead Letter Queue URL"
  value       = var.enable_dlq ? aws_sqs_queue.dlq[0].url : null
}

output "dlq_arn" {
  description = "Dead Letter Queue ARN"
  value       = var.enable_dlq ? aws_sqs_queue.dlq[0].arn : null
}

output "archive_arn" {
  description = "EventBridge 아카이브 ARN"
  value       = var.archive_config.enabled ? aws_cloudwatch_event_archive.archive[0].arn : null
}

output "service_role_arn" {
  description = "EventBridge 서비스 역할 ARN"
  value       = aws_iam_role.eventbridge_service_role.arn
}

output "target_role_arn" {
  description = "EventBridge 타겟 역할 ARN"
  value       = aws_iam_role.eventbridge_target_role.arn
}

output "service_role_name" {
  description = "EventBridge 서비스 역할 이름"
  value       = aws_iam_role.eventbridge_service_role.name
}

output "target_role_name" {
  description = "EventBridge 타겟 역할 이름"
  value       = aws_iam_role.eventbridge_target_role.name
}