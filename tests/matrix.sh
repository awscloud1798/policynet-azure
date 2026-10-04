#!/usr/bin/env bash
# usage: matrix.sh RG WEB_PUBLIC_IP WEB_PRIVATE_IP APP_PRIVATE_IP DB_PRIVATE_IP
set -uo pipefail
RG=$1; WEB_PUB=$2; WEB=$3; APP=$4; DB=$5
fail=0

# TCP probe from inside a VM (through the Azure control plane, no SSH needed)
from_vm() {
  az vm run-command invoke -g "$RG" -n "$1" --command-id RunShellScript \
    --scripts "timeout 4 bash -c '</dev/tcp/$2/$3' 2>/dev/null && echo OPEN || echo CLOSED" \
    --query "value[0].message" -o tsv
}

# TCP probe from this machine (the "internet")
from_runner() {
  timeout 4 bash -c "</dev/tcp/$1/$2" 2>/dev/null && echo OPEN || echo CLOSED
}

expect() {
  if echo "$3" | grep -q "$2"; then echo "PASS  $1"; else echo "FAIL  $1 (wanted $2)"; fail=1; fi
}

expect "1 internet -> web:80" OPEN   "$(from_runner "$WEB_PUB" 80)"
expect "2 internet -> web:22" CLOSED "$(from_runner "$WEB_PUB" 22)"
expect "3 web -> app:8080"    OPEN   "$(from_vm vm-web "$APP" 8080)"
expect "4 web -> db:5432"     CLOSED "$(from_vm vm-web "$DB" 5432)"
expect "5 app -> db:5432"     OPEN   "$(from_vm vm-app "$DB" 5432)"
expect "6 db -> app:8080"     CLOSED "$(from_vm vm-db "$APP" 8080)"
exit $fail
