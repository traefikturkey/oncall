# Ubuntu QEMU Cloud-Image Smoke Test

This test boots the Ubuntu 26.04 daily cloud image with a NoCloud seed and then runs the same shared Ansible playbook used by the real Ubuntu Packer template.

It intentionally does not validate the real template's LVM storage layout. Ubuntu cloud images are already partitioned and contain a prebuilt root filesystem, so converting the root disk to the repository's LVM layout would require a separate disk migration workflow. The real LVM layout remains covered by the ISO/autoinstall template path through `config/linux-storage.pkrvars.hcl`.

Use this test for fast validation of cloud-init access, SSH, and shared Ansible roles. Use the real Ubuntu template path when storage layout, EFI partitioning, and LVM behavior are the thing under test.

By default `run.sh` uses `test_ssh_key` so manual SSH access is predictable. If the key is missing, the script creates it locally. To let Packer generate a temporary SSH key instead, run `USE_FIXED_SSH_KEY=false ./run.sh`.
