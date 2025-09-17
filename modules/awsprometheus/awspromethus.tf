resource "aws_prometheus_workspace" "aws_prometheus" {
  alias = var.prometheus_alias

}

data "aws_prometheus_workspace" "aws_prometheus" {
  workspace_id = aws_prometheus_workspace.aws_prometheus.id
}