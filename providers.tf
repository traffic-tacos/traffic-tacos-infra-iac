terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.38.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 3.0.2"
    }
  }
}

provider "aws" {
  region = var.region
  default_tags {
    tags = {
      Project   = "ticket-traffic"
      ManagedBy = "terraform"
    }
  }
}

provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
  default_tags {
    tags = {
      Project   = "ticket-traffic"
      ManagedBy = "terraform"
    }
  }
}

provider "kubernetes" {
  # Use conditional configuration to avoid connection issues during initial deployment
  host                   = try(module.eks.cluster_endpoint, "https://kubernetes.default.svc")
  cluster_ca_certificate = try(base64decode(module.eks.cluster_certificate_authority_data), "")
  # insecure               = true # Only for initial deployment

  dynamic "exec" {
    for_each = can(module.eks.cluster_id) ? [1] : []
    content {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args = [
        "eks",
        "get-token",
        "--cluster-name",
        module.eks.cluster_id,
        "--region",
        var.region
      ]
    }
  }
}

provider "helm" {
  kubernetes = {
    host                   = try(module.eks.cluster_endpoint, "https://kubernetes.default.svc")
    cluster_ca_certificate = try(base64decode(module.eks.cluster_certificate_authority_data), "")
    # insecure               = true # Only for initial deployment

    exec = can(module.eks.cluster_id) ? {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args = [
        "eks",
        "get-token",
        "--cluster-name",
        module.eks.cluster_id,
        "--region",
        var.region
      ]
    } : null
  }
}
  