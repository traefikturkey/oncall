variable "vm_id" {
 description = "Virtual Machine to import ID"
 type        = string
}

variable "node" {
 description = "Proxmox node name"
 type        = string
 default     = "pve"
}

variable "token_secret" {
 description = "PVE token secret value"
 type        = string
 sensitive   = true
}

variable "token_id" {
 description = "Proxmox token name"
 type        = string
}

variable "pve_ip" {
 description = "Proxmox node IP"
 type        = string
}