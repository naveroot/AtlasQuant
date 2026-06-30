#!/usr/bin/env bash
# Ensure PR metadata links the change to a Plane work item.
set -euo pipefail

prefix="${PLANE_PROJECT_PREFIX:-ATLASQUANT}"
branch="${PR_BRANCH:-${GITHUB_HEAD_REF:-}}"
title="${PR_TITLE:-}"
body="${PR_BODY:-}"

if [[ -z "${branch}" && -z "${title}" && -z "${body}" ]]; then
  echo "::error::Nothing to scan: set PR_BRANCH, PR_TITLE, and/or PR_BODY." >&2
  exit 1
fi

identifiers=$(
  printf '%s\n%s\n%s' "${branch}" "${title}" "${body}" | python3 -c "
import os
import re
import sys

prefix = os.environ.get('PLANE_PROJECT_PREFIX', 'ATLASQUANT')
text = sys.stdin.read()
pattern = re.compile(rf'\\b({re.escape(prefix)}-\\d+)\\b', re.IGNORECASE)
seen = []
for match in pattern.finditer(text):
    ident = match.group(1).upper()
    if ident not in seen:
        seen.append(ident)
print('\\n'.join(seen))
"
)

if [[ -z "${identifiers}" ]]; then
  echo "::error::Missing Plane work item identifier. Add ${prefix}-N to the PR branch, title, or body (for example: Plane: ${prefix}-7)." >&2
  exit 1
fi

echo "Plane work item link found:"
while IFS= read -r ident; do
  [[ -z "${ident}" ]] && continue
  echo "- ${ident}"
done <<< "${identifiers}"
