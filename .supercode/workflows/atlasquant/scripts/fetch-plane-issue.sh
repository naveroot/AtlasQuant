#!/usr/bin/env bash
# Загружает текст задачи из Plane API в stdout (становится $prompt).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="${SCRIPT_DIR}/../.env"
if [[ -f "${ENV_FILE}" ]]; then
  set -a
  # shellcheck disable=SC1090
  source "${ENV_FILE}"
  set +a
fi

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

  # Workspace search returns sequence_id + project__identifier
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

NAME=$(echo "${JSON}" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('name',''))")
SEQ=$(echo "${JSON}" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('sequence_id',''))")
DESC=$(echo "${JSON}" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('description_stripped') or d.get('description_html',''))")

SLUG="ATLASQUANT-${SEQ}"
bash "${SCRIPT_DIR}/init-agent-run.sh" "${SLUG}" "${NAME}" 2>/dev/null || true

cat <<EOF
# Plane Task: ${NAME}

Sequence: ${SLUG}
Issue ID: ${ISSUE_ID}
Slug: ${SLUG}

## Description
${DESC}

## SDD Workflow (AI SWE)
1. Architect → docs/specs/${SLUG}.md + docs/plans/${SLUG}.md (status: draft)
2. Gate 1 TAUS Spec Review → status: active
3. Gate 2 Grounding → plan vs codebase
4. Gate 3 Implement + bin/ci
5. Gate 4 Spec conformance → AC evidence
6. Gate 5 PR summary

Ralph Loop state: .agent-run/ (initialized)

Follow AGENTS.md (MVP scope, minimal diff, tests, bin/ci before PR).
EOF
