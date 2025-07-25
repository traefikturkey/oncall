# Packer Examples for Proxmox

## Table of Contents

1. [Introduction](#introduction)
1. [Requirements](#requirements)
1. [Download](#download)
1. [Configuration](#configuration)
1. [Packer Machine Image Builds](#packer-machine-image-builds)
1. [Terraform](#terraform)
1. [Troubleshoot](#troubleshoot)
1. [Known Issues](#known-issues)
1. [Unsupported Features](#unsupported-features)
1. [Contributing](#contributing)
1. [Credits](#credits)

## Introduction

This repository provides opinionated infrastructure-as-code examples to automate the creation of virtual machine images and their guest operating systems on Proxmox using [HashiCorp Packer][packer] and the [Packer Plugin for Proxmox][packer-plugin-proxmox] (`proxmox-iso` builder). All examples are authored in the HashiCorp Configuration Language ("HCL2").

By default, the machine image artifacts are converted to templates within Proxmox after a virtual machine is built and configured according to the individual templates.

The following builds are available:

## Linux Distributions

| Operating System | Version   | Custom Storage Config | Static IP Support  | UEFI Bootloader    | BIOS Bootloader    | pve static vm_id   |
| :---             | :---      | :---:                 | :---:              | :---:              | :---:              | :---:              |
| AlmaLinux        | 10        | &check;               | &check;            | &check;            | &check;            | random             |
| AlmaLinux        | 9         | &check;               | &check;            | &check;            | &check;            | random             |
| AlmaLinux        | 8         | &check;               | &check;            | &check;            | &check;            | random             |
| CentOS Stream    | 10        | &check;               | &check;            | &check;            | &check;            | 10013              |
| CentOS Stream    | 9         | &check;               | &check;            | &check;            | &check;            | 10014              |
| Debian           | 12        | &check;               | &check;            | &check;            | &check;            | 10011              |
| Debian           | 11        | &check;               | &check;            | &check;            | &check;            | 10012              |
| OpenSUSE Leap    | 15.6      | &check;               | &check;            | &check;            | &check;            | 10010              |
| OpenSUSE Leap    | 15.5      | &check;               | &check;            | &check;            | &check;            | 10009              |
| Oracle Linux     | 9         | &check;               | &check;            | &check;            | &check;            | 10007              |
| Oracle Linux     | 8         | &check;               | &check;            | &check;            | &check;            | 10008              |
| Rocky Linux      | 10        | &check;               | &check;            | &check;            | &check;            | 10004              |
| Rocky Linux      | 9         | &check;               | &check;            | &check;            | &check;            | 10005              |
| Rocky Linux      | 8         | &check;               | &check;            | &check;            | &check;            | 10006              |
| Ubuntu Server    | 24.04 LTS | &check;               | &check;            | &check;            | &check;            | 10001              |
| Ubuntu Server    | 22.04 LTS | &check;               | &check;            | &check;            | &check;            | 10000              |
| Ubuntu Server    | 20.04 LTS | &check;               | &check;            | &check;            | &check;            | 10003              |
| Windows Desktop  | 11        |                       |                    | &check;            | N/A                | random             |

## Requirements

**Operating Systems**:

Operating systems and versions tested with the project:

- Proxmox PVE Version >= 8
- Ubuntu Server 22.04 LTS (`x86_64`)
- CentOS Stream 9 (`x86_64`)

**Packer**:

- HashiCorp [Packer][packer-install] 1.12.0 or higher.

  > **Note**
  >
  > Click on the operating system name to display the installation steps.

  - <details>
      <summary>Ubuntu</summary>

    The Terraform packages are signed using a private key controlled by HashiCorp, so you must configure your system to trust that HashiCorp key for package authentication.

    To configure your repository:

    ```shell
    sudo bash -c 'wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor > /usr/share/keyrings/hashicorp-archive-keyring.gpg'
    ```

    Verify the key's fingerprint:

    ```shell
    gpg --no-default-keyring --keyring /usr/share/keyrings/hashicorp-archive-keyring.gpg --fingerprint
    ```

    The fingerprint must match E8A0 32E0 94D8 EB4E A189 D270 DA41 8C88 A321 9F7B. You can also verify the key on [Security at HashiCorp][hcp-security] under Linux Package Checksum Verification.

    Add the official HashiCorp repository to your system:

    ```shell
    sudo bash -c 'echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] \
    https://apt.releases.hashicorp.com $(lsb_release -cs) main" > /etc/apt/sources.list.d/hashicorp.list'
    ```

    Install Packer from HashiCorp repository:

    ```shell
    sudo apt update && sudo apt install packer
    ```

    </details>

  - <details>
      <summary>CentOS Stream 9</summary>

    Install `yum-config-manager` to manage your repositories.

    ```shell
    sudo yum install -y yum-utils
    ```

    Use `yum-config-manager` to add the official HashiCorp Linux repository:

    ```shell
    sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo
    ```

    Install.

    ```shell
    sudo yum -y install packer
    ```
    </details>


- Packer plugins:

  > **Note**
  >
  > Required plugins are automatically downloaded and initialized when using `./build.sh`. For dark sites, you may download the plugins and place these same directory as your Packer executable `/usr/local/bin` or `$HOME/.packer.d/plugins`.

  - [Packer Plugin for Git][packer-plugin-git] 0.6.2 or later - a community plugin for HashiCorp Packer.
  - HashiCorp [Packer Plugin for Proxmox-ISO][packer-plugin-proxmox] version 1.2.1 - the plugin for HashiCorp Packer to communicate with Proxmox VE. This needs to be pinned to version 1.2.1 at this time due to a [CPU bug](https://github.com/hashicorp/packer-plugin-proxmox/issues/307).

**Ansible**:

- [Ansible][ansible] [Core][ansible-core] version 2.14 or higher.

  > **Note**
  >
  > Click on the operating system name to display the installation steps.

  - <details>
      <summary>Ubuntu</summary>

    It is recommended that you install ansible-core using your system's package manager instead of via pip.

    Refresh the repositories:
    ```shell
    sudo apt update
    ```

    Install software-properties-common:
    ```shell
    sudo apt install -y software-properties-common
    ```

    Add the Ansible repository to your system:

    ```shell
    sudo add-apt-repository --yes --update ppa:ansible/ansible
    ```

    Install ansible-core from the Ansible repository:

    ```shell
    sudo apt install -y ansible-core
    ```

    </details>


  - <details>
      <summary>CentOS Stream 9</summary>

    It is recommended that you install ansible using your system's package manager instead of via pip.

    Install.

    ```shell
    dnf -y install ansible
    ```
    </details>


**Platform**:

- Proxmox PVE 8.0 or later.

# Download

After installing the required software, the quickest way to get building is to clone this repository.

```shell
git clone https://github.com/ajschroeder/packer-examples-for-proxmox.git
cd packer-examples-for-proxmox
```

The following table describes the directory structure.

| Directory       | Description                                                                              |
| :---            | :---                                                                                     |
| **`ansible`**   | Contains the Ansible roles to prepare Linux machine image builds.                        |
| **`builds`**    | Contains the templates, variables, and configuration files for the machine image builds. |
| **`manifests`** | Manifests created after the completion of the machine image builds.                      |


# Configuration

## Example Variables

The project includes example variables files that you can use as a starting point for your own configuration.

The [variables][packer-variables] are defined in `.pkrvars.hcl` files.

Run the config script `./config.sh` to copy the `.pkrvars.hcl.example` files to a `config` directory.

```shell
./config.sh
./build.sh
```

The `config` folder is the default folder. You can override the default by passing an alternate value as the first argument.

For example:

San Francisco: `us-west-1`

```shell
./config.sh us-west-1
./build.sh us-west-1
```

Los Angeles: `us-west-2`

```shell
./config.sh us-west-2
./build.sh us-west-2
```

This is useful for the purposes of running machine image builds for different environment.

## Configuration Variables

## Proxmox Virtual Machine IDs
Each template has a preset static vm_id.

These can be changed by editing the `./config/*/(linux or windows)-(*).pkr.hcl` files.

### Ansible Variables

Edit the `config/ansible.pkrvars.hcl` file to configure the credentials for the Ansible account on Linux machine images.

```hcl title="config/ansible.pkrvars.hcl"
ansible_username = "ansible"
ansible_key      = "<public_key>"
```

**Ansible User Password**

A random password is auto-generated for the Ansible user.

### Build Variables

Edit the `config/build.pkrvars.hcl` file to configure the credentials for the default account on machine images.

```hcl title="config/build.pkrvars.hcl"
build_username           = "example"
build_password           = "<plaintext_password>"
build_password_encrypted = "<sha512_encrypted_password>"
build_key                = "<public_key>"
```

You will need to generate a SHA-512 encrypted password for the `build_password_encrypted` using tools like `mkpasswd`.

Run the following command to generate a SHA-512 encrypted password:

```shell
mkpasswd -m sha512crypt
```

The following output is displayed:

```shell
Password: ***************
[password hash]
```

Generate a public key for the `build_key` for public key authentication.

Run the following command to generate a public key for the `build_key` for public key authentication.

```shell
ssh-keygen -t ecdsa -b 512 -C "<name@example.com>"
```

The following output is displayed:

```shell
Generating public/private ecdsa key pair.
Enter file in which to save the key (/Users/example/.ssh/id_ecdsa):
Enter passphrase (empty for no passphrase): **************
Enter same passphrase again: **************
Your identification has been saved in /Users/example/.ssh/id_ecdsa.
Your public key has been saved in /Users/example/.ssh/id_ecdsa.pub.
```

The content of the public key, `build_key`, is added the key to the `~/.ssh/authorized_keys` file of the `build_username` on the Linux guest operating systems.

> [!IMPORTANT]
>
> Make sure to replace the example public keys and passwords!
>
> By default, both Public Key Authentication and Password Authentication are enabled for Linux distributions.
>
> If you wish to disable Password Authentication and only use Public Key Authentication, comment or remove the portion of the associated Ansible `configure` role.

### Common Variables

Edit the `config/common.pkrvars.hcl` file to configure the following common variables:

- Removable Media Settings
- Boot and Provisioning Settings
- HCP Packer Registry

```hcl title="config/common.pkrvars.hcl"
// Removable Media Settings
common_iso_storage = "<Proxmox Storage Location>"

// Boot and Provisioning Settings
common_data_source       = "http"
common_http_interface    = null
common_http_bind_address = null
common_http_port_min     = 8000
common_http_port_max     = 8099
common_ip_wait_timeout   = "20m"
common_shutdown_timeout  = "15m"

// HCP Packer
common_hcp_packer_registry_enabled = false
```

#### Data Source

The default provisioning data source for Linux machine image builds is `http`. This is used to serve the kickstart files to the Linux guest operating system during the build.

```hcl title="config/common.pkrvars.hcl"
common_data_source = "http"
```

> **Note**
>
>    Packer includes a built-in HTTP server that is used to serve the kickstart files for Linux machine image builds.
>
>    If iptables/nftables is enabled on your Packer host, you will need to open `common_http_port_min` through `common_http_port_max` ports.
>
>    iptables command:
>    ```shell
>    iptables -A INPUT -p tcp --match multiport --dports 8000:9000 -j ACCEPT
>    ```
>
>    firewall-cmd example:
>    ```shell
>    firewall-cmd --zone=public --add-port=8000-9000/tcp --permanent
>    firewall-cmd --reload
>    ```

You can change the `common_data_source` from `http` to `disk` to build supported Linux machine images without the need to use Packer's HTTP server. This is useful for environments that may not be able to route back to the system from which Packer is running. For example, building a machine image in VMware Cloud on AWS.

```hcl title="config/common.pkrvars.hcl"
common_data_source = "disk"
```

The Packer plugin's `cd_content` option is used when selecting `disk` unless the distribution does not support a secondary CD-ROM.

#### HTTP Interface

Name of the network interface that Packer gets `HTTPIP` from. Defaults to the first non loopback interface.

```hcl title="config/common.pkrvars.hcl"
common_http_interface = "eth2"
```

#### HTTP Bind Address

IP address on the build server to bind the Packer HTTP instance to. Must be an interface that is reachable from the Proxmox server.
```hcl title="config/common.pkrvars.hcl"
common_http_bind_address = 172.16.15.97"
```

### Network Variables

Edit the `config/network.pkrvars.hcl` file to configure the following:

#### Proxmox Specific Network Variables for VM Templates
These variables are used by Packer to configure the network interface for the VM template. These are specific to your environment. For example, to use the default `vmbr0` interface and the tag for VLAN 102, you would set it as follows:

```hcl title="config/network.pkrvars.hcl"
// Proxmox settings for VM templates
vm_bridge_interface  = "vmbr0"
vm_vlan_tag          = "102"
```

Configuring a static IP address under the `configs/network.pkrvars.hcl` file is supported. If you want to use DHCP for the templates then leave these variables commented out. The default is DHCP.

> **Note**
>
> - These settings are site specific for each Proxmox host and are going to be needed regardless if you use DHCP or static IP addresses.

#### Static IP address settings
The Packer build templates default to using DHCP, however, you can use static IP addressing for your VM templates. Simply uncomment the following vars and configure to your specific requirements:

```hcl title="config/network.pkrvars.hcl"
vm_ip_address = "192.168.101.100"
vm_ip_netmask = 24
vm_ip_gateway = "192.168.101.1"
vm_dns_list   = [ "8.8.8.8", "8.8.4.4" ]
```

> **Note**
>
> - If you need/want to go back to using DHCP, just comment these variables out again and the templates should go back to using DHCP.

### Proxmox Variables

Edit the `config/proxmox.pkrvars.hcl` file to configure the following:

- Promxox Endpoint and Credentials

```hcl title="config/proxmox.pkrvars.hcl"
// Proxmox Credentials
proxmox_api_token_id        = "name@realm!token"
proxmox_api_token_secret    = "<token secret>"
proxmox_insecure_connection = false

// Proxmox Specific Settings
proxmox_hostname = "<FQDN or IP of proxmox server>"
proxmox_node     = "<proxmox node name>"
```

The `proxmox_api_token_id` variable uses a specific format and, as the time of this writing, needs to be assigned to the `PVEAdmin` role. One of the to-do's is to document a least-privilege method of creating the Proxmox API token.

For more information, please see the [Proxmox documentation][proxmox-api-tokens] on authentication.

For Proxmox installs that use a self-signed certificate, you will want to set `proxmox_insecure_connection` to `true`.

### Storage Variables

Edit the `config/linux-storage.pkrvars.hcl` file to configure storage for VM templates.

#### Disk Device

```hcl
// VM Storage Settings
vm_disk_device     = "vda"
```

`vm_disk_device`:`string` - This variable depends on the disk controller used inside of the specific `.auto.pkrvars.hcl` file. By default, the builds use the `virtio-scsi-pci` disk controller and that requires the use of `vda`. If you decide to use a non-virtio controller, then you'll have to change the `vm_disk_device` variable to the appropriate device.

#### EFI Device
```hcl
vm_efi_storage_pool      = "pool0"
vm_efi_type              = "4m"
vm_efi_pre_enrolled_keys = false
```

#### Disk Partitions

`vm_disk_partitions`:`list[dict]` - Use this list to define the primary partitions that will be created when a specific build runs. Each of the builds process this list in order, so the first partition defined in the list will be the first partition created, the second one listed will be the second one created, and so on.

> **Note**
>
> - All partition sizes are in MegaBytes (MB)
> - If you want to have a partition consume all available free space, you can indicate that with `-1`

##### Partitioning Examples

<details>
  <summary>Single Partition Example for BIOS bootloaders</summary>
Below is an example of a partition layout for a VM template that boots with BIOS and uses a single partition for the OS.

```hcl title="config/linux-storage.pkrvars.hcl"
// VM Storage Settings
vm_disk_device     = "vda"
vm_disk_use_swap   = true
vm_disk_partitions = [
  {
    name = "root"
    size = -1,
    format = {
      label  = "ROOTFS",
      fstype = "ext4",
    },
    mount = {
      path    = "/",
      options = "",
    },
    volume_group = "",
  },
]
```
</details>

<details>
  <summary>Single Partition Example for UEFI bootloaders</summary>
This example is similar to the above example except that it has the extra partitions needed for the UEFI (OVMF) bootloader. Note the extra variables for the EFI settings.

```hcl title="config/linux-storage.pkrvars.hcl"
// VM EFI Settings
vm_efi_storage_pool      = "pool0"
vm_efi_type              = "4m"
vm_efi_pre_enrolled_keys = false

// VM Storage Settings
vm_disk_device     = "vda"
vm_disk_use_swap   = true
vm_disk_partitions = [
  {
    name = "efi"
    size = 1024,
    format = {
      label  = "EFIFS",
      fstype = "fat32",
    },
    mount = {
      path    = "/boot/efi",
      options = "",
    },
    volume_group = "",
  },
  {
    name = "boot"
    size = 1024,
    format = {
      label  = "BOOTFS",
      fstype = "ext4",
    },
    mount = {
      path    = "/boot",
      options = "",
    },
    volume_group = "",
  },
  {
    name = "root"
    size = -1,
    format = {
      label  = "ROOTFS",
      fstype = "ext4",
    },
    mount = {
      path    = "/",
      options = "",
    },
    volume_group = "",
  },
]
```
</details>

<details>
  <summary>LVM Partitioning Example with CIS partitions for UEFI bootloaders</summary>
This is a more complex example of a partition layout for a VM template that uses LVM and has volumes with mount options required by CIS for hardening a linux system.


```hcl title="config/linux-storage.pkrvars.hcl"
//VM EFI Settings
vm_efi_storage_pool      = "pool0"
vm_efi_type              = "4m"
vm_efi_pre_enrolled_keys = false

// UEFI VM Storage Settings
vm_disk_device     = "vda"
vm_disk_use_swap   = true
vm_disk_partitions = [
  {
    name = "efi"
    size = 1024,
    format = {
      label  = "EFIFS",
      fstype = "fat32",
    },
    mount = {
      path    = "/boot/efi",
      options = "",
    },
    volume_group = "",
  },
  {
    name = "boot"
    size = 1024,
    format = {
      label  = "BOOTFS",
      fstype = "ext4",
    },
    mount = {
      path    = "/boot",
      options = "",
    },
    volume_group = "",
  },
  {
    name = "sysvg"
    size = -1,
    format = {
      label  = "",
      fstype = "",
    },
    mount = {
      path    = "",
      options = "",
    },
    volume_group = "sysvg",
  },
]
vm_disk_lvm = [
  {
    name: "sysvg",
    partitions: [
      {
        name = "lv_swap",
        size = 1024,
        format = {
          label  = "SWAPFS",
          fstype = "swap",
        },
        mount = {
          path    = "",
          options = "",
        },
      },
      {
        name = "lv_root",
        size = 10240,
        format = {
          label  = "ROOTFS",
          fstype = "ext4",
        },
        mount = {
          path    = "/",
          options = "",
        },
      },
      {
        name = "lv_home",
        size = 4096,
        format = {
          label  = "HOMEFS",
          fstype = "ext4",
        },
        mount = {
          path    = "/home",
          options = "nodev,nosuid",
        },
      },
      {
        name = "lv_opt",
        size = 2048,
        format = {
          label  = "OPTFS",
          fstype = "ext4",
        },
        mount = {
          path    = "/opt",
          options = "nodev",
        },
      },
      {
        name = "lv_tmp",
        size = 4096,
        format = {
          label  = "TMPFS",
          fstype = "ext4",
        },
        mount = {
          path    = "/tmp",
          options = "nodev,noexec,nosuid",
        },
      },
      {
        name = "lv_var",
        size = 2048,
        format = {
          label  = "VARFS",
          fstype = "ext4",
        },
        mount = {
          path    = "/var",
          options = "nodev",
        },
      },
      {
        name = "lv_var_tmp",
        size = 1000,
        format = {
          label  = "VARTMPFS",
          fstype = "ext4",
        },
        mount = {
          path    = "/var/tmp",
          options = "nodev,noexec,nosuid",
        },
      },
      {
        name = "lv_var_log",
        size = 4096,
        format = {
          label  = "VARLOGFS",
          fstype = "ext4",
        },
        mount = {
          path    = "/var/log",
          options = "nodev,noexec,nosuid",
        },
      },
      {
        name = "lv_var_audit",
        size = 500,
        format = {
          label  = "AUDITFS",
          fstype = "ext4",
        },
        mount = {
          path    = "/var/log/audit",
          options = "nodev,noexec,nosuid",
        },
      },
    ],
  }
]
```
</details>


## Packer Machine Image Builds

Edit the `<build type>.pkrvars.hcl` file in the `config` directory for each type of build to set the following virtual machine hardware settings, as required:

- CPUs `(int)`
- CPU Cores `(int)`
- Memory in MB `(int)`
- Primary Disk in MB `(string)` (e.g. 32GB)
- .iso Path `(string)`
- .iso File `(string)`

```hcl title="config/linux-ubuntu-22-04-lts.pkrvars.hcl"
// Guest Operating System Metadata
vm_os_language   = "en_US"
vm_os_keyboard   = "us"
vm_os_timezone   = "UTC"
vm_os_family     = "linux"
vm_os_name       = "ubuntu"
vm_os_version    = "22.04-lts"

// Virtual Machine Guest Operating System Setting
vm_os_type       = "l26"
vm_cloudinit     = true

// Virtual Machine Hardware Settings
vm_bios                 = "ovmf"
vm_cpu_count            = 1
vm_cpu_sockets          = 1
vm_cpu_type             = "kvm64"
vm_mem_size             = 2048
vm_disk_type            = "virtio"
vm_disk_size            = "32G"
vm_disk_format          = "raw"
vm_disk_controller_type = "virtio-scsi-pci"
vm_network_card_model   = "virtio"

// Removable Media Settings
iso_path     = "iso"
iso_file     = "ubuntu-22.04-live-server-amd64.iso"
// The checksum can be a URL or an actual checksum value. URL is preferred
iso_checksum = "file:https://releases.ubuntu.com/jammy/SHA256SUMS"

// Boot Settings
vm_boot      = "order=virtio0;ide2;net0"
vm_boot_wait = "5s"

// EFI Settings
vm_firmware_path         = "./OVMF.fd"
```

> **Note**
>
>   All `config/<build type>.pkrvars.hcl` default to using:
>   - VirtIO SCSI storage device
>   - VirtIO (paravirtualized) network card device
>   - UEFI boot firmware

The defaults use VirtIO to balance out performance, compatibility, and ease of use. Feel free to change the storage and network controllers to suit your needs. However, if you change the storage or network controllers and run into issues you should change them back to defaults and try the builds again. I won't support any builds that don't use the VirtIO drivers.

Both UEFI and BIOS booting are supported for builds. Inside the `<build type>.pkrvars.hcl` file specific to the build, you can set the `vm_bios` variable to either `seabios` for BIOS or `ovmf` for UEFI booting.

> **Note**
>
>   The storage layouts are different for each bootloader type so you'll need to configure the storage layouts accordingly.

# Terraform
An example Terraform for a UEFI Ubuntu 24.04 template is included.  For more information [go here](example_uefi_ubuntu_terraform/README.md)

There is also a script to import an existing vm to use as an example for building Terraform builds.  For more information [go here](terraform_import/README.md)

### Cloud-Init
All builds for operating systems that support [cloud-init][cloud-init] now have the option to enable it. This can be done on a per-build basis inside the `<build type>.pkrvars.hcl` files in the `config` directory. The default setting is `true`.

If a particular linux distribution ships with cloud-init (e.g. Ubuntu) and cloud-init is set to `false` in the `config/<build type>.pkrvars.hcl` file for the build, then cloud-init will be disabled in the operating system **and** within Proxmox for that specific template.

# Known Issues

## Windows Builds
For obvious reasons, product keys and actual ISO names are not provided for any of the Windows builds in this repository. For example, if you wanted to build a Windows 11 template VM, the Windows 11 build uses the Windows 11 Enterprise Eval ISO. By default packer will build the Windows 11 Enterprise Eval whether you choose the Pro or Enterprise build when running `build.sh`. Also, this build by default should not require any interventions by a human.

If you have a valid product key and want to build a Windows 11 Pro or Enterprise template VM, you will need to change the following variables (if building Pro you don't need to change Enterprise vars and vice versa):

```hcl title="config/windows-desktop-11.pkrvars.hcl"
vm_inst_os_image_pro = "Windows 11 Enterprise Evaluation"   <-- If building Professional with a valid key, you will need to enter in whatever the name of the Operating System is when the Windows install prompts you
vm_inst_os_key_pro   = "XXXXX-XXXXX-XXXXX-XXXXX-XXXXX"
vm_inst_os_image_ent = "Windows 11 Enterprise Evaluation"   <-- If building Enterprise with a valid key, you can remove the Evaluation from this string
vm_inst_os_key_ent   = "XXXXX-XXXXX-XXXXX-XXXXX-XXXXX"
...
iso_file             = "Name-of-Windows-11-Non-Evaluation-DVD.iso"  <-- This is the name of the real Windows 11 DVD
```

If your template build hangs or times out, re-run it and then open the console of the template VM and see if Windows is waiting for you to select an Operating System. Select the Operating System version and then click Next and the build should work hands-off the rest of the way. If you want this to be completely hands-off, just change the `vm_inst_os_image_pro` and/or `vm_inst_os_image_ent` vars to match the Operating System selection entry exactly. Then the next time you execute the particular Windows template build, it shouldn't get stuck waiting for input.

# Unsupported Features

# Contributing
Contributions are welcome, please read the [CONTRIBUTING](.github/CONTRIBUTING.md) document for more details.

# Credits
The repository is modeled after the [VMware Packer Examples][packer-examples-for-vsphere] repository. As someone who initially struggled with organization of a packer project, the VMware repository helped me significantly.

Forked from [here](https://github.com/ajschroeder/proxmox-packer-examples) with some minor tweaks by the traefikturkey team.  Credit goes to [TheHitman1977](https://github.com/ajschroeder) for the initial work.

[//]: Links
[ansible]: https://www.ansible.com
[ansible-core]: https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html#selecting-an-ansible-package-and-version-to-install
[cloud-init]: https://cloud-init.io/
[packer]: https://www.packer.io
[packer-examples-for-vsphere]: https://github.com/vmware-samples/packer-examples-for-vsphere
[packer-install]: https://developer.hashicorp.com/packer/tutorials/docker-get-started/get-started-install-cli
[packer-plugin-git]: https://github.com/ethanmdavidson/packer-plugin-git
[packer-plugin-proxmox]: https://developer.hashicorp.com/packer/integrations/hashicorp/proxmox
[packer-variables]: https://developer.hashicorp.com/packer/docs/templates/hcl_templates/variables
[proxmox-api-tokens]: https://pve.proxmox.com/pve-docs/pveum-plain.html


[^1]: If you try to create a VM with the same ID as an existing VM the Proxmox API will generate a 500 error.
