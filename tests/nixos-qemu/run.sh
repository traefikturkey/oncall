#!/usr/bin/env bash

set -euo pipefail

SCRIPT_PATH=$(realpath "$(dirname "$0")")
VARS_FILE=${1:-"$SCRIPT_PATH/test.pkrvars.hcl"}

if [ ! -f "$VARS_FILE" ]; then
  echo "Missing vars file: $VARS_FILE"
  echo "Copy $SCRIPT_PATH/test.pkrvars.hcl.example to test.pkrvars.hcl and adjust as needed."
  exit 1
fi

packer init "$SCRIPT_PATH"
packer build -var-file="$VARS_FILE" "$SCRIPT_PATH"
