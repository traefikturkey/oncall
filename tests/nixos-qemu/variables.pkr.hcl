variable "build_username" {
  type        = string
  description = "The username to login to the guest operating system."
  default     = "deploy"
}

variable "build_password_encrypted" {
  type        = string
  description = "The encrypted password to login to the guest operating system."
  default     = "$6$MsfTs/5vjdnlgqEt$pkl1uGs645Y1NLpzQu7R/coOohkyzksn2YkY2EgjOuXkA6Tnrr3Yag8LYeotfYaiiyIzn3MyYCWdeqM.2VKAz1"
}

variable "disk_size" {
  type        = string
  description = "The output disk size for the QEMU image."
  default     = "32G"
}

variable "headless" {
  type        = bool
  description = "Run the local QEMU test headless."
  default     = false
}

variable "iso_checksum" {
  type        = string
  description = "The checksum value of the ISO image."
}

variable "iso_url" {
  type        = string
  description = "The NixOS ISO URL or local file path."
}

variable "output_directory" {
  type        = string
  description = "The directory where the built QEMU artifact will be written."
  default     = "output/nixos-25.11"
}

variable "shutdown_timeout" {
  type        = string
  description = "How long to wait for the installer to shut down."
  default     = "45m"
}

variable "vm_bios" {
  type        = string
  description = "The firmware type. The local QEMU smoke test uses BIOS by default."
  default     = "seabios"
}

variable "vm_boot_wait" {
  type        = string
  description = "The time to wait after booting the ISO before typing boot commands."
  default     = "5s"
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

variable "vm_dns_list" {
  type        = list(string)
  description = "The DNS servers of the VM."
  default     = []
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
  description = "The network device name configured inside NixOS."
  default     = "eth0"
}

variable "vm_os_name" {
  type        = string
  description = "The guest operating system name."
  default     = "nixos"
}

variable "vm_os_version" {
  type        = string
  description = "The guest operating system version."
  default     = "25.11"
}
