variable "additional_packages" {
  type        = list(string)
  description = "Additional packages to install."
  default     = []
}

variable "build_username" {
  type        = string
  description = "The username to login to the guest operating system."
  default     = "deploy"
}

variable "build_password" {
  type        = string
  description = "The password to login to the guest operating system."
  default     = "deploy"
}

variable "build_password_encrypted" {
  type        = string
  description = "The encrypted password to login to the guest operating system."
  default     = "$6$MsfTs/5vjdnlgqEt$pkl1uGs645Y1NLpzQu7R/coOohkyzksn2YkY2EgjOuXkA6Tnrr3Yag8LYeotfYaiiyIzn3MyYCWdeqM.2VKAz1"
}

variable "build_key" {
  type        = string
  description = "The SSH public key to login to the build user. Defaults to the local QEMU test key."
  default     = ""
}

variable "ansible_username" {
  type        = string
  description = "The username Ansible creates for later image access."
  default     = "ansible"
}

variable "ansible_key" {
  type        = string
  description = "The public key Ansible installs for the Ansible user. Defaults to the local QEMU test key."
  default     = ""
}

variable "disk_size" {
  type        = string
  description = "The output disk size for the QEMU image."
  default     = "32G"
}

variable "headless" {
  type        = bool
  description = "Run the local QEMU test headless."
  default     = true
}

variable "iso_checksum" {
  type        = string
  description = "The checksum value of the ISO image."
}

variable "iso_url" {
  type        = string
  description = "The Ubuntu ISO URL or local file path."
}

variable "output_directory" {
  type        = string
  description = "The directory where the built QEMU artifact will be written."
  default     = "output/ubuntu-26.04-lts"
}

variable "shutdown_timeout" {
  type        = string
  description = "How long to wait for the installed guest to shut down."
  default     = "15m"
}

variable "ssh_timeout" {
  type        = string
  description = "How long to wait for SSH after installation."
  default     = "10m"
}

variable "ssh_authorized_keys" {
  type        = list(string)
  description = "Public SSH keys authorized for the build user."
  default     = []
}

variable "ssh_private_key_file" {
  type        = string
  description = "Private SSH key file Packer should use for the build user."
  default     = null
}

variable "use_fixed_ssh_key" {
  type        = bool
  description = "Use the configured local SSH key instead of letting Packer generate a temporary key."
  default     = true
}

variable "vm_bios" {
  type        = string
  description = "The firmware type. The local QEMU smoke test uses BIOS by default."
  default     = "seabios"
}

variable "vm_boot_wait" {
  type        = string
  description = "The time to wait after booting the ISO before typing boot commands."
  default     = "10s"
}

variable "vm_cpu_count" {
  type        = number
  description = "The number of virtual CPUs."
  default     = 2
}

variable "vm_disk_device" {
  type        = string
  description = "The guest disk device name used during installation."
  default     = "vda"
}

variable "vm_disk_lvm" {
  description = "LVM configuration passed to the storage template."
  default     = []
}

variable "vm_disk_partitions" {
  description = "Partition configuration passed to the storage template."
  default = [
    {
      name = "autopart"
      format = {
        fstype = "simple"
      }
    }
  ]
}

variable "vm_disk_use_swap" {
  type        = bool
  description = "Whether the storage template should configure swap."
  default     = true
}

variable "vm_dns_list" {
  type        = list(string)
  description = "The DNS servers of the VM."
  default     = []
}

variable "vm_ip_address" {
  type        = string
  description = "The IP address of the VM."
  default     = null
}

variable "vm_ip_gateway" {
  type        = string
  description = "The gateway of the VM."
  default     = null
}

variable "vm_ip_netmask" {
  type        = number
  description = "The netmask of the VM."
  default     = null
}

variable "vm_mem_size" {
  type        = number
  description = "The size for the virtual memory in MB."
  default     = 4096
}

variable "vm_network_card_model" {
  type        = string
  description = "The virtual network adapter to emulate."
  default     = "virtio-net"
}

variable "vm_network_device" {
  type        = string
  description = "The network device name configured inside Ubuntu."
  default     = "ens3"
}

variable "vm_os_keyboard" {
  type        = string
  description = "The guest operating system keyboard layout."
  default     = "us"
}

variable "vm_os_language" {
  type        = string
  description = "The guest operating system language."
  default     = "en_US"
}

variable "vm_os_name" {
  type        = string
  description = "The guest operating system name."
  default     = "ubuntu"
}

variable "vm_os_timezone" {
  type        = string
  description = "The guest operating system timezone."
  default     = "UTC"
}

variable "vm_os_version" {
  type        = string
  description = "The guest operating system version."
  default     = "26.04-lts"
}

variable "vm_cloudinit" {
  type        = bool
  description = "Whether the Ansible roles should leave cloud-init enabled."
  default     = true
}

variable "run_ansible" {
  type        = bool
  description = "Whether to run the shared Ansible provisioning roles during the QEMU smoke test."
  default     = true
}
