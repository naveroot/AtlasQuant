#!/usr/bin/env bash
# Stdio wrapper for Plane MCP Server (self-hosted plane.alfapulse.ru).
# Used by Cursor .cursor/mcp.json — loads secrets from .env, runs via mise + uvx.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ATLAS_ROOT="$(cd "${SCRIPT_DIR}/../../../.." && pwd)"
ENV_FILE="${SCRIPT_DIR}/../.env"
ORCHESTRATOR_ENV="${ATLAS_ROOT}/.orchestrator/.env"

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

load_env

if [[ -n "${PLANE_AGENT_API_KEY:-}" ]]; then
  export PLANE_API_KEY="${PLANE_AGENT_API_KEY}"
fi

: "${PLANE_API_KEY:?PLANE_API_KEY is required (see .supercode/workflows/atlasquant/.env; prefer PLANE_AGENT_API_KEY for agent comments)}"
: "${PLANE_BASE_URL:=https://plane.alfapulse.ru}"

export PLANE_API_KEY
export PLANE_BASE_URL
export PLANE_WORKSPACE_SLUG="${PLANE_WORKSPACE_SLUG:-${PLANE_WORKSPACE:-atlasquant}}"

# Cursor spawns MCP with a minimal PATH — mise/uvx live under ~/.local/bin
export PATH="${HOME}/.local/bin:${HOME}/.local/share/mise/shims:${PATH}"

cd "${ATLAS_ROOT}"
exec mise exec -- uvx plane-mcp-server stdio
