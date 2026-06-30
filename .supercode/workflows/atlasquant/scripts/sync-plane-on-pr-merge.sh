#!/usr/bin/env bash
# Sync Plane work item(s) to "done" after a GitHub PR is merged.
# Used by .github/workflows/sync-plane-status.yml (GitHub Actions).
#
# Issue identifiers are extracted from branch name, PR title, and body
# (e.g. ATLASQUANT-12 in feature/ATLASQUANT-12-user-auth).
#
# Local dry-run:
#   PR_BRANCH=feature/ATLASQUANT-1-auth PR_TITLE="feat: auth" PR_URL=https://github.com/.../pull/1 \
#     PLANE_DRY_RUN=1 bash sync-plane-on-pr-merge.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
UPDATE_SCRIPT="${PLANE_UPDATE_SCRIPT:-${SCRIPT_DIR}/update-plane-state.sh}"

load_env() {
  local env_file orchestrator_env
  env_file="${SCRIPT_DIR}/../.env"
  orchestrator_env="${SCRIPT_DIR}/../../../../.orchestrator/.env"

  if [[ -f "${env_file}" ]]; then
    set -a
    # shellcheck disable=SC1090
    source "${env_file}"
    set +a
  fi
  if [[ -f "${orchestrator_env}" ]]; then
    set -a
    # shellcheck disable=SC1090
    source "${orchestrator_env}"
    set +a
  fi
}

extract_identifiers() {
  python3 -c "
import os
import re
import sys

prefix = os.environ.get('PLANE_PROJECT_PREFIX', 'ATLASQUANT')
text = sys.stdin.read()
pattern = re.compile(rf'\\b({re.escape(prefix)}-\\d+)\\b', re.IGNORECASE)
seen = set()
ordered = []
for match in pattern.finditer(text):
    ident = match.group(1).upper()
    if ident not in seen:
        seen.add(ident)
        ordered.append(ident)
for ident in ordered:
    print(ident)
"
}

main() {
  load_env

  : "${PLANE_PROJECT_PREFIX:=ATLASQUANT}"

  local branch="${PR_BRANCH:-${GITHUB_HEAD_REF:-}}"
  local title="${PR_TITLE:-}"
  local body="${PR_BODY:-}"
  local pr_url="${PR_URL:-}"

  if [[ -z "${branch}" && -z "${title}" && -z "${body}" ]]; then
    echo "Nothing to scan: set PR_BRANCH, PR_TITLE, and/or PR_BODY" >&2
    exit 1
  fi

  local identifiers
  identifiers=$(printf '%s\n%s\n%s' "${branch}" "${title}" "${body}" | extract_identifiers || true)

  if [[ -z "${identifiers}" ]]; then
    echo "No ${PLANE_PROJECT_PREFIX}-N identifiers found in PR metadata — skipping Plane sync"
    exit 0
  fi

  local comment="✅ PR merged → Done"
  if [[ -n "${pr_url}" ]]; then
    comment="✅ PR merged → Done — ${pr_url}"
  fi

  while IFS= read -r ident; do
    [[ -z "${ident}" ]] && continue

    if [[ "${PLANE_DRY_RUN:-}" == "1" ]]; then
      echo "[dry-run] Would set ${ident} → done (${comment})"
      continue
    fi

    echo "Updating Plane: ${ident} → done"
    env -u PLANE_ISSUE_ID \
      PLANE_ISSUE_IDENTIFIER="${ident}" \
      PLANE_ISSUE_IDENTIFIER_PRECEDENCE=1 \
      bash "${UPDATE_SCRIPT}" done "${comment}"
  done <<< "${identifiers}"
}

main "$@"
