{ config, pkgs, lib, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  boot.kernelParams = [ "net.ifnames=0" "biosdevname=0" ];
%{ if vm_bios == "ovmf" ~}
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
%{ else ~}
  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/${vm_disk_device}";
%{ endif ~}

  networking.hostName = "${vm_os_name}";
  networking.usePredictableInterfaceNames = false;
%{ if vm_ip_address != null ~}
  networking.useDHCP = false;
  networking.defaultGateway = "${vm_ip_gateway}";
  networking.nameservers = [
%{ for dns in vm_dns_list ~}
    "${dns}"
%{ endfor ~}
  ];
  networking.interfaces."${vm_network_device}".ipv4.addresses = [
    {
      address = "${vm_ip_address}";
      prefixLength = ${vm_ip_netmask};
    }
  ];
%{ else ~}
  networking.useDHCP = false;
  networking.interfaces."${vm_network_device}".useDHCP = true;
%{ endif ~}

  services.openssh.enable = true;
  services.openssh.settings.PasswordAuthentication = true;
  services.openssh.settings.PermitRootLogin = "no";
  services.qemuGuest.enable = true;

  security.sudo.wheelNeedsPassword = false;
  users.mutableUsers = false;
  users.users."${build_username}" = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    hashedPassword = "${build_password_encrypted}";
  };

  environment.systemPackages = with pkgs; [
    curl
    git
    python3
    qemu
  ];

  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  system.stateVersion = "${vm_os_version}";
}
