#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)

cd "$SCRIPT_DIR"

USE_FIXED_SSH_KEY=${USE_FIXED_SSH_KEY:-true}
RUN_ANSIBLE=${RUN_ANSIBLE:-true}

vars=(
  -var-file=test.pkrvars.hcl
  -var "run_ansible=${RUN_ANSIBLE}"
  -var "use_fixed_ssh_key=${USE_FIXED_SSH_KEY}"
)

if [[ "$USE_FIXED_SSH_KEY" == "true" ]]; then
  if [[ ! -f test_ssh_key ]]; then
    ssh-keygen -t ed25519 -N '' -C 'ubuntu-qemu-test' -f test_ssh_key
  fi

  chmod 600 test_ssh_key
  public_key=$(<test_ssh_key.pub)
  vars+=(
    -var "ssh_private_key_file=${SCRIPT_DIR}/test_ssh_key"
    -var "ssh_authorized_keys=[\"${public_key}\"]"
  )
fi

packer init .
packer validate "${vars[@]}" .
packer build -force "${vars[@]}" .
