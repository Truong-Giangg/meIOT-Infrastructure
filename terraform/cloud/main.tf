// Terraform skeleton for AWS EKS
terraform {
  required_version = ">= 1.0"
}

provider "aws" {
  region = var.aws_region
}

variable "aws_region" {
  description = "AWS region for EKS"
  type        = string
  default     = "us-east-1"
}

# Add EKS module or resources (e.g., eks, vpc, node groups) here.
