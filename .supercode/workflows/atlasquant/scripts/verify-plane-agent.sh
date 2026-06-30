#!/usr/bin/env bash
# Verify Plane agent API key and print display_name from GET /users/me/
# Usage:
#   verify-plane-agent.sh [--expect "AtlasQuant Agent"]
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="${SCRIPT_DIR}/../.env"
ORCHESTRATOR_ENV="${SCRIPT_DIR}/../../../../.orchestrator/.env"

load_env() {
  if [[ -f "${ENV_FILE}" ]]; then
    set -a
    # shellcheck disable=SC1090
    source "${ENV_FILE}"
    set +a
  fi
  if [[ -f "${ORCHESTRATOR_ENV}" ]]; then
    set -a
    # shellcheck disable=SC1090
    source "${ORCHESTRATOR_ENV}"
    set +a
  fi
}

resolve_agent_api_key() {
  if [[ -n "${PLANE_AGENT_API_KEY:-}" ]]; then
    echo "${PLANE_AGENT_API_KEY}"
  elif [[ -n "${PLANE_API_KEY:-}" ]]; then
    echo "${PLANE_API_KEY}"
  else
    echo "Error: set PLANE_AGENT_API_KEY or PLANE_API_KEY" >&2
    exit 1
  fi
}

main() {
  local expect_name=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --expect)
        expect_name="${2:?--expect requires a value}"
        shift 2
        ;;
      *)
        echo "Usage: verify-plane-agent.sh [--expect \"Display Name\"]" >&2
        exit 1
        ;;
    esac
  done

  load_env

  local api_key
  api_key=$(resolve_agent_api_key)

  : "${PLANE_BASE_URL:=https://plane.alfapulse.ru}"

  local response http_code
  response=$(curl -sS -w "\n%{http_code}" \
    -H "X-API-Key: ${api_key}" \
    -H "Content-Type: application/json" \
    "${PLANE_BASE_URL%/}/api/v1/users/me/")

  http_code="${response##*$'\n'}"
  response="${response%$'\n'*}"

  if [[ "${http_code}" != "200" ]]; then
    echo "Error: Plane API ${http_code}: ${response}" >&2
    exit 1
  fi

  local display_name
  display_name=$(python3 -c "
import json, sys
data = json.loads(sys.argv[1])
name = data.get('display_name') or ''
if not name:
    parts = [data.get('first_name') or '', data.get('last_name') or '']
    name = ' '.join(p for p in parts if p).strip()
print(name)
" "${response}")

  if [[ -z "${display_name}" ]]; then
    echo "Error: display_name empty in /users/me/ response" >&2
    exit 1
  fi

  echo "display_name=${display_name}"

  if [[ -n "${expect_name}" && "${display_name}" != "${expect_name}" ]]; then
    echo "Error: expected display_name '${expect_name}', got '${display_name}'" >&2
    exit 1
  fi
}

main "$@"
