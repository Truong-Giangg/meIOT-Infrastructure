// Terraform configuration to provision Proxmox VMs (3 by default)
terraform {
  required_version = ">= 1.0"
  required_providers {
    proxmox = {
      source  = "Telmate/proxmox"
      version = ">= 2.9.0"
    }
  }
}

provider "proxmox" {
  pm_api_url      = var.proxmox_url
  pm_user         = var.proxmox_user
  pm_password     = var.proxmox_password
  pm_tls_insecure = var.pm_tls_insecure
}

# Create a small set of VMs for RKE / testing
resource "proxmox_vm_qemu" "rke_node" {
  count       = var.vm_count
  name        = "${var.vm_name_prefix}-${count.index + 1}"
  target_node = var.proxmox_node
  vmid        = var.start_vmid + count.index

  cores   = var.vm_cores
  sockets = 1
  memory  = var.vm_memory_mb

  # disk on storage (format: <storage>:<size>G)
  scsi0 = "${var.storage}:${var.vm_disk_gb}G"

  # simple NIC on bridge
  net0 = "virtio,bridge=${var.network_bridge}"

  # Cloud-init user and SSH keys (requires cloud-init template or support)
  ciuser  = var.cloud_init_user
  sshkeys = file(var.ssh_pub_key)

  onboot   = true
  hotplug  = "network,disk,usb"
  autostart = true
}

// Outputs to help identify created VMs
output "vm_ids" {
  description = "List of created VM IDs"
  value       = [for vm in proxmox_vm_qemu.rke_node : vm.vmid]
}

