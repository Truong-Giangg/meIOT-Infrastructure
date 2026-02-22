variable "proxmox_url" {
  description = "Proxmox API URL"
  type        = string
  default     = "https://proxmox.meiot.site:8006"
}

variable "proxmox_user" {
  description = "Proxmox API user"
  type        = string
  default     = "root@pam"
}

variable "proxmox_password" {
  description = "Proxmox API password (no default; set via environment or tfvars)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "pm_tls_insecure" {
  description = "Skip TLS verification for Proxmox API (use only in test environments)"
  type        = bool
  default     = true
}

variable "proxmox_node" {
  description = "Proxmox target node name for VMs"
  type        = string
  default     = "proxmox-node"
}

variable "storage" {
  description = "Proxmox storage for VM disks (e.g., local-lvm)"
  type        = string
  default     = "local-lvm"
}

variable "network_bridge" {
  description = "Bridge on Proxmox to attach VM NICs"
  type        = string
  default     = "vmbr0"
}

variable "vm_count" {
  description = "Number of VMs to create"
  type        = number
  default     = 3
}

variable "vm_name_prefix" {
  description = "Prefix for VM names"
  type        = string
  default     = "rke-node"
}

variable "start_vmid" {
  description = "Starting VMID (will increment for each VM)"
  type        = number
  default     = 100
}

variable "vm_cores" {
  description = "Number of CPU cores per VM"
  type        = number
  default     = 2
}

variable "vm_memory_mb" {
  description = "Memory (MB) per VM"
  type        = number
  default     = 4096
}

variable "vm_disk_gb" {
  description = "Disk size (GB) per VM"
  type        = number
  default     = 40
}

variable "ssh_pub_key" {
  description = "Path to SSH public key to inject via cloud-init"
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}

variable "cloud_init_user" {
  description = "Default cloud-init user for the VM"
  type        = string
  default     = "ubuntu"
}
