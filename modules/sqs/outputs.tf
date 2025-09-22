output "queue_name" {
  description = "SQS 큐 이름"
  value       = aws_sqs_queue.main.name
}

output "queue_url" {
  description = "SQS 큐 URL"
  value       = aws_sqs_queue.main.url
}

output "queue_arn" {
  description = "SQS 큐 ARN"
  value       = aws_sqs_queue.main.arn
}

output "dlq_name" {
  description = "Dead Letter Queue 이름"
  value       = var.enable_dlq ? aws_sqs_queue.dlq[0].name : null
}

output "dlq_url" {
  description = "Dead Letter Queue URL"
  value       = var.enable_dlq ? aws_sqs_queue.dlq[0].url : null
}

output "dlq_arn" {
  description = "Dead Letter Queue ARN"
  value       = var.enable_dlq ? aws_sqs_queue.dlq[0].arn : null
}

output "role_name" {
  description = "SQS 접근 IAM 역할 이름"
  value       = aws_iam_role.sqs_role.name
}

output "role_arn" {
  description = "SQS 접근 IAM 역할 ARN"
  value       = aws_iam_role.sqs_role.arn
}

output "policy_arn" {
  description = "SQS 접근 정책 ARN"
  value       = aws_iam_policy.sqs_policy.arn
}