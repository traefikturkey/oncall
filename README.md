# MTEA FSG Infrastructure Automation

**Modoc Tribal Enterprise Authority (MTEA)**  
**Federal Services Group (FSG)**  
Network Automation & Infrastructure-as-Code

---

## Table of Contents

- [Introduction](#introduction)
- [Supported Operating Systems](#supported-operating-systems)
- [Quick Start](#quick-start)
- [Requirements](#requirements)
- [Configuration Guide](#configuration-guide)
- [Building VM Templates](#building-vm-templates)
- [Docker Usage](#docker-usage)
- [Advanced Configuration](#advanced-configuration)
- [Troubleshooting](#troubleshooting)
- [CI/CD Integration](#cicd-integration)
- [Credits](#credits)

---

## Introduction

This repository provides MTEA FSG's infrastructure-as-code tooling for automating the creation of virtual machine templates on Proxmox. Built with [HashiCorp Packer](https://www.packer.io) and [Ansible](https://www.ansible.com), these tools enable consistent, repeatable deployment of standardized VM images across the MTEA FSG network infrastructure.

### Key Features

- ✅ **Automated VM Template Creation** - Build production-ready templates with a single command
- ✅ **Multi-Distribution Support** - Linux (Ubuntu, RHEL family, Debian, SUSE) and Windows 11
- ✅ **Customizable Storage Layouts** - Simple partitions, LVM, and CIS-compliant configurations
- ✅ **Network Flexibility** - Static IP or DHCP configuration
- ✅ **Cloud-Init Ready** - Modern cloud-init support for rapid provisioning
- ✅ **Dual Boot Support** - UEFI and BIOS bootloader options
- ✅ **Docker Containerized** - Consistent builds across Windows, macOS, and Linux
- ✅ **Infrastructure-as-Code** - Version controlled with HCL2

---

## Supported Operating Systems

| Operating System | Version   | Custom Storage | Static IP | UEFI | BIOS | VM ID |
| :---             | :---      | :---:          | :---:     | :---:| :---:| :---: |
| AlmaLinux        | 10, 9, 8  | ✓              | ✓         | ✓    | ✓    | random|
| CentOS Stream    | 10, 9     | ✓              | ✓         | ✓    | ✓    | 10013-14|
| Debian           | 12, 11    | ✓              | ✓         | ✓    | ✓    | 10011-12|
| OpenSUSE Leap    | 15.6, 15.5| ✓              | ✓         | ✓    | ✓    | 10009-10|
| Oracle Linux     | 9, 8      | ✓              | ✓         | ✓    | ✓    | 10007-08|
| Rocky Linux      | 10, 9, 8  | ✓              | ✓         | ✓    | ✓    | 10004-06|
| Ubuntu Server    | 26.04, 24.04, 22.04, 20.04 LTS | ✓ | ✓    | ✓    | ✓    | 10000-03, 10015|
| Windows Desktop  | 11        |                |           | ✓    |      | random|

All templates include:
- QEMU Guest Agent for improved VM management
- SSH access with key-based authentication
- Ansible automation user pre-configured
- Cloud-init support (Linux)
- Latest security updates at build time

---

## Quick Start

### Prerequisites

- [Docker](https://docs.docker.com/get-docker/) and [Docker Compose](https://docs.docker.com/compose/install/) installed
- Access to MTEA FSG Proxmox infrastructure (v8.0+)
- Proxmox API token with appropriate permissions

### 3-Step Setup

#### 1. Clone and Initialize

```bash
git clone <repository-url>
cd <repository-name>
./docker-build.sh setup
```

This builds the Docker image and creates configuration template files in `./config/`.

#### 2. Configure for MTEA FSG

Edit configuration files in the `config/` directory:

**Essential configuration files:**

- **`proxmox.pkrvars.hcl`** - Proxmox API credentials and node
- **`build.pkrvars.hcl`** - VM build user credentials  
- **`ansible.pkrvars.hcl`** - Ansible automation user
- **`network.pkrvars.hcl`** - MTEA FSG network (VLANs, subnets)
- **`linux-storage.pkrvars.hcl`** - Storage pools and partitions

<details>
<summary>Example: Proxmox Configuration</summary>

```hcl
// config/proxmox.pkrvars.hcl
proxmox_api_token_id        = "packer@pam!packer-token"
proxmox_api_token_secret    = "<your-api-token-secret>"
proxmox_insecure_connection = true
proxmox_hostname            = "proxmox.mtea.local"
proxmox_node                = "pve-node-01"
```
</details>

<details>
<summary>Example: Network Configuration</summary>

```hcl
// config/network.pkrvars.hcl
vm_bridge_interface = "vmbr0"
vm_vlan_tag         = "100"

// Optional: Static IP (defaults to DHCP if commented)
// vm_ip_address = "10.10.10.100"
// vm_ip_netmask = 24
// vm_ip_gateway = "10.10.10.1"
// vm_dns_list   = ["10.10.10.10", "10.10.10.11"]
```
</details>

#### 3. Build a Template

```bash
./docker-build.sh build
```

Select your desired OS from the interactive menu (e.g., option 15 for Ubuntu 24.04 LTS).

### Validation

Validate all templates before building:

```bash
./docker-build.sh validate
```

---

## Requirements

### Infrastructure Platform
- **Proxmox VE** 8.0 or later

### Docker Environment (Recommended)
- Docker 20.10+
- Docker Compose 2.0+

All dependencies (Packer, Ansible, plugins) are included in the Docker image.

### Manual Installation (Alternative)

<details>
<summary>Ubuntu - Install Packer & Ansible</summary>

```bash
# Add HashiCorp repository
sudo bash -c 'wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor > /usr/share/keyrings/hashicorp-archive-keyring.gpg'
sudo bash -c 'echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] \
https://apt.releases.hashicorp.com $(lsb_release -cs) main" > /etc/apt/sources.list.d/hashicorp.list'

# Install Packer
sudo apt update && sudo apt install packer

# Install Ansible
sudo apt install -y software-properties-common
sudo add-apt-repository --yes --update ppa:ansible/ansible
sudo apt install -y ansible-core
```
</details>

<details>
<summary>CentOS/RHEL - Install Packer & Ansible</summary>

```bash
# Install Packer
sudo yum install -y yum-utils
sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo
sudo yum -y install packer

# Install Ansible
sudo dnf -y install ansible
```
</details>

**Required Packer Plugins** (auto-downloaded on first run):
- [Packer Plugin for Git](https://github.com/ethanmdavidson/packer-plugin-git) 0.6.2+
- [Packer Plugin for Proxmox](https://developer.hashicorp.com/packer/integrations/hashicorp/proxmox) 1.2.1 (pinned)

---

## Configuration Guide

### Directory Structure

```
mtea-fsg-automation/
├── ansible/          # Ansible roles for OS configuration
├── builds/           # Packer templates per OS
├── config/           # Your MTEA FSG-specific settings (YOU EDIT THESE)
├── manifests/        # Build manifests (auto-generated)
└── tests/            # Validation test suites
```

### Configuration Scripts

Generate configuration templates:

```bash
./config.sh              # Creates ./config/ directory
./config.sh dev          # Creates ./dev/ directory (for multiple environments)
./config.sh prod         # Creates ./prod/ directory
```

Then customize the `.pkrvars.hcl` files for your MTEA FSG infrastructure.

### Essential Configuration Files

#### 1. Proxmox Connection (`config/proxmox.pkrvars.hcl`)

```hcl
proxmox_api_token_id        = "packer@pam!packer-token"
proxmox_api_token_secret    = "<api-token-secret>"
proxmox_insecure_connection = true  // false with valid TLS cert
proxmox_hostname            = "proxmox.mtea.local"
proxmox_node                = "pve-node-01"
```

**API Token Setup**: Token must have `PVEAdmin` role. See [Proxmox API documentation](https://pve.proxmox.com/pve-docs/pveum-plain.html).

#### 2. Build User Credentials (`config/build.pkrvars.hcl`)

```hcl
build_username           = "mtea-admin"
build_password           = "<plaintext-password>"
build_password_encrypted = "<sha512-hash>"
build_key                = "<ssh-public-key>"
```

Generate SHA-512 password hash:
```bash
mkpasswd -m sha512crypt
```

Generate SSH key:
```bash
ssh-keygen -t ecdsa -b 521 -C "mtea-fsg-automation"
```

#### 3. Ansible User (`config/ansible.pkrvars.hcl`)

```hcl
ansible_username = "ansible"
ansible_key      = "<ansible-ssh-public-key>"
```

#### 4. Network Settings (`config/network.pkrvars.hcl`)

```hcl
// Proxmox Network
vm_bridge_interface = "vmbr0"
vm_vlan_tag         = "100"

// Optional: Static IP (comment out for DHCP)
// vm_ip_address = "10.10.10.100"
// vm_ip_netmask = 24
// vm_ip_gateway = "10.10.10.1"
// vm_dns_list   = ["10.10.10.10", "10.10.10.11"]
```

#### 5. Storage Configuration (`config/linux-storage.pkrvars.hcl`)

```hcl
vm_storage_pool     = "local-lvm"
vm_efi_storage_pool = "local-lvm"
vm_disk_device      = "vda"
vm_disk_use_swap    = true
```

<details>
<summary>Storage Layout: Simple Single Partition (UEFI)</summary>

```hcl
vm_disk_partitions = [
  {
    name = "efi", size = 1024,
    format = { label = "EFIFS", fstype = "fat32" },
    mount = { path = "/boot/efi", options = "" },
    volume_group = "",
  },
  {
    name = "boot", size = 1024,
    format = { label = "BOOTFS", fstype = "ext4" },
    mount = { path = "/boot", options = "" },
    volume_group = "",
  },
  {
    name = "root", size = -1,  // All remaining space
    format = { label = "ROOTFS", fstype = "ext4" },
    mount = { path = "/", options = "" },
    volume_group = "",
  },
]
```
</details>

<details>
<summary>Storage Layout: LVM with CIS-Compliant Hardening</summary>

```hcl
vm_disk_partitions = [
  { name = "efi", size = 1024, format = { label = "EFIFS", fstype = "fat32" },
    mount = { path = "/boot/efi", options = "" }, volume_group = "" },
  { name = "boot", size = 1024, format = { label = "BOOTFS", fstype = "ext4" },
    mount = { path = "/boot", options = "" }, volume_group = "" },
  { name = "sysvg", size = -1, format = { label = "", fstype = "" },
    mount = { path = "", options = "" }, volume_group = "sysvg" },
]

vm_disk_lvm = [
  {
    name: "sysvg",
    partitions: [
      { name = "lv_root", size = 10240, format = { label = "ROOTFS", fstype = "ext4" },
        mount = { path = "/", options = "" }},
      { name = "lv_home", size = 4096, format = { label = "HOMEFS", fstype = "ext4" },
        mount = { path = "/home", options = "nodev,nosuid" }},
      { name = "lv_tmp", size = 4096, format = { label = "TMPFS", fstype = "ext4" },
        mount = { path = "/tmp", options = "nodev,noexec,nosuid" }},
      { name = "lv_var", size = 2048, format = { label = "VARFS", fstype = "ext4" },
        mount = { path = "/var", options = "nodev" }},
      { name = "lv_var_log", size = 4096, format = { label = "VARLOGFS", fstype = "ext4" },
        mount = { path = "/var/log", options = "nodev,noexec,nosuid" }},
    ],
  }
]
```
</details>

#### 6. Common Settings (`config/common.pkrvars.hcl`)

```hcl
common_iso_storage      = "local"  // Proxmox storage with ISO files
common_data_source      = "http"   // or "disk" for isolated networks
common_http_port_min    = 8000
common_http_port_max    = 8099
common_ip_wait_timeout  = "20m"
common_shutdown_timeout = "15m"
```

**Firewall Configuration** (if using `http` data source):

```bash
# iptables
iptables -A INPUT -p tcp --match multiport --dports 8000:8099 -j ACCEPT

# firewalld
firewall-cmd --zone=public --add-port=8000-8099/tcp --permanent
firewall-cmd --reload
```

---

## Building VM Templates

### Interactive Build

```bash
./build.sh
# Or with Docker:
./docker-build.sh build
```

Select from the menu:
- Options 1-14: Various Linux distributions
- Option 15: Ubuntu 24.04 LTS
- Option 21: Ubuntu 26.04 LTS
- Options 18-20: Windows 11

### Debug Mode

```bash
./build.sh --debug
# Or with Docker:
docker-compose run --rm packer ./build.sh --debug
```

Enables verbose output and pauses on errors.

### Build Process

1. **Initialize**: Packer downloads required plugins (first run)
2. **Create VM**: Temporary VM created in Proxmox
3. **Boot & Install**: Automated OS installation from ISO
4. **Provision**: Ansible applies configuration, updates, packages
5. **Convert**: VM converted to reusable template
6. **Manifest**: Build metadata saved to `manifests/`

### Template Features

All templates include:
- QEMU Guest Agent
- SSH access (key-based)
- Ansible automation user
- Cloud-init support (Linux)
- Latest security patches
- Customizable storage layouts

### Multiple Environments

```bash
# Development environment
./config.sh dev
./build.sh dev

# Production environment
./config.sh prod
./build.sh prod
```

---

## Docker Usage

### Quick Commands

```bash
./docker-build.sh setup      # Initial setup (first time)
./docker-build.sh build      # Run interactive build
./docker-build.sh validate   # Validate all templates
./docker-build.sh shell      # Open shell in container
./docker-build.sh clean      # Remove Docker resources
./docker-build.sh rebuild    # Rebuild image from scratch
```

### Using Docker Compose Directly

```bash
# Build image
docker-compose build

# Run interactively
docker-compose run --rm packer

# Run specific command
docker-compose run --rm packer ./validate.sh

# Debug mode
docker-compose run --rm packer ./build.sh --debug
```

### Custom Config Path

```bash
docker-compose run --rm packer ./build.sh /workspace/my-custom-config
```

### Environment Variables

Enable Packer logging:

```bash
PACKER_LOG=1 docker-compose run --rm packer ./build.sh
```

Or add to `docker-compose.yml`:

```yaml
environment:
  - PACKER_LOG=1
  - PACKER_LOG_PATH=/workspace/packer.log
```

### Volume Mounts

By default, the following are mounted:
- `./` → `/workspace` (entire project)
- `./config` → `/workspace/config` (your configurations)
- `./manifests` → `/workspace/manifests` (build outputs)
- `~/.ssh` → `/root/.ssh:ro` (SSH keys, read-only)

### Network Mode

Uses `host` network mode for Proxmox connectivity and HTTP server. Modify `network_mode` in `docker-compose.yml` if needed.

### Building Without Docker Compose

```bash
# Build image
docker build -t mtea-fsg-automation:latest .

# Run interactively
docker run -it --rm --network host \
  -v "$(pwd):/workspace" \
  -v "$(pwd)/config:/workspace/config" \
  -v "$(pwd)/manifests:/workspace/manifests" \
  -v "$HOME/.ssh:/root/.ssh:ro" \
  mtea-fsg-automation:latest

# Run single command
docker run -it --rm --network host \
  -v "$(pwd):/workspace" \
  -v "$(pwd)/config:/workspace/config" \
  mtea-fsg-automation:latest \
  ./validate.sh
```

### Docker Benefits

- ✅ **Consistent Environment** - Same tools/versions across all systems
- ✅ **Portability** - Works on Windows, macOS, Linux without manual setup
- ✅ **Isolation** - No pollution of host system
- ✅ **Easy Updates** - Rebuild image to update tools
- ✅ **Team Collaboration** - Everyone uses identical environment

---

## Advanced Configuration

### Per-OS Template Settings

Each OS has a config file: `config/linux-<os>-<version>.pkrvars.hcl`

Example `config/linux-ubuntu-24-04-lts.pkrvars.hcl`:

```hcl
// Guest OS Settings
vm_os_language = "en_US"
vm_os_keyboard = "us"
vm_os_timezone = "America/Los_Angeles"

// Hardware
vm_cpu_count   = 2
vm_cpu_sockets = 1
vm_cpu_type    = "host"  // "host" for best performance
vm_mem_size    = 4096
vm_disk_size   = "40G"

// Boot & Storage
vm_bios        = "ovmf"  // UEFI (or "seabios" for BIOS)
vm_disk_type   = "virtio"
vm_disk_format = "raw"

// Cloud-Init
vm_cloudinit   = true

// ISO
iso_path       = "iso"
iso_file       = "ubuntu-24.04-live-server-amd64.iso"
iso_checksum   = "https://releases.ubuntu.com/noble/SHA256SUMS"
```

### Cloud-Init Support

Enable/disable per OS:

```hcl
vm_cloudinit           = true   // Enable cloud-init
vm_cloudinit_disk_type = "ide"  // or "scsi", "virtio"
```

When cloning templates with cloud-init:
- Set hostname and network
- Inject SSH keys
- Run custom scripts
- Configure users and packages

### Terraform Integration

Deploy VMs from templates using Terraform. See:
- `example_uefi_ubuntu_terraform/` - Ubuntu deployment example
- `terraform_import/` - Import existing VMs

---

## Troubleshooting

### Configuration Issues

**Problem**: Build fails with config errors

**Solution**:
1. Verify all required config files edited
2. Check Proxmox credentials are correct
3. Test connectivity: `ping proxmox.mtea.local`

### Build Timeouts

**Problem**: Build exceeds timeout

**Solution**: Increase timeout in OS-specific variables:

```hcl
// In config/linux-ubuntu-24-04-lts.pkrvars.hcl
variable "timeout" {
  default = "120m"  // Increase from default 90m
}
```

### ISO Not Found

**Problem**: Packer can't find ISO file

**Solution**:
1. Verify ISO uploaded to Proxmox storage
2. Check `common_iso_storage` matches storage name
3. Confirm `iso_path` and `iso_file` are correct
4. Test: Navigate to Proxmox web UI → Storage → ISO images

### Network Connectivity

**Problem**: Can't reach Proxmox or HTTP server timeouts

**Solution**:
1. Verify `vm_bridge_interface` exists: `pvesh get /nodes/<node>/network`
2. Check VLAN tag matches network config
3. Ensure firewall allows ports 8000-8099
4. Test: `curl http://<packer-host>:8000/`
5. For Docker: Verify `network_mode: host` in docker-compose.yml

### SSH Connection Failures

**Problem**: Packer can't SSH to VM

**Solution**:
1. Verify credentials in `config/build.pkrvars.hcl`
2. Check VM has network connectivity (console in Proxmox)
3. Verify QEMU guest agent starting: `systemctl status qemu-guest-agent`
4. Check Proxmox firewall rules

### Packer Plugin Errors

**Problem**: Plugin download or compatibility issues

**Solution**: Re-initialize plugins:

```bash
cd builds/linux/ubuntu/24-04-lts/
packer init .
```

### Permission Issues (Docker)

**Problem**: File permission errors on mounted volumes

**Solution**:

```bash
sudo chown -R $(id -u):$(id -g) config/ manifests/
```

### Proxmox Connection Issues (Docker)

**Checklist**:
- [ ] Container can reach Proxmox (check `proxmox_hostname`)
- [ ] Network mode is `host` in docker-compose.yml
- [ ] Firewall allows HTTP ports 8000-8099
- [ ] No proxy blocking connections

---

## CI/CD Integration

### GitHub Actions

```yaml
name: Validate Packer Templates

on: [push, pull_request]

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Build Docker Image
        run: docker-compose build
      
      - name: Validate Templates
        run: docker-compose run --rm packer ./validate.sh
```

### GitLab CI

```yaml
validate:
  image: docker:latest
  services:
    - docker:dind
  script:
    - docker-compose build
    - docker-compose run --rm packer ./validate.sh
```

---

## Known Issues

### Windows Builds

Windows templates require:
- Valid product keys (not included)
- Correct OS image names in config
- VirtIO drivers for storage/network

See `config/windows-desktop-11.pkrvars.hcl.example` for configuration details.

### Proxmox API Permissions

Currently requires `PVEAdmin` role. Least-privilege configuration documentation in progress.

### Packer Proxmox Plugin

Pinned to v1.2.1 due to [CPU bug](https://github.com/hashicorp/packer-plugin-proxmox/issues/307) in newer versions.

---

## Credits

**Maintained by**: MTEA Federal Services Group  
**Organization**: Modoc Tribal Enterprise Authority

**Based on**:
- [proxmox-packer-examples](https://github.com/ajschroeder/proxmox-packer-examples) by ajschroeder
- [packer-examples-for-vsphere](https://github.com/vmware-samples/packer-examples-for-vsphere) by VMware

**Technologies**:
- [HashiCorp Packer](https://www.packer.io)
- [Ansible](https://www.ansible.com)
- [Proxmox VE](https://www.proxmox.com/)
- [Cloud-Init](https://cloud-init.io/)

---

**MTEA Federal Services Group**  
Network Automation & Infrastructure Engineering
