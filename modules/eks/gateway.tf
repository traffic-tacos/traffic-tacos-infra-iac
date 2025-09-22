resource "kubernetes_manifest" "gateway_class" {
  count = var.enable_gateway_api ? 1 : 0

  manifest = {
    apiVersion = "gateway.networking.k8s.io/v1"
    kind       = "GatewayClass"
    metadata = {
      name = "aws-alb"
    }
    spec = {
      controllerName = "gateway.aws/aws-gateway-api-controller"
    }
  }

  depends_on = [aws_eks_addon.eks_addons]
}

resource "kubernetes_manifest" "api_gateway" {
  count = var.enable_gateway_api ? 1 : 0

  manifest = {
    apiVersion = "gateway.networking.k8s.io/v1"
    kind       = "Gateway"
    metadata = {
      name      = "api-gateway"
      namespace = "default"
      annotations = {
        "alb.ingress.kubernetes.io/scheme"          = "internet-facing"
        "alb.ingress.kubernetes.io/target-type"     = "ip"
        "alb.ingress.kubernetes.io/listen-ports"    = "[{\"HTTPS\": 443}]"
        "alb.ingress.kubernetes.io/certificate-arn" = var.acm_certificate_arn
        "alb.ingress.kubernetes.io/ssl-policy"      = "ELBSecurityPolicy-TLS13-1-2-2021-06"
      }
    }
    spec = {
      gatewayClassName = "aws-alb"
      listeners = [
        {
          name     = "https"
          port     = 443
          protocol = "HTTPS"
          hostname = "api.${var.domain_name}"
          tls = {
            mode = "Terminate"
          }
        }
      ]
    }
  }

  depends_on = [kubernetes_manifest.gateway_class]
}

# Data source to get the ALB information from the Gateway
data "kubernetes_resource" "gateway_status" {
  count = var.enable_gateway_api ? 1 : 0

  api_version = "gateway.networking.k8s.io/v1"
  kind        = "Gateway"
  metadata = {
    name      = "api-gateway"
    namespace = "default"
  }

  depends_on = [kubernetes_manifest.api_gateway]
}

locals {
  # Extract ALB DNS name and zone ID from Gateway status
  gateway_status = var.enable_gateway_api ? data.kubernetes_resource.gateway_status[0].object.status : null

  alb_hostname = var.enable_gateway_api && local.gateway_status != null ? (
    try(local.gateway_status.addresses[0].value, "")
  ) : ""

  # AWS ALB zone IDs by region
  alb_zone_ids = {
    "us-east-1"      = "Z35SXDOTRQ7X7K"
    "us-east-2"      = "Z3AADJGX6KTTL2"
    "us-west-1"      = "Z368ELLRRE2KJ0"
    "us-west-2"      = "Z1H1FL5HABSF5"
    "ap-northeast-1" = "Z14GRHDCWA56QT"
    "ap-northeast-2" = "ZWKZPGTI48KDX"
    "ap-south-1"     = "ZP97RAFLXTNZK"
    "ap-southeast-1" = "Z1LMS91P8CMLE5"
    "ap-southeast-2" = "Z1GM3OXH4ZPM65"
    "eu-central-1"   = "Z3F0SRJ5LGBH90"
    "eu-west-1"      = "Z32O12XQLNTSW2"
    "eu-west-2"      = "ZHURV8PSTC4K8"
    "eu-west-3"      = "Z3Q77PNBQS71R4"
  }

  alb_zone_id = var.enable_gateway_api ? lookup(local.alb_zone_ids, var.aws_region, "ZWKZPGTI48KDX") : ""
}