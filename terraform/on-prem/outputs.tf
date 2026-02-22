output "vm_names" {
  description = "Names of created VMs"
  value       = [for vm in proxmox_vm_qemu.rke_node : vm.name]
}

output "vm_ips" {
  description = "IPs (if available) of created VMs"
  value       = [for vm in proxmox_vm_qemu.rke_node : try(vm.ip, "")]
}
