#!/usr/bin/env bash
clear

file="./terraform.tfstate"

if [ -f "$file" ]; then
  echo "File '$file' exists. Removing..."
  rm -rf "$file"
else
  echo "$file doesn't exist, starting import"
fi

TFVARS_FILE="terraform.tfvars"

vmid=$(grep -E '^vm_id\s*=' "$TFVARS_FILE" | awk -F'=' '{print $2}' | tr -d ' "')
pvenode=$(grep -E '^node\s*=' "$TFVARS_FILE" | awk -F'=' '{print $2}' | tr -d ' "')

echo -n "This will import vm $vmid from $pvenode. The import name will be 'importvm' in the $vmid-$(date +"%Y%m%d-%H%M").tfstate file "
echo -n ""
terraform import proxmox_vm_qemu.importvm ${pvenode}/vm/${vmid}

mv terraform.tfstate $vmid-$(date +"%Y%m%d-%H%M").tfstate

echo "Complete, exiting"
