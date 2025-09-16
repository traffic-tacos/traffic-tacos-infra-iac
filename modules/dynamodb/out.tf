output "table_names" {
  description = "DynamoDB 테이블 이름 목록"
  value       = { for k, table in aws_dynamodb_table.table : k => table.name }
}

output "table_arns" {
  description = "DynamoDB 테이블 ARN 목록"
  value       = { for k, table in aws_dynamodb_table.table : k => table.arn }
}

output "table_stream_arns" {
  description = "DynamoDB 테이블 스트림 ARN 목록"
  value       = { for k, table in aws_dynamodb_table.table : k => table.stream_arn if table.stream_enabled }
}

output "application_role_arn" {
  description = "DynamoDB 애플리케이션 역할 ARN"
  value       = aws_iam_role.dynamodb_application_role.arn
}

output "readonly_role_arn" {
  description = "DynamoDB 읽기 전용 역할 ARN"
  value       = aws_iam_role.dynamodb_readonly_role.arn
}

output "application_role_name" {
  description = "DynamoDB 애플리케이션 역할 이름"
  value       = aws_iam_role.dynamodb_application_role.name
}

output "readonly_role_name" {
  description = "DynamoDB 읽기 전용 역할 이름"
  value       = aws_iam_role.dynamodb_readonly_role.name
}