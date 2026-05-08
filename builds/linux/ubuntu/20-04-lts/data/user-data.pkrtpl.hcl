#cloud-config
autoinstall:
  version: 1
  apt:
    geoip: true
    preserve_sources_list: false
    primary:
      - arches: [amd64, i386]
        uri: http://archive.ubuntu.com/ubuntu
      - arches: [default]
        uri: http://ports.ubuntu.com/ubuntu-ports
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
    - cloud-init
%{ for package in additional_packages ~}
    - ${package}
%{ endfor ~}
  user-data:
    disable_root: false
    timezone: ${vm_os_timezone}
  late-commands:
    - sed -i -e 's/^#\?PasswordAuthentication.*/PasswordAuthentication yes/g' /target/etc/ssh/sshd_config
    - echo '${build_username} ALL=(ALL) NOPASSWD:ALL' > /target/etc/sudoers.d/${build_username}
    - curtin in-target --target=/target -- chmod 440 /etc/sudoers.d/${build_username}
    - curtin in-target -- apt-get update
    - curtin in-target -- apt-get install qemu-guest-agent
    - echo 'network: {config: disabled}' > /target/etc/cloud/cloud.cfg.d/99-disable-network-config.cfg
    - echo 'datasource_list: [ NoCloud, None ]' > /target/etc/cloud/cloud.cfg.d/90_dpkg.cfg
    - curtin in-target --target=/target -- systemctl enable qemu-guest-agent
