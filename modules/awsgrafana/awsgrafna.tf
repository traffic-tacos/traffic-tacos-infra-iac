resource "aws_grafana_workspace" "aws_grafana" {
  account_access_type      = "CURRENT_ACCOUNT"
  authentication_providers = ["AWS_SSO"]
  permission_type          = "SERVICE_MANAGED"
  role_arn                 = aws_iam_role.grafana_workspace_role.arn
  name                     = var.grafana_name


  configuration = jsonencode(
    {
      "plugins" = {
        "pluginAdminEnabled" = true
      },
      "unifiedAlerting" = {
        "enabled" = false
      }
    }
  )
}

resource "aws_grafana_role_association" "grafana_admins" {
  # IAM Identity Center에서 'GrafanaAdmins' 그룹의 ID를 가져와야 합니다.
  # 이 ID는 AWS 콘솔의 IAM Identity Center -> Groups 에서 확인할 수 있습니다.
  # 예: "a1b2c3d4-5678-90ab-cdef-EXAMPLE11111"
  role          = "ADMIN" # 부여할 권한 (ADMIN, EDITOR, VIEWER 중 선택)
  workspace_id  = aws_grafana_workspace.aws_grafana.id

  group_ids      = [aws_identitystore_group.admin_group.group_id]

}
