packer {
  required_version = ">= 1.12.0"
  required_plugins {
    qemu = {
      source  = "github.com/hashicorp/qemu"
      version = "~> 1"
    }
  }
}

locals {
  install_disk = "/dev/${var.vm_disk_device}"
  data_source_content = {
    "/configuration.nix" = templatefile("${abspath(path.root)}/../../builds/linux/nixos/25.11/data/configuration.pkrtpl.nix", {
      build_username           = var.build_username
      build_password_encrypted = var.build_password_encrypted
      vm_bios                  = var.vm_bios
      vm_disk_device           = var.vm_disk_device
      vm_network_device        = var.vm_network_device
      vm_ip_address            = var.vm_ip_address
      vm_ip_netmask            = var.vm_ip_netmask
      vm_ip_gateway            = var.vm_ip_gateway
      vm_dns_list              = var.vm_dns_list
      vm_os_name               = var.vm_os_name
      vm_os_version            = var.vm_os_version
    })
    "/install.sh" = templatefile("${abspath(path.root)}/install.pkrtpl.sh", {
      install_disk = local.install_disk
    })
  }
  boot_command = [
    "<enter><wait180s>",
    "mkdir -p /tmp/nixos-config<enter><wait>",
    "sudo mount -L CIDATA /tmp/nixos-config || sudo mount /dev/sr1 /tmp/nixos-config || sudo mount /dev/sr0 /tmp/nixos-config<enter><wait2s>",
    "sudo sh /tmp/nixos-config/install.sh<enter><wait60s>",
  ]
}

source "qemu" "nixos" {
  boot_command     = local.boot_command
  boot_wait        = var.vm_boot_wait
  boot_key_interval = "100ms"
  communicator     = "none"
  cpus             = var.vm_cpu_count
  disk_cache       = "writeback"
  disk_compression = true
  disk_interface   = "virtio"
  disk_size        = var.disk_size
  format           = "qcow2"
  headless         = var.headless
  cd_content       = local.data_source_content
  cd_label         = "CIDATA"
  iso_checksum     = var.iso_checksum
  iso_url          = var.iso_url
  memory           = var.vm_mem_size
  net_device       = var.vm_network_card_model
  output_directory = var.output_directory
  qemuargs = [
    ["-serial", "file:${abspath(path.root)}/serial.log"]
  ]
  shutdown_timeout = var.shutdown_timeout
  vm_name          = "${var.vm_os_name}-${var.vm_os_version}-qemu"
}

build {
  sources = ["source.qemu.nixos"]
}
