terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# Local EKS module
module "eks" {
  source = "../../modules/eks"

  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version

  node_groups = {
    default = {
      desired_capacity = var.node_desired_capacity
      min_capacity     = var.node_min_capacity
      max_capacity     = var.node_max_capacity
      instance_type    = var.node_instance_type
      key_name         = var.key_name
    }
  }
}

# Note: This configuration also includes an eksctl-based fallback in eksctl.tf
