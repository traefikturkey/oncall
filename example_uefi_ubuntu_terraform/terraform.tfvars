# Example tfvars
cpu_cores            = "2"
ram_amount           = "4096"
vmname               = "testvm"
vm_id                = "0"
templatename         = "linux-ubuntu-24.04-lts"
vlantag              = "0"
virt_switch          = "vmbr0"
disk_datastore       = "local-lvm"
disk_size            = "30G"
ipconfig_set         = "dhcp"
cloud_user           = "ubuntu"
pub_ssh_key_path     = "~/.ssh/id_rsa.pub"
proxmox_api_url      = "https://192.168.1.2:8006/api2/json"
proxmox_token_secret = ""
token_id             = "root@pam!terraform"



