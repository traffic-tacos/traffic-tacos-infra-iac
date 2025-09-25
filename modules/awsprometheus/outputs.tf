output "workspace_prometheus_endpoint" {
  description = "Prometheus endpoint available for this workspace"
  value       = aws_prometheus_workspace.aws_prometheus.prometheus_endpoint
}

output "workspace_arn" {
  description = "Amazon Resource Name (ARN) of the workspace"
  value       = aws_prometheus_workspace.aws_prometheus.arn
}

output "workspace_id" {
  description = "Identifier of the workspace"
  value       = aws_prometheus_workspace.aws_prometheus.id
}