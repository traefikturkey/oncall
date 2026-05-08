#cloud-config
autoinstall:
  version: 1
  early-commands:
    - sudo systemctl stop ssh
  locale: ${vm_os_language}
  keyboard:
    layout: ${vm_os_keyboard}
${storage}
${network} 
  identity:
    hostname: ubuntu-server
    username: ${build_username}
    password: ${build_password_encrypted}
  ssh:
    install-server: true
    allow-pw: true
  packages:
    - openssh-server
    - qemu-guest-agent
    - cloud-init
  user-data:
    disable_root: false
    timezone: ${vm_os_timezone}
  late-commands:
    - sed -i -e 's/^#\?PasswordAuthentication.*/PasswordAuthentication yes/g' /target/etc/ssh/sshd_config
    - echo '${build_username} ALL=(ALL) NOPASSWD:ALL' > /target/etc/sudoers.d/${build_username}
    - curtin in-target --target=/target -- chmod 440 /etc/sudoers.d/${build_username}
    - echo 'network: {config: disabled}' > /target/etc/cloud/cloud.cfg.d/99-disable-network-config.cfg
    - echo 'datasource_list: [ NoCloud, None ]' > /target/etc/cloud/cloud.cfg.d/90_dpkg.cfg
    - curtin in-target --target=/target -- systemctl enable qemu-guest-agent
    - echo 'send dhcp-client-identifier = hardware;' > /target/etc/dhcp/dhclient.conf
    - curtin in-target --target=/target -- touch /etc/cloud/cloud-init.disabled
