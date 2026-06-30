#!/usr/bin/env bash
set -euo pipefail

: "${TWC_VPS_HOST:?TWC_VPS_HOST is required}"
: "${SSH_PRIVATE_KEY:?SSH_PRIVATE_KEY is required}"

ssh_dir="${HOME}/.ssh"
key_path="${SSH_KEY_PATH:-${ssh_dir}/id_ed25519}"

mkdir -p "$ssh_dir"
chmod 700 "$ssh_dir"

printf '%s\n' "$SSH_PRIVATE_KEY" | tr -d '\r' > "$key_path"
chmod 600 "$key_path"

if ! grep -q "BEGIN .*PRIVATE KEY" "$key_path"; then
  echo "::error::SSH private key has an unexpected format. Store the full private key, including BEGIN/END lines, in SSH_PRIVATE_KEY or KAMAL_SSH_PRIVATE_KEY." >&2
  exit 1
fi

eval "$(ssh-agent -s)"
ssh-add "$key_path"

ssh-keyscan -T 15 -H "$TWC_VPS_HOST" >> "${ssh_dir}/known_hosts"
ssh -o BatchMode=yes -o StrictHostKeyChecking=yes -o ConnectTimeout=15 "root@${TWC_VPS_HOST}" "echo SSH OK"
