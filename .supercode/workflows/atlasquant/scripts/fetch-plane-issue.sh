#!/usr/bin/env bash
# DEPRECATED: используйте Plane MCP в SWE Pipeline (Load Issue / gate transitions).
# Fallback для headless/CI — прямой Plane REST API.
# Загружает текст задачи из Plane API в stdout (становится $prompt).
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

load_env

: "${PLANE_API_KEY:?PLANE_API_KEY is required}"
: "${PLANE_BASE_URL:=https://plane.alfapulse.ru}"
: "${PLANE_WORKSPACE:?PLANE_WORKSPACE is required}"
: "${PLANE_PROJECT_ID:?PLANE_PROJECT_ID is required}"

API="${PLANE_BASE_URL%/}/api/v1"
AUTH=(-H "X-API-Key: ${PLANE_API_KEY}")

resolve_by_identifier() {
  local ident="$1"
  local seq="${ident##*-}"
  local prefix="${ident%-*}"

  local results
  results=$(curl -sf "${AUTH[@]}" \
    "${API}/workspaces/${PLANE_WORKSPACE}/work-items/search/?search=${prefix}" \
    | python3 -c "
import json, sys
ident = sys.argv[1]
seq = int(sys.argv[2])
prefix = sys.argv[3]
data = json.load(sys.stdin)
for item in data.get('issues', []):
    if item.get('sequence_id') == seq and item.get('project__identifier') == prefix:
        print(item['id'])
        break
" "${ident}" "${seq}" "${prefix}")

  if [[ -z "${results}" ]]; then
    echo "Error: work item ${ident} not found" >&2
    exit 1
  fi
  echo "${results}"
}

if [[ -n "${PLANE_ISSUE_ID:-}" ]]; then
  ISSUE_ID="${PLANE_ISSUE_ID}"
elif [[ -n "${PLANE_ISSUE_IDENTIFIER:-}" ]]; then
  ISSUE_ID=$(resolve_by_identifier "${PLANE_ISSUE_IDENTIFIER}")
else
  echo "Error: set PLANE_ISSUE_ID or PLANE_ISSUE_IDENTIFIER" >&2
  exit 1
fi

URL="${API}/workspaces/${PLANE_WORKSPACE}/projects/${PLANE_PROJECT_ID}/work-items/${ISSUE_ID}/"
JSON=$(curl -sf "${AUTH[@]}" "${URL}?expand=labels,state")

PARSED=$(echo "${JSON}" | python3 -c "
import json, sys, os
d = json.load(sys.stdin)
state = d.get('state') or {}
if isinstance(state, str):
    state_id, state_name = state, state
else:
    state_id = state.get('id', '')
    state_name = state.get('name', '')
ready_id = os.environ.get('PLANE_STATE_READY', '')
print(d.get('name', ''))
print(d.get('sequence_id', ''))
print(d.get('description_stripped') or d.get('description_html', ''))
print(state_id)
print(state_name)
print('ready_match' if ready_id and state_id == ready_id else 'not_ready')
" 2>/dev/null)

NAME=$(echo "${PARSED}" | sed -n '1p')
SEQ=$(echo "${PARSED}" | sed -n '2p')
DESC=$(echo "${PARSED}" | sed -n '3p')
STATE_ID=$(echo "${PARSED}" | sed -n '4p')
STATE_NAME=$(echo "${PARSED}" | sed -n '5p')
READY_MATCH=$(echo "${PARSED}" | sed -n '6p')

SLUG="ATLASQUANT-${SEQ}"
bash "${SCRIPT_DIR}/init-agent-run.sh" "${SLUG}" "${NAME}" 2>/dev/null || true

if [[ "${READY_MATCH}" != "ready_match" && -n "${PLANE_STATE_READY:-}" && -n "${STATE_ID}" ]]; then
  echo "Warning: issue state is '${STATE_NAME}' (expected Agent Ready)" >&2
fi

# Claim task: move to Spec Review
if [[ -n "${PLANE_STATE_SPEC_REVIEW:-}" || -f "${SCRIPT_DIR}/../../../../.orchestrator/config.yml" ]]; then
  PLANE_ISSUE_ID="${ISSUE_ID}" bash "${SCRIPT_DIR}/update-plane-state.sh" spec_review "Pipeline: Load Issue → Spec Review" \
    || echo "Warning: could not update Plane state to spec_review (check state UUIDs and PLANE_API_KEY)" >&2
fi

cat <<EOF
# Plane Task: ${NAME}

Sequence: ${SLUG}
Issue ID: ${ISSUE_ID}
Slug: ${SLUG}
Plane State: ${STATE_NAME} (${STATE_ID})

## Description
${DESC}

## SDD Workflow (AI SWE)
1. Architect → docs/specs/${SLUG}.md + docs/plans/${SLUG}.md (status: draft)
2. Gate 1 TAUS Spec Review → status: active → Plane: Grounding
3. Gate 2 Grounding → plan vs codebase → Plane: Implement
4. Gate 3 Implement + bin/ci
5. Gate 4 Spec conformance → AC evidence → Plane: Review
6. Gate 5 PR summary

Ralph Loop state: .agent-run/ (initialized)

Follow AGENTS.md (MVP scope, minimal diff, tests, bin/ci before PR).
EOF
