# CRD 문제로 주석처리
# data "aws_caller_identity" "current" {}

# locals {
#   otel_operator_namespace   = "opentelemetry-operator"
#   otel_collector_ns         = "otel-collector"
#   otel_service_account_name = "otel-collector-sa"
# }

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

# # Install Otel Collector
# resource "kubernetes_manifest" "tail_sampling_otel_collector" {
#   manifest = {
#     "apiVersion" = "opentelemetry.io/v1alpha1"
#     "kind"       = "OpenTelemetryCollector"
#     "metadata" = {
#       "name"      = "otel-tail-collector"
#       "namespace" = local.otel_collector_ns
#     }
#     "spec" = {
#       "serviceAccount" = local.otel_service_account_name
#       "affinity" = {
#         "podAntiAffinity" = {
#           "requiredDuringSchedulingIgnoredDuringExecution" = [
#             {
#               "labelSelector" = {
#                 "matchExpressions" = [
#                   {

#                     "key"      = "node-type"
#                     "operator" = "In"
#                     "values"   = ["monitoring"]
#                   }
#                 ]
#               }
#               "topologyKey" = "kubernetes.io/hostname"
#             }
#           ]
#         }
#       }
#       tolerations = [
#         {
#           "key"      = "workload"
#           "operator" = "Equal"
#           "value"    = "monitoring"
#           "effect"   = "NoSchedule"
#         }
#       ]
#       "mode" = "deployment"
#       "config" = {
#         "receivers" = {
#           "otlp" = {
#             "protocols" = {
#               "grpc" = "0.0.0.0:4317"
#               "http" = "0.0.0.0:4318"
#             }

#           }
#         }
#         "processors" = {
#           "batch" = {}
#         }
#         "exporters" = {
#           "awsxray" = {

#           }
#         }
#         "service" = {
#           "pipelines" = {
#             "traces" = {
#               "receivers"  = ["otlp"]
#               "processors" = ["batch"]
#               "exporters"  = ["awsxray"]
#             }
#           }
#         }
#       }
#     }
#   }


#   depends_on = [helm_release.otel-operator]
# }

# # OTEL daemonset 

# resource "kubernetes_manifest" "daemonset_otel_collector" {
#   manifest = {
#     "apiVersion" = "opentelemetry.io/v1alpha1"
#     "kind"       = "OpenTelemetryCollector"
#     "metadata" = {
#       "name"      = "otel-collector"
#       "namespace" = local.otel_collector_ns
#     }
#     "spec" = {
#       "serviceAccount" = local.otel_service_account_name
#       tolerations = [
#         {
#           "operator" = "Exists"
#         }
#       ]
#       "mode" = "daemonset"
#       "config" = {
#         "receivers" = {
#           "otlp" = {
#             "protocols" = {
#               "grpc" = "0.0.0.0:4317"
#               "http" = "0.0.0.0:4318"
#             }

#           }
#         }
#         "processors" = {
#           "batch" = {
#             "send_batch_size" = 10000
#             "timeout"         = "10s"


#           }
#         }
#         "exporters" = {
#           "awsxray" = {
#             "region" = var.aws_region
#           }
#           "prometheusremotewrite" = {
#             "endpoint" = "${var.prometheus_workspace_endpoint}api/v1/remote_write"
#             "auth" = {
#               "authenticator" = "sigv4auth"
#             }
#           }
#         }
#         "service" = {
#           "extensions" = ["sigv4auth"]
#           "pipelines" = {
#             "traces" = {
#               "receivers"  = ["otlp"]
#               "processors" = ["batch"]
#               "exporters"  = ["awsxray"]
#             }
#             "metrics" = {
#               "receivers"  = ["otlp"]
#               "processors" = ["batch"]
#               "exporters"  = ["prometheusremotewrite"]
#             }
#           }
#         }
#         "extensions" = {
#           "sigv4auth" = {
#           }
#         }
#       }
#     }
#   }


#   depends_on = [helm_release.otel-operator]
# }


