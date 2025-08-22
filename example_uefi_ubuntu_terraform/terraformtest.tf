resource "proxmox_vm_qemu" "main" {
    target_node = var.proxmox_node
    name = var.vmname
    vmid = var.vm_id
    os_type = "cloud-init"
    bios = "ovmf" # to use UEFI
    # The template name to clone this vm from
    clone = var.templatename
    # Activate QEMU agent for this VM
    agent = 1

    cpu {
        cores = var.cpu_cores
        sockets = 1
    }
    memory = var.ram_amount

    network {
        id = 0
        model = "virtio"
        bridge = var.virt_switch
        tag = var.vlantag
        firewall = false
     }

    scsihw   = "virtio-scsi-single" 
    boot     = "order=virtio0;net0"
    bootdisk = "virtio0"
    
    disks {
        virtio {
            virtio0 {
                disk{
                    storage = var.disk_datastore
                    size    = var.disk_size
                }
            }
        }
        ide {
            ide0 {
                cloudinit {
                    storage = var.disk_datastore
                }
            }
       }
    }
    efidisk {
        efitype = "4m"
        storage = var.disk_datastore
        pre_enrolled_keys = false
    }     

    # Cloud-init options
    # Keep in mind to use the CIDR notation for the ip.
    ipconfig0 = var.ipconfig_set
    ciuser = var.cloud_user
    sshkeys = file(var.pub_ssh_key_path)
}
