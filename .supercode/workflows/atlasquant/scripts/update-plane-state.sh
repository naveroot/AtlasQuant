#!/usr/bin/env bash
# DEPRECATED: используйте Plane MCP (`update_work_item` + `create_work_item_comment`).
# Fallback для headless/CI — прямой Plane REST API.
# PATCH Plane work item state by config key (ready, spec_review, grounding, …)
# Usage: update-plane-state.sh <state_key> [comment]
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

resolve_state_uuid() {
  local key="$1"
  local env_var
  env_var="PLANE_STATE_$(echo "${key}" | tr '[:lower:]' '[:upper:]')"
  local uuid="${!env_var:-}"

  if [[ -n "${uuid}" ]]; then
    echo "${uuid}"
    return
  fi

  local config_file="${SCRIPT_DIR}/../../../../.orchestrator/config.yml"
  if [[ -f "${config_file}" ]]; then
    uuid=$(awk -v key="${key}" '
      $0 ~ /^  states:/ { in_states=1; next }
      in_states && $0 ~ /^  [a-z]/ && $0 !~ /^    / { in_states=0 }
      in_states && $0 ~ "^    " key ":" {
        gsub(/.*: *"/, ""); gsub(/".*/, ""); print; exit
      }
    ' "${config_file}")
    if [[ -n "${uuid}" ]]; then
      echo "${uuid}"
      return
    fi
  fi

  echo "Error: state UUID for '${key}' not found (set ${env_var} or config.yml)" >&2
  exit 1
}

resolve_issue_id() {
  if [[ -n "${PLANE_ISSUE_IDENTIFIER:-}" && "${PLANE_ISSUE_IDENTIFIER_PRECEDENCE:-}" == "1" ]]; then
    resolve_issue_identifier "${PLANE_ISSUE_IDENTIFIER}"
    return
  fi

  if [[ -n "${PLANE_ISSUE_ID:-}" && -n "${PLANE_ISSUE_IDENTIFIER:-}" ]]; then
    echo "Error: both PLANE_ISSUE_ID and PLANE_ISSUE_IDENTIFIER are set. Unset one, or set PLANE_ISSUE_IDENTIFIER_PRECEDENCE=1 for PR merge automation." >&2
    exit 1
  fi

  if [[ -n "${PLANE_ISSUE_ID:-}" ]]; then
    echo "${PLANE_ISSUE_ID}"
    return
  fi

  if [[ -n "${PLANE_ISSUE_IDENTIFIER:-}" ]]; then
    resolve_issue_identifier "${PLANE_ISSUE_IDENTIFIER}"
    return
  fi

  echo "Error: set PLANE_ISSUE_ID or PLANE_ISSUE_IDENTIFIER" >&2
  exit 1
}

resolve_issue_identifier() {
  local ident="$1"
  local seq="${ident##*-}"
  local prefix="${ident%-*}"

  curl -sf "${AUTH[@]}" \
    "${API}/workspaces/${PLANE_WORKSPACE}/work-items/search/?search=${prefix}" \
    | python3 -c "
import json, sys
ident, seq, prefix = sys.argv[1], int(sys.argv[2]), sys.argv[3]
data = json.load(sys.stdin)
for item in data.get('issues', []):
    if item.get('sequence_id') == seq and item.get('project__identifier') == prefix:
        print(item['id'])
        break
else:
    sys.exit(1)
" "${ident}" "${seq}" "${prefix}"
}

main() {
  local state_key="${1:-}"
  local comment="${2:-}"
  local requested_issue_id="${PLANE_ISSUE_ID:-}"
  local requested_issue_identifier="${PLANE_ISSUE_IDENTIFIER:-}"
  local requested_identifier_precedence="${PLANE_ISSUE_IDENTIFIER_PRECEDENCE:-}"

  if [[ -z "${state_key}" ]]; then
    echo "Usage: update-plane-state.sh <state_key> [comment]" >&2
    echo "Keys: ready, spec_review, grounding, implement, review, done, blocked, cancelled" >&2
    exit 1
  fi

  load_env

  # Inline env passed by automation must win over persistent .env values.
  if [[ -n "${requested_issue_id}" ]]; then
    PLANE_ISSUE_ID="${requested_issue_id}"
  fi
  if [[ -n "${requested_issue_identifier}" ]]; then
    PLANE_ISSUE_IDENTIFIER="${requested_issue_identifier}"
  fi
  if [[ -n "${requested_identifier_precedence}" ]]; then
    PLANE_ISSUE_IDENTIFIER_PRECEDENCE="${requested_identifier_precedence}"
  fi

  : "${PLANE_API_KEY:?PLANE_API_KEY is required}"
  : "${PLANE_BASE_URL:=https://plane.alfapulse.ru}"
  : "${PLANE_WORKSPACE:?PLANE_WORKSPACE is required}"
  : "${PLANE_PROJECT_ID:?PLANE_PROJECT_ID is required}"

  local admin_key agent_key
  admin_key="${PLANE_API_KEY}"
  if [[ -n "${PLANE_AGENT_API_KEY:-}" ]]; then
    agent_key="${PLANE_AGENT_API_KEY}"
  else
    agent_key="${PLANE_API_KEY}"
  fi

  API="${PLANE_BASE_URL%/}/api/v1"
  AUTH=(-H "X-API-Key: ${admin_key}")
  AGENT_AUTH=(-H "X-API-Key: ${agent_key}")

  local state_uuid issue_id
  state_uuid=$(resolve_state_uuid "${state_key}")
  issue_id=$(resolve_issue_id)

  if [[ -n "${PLANE_ISSUE_IDENTIFIER:-}" ]]; then
    echo "Resolved Plane ${PLANE_ISSUE_IDENTIFIER} → ${issue_id}"
  fi

  curl -sf "${AUTH[@]}" -X PATCH \
    -H "Content-Type: application/json" \
    -d "{\"state\": \"${state_uuid}\"}" \
    "${API}/workspaces/${PLANE_WORKSPACE}/projects/${PLANE_PROJECT_ID}/work-items/${issue_id}/" \
    > /dev/null

  echo "Plane state → ${state_key} (${issue_id})"

  if [[ -n "${comment}" ]]; then
    local comment_html
    comment_html=$(python3 -c "import html, sys; print(f'<p>{html.escape(sys.argv[1])}</p>')" "${comment}")
    curl -sf "${AGENT_AUTH[@]}" -X POST \
      -H "Content-Type: application/json" \
      -d "{\"comment_html\": $(python3 -c "import json,sys; print(json.dumps(sys.argv[1]))" "${comment_html}")}" \
      "${API}/workspaces/${PLANE_WORKSPACE}/projects/${PLANE_PROJECT_ID}/work-items/${issue_id}/comments/" \
      > /dev/null
  fi
}

main "$@"
