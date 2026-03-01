terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0"
    }
  }
}

# A thin wrapper around the upstream EKS module so the repo can reference a
# local path. All variables are forwarded.
module "upstream" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.0"

  # Note: The upstream module uses "name" not "cluster_name"
  name                = var.cluster_name
  kubernetes_version  = var.cluster_version

  vpc_id              = var.vpc_id
  subnet_ids          = var.subnet_ids
  control_plane_subnet_ids = var.subnet_ids

  # Node groups - simplified for free tier
  eks_managed_node_groups = {
    for name, config in var.node_groups : name => merge(
      config,
      {
        # Upstream expects these names
        name           = config.name != null ? config.name : name
        min_size       = config.min_capacity
        max_size       = config.max_capacity
        desired_size   = config.desired_capacity
        instance_types = [config.instance_type]
      }
    )
  }

  tags = var.tags
}

