output "cluster_id" {
  description = "The ID of the EKS cluster"
  value       = module.upstream.cluster_id
}

output "cluster_name" {
  description = "The name of the EKS cluster"
  value       = module.upstream.cluster_name
}

output "cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = module.upstream.cluster_endpoint
}

output "cluster_security_group_id" {
  description = "Security group ID attached to the EKS cluster"
  value       = module.upstream.cluster_security_group_id
}

output "node_security_group_id" {
  description = "Security group ID attached to the EKS nodes"
  value       = module.upstream.node_security_group_id
}

output "cluster_iam_role_arn" {
  description = "IAM role ARN of the EKS cluster"
  value       = module.upstream.cluster_iam_role_arn
}

output "cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data required to communicate with the cluster"
  value       = module.upstream.cluster_certificate_authority_data
  sensitive   = true
}
