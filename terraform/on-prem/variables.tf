variable "proxmox_url" {
  description = "Proxmox API URL"
  type        = string
  default     = "https://proxmox.example.local:8006"
}

variable "proxmox_user" {
  description = "Proxmox API user"
  type        = string
  default     = "root@pam"
}
