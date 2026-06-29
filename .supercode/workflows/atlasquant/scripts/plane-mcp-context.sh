#!/usr/bin/env bash
# Emits Plane MCP context for Supercode pipeline prompts.
# Usage:
#   plane-mcp-context.sh              # base config
#   plane-mcp-context.sh load         # intake step
#   plane-mcp-context.sh transition <state_key> [comment]
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
  local env_var="PLANE_STATE_$(echo "${key}" | tr '[:lower:]' '[:upper:]')"
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

  echo "MISSING" >&2
  return 1
}

emit_base() {
  : "${PLANE_PROJECT_ID:?PLANE_PROJECT_ID is required}"
  local workspace_slug="${PLANE_WORKSPACE_SLUG:-${PLANE_WORKSPACE:-atlasquant}}"

  cat <<EOF
# Plane MCP context (AtlasQuant pipeline)

Server: **plane** (stdio → ${PLANE_BASE_URL:-https://plane.alfapulse.ru})
Workspace slug: \`${workspace_slug}\`
Project ID: \`${PLANE_PROJECT_ID}\`

## Pipeline state UUIDs (for \`update_work_item\` → \`state_id\`)

| Key | UUID |
|-----|------|
| ready | $(resolve_state_uuid ready 2>/dev/null || echo "(unset)") |
| spec_review | $(resolve_state_uuid spec_review 2>/dev/null || echo "(unset)") |
| grounding | $(resolve_state_uuid grounding 2>/dev/null || echo "(unset)") |
| implement | $(resolve_state_uuid implement 2>/dev/null || echo "(unset)") |
| review | $(resolve_state_uuid review 2>/dev/null || echo "(unset)") |
| done | $(resolve_state_uuid done 2>/dev/null || echo "(unset)") |
| blocked | $(resolve_state_uuid blocked 2>/dev/null || echo "(unset)") |
| cancelled | $(resolve_state_uuid cancelled 2>/dev/null || echo "(unset)") |

## MCP tools (Plane MCP Server)

| Action | Tool | Key parameters |
|--------|------|----------------|
| Load issue by slug | \`retrieve_work_item_by_identifier\` | \`project_identifier\`, \`work_item_identifier\` |
| Load issue by UUID | \`retrieve_work_item\` | \`project_id\`, \`work_item_id\` |
| Change state | \`update_work_item\` | \`project_id\`, \`work_item_id\`, \`state_id\` |
| Add gate comment | \`create_work_item_comment\` | \`project_id\`, \`work_item_id\`, \`comment_html\` |
| List states | \`list_states\` | \`project_id\` |

Comments must be HTML, e.g. \`<p>Gate 1 PASS → Grounding</p>\`.

## Plane Pages (Memory Bank)

Spec/plan live in project **Pages** (external_source: atlasquant-docs). Manifest: \`docs/plane-pages/manifest.yml\`.

| Action | Tool / CLI |
|--------|------------|
| Page context | \`bash .supercode/workflows/atlasquant/scripts/plane-pages-context.sh base\` |
| Read page | \`retrieve_page\` or \`plane-pages.sh get <external_id>\` |
| Create/upsert | \`create_page\` or \`plane-pages.sh upsert-json\` |
| Sync cache | \`plane-pages.sh pull\` |
EOF
}

emit_load() {
  local ident="${PLANE_ISSUE_IDENTIFIER:-}"
  local issue_id="${PLANE_ISSUE_ID:-}"
  local prefix="" seq=""

  if [[ -n "${ident}" ]]; then
    seq="${ident##*-}"
    prefix="${ident%-*}"
  fi

  emit_base

  cat <<EOF

## Load issue (intake)

EOF

  if [[ -n "${issue_id}" ]]; then
    cat <<EOF
Preferred: \`retrieve_work_item\`
- project_id: \`${PLANE_PROJECT_ID}\`
- work_item_id: \`${issue_id}\`

EOF
  fi

  if [[ -n "${prefix}" && -n "${seq}" ]]; then
    cat <<EOF
Or: \`retrieve_work_item_by_identifier\`
- project_identifier: \`${prefix}\`
- work_item_identifier: \`${seq}\`

Expected slug for docs: \`${prefix}-${seq}\`
EOF
  fi

  if [[ -z "${issue_id}" && -z "${ident}" ]]; then
    echo "Error: set PLANE_ISSUE_ID or PLANE_ISSUE_IDENTIFIER in .env" >&2
    exit 1
  fi

  local spec_review
  spec_review=$(resolve_state_uuid spec_review)

  cat <<EOF

After load, claim task:
1. \`update_work_item\` → state_id \`${spec_review}\` (spec_review)
2. \`create_work_item_comment\` → \`<p>Pipeline: Load Issue → Spec Review</p>\`
3. Run: \`bash .supercode/workflows/atlasquant/scripts/init-agent-run.sh <slug> "<title>"\`

Then output the task brief (title, description, SDD steps) for the next pipeline stage.
EOF
}

emit_transition() {
  local state_key="${1:?state_key required}"
  local comment="${2:-Pipeline state sync via Plane MCP}"
  local state_uuid
  state_uuid=$(resolve_state_uuid "${state_key}")

  emit_base

  local work_item_id="${PLANE_ISSUE_ID:-}"
  if [[ -z "${work_item_id}" && -n "${PLANE_ISSUE_IDENTIFIER:-}" ]]; then
    cat <<EOF

Resolve work item first via \`retrieve_work_item_by_identifier\` (${PLANE_ISSUE_IDENTIFIER}) if you only have the slug.
EOF
  fi

  cat <<EOF

## Transition → \`${state_key}\`

1. \`update_work_item\`
   - project_id: \`${PLANE_PROJECT_ID}\`
   - work_item_id: \`${work_item_id:-<from retrieve_work_item>}\`
   - state_id: \`${state_uuid}\`

2. \`create_work_item_comment\`
   - comment_html: \`<p>${comment}</p>\`

Confirm both calls succeeded before continuing.
EOF
}

main() {
  load_env
  local mode="${1:-env}"

  case "${mode}" in
    env|base) emit_base ;;
    load) emit_load ;;
    transition) shift; emit_transition "$@" ;;
    *)
      echo "Usage: plane-mcp-context.sh [env|load|transition <state_key> [comment]]" >&2
      exit 1
      ;;
  esac
}

main "$@"
