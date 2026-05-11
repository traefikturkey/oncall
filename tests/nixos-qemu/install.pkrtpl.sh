#!/usr/bin/env sh

set -eu

parted -s ${install_disk} mklabel msdos mkpart primary ext4 1MiB 100% set 1 boot on
mkfs.ext4 -F ${install_disk}1
mount ${install_disk}1 /mnt
nixos-generate-config --root /mnt
cp /tmp/nixos-config/configuration.nix /mnt/etc/nixos/configuration.nix
nixos-install --no-root-password
shutdown -h now
