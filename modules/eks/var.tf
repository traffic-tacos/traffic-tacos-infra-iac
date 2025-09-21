variable "cluster_name" {
    type = string
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
  default = 50
}

variable "spot_disk_size" {
  default = 30
}

variable "bastion_host_ip" {
  type        = string
}

# variable "eks_access_users" {
#   type        = list(string)
#   default     = ["syeon", "dabin", "yoojunghuh", "hyeonmin", "tyler"]
# }

variable "aws_account_id" {
    type = string
    default = "137406935518"
  
}

variable "eks_addons" {   
  default = [
    {
      name = "vpc-cni"
      version = "v1.20.1-eksbuild.3"
    },
    {
      name = "kube-proxy"
      version = "v1.33.3-eksbuild.6"
    },
    {
      name = "eks-pod-identity-agent"
      version = "v1.3.8-eksbuild.2"
    },
    {
      name = "eks-node-monitoring-agent"
      version = "v1.4.0-eksbuild.2"
    },
    {   
      name = "coredns"
      version = "v1.12.3-eksbuild.1"
    },
    {
      name = "aws-ebs-csi-driver"
      version = "v1.48.0-eksbuild.2"
    },
    {
      name = "cert-manager"
      version = "v1.18.2-eksbuild.2"
    }
  ]
}
