# Terraform import

Run the commands 
- `mv terraform.tfvars.example terraform.tfvars`
- Update terraform.tfvars as required
- `./import.sh`

## Initial configuration
Update the [terraform.tfvars](terraform.tfvars.example) file with the appropriate values, minimum required updates are marked below

```
# terraform.tfvars
node            = "pve"  # ***This needs to be exactly what the Proxmox node is named***
vm_id           = "100"  # ***The VM ID of the vm you want to import***
token_secret    = ""  # ***Needs updated***
token_id        = "root@pam!terraform"  # ***Needs updated***
pve_ip          = "192.168.1.50"  # ***the IP of the Proxmox node***
```

## NOTES

telmate/promxox hasn't fully upgraded to support Proxmox 9.x yet.  As a workaround, I've added a line to the main.tf to not do the minimum permissions check.

- Added line:
- `pm_minimum_permission_check = false`