packer {
  required_version = ">= 1.12.0"
  required_plugins {
    ansible = {
      source  = "github.com/hashicorp/ansible"
      version = "~> 1"
    }
    qemu = {
      source  = "github.com/hashicorp/qemu"
      version = "~> 1"
    }
  }
}

locals {
  ssh_private_key_file = var.use_fixed_ssh_key ? var.ssh_private_key_file : null
  ssh_authorized_keys  = var.use_fixed_ssh_key ? var.ssh_authorized_keys : []
  build_key            = var.build_key != "" ? var.build_key : (length(local.ssh_authorized_keys) > 0 ? local.ssh_authorized_keys[0] : "")
  ansible_key          = var.ansible_key != "" ? var.ansible_key : (length(local.ssh_authorized_keys) > 0 ? local.ssh_authorized_keys[0] : "")
  data_source_content = {
    "/meta-data" = file("${abspath(path.root)}/meta-data")
    "/user-data" = templatefile("${abspath(path.root)}/user-data.pkrtpl.hcl", {
      build_username           = var.build_username
      build_password_encrypted = var.build_password_encrypted
      ssh_authorized_keys      = local.ssh_authorized_keys
      vm_os_timezone           = var.vm_os_timezone
    })
  }
}

source "qemu" "ubuntu" {
  boot_wait            = var.vm_boot_wait
  cd_content           = local.data_source_content
  cd_label             = "CIDATA"
  communicator         = "ssh"
  ssh_username         = var.build_username
  ssh_password         = var.build_password
  ssh_private_key_file = local.ssh_private_key_file
  ssh_timeout          = var.ssh_timeout
  cpus                 = var.vm_cpu_count
  disk_image           = true
  disk_cache           = "writeback"
  disk_compression     = true
  disk_interface       = "virtio"
  disk_size            = var.disk_size
  format               = "qcow2"
  headless             = var.headless
  iso_checksum         = var.iso_checksum
  iso_url              = var.iso_url
  memory               = var.vm_mem_size
  net_device           = var.vm_network_card_model
  output_directory     = var.output_directory
  qemuargs             = [["-serial", "file:${var.output_directory}/serial.log"]]
  shutdown_command     = "echo '${var.build_password}' | sudo -S shutdown -P now"
  shutdown_timeout     = var.shutdown_timeout
  vm_name              = "${var.vm_os_name}-${var.vm_os_version}-qemu"
}

build {
  sources = ["source.qemu.ubuntu"]

  provisioner "ansible" {
    only                   = var.run_ansible ? ["qemu.ubuntu"] : ["skip.ansible"]
    user                   = var.build_username
    galaxy_file            = "${abspath(path.root)}/../../ansible/linux-requirements.yml"
    galaxy_force_with_deps = true
    playbook_file          = "${abspath(path.root)}/../../ansible/linux-playbook.yml"
    roles_path             = "${abspath(path.root)}/../../ansible/roles"
    ansible_env_vars = [
      "ANSIBLE_CONFIG=${abspath(path.root)}/../../ansible/ansible.cfg",
      "ANSIBLE_PYTHON_INTERPRETER=/usr/bin/python3"
    ]
    extra_arguments = [
      "--extra-vars", "display_skipped_hosts=false",
      "--extra-vars", "build_username=${var.build_username}",
      "--extra-vars", "build_key='${local.build_key}'",
      "--extra-vars", "ansible_username=${var.ansible_username}",
      "--extra-vars", "ansible_key='${local.ansible_key}'",
      "--extra-vars", "enable_cloudinit='${var.vm_cloudinit}'",
    ]
  }
}
