# main.tf - This is where I define my providers

terraform {
  required_providers {
    proxmox = {
      source = "telmate/proxmox"
      version = "3.0.2-rc01"
    }
  }
}

provider "proxmox" {
    pm_tls_insecure = true
    pm_api_url = "https://${var.pve_ip}:8006/api2/json"
    pm_api_token_secret = var.token_secret
    pm_api_token_id = var.token_id
}

resource "proxmox_vm_qemu" "importvm" {
  name        = "importvm"
  target_node = var.node
  vmid        = var.vm_id
}