#cloud-config
hostname: ubuntu-qemu
manage_etc_hosts: true
timezone: ${vm_os_timezone}
ssh_pwauth: true
disable_root: false
users:
  - default
  - name: ${build_username}
    gecos: Packer build user
    groups: adm, sudo
    shell: /bin/bash
    lock_passwd: false
    passwd: ${build_password_encrypted}
    sudo: ALL=(ALL) NOPASSWD:ALL
%{ if length(ssh_authorized_keys) > 0 ~}
    ssh_authorized_keys:
%{ for key in ssh_authorized_keys ~}
      - ${key}
%{ endfor ~}
%{ endif ~}
write_files:
  - path: /etc/ssh/sshd_config.d/99-packer-cloud-image.conf
    permissions: "0644"
    content: |
      PasswordAuthentication yes
runcmd:
  - systemctl reload ssh || systemctl restart ssh
