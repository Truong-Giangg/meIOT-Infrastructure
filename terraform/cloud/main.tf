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

# Note: This configuration uses a local `null_resource` (see `eksctl.tf`) to run `eksctl create cluster`.
# The optional upstream module was removed to avoid provider/module input mismatches in this repository.
