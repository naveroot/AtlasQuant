#!/usr/bin/env bash
set -euo pipefail

missing=0

require_env() {
  local name="$1"

  if [[ -z "${!name:-}" ]]; then
    echo "::error::${name} is required for Kamal deploy." >&2
    missing=1
  fi
}

require_env "TWC_VPS_HOST"
require_env "RAILS_MASTER_KEY"
require_env "ATLAS_QUANT_DATABASE_PASSWORD"

if [[ -z "${SSH_PRIVATE_KEY:-}" ]]; then
  echo "::error::SSH private key is required. Configure either SSH_PRIVATE_KEY or KAMAL_SSH_PRIVATE_KEY in GitHub Actions secrets." >&2
  missing=1
fi

if [[ "$missing" -ne 0 ]]; then
  exit 1
fi

echo "Kamal deploy inputs are present."
