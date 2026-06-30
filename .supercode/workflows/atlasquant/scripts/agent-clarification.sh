#!/usr/bin/env bash
# Post structured Needs Info comment to Plane and move work item to Blocked.
# Usage:
#   agent-clarification.sh <role> <issue_id> [--assumed "text"] "Question 1" ["Question 2" ...]
#   agent-clarification.sh <role> [--assumed "text"] "Question 1" ...   # uses PLANE_ISSUE_ID
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

resolve_api_key() {
  if [[ -n "${PLANE_AGENT_API_KEY:-}" ]]; then
    echo "${PLANE_AGENT_API_KEY}"
  elif [[ -n "${PLANE_API_KEY:-}" ]]; then
    echo "${PLANE_API_KEY}"
  else
    echo "Error: set PLANE_AGENT_API_KEY or PLANE_API_KEY" >&2
    exit 1
  fi
}

resolve_admin_api_key() {
  if [[ -n "${PLANE_API_KEY:-}" ]]; then
    echo "${PLANE_API_KEY}"
  else
    echo "Error: set PLANE_API_KEY (admin key for state changes)" >&2
    exit 1
  fi
}

resolve_state_uuid() {
  local key="blocked"
  local env_var="PLANE_STATE_BLOCKED"
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

  echo "Error: PLANE_STATE_BLOCKED not found" >&2
  exit 1
}

format_comment_html() {
  local role="$1"
  local assumed="${2:-}"
  shift 2
  local -a questions=("$@")

  python3 - "${role}" "${assumed}" "${questions[@]}" <<'PY'
import html, sys

role = sys.argv[1]
assumed = sys.argv[2]
questions = sys.argv[3:]

if not questions:
    sys.stderr.write("Error: at least one question required\n")
    sys.exit(1)

items = "".join(f"<li>{html.escape(q)}</li>" for q in questions)
out = f"<p><strong>[Needs Info] [{html.escape(role)}]</strong></p>"
out += "<p>Blocked pending clarification:</p>"
out += f"<ol>{items}</ol>"
if assumed:
    out += f"<p><em>Assumed if no reply:</em> {html.escape(assumed)}</p>"
print(out)
PY
}

main() {
  if [[ $# -lt 2 ]]; then
    echo "Usage: agent-clarification.sh <role> [<issue_id>] [--assumed text] \"Q1\" [\"Q2\" ...]" >&2
    exit 1
  fi

  load_env

  local admin_key agent_key role issue_id assumed=""
  admin_key=$(resolve_admin_api_key)
  agent_key=$(resolve_api_key)

  : "${PLANE_BASE_URL:=https://plane.alfapulse.ru}"
  : "${PLANE_WORKSPACE:?PLANE_WORKSPACE is required}"
  : "${PLANE_PROJECT_ID:?PLANE_PROJECT_ID is required}"

  role="$1"
  shift

  if [[ "${1:-}" =~ ^[0-9a-f-]{36}$ ]]; then
    issue_id="$1"
    shift
  else
    issue_id="${PLANE_ISSUE_ID:-}"
    if [[ -z "${issue_id}" ]]; then
      echo "Error: provide issue_id UUID or set PLANE_ISSUE_ID" >&2
      exit 1
    fi
  fi

  local -a questions=()
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --assumed)
        assumed="${2:?--assumed requires a value}"
        shift 2
        ;;
      *)
        questions+=("$1")
        shift
        ;;
    esac
  done

  if [[ ${#questions[@]} -eq 0 ]]; then
    echo "Error: at least one question required" >&2
    exit 1
  fi

  local comment_html state_uuid
  comment_html=$(format_comment_html "${role}" "${assumed}" "${questions[@]}")
  state_uuid=$(resolve_state_uuid)

  API="${PLANE_BASE_URL%/}/api/v1"
  ADMIN_AUTH=(-H "X-API-Key: ${admin_key}")
  AGENT_AUTH=(-H "X-API-Key: ${agent_key}")

  curl -sf "${ADMIN_AUTH[@]}" -X PATCH \
    -H "Content-Type: application/json" \
    -d "{\"state\": \"${state_uuid}\"}" \
    "${API}/workspaces/${PLANE_WORKSPACE}/projects/${PLANE_PROJECT_ID}/work-items/${issue_id}/" \
    > /dev/null

  curl -sf "${AGENT_AUTH[@]}" -X POST \
    -H "Content-Type: application/json" \
    -d "{\"comment_html\": $(python3 -c "import json,sys; print(json.dumps(sys.argv[1]))" "${comment_html}")}" \
    "${API}/workspaces/${PLANE_WORKSPACE}/projects/${PLANE_PROJECT_ID}/work-items/${issue_id}/comments/" \
    > /dev/null

  echo "Plane → blocked (${issue_id})"
  echo "Posted Needs Info comment as [${role}]"
}

main "$@"
