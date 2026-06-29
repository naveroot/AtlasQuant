#!/usr/bin/env bash
# Emits Plane Pages context for Supercode / orchestrator prompts.
# Usage: plane-pages-context.sh [base|spec-plan <slug>]
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ATLAS_ROOT="$(cd "${SCRIPT_DIR}/../../../.." && pwd)"
MANIFEST="${ATLAS_ROOT}/docs/plane-pages/manifest.yml"
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

page_id_for() {
  local key="$1"
  python3 - <<PY
import re, sys
from pathlib import Path
manifest = Path("${MANIFEST}")
key = ${key@Q}
if not manifest.exists():
    sys.exit(0)
for line in manifest.read_text().splitlines():
    m = re.match(rf'^  "{re.escape(key)}": ([0-9a-f-]{{36}})', line)
    if m:
        print(m.group(1))
        break
PY
}

emit_base() {
  : "${PLANE_PROJECT_ID:?PLANE_PROJECT_ID is required}"
  local workspace="${PLANE_WORKSPACE_SLUG:-${PLANE_WORKSPACE:-atlasquant}}"

  cat <<EOF
# Plane Pages context (Memory Bank)

Project ID: \`${PLANE_PROJECT_ID}\`
Workspace: \`${workspace}\`
Manifest: \`docs/plane-pages/manifest.yml\`
External source: \`atlasquant-docs\`

## Key pages

| Role | external_id | page_id |
|------|-------------|---------|
| Memory Bank index | docs/index.md | $(page_id_for "docs/index.md" || echo "(run migrate)") |
| Spec format | docs/specs/README.md | $(page_id_for "docs/specs/README.md" || echo "(run migrate)") |
| Spec template | docs/specs/_template.md | $(page_id_for "docs/specs/_template.md" || echo "(run migrate)") |

## MCP tools (when Pages v1 API available)

| Action | Tool | Notes |
|--------|------|-------|
| List pages | \`list_pages\` | project_id |
| Read page | \`retrieve_page\` | page_id + project_id |
| Create page | \`create_page\` | name, description_html, external_id, project_id |
| Link to issue | \`attach_page_to_work_item\` | work_item_id, page_id |

## CLI fallback (Plane CE v1.3.x)

\`\`\`bash
bash .supercode/workflows/atlasquant/scripts/plane-pages.sh pull
bash .supercode/workflows/atlasquant/scripts/plane-pages.sh get docs/specs/-2.md
\`\`\`

Upsert (Architect):
\`\`\`bash
jq -n --arg id docs/specs/ATLASQUANT-N.md --arg name "Spec: ..." --arg html "<p>...</p>" \
  '{external_id:$id,name:$name,description_html:$html,parent_external_id:"specs"}' \
  | bash .supercode/workflows/atlasquant/scripts/plane-pages.sh upsert-json
\`\`\`
EOF
}

emit_spec_plan() {
  local slug="${1:?slug required}"
  local num="${slug##*-}"
  emit_base
  cat <<EOF

## Spec / Plan for ${slug}

Resolve by external_id (check manifest):

EOF
  for candidate in \
    "docs/specs/${num}.md" \
    "docs/specs/-${num}.md" \
    "docs/plans/${num}.md" \
    "docs/plans/-${num}.md" \
    "docs/plans/#${num}.md"; do
    pid="$(page_id_for "${candidate}" || true)"
    [[ -n "${pid}" ]] && echo "- \`${candidate}\` → page_id \`${pid}\`"
  done
}

main() {
  load_env
  case "${1:-base}" in
    base) emit_base ;;
    spec-plan) shift; emit_spec_plan "$@" ;;
    *)
      echo "Usage: plane-pages-context.sh [base|spec-plan <ATLASQUANT-N>]" >&2
      exit 1
      ;;
  esac
}

main "$@"
