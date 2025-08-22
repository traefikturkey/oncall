# Terraform

## Initial configuration
Update the [terraform.tfvars](terraform.tfvars) file with the appropriate values, minimum required updates are marked below

```
# terraform.tfvars
cpu_sockets = "2"
ram_amount = "4096"
vmname = "testvm"   # ***Needs updated***
vm_id = "0"
templatename = "linux-ubuntu-24.04-lts"   # ***Needs updated***
ram_amount = "4096"
vlantag = "0"
virt_switch = "vmbr0"
disk_datastore = "local-lvm"
disk_size = "30G"
ipconfig_set = "dhcp"
cloud_user = "ubuntu"
pub_ssh_key_path = "~/.ssh/id_rsa.pub"   # ***Needs updated***
pm_api_url = "https://192.168.1.2:8006/api2/json"  # ***Needs updated***
pm_api_token_secret = ""  # ***Needs updated***
pm_api_token_id = "root@pam!terraform"  # ***Needs updated***
```

Run the commands 
- `terraform init`
- `terraform plan`
- `terraform apply` or `terraform apply --auto-approve`

## NOTES

telmate/promxox hasn't fully upgraded to support Proxmox 9.x yet.  As a workaround, I've added a line to the main.tf to not do the minimum permissions check.

- Added line:
- `pm_minimum_permission_check = false`