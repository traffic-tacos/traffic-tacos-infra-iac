data "aws_ssoadmin_instances" "admin_group" {}

resource "aws_identitystore_group" "admin_group" {
  display_name      = "grafana-admins"
  description       = "Grafana Admins Group"
  identity_store_id = tolist(data.aws_ssoadmin_instances.admin_group.identity_store_ids)[0]
}