data "aws_iam_policy_document" "grafana_workspace_policy" {
  statement {
    sid    = "AllowReadingMetricsFromCloudWatch"
    effect = "Allow"
    actions = [
      "cloudwatch:ListMetrics",
      "cloudwatch:GetMetricStatistics",
      "cloudwatch:GetMetricData",
      "cloudwatch:DescribeAlarmsForMetric",
      "cloudwatch:DescribeAlarms",
      "cloudwatch:DescribeAlarmHistory"
    ]
    resources = ["*"]
  }


  statement {
    sid    = "AllowReadingLogsFromCloudWatch"
    effect = "Allow"
    actions = [
      "logs:StopQuery",
      "logs:StartQuery",
      "logs:GetQueryResults",
      "logs:GetLogGroupFields",
      "logs:GetLogEvents",
      "logs:DescribeLogGroups"
    ]
    resources = ["*"]
  }


  statement {
    sid    = "AllowReadingTagsInstancesRegionsFromEC2"
    effect = "Allow"
    actions = [
      "ec2:DescribeTags",
      "ec2:DescribeRegions",
      "ec2:DescribeInstances"
    ]
    resources = ["*"]
  }


  statement {
    sid    = "AllowReadingResourcesForTags"
    effect = "Allow"
    actions = [
      "tag:GetResources"
    ]
    resources = ["*"]
  }


  statement {
    sid    = "AllowReadingFromAManagedPrometheus"
    effect = "Allow"
    actions = [
      "aps:QueryMetrics",
      "aps:ListWorkspaces",
      "aps:GetSeries",
      "aps:GetMetricMetadata",
      "aps:GetLabels",
      "aps:DescribeWorkspace",
      "aps:ListRules",
      "aps:ListAlertManagerSilences",
      "aps:ListAlertManagerAlerts",
      "aps:GetAlertManagerStatus",
      "aps:ListAlertManagerAlertGroups"
    ]
    resources = ["*"]
  }


  statement {
    sid    = "AllowReadingFromXRay"
    effect = "Allow"
    actions = [
      "xray:GetTraceGraph",
      "xray:GetTraceSummaries",
      "xray:GetServiceGraph",
      "xray:GetTimeSeriesServiceStatistics",
      "xray:GetSamplingRules",
      "xray:GetSamplingStatisticSummaries",
      "xray:GetSamplingTargets",
      "xray:GetGroups",
      "xray:GetGroup",
      "xray:BatchGetTraces"
    ]
    resources = ["*"]
  }


  statement {
    effect = "Allow"
    actions = [
      "kms:Decrypt",
      "kms:Encrypt",
      "kms:GenerateDataKey*",
      "kms:CreateGrant",
      "kms:ReEncrypt*",
      "kms:DescribeKey"
    ]
    resources = ["*"]
  }
}


data "aws_iam_policy_document" "grafana_assume_role_policy" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["grafana.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}


resource "aws_iam_role" "grafana_workspace_role" {
  name               = "${var.grafana_name}-workspace-role"
  assume_role_policy = data.aws_iam_policy_document.grafana_assume_role_policy.json


}


resource "aws_iam_policy" "grafana_workspace_policy" {
  name        = "${var.grafana_name}-workspace-policy"
  description = "Policy for Amazon Managed Grafana workspace to access AWS services"
  policy      = data.aws_iam_policy_document.grafana_workspace_policy.json


}


resource "aws_iam_role_policy_attachment" "grafana_workspace_policy_attachment" {
  role       = aws_iam_role.grafana_workspace_role.name
  policy_arn = aws_iam_policy.grafana_workspace_policy.arn
}

