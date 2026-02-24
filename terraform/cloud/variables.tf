variable "aws_region" {
  description = "AWS region for EKS"
  type        = string
  default     = "us-east-1"
}

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = "meiot-eks"
}

variable "cluster_version" {
  description = "Kubernetes version for the cluster"
  type        = string
  default     = "1.27"
}

variable "node_instance_type" {
  description = "EC2 instance type for worker nodes (choose free-tier compatible like t3.micro)"
  type        = string
  default     = "t3.micro"
}

variable "node_desired_capacity" {
  description = "Desired number of nodes in the node group"
  type        = number
  default     = 1
}

variable "node_min_capacity" {
  description = "Minimum size of the node group"
  type        = number
  default     = 1
}

variable "node_max_capacity" {
  description = "Maximum size of the node group"
  type        = number
  default     = 1
}

variable "key_name" {
  description = "SSH key pair name to attach to nodes (leave empty to skip)"
  type        = string
  default     = ""
}
