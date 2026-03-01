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

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "private_subnet_cidrs" {
  description = "List of CIDR blocks for private subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

variable "public_subnet_cidrs" {
  description = "List of CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
}

variable "enable_nat_gateway" {
  description = "Enable NAT Gateway for private subnet internet access"
  type        = bool
  default     = true
}

variable "single_nat_gateway" {
  description = "Use a single NAT Gateway for all private subnets (cost optimization)"
  type        = bool
  default     = true
}
