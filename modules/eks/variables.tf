variable "cluster_name" {
  type        = string
  description = "Name of the EKS cluster"
}

variable "cluster_version" {
  type        = string
  description = "Kubernetes version to use for the cluster"
}

variable "vpc_create" {
  type        = bool
  description = "Whether to create a new VPC or use existing"
  default     = true
}

variable "vpc_name" {
  type        = string
  description = "Name of the VPC"
}

variable "node_groups" {
  type = map(object({
    desired_capacity = number
    min_capacity     = number
    max_capacity     = number
    instance_type    = string
    key_name         = optional(string)
    name             = optional(string)
  }))
  description = "Map of node group configurations"
}

variable "manage_aws_auth" {
  type        = bool
  description = "Whether to manage the aws-auth ConfigMap"
  default     = true
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to all resources"
  default     = {}
}
