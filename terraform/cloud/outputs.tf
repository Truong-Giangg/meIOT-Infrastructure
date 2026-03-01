output "cluster_name" {
  description = "EKS cluster name"
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "EKS cluster API endpoint"
  value       = module.eks.cluster_endpoint
}

output "cluster_id" {
  description = "EKS cluster ID"
  value       = module.eks.cluster_id
}

output "cluster_security_group_id" {
  description = "Security group ID of the EKS cluster"
  value       = module.eks.cluster_security_group_id
}

output "node_security_group_id" {
  description = "Security group ID of the EKS nodes"
  value       = module.eks.node_security_group_id
}

output "aws_region" {
  description = "AWS region where the cluster is deployed"
  value       = var.aws_region
}

output "vpc_id" {
  description = "VPC ID where the cluster is deployed"
  value       = aws_vpc.main.id
}

output "private_subnet_ids" {
  description = "IDs of private subnets"
  value       = aws_subnet.private[*].id
}

output "public_subnet_ids" {
  description = "IDs of public subnets"
  value       = aws_subnet.public[*].id
}

output "kubectl_config_command" {
  description = "Command to configure kubectl for the EKS cluster"
  value       = "aws eks update-kubeconfig --region ${var.aws_region} --name ${module.eks.cluster_name}"
}

output "configure_kubectl_instruction" {
  description = "Instructions for configuring kubectl"
  value       = <<-EOT
    Run the following command to configure kubectl:
    
    aws eks update-kubeconfig --region ${var.aws_region} --name ${module.eks.cluster_name}
    
    Then verify with:
    kubectl get nodes
  EOT
}
