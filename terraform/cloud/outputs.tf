output "cluster_name" {
  description = "Requested EKS cluster name (created via eksctl)"
  value       = var.cluster_name
}

output "note" {
  description = "Note about provisioning"
  value       = "This Terraform configuration uses local-exec to call eksctl. The cluster kubeconfig is managed by eksctl; run 'eksctl utils write-kubeconfig --cluster=${var.cluster_name} --region=${var.aws_region}' to write kubeconfig."
}
