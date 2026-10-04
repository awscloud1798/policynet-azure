#!/usr/bin/env bash
# Run the six-rule test from your Codespace. Usage: bash tests/run-matrix.sh
set -e
cd "$(dirname "$0")/../envs/dev"
bash ../../tests/matrix.sh \
  "$(terraform output -raw rg_name)" \
  "$(terraform output -raw web_public_ip)" \
  "$(terraform output -raw web_private_ip)" \
  "$(terraform output -raw app_private_ip)" \
  "$(terraform output -raw db_private_ip)"
