/*
    DESCRIPTION:
    NixOS 25.11 template using the Packer Builder for Proxmox (proxmox-iso).
*/

//  BLOCK: packer
//  The Packer configuration.

packer {
  required_version = ">= 1.12.0"
  required_plugins {
    ansible = {
      source  = "github.com/hashicorp/ansible"
      version = "~> 1"
    }
    git = {
      version = ">= 0.6.2"
      source  = "github.com/ethanmdavidson/git"
    }
    proxmox = {
      version = "= 1.2.1"
      source  = "github.com/hashicorp/proxmox"
    }
  }
}

//  BLOCK: data
//  Defines the data sources.

data "git-repository" "cwd" {}

//  BLOCK: locals
//  Defines the local variables.

locals {
  build_by          = "Built by: HashiCorp Packer ${packer.version}"
  build_date        = formatdate("DD-MM-YYYY hh:mm ZZZ", "${timestamp()}")
  build_version     = data.git-repository.cwd.head
  build_description = "Version: ${local.build_version}\nBuilt on: ${local.build_date}\n${local.build_by}\nCloud-Init: ${var.vm_cloudinit}"
  manifest_date     = formatdate("YYYY-MM-DD hh:mm:ss", timestamp())
  manifest_path     = "${path.cwd}/manifests/"
  manifest_output   = "${local.manifest_path}${local.manifest_date}.json"
  vm_name           = "${var.vm_os_family}-${var.vm_os_name}-${var.vm_os_version}"
  install_disk      = "/dev/${var.vm_disk_device}"
  efi_partition     = "${local.install_disk}1"
  root_partition    = var.vm_bios == "ovmf" ? "${local.install_disk}2" : "${local.install_disk}1"
  partition_command = var.vm_bios == "ovmf" ? "parted -s ${local.install_disk} mklabel gpt mkpart ESP fat32 1MiB 512MiB set 1 esp on mkpart primary ext4 512MiB 100%" : "parted -s ${local.install_disk} mklabel msdos mkpart primary ext4 1MiB 100% set 1 boot on"
  config_copy_command = var.common_data_source == "http" ? "curl -fsSL http://{{ .HTTPIP }}:{{ .HTTPPort }}/configuration.nix -o /mnt/etc/nixos/configuration.nix" : "mkdir -p /tmp/nixos-config && mount /dev/sr1 /tmp/nixos-config && cp /tmp/nixos-config/configuration.nix /mnt/etc/nixos/configuration.nix"
  data_source_content = {
    "/configuration.nix" = templatefile("${abspath(path.root)}/data/configuration.pkrtpl.nix", {
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
  }
  boot_command = concat([
    "<enter><wait90s>",
    "${local.partition_command}<enter><wait5s>",
  ], var.vm_bios == "ovmf" ? [
    "mkfs.fat -F 32 ${local.efi_partition}<enter><wait5s>",
  ] : [], [
    "mkfs.ext4 -F ${local.root_partition}<enter><wait5s>",
    "mount ${local.root_partition} /mnt<enter><wait2s>",
  ], var.vm_bios == "ovmf" ? [
    "mkdir -p /mnt/boot<enter><wait>",
    "mount ${local.efi_partition} /mnt/boot<enter><wait2s>",
  ] : [], [
    "nixos-generate-config --root /mnt<enter><wait10s>",
    "${local.config_copy_command}<enter><wait5s>",
    "nixos-install --no-root-password<enter><wait300s>",
    "shutdown -h now<enter>",
  ])
  vm_bios = var.vm_bios == "ovmf" ? var.vm_firmware_path : null
}

//  BLOCK: source
//  Defines the builder configuration blocks.

source "proxmox-iso" "nixos" {

  // Proxmox Connection Settings and Credentials
  proxmox_url              = "https://${var.proxmox_hostname}:8006/api2/json"
  username                 = "${var.proxmox_api_token_id}"
  token                    = "${var.proxmox_api_token_secret}"
  insecure_skip_tls_verify = "${var.proxmox_insecure_connection}"

  // Proxmox Settings
  node = "${var.proxmox_node}"

  // Virtual Machine Settings
  vm_name         = "${local.vm_name}"
  bios            = "${var.vm_bios}"
  sockets         = "${var.vm_cpu_sockets}"
  cores           = "${var.vm_cpu_count}"
  cpu_type        = "${var.vm_cpu_type}"
  memory          = "${var.vm_mem_size}"
  os              = "${var.vm_os_type}"
  scsi_controller = "${var.vm_disk_controller_type}"
  vm_id           = var.vm_id_number

  disks {
    disk_size    = "${var.vm_disk_size}"
    type         = "${var.vm_disk_type}"
    storage_pool = "${var.vm_storage_pool}"
    format       = "${var.vm_disk_format}"
  }

  dynamic "efi_config" {
    for_each = var.vm_bios == "ovmf" ? [1] : []
    content {
      efi_storage_pool  = var.vm_bios == "ovmf" ? var.vm_efi_storage_pool : null
      efi_type          = var.vm_bios == "ovmf" ? var.vm_efi_type : null
      pre_enrolled_keys = var.vm_bios == "ovmf" ? var.vm_efi_pre_enrolled_keys : null
    }
  }

  ssh_username = "${var.build_username}"
  ssh_password = "${var.build_password}"
  ssh_timeout  = "${var.timeout}"
  ssh_port     = "22"
  qemu_agent   = true

  network_adapters {
    bridge   = "${var.vm_bridge_interface}"
    model    = "${var.vm_network_card_model}"
    vlan_tag = "${var.vm_vlan_tag}"
  }

  // Removable Media Settings
  http_content = var.common_data_source == "http" ? local.data_source_content : null

  // Boot and Provisioning Settings
  http_interface    = var.common_data_source == "http" ? var.common_http_interface : null
  http_bind_address = var.common_data_source == "http" ? var.common_http_bind_address : null
  http_port_min     = var.common_data_source == "http" ? var.common_http_port_min : null
  http_port_max     = var.common_data_source == "http" ? var.common_http_port_max : null
  boot              = var.vm_boot
  boot_wait         = var.vm_boot_wait
  boot_command      = local.boot_command

  boot_iso {
    iso_file     = "${var.common_iso_storage}:${var.iso_path}/${var.iso_file}"
    unmount      = true
    iso_checksum = "${var.iso_checksum}"
  }

  dynamic "additional_iso_files" {
    for_each = var.common_data_source == "disk" ? [1] : []
    content {
      cd_files         = var.common_data_source == "disk" ? local.data_source_content : null
      cd_label         = var.common_data_source == "disk" ? "cidata" : null
      iso_storage_pool = var.common_data_source == "disk" ? "local" : null
    }
  }

  template_name        = "${local.vm_name}"
  template_description = "${local.build_description}"

  # VM Cloud Init Settings
  cloud_init              = var.vm_cloudinit
  cloud_init_storage_pool = var.vm_cloudinit == true ? var.vm_storage_pool : null
  cloud_init_disk_type    = var.vm_cloudinit_disk_type
}

# Build Definition to create the VM Template
build {
  sources = ["source.proxmox-iso.nixos"]

  provisioner "ansible" {
    user                   = var.build_username
    galaxy_file            = "${path.cwd}/ansible/linux-requirements.yml"
    galaxy_force_with_deps = true
    playbook_file          = "${path.cwd}/ansible/linux-playbook.yml"
    roles_path             = "${path.cwd}/ansible/roles"
    ansible_env_vars = [
      "ANSIBLE_CONFIG=${path.cwd}/ansible/ansible.cfg",
      "ANSIBLE_PYTHON_INTERPRETER=/run/current-system/sw/bin/python3"
    ]
    extra_arguments = [
      "--extra-vars", "display_skipped_hosts=false",
      "--extra-vars", "build_username=${var.build_username}",
      "--extra-vars", "build_key='${var.build_key}'",
      "--extra-vars", "ansible_username=${var.ansible_username}",
      "--extra-vars", "ansible_key='${var.ansible_key}'",
      "--extra-vars", "enable_cloudinit='${var.vm_cloudinit}'",
    ]
  }

  post-processor "manifest" {
    output     = local.manifest_output
    strip_path = true
    strip_time = true
    custom_data = {
      ansible_username      = "${var.ansible_username}"
      build_username        = "${var.build_username}"
      build_date            = "${local.build_date}"
      build_version         = "${local.build_version}"
      common_data_source    = "${var.common_data_source}"
      vm_cpu_sockets        = "${var.vm_cpu_sockets}"
      vm_cpu_count          = "${var.vm_cpu_count}"
      vm_disk_size          = "${var.vm_disk_size}"
      vm_bios               = "${var.vm_bios}"
      vm_os_type            = "${var.vm_os_type}"
      vm_mem_size           = "${var.vm_mem_size}"
      vm_network_card_model = "${var.vm_network_card_model}"
      vm_cloudinit          = "${var.vm_cloudinit}"
    }
  }
}
