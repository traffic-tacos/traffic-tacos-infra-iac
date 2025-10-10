# CRD 문제로 주석처리

locals {
  otel_operator_namespace   = "opentelemetry-operator"
  otel_collector_ns         = "otel-collector"
  otel_service_account_name = "otel-collector-sa"
}

# resource "kubernetes_namespace" "otel_ns" {
#   metadata {
#     name = local.otel_operator_namespace
#   }
#   depends_on = [aws_eks_cluster.cluster]
# }

# resource "kubernetes_namespace" "otel_collector_ns" {
#   metadata {
#     name = local.otel_collector_ns
#   }
#   depends_on = [aws_eks_cluster.cluster]
# }

# # ServiceAccount for OpenTelemetry Collector with IAM role annotation
# resource "kubernetes_service_account" "otel_collector_sa" {
#   metadata {
#     name      = local.otel_service_account_name
#     namespace = local.otel_collector_ns
#     annotations = {
#       "eks.amazonaws.com/role-arn" = aws_iam_role.otel_collector_role.arn
#     }
#   }
#   depends_on = [kubernetes_namespace.otel_collector_ns]
# }

# resource "helm_release" "otel-operator" {
#   name       = "otel-operator"
#   repository = "https://open-telemetry.github.io/opentelemetry-helm-charts"
#   chart      = "opentelemetry-operator"
#   version    = "0.95.1"
#   namespace  = local.otel_operator_namespace
#   depends_on = [kubernetes_namespace.otel_ns]

#   set = [
#     {
#       name  = "admissionWebhooks.certManager.enabled"
#       value = "true"
#     },
#     {
#       name  = "manager.collectorImage.repository"
#       value = "otel/opentelemetry-collector-contrib"
#     },
#     {
#       name  = "manager.collectorImage.tag"
#       value = "0.135.0"
#     }
#   ]

# }
