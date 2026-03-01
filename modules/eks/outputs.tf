output "cluster_id" {
  value = module.upstream.cluster_id
}
output "cluster_endpoint" {
  value = module.upstream.cluster_endpoint
}
output "kubeconfig" {
  value     = module.upstream.kubeconfig
  sensitive = true
}
output "kubeconfig_raw" {
  value     = module.upstream.kubeconfig_raw
  sensitive = true
}
