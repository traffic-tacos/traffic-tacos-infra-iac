variable "cluster_name" {
  type    = string
  default = "ticket-cluster"
}
variable "vpc_id" {
  type = string
}

variable "vpc_cidr" {
  type = string
}

variable "cluster_version" {
  default = "1.33"
}
variable "private_subnet_ids" {
  type = list(string)
}

variable "ondemand_disk_size" {
  type    = number
  default = 50
}

variable "mix_disk_size" {
  type    = number
  default = 30
}

variable "monitoring_disk_size" {
  type    = number
  default = 30

}

variable "bastion_host_ip" {
  type = string
}

# variable "eks_access_users" {
#   type        = list(string)
#   default     = ["syeon", "dabin", "yoojunghuh", "hyeonmin", "tyler"]
# }

variable "aws_account_id" {
  type    = string
  default = "137406935518"

}

variable "eks_addons" {
  default = [
    {
      name    = "vpc-cni"
      version = "v1.20.1-eksbuild.3"
    },
    {
      name    = "kube-proxy"
      version = "v1.33.3-eksbuild.6"
    },
    {
      name    = "eks-pod-identity-agent"
      version = "v1.3.8-eksbuild.2"
    },
    {
      name    = "eks-node-monitoring-agent"
      version = "v1.4.0-eksbuild.2"
    },
    {
      name    = "coredns"
      version = "v1.12.3-eksbuild.1"
    },
    {
      name    = "aws-ebs-csi-driver"
      version = "v1.48.0-eksbuild.2"
    },
    {
      name    = "cert-manager"
      version = "v1.18.2-eksbuild.2"
    },
    {
      name    = "kube-state-metrics"
      version = "v2.17.0-eksbuild.1"
    },
    {
      name    = "metrics-server"
      version = "v0.8.0-eksbuild.2"
    }
    # Note: aws-gateway-api-controller is not supported in Kubernetes 1.33
    # {
    #   name    = "aws-gateway-api-controller"
    #   version = "v1.3.0-eksbuild.1"
    # },
  ]
}

variable "enable_gateway_api" {
  description = "Enable Gateway API support"
  type        = bool
  default     = true
}

variable "domain_name" {
  description = "Domain name for Gateway hostname"
  type        = string
  default     = ""
}

variable "acm_certificate_arn" {
  description = "ARN of ACM certificate for HTTPS"
  type        = string
  default     = ""
}

variable "aws_region" {
  description = "AWS region for ALB zone ID mapping"
  type        = string
  default     = "ap-northeast-2"
}

variable "mix_instance_types" {
  type    = list(string)
  default = ["t3.medium", "t3.large", "t3.xlarge"]
}
