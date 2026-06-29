#!/usr/bin/env bash
# Gate 1: TAUS — проверяет active spec/plan в Plane Pages (кэш .plane-pages/cache/).
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

if [[ -f ".agent-run/gate-1.result" ]]; then
  cat ".agent-run/gate-1.result"
  exit 0
fi

SCRIPT=".supercode/workflows/atlasquant/scripts/plane-pages.sh"
CACHE=".plane-pages/cache"

if [[ -x "${SCRIPT}" || -f "${SCRIPT}" ]]; then
  bash "${SCRIPT}" pull >/dev/null 2>&1 || true
fi

find_spec_plan() {
  local kind="$1"
  local slug=""
  if [[ -f ".agent-run/active-context.md" ]]; then
    slug=$(grep -Eo 'ATLASQUANT-[0-9]+' .agent-run/active-context.md 2>/dev/null | head -1 || true)
  fi

  if [[ -n "${slug}" ]]; then
    local num="${slug##*-}"
    for candidate in \
      "${CACHE}/docs__${kind}__${num}.md" \
      "${CACHE}/docs__${kind}__-${num}.md" \
      "${CACHE}/docs__${kind}____hash__${num}.md"; do
      [[ -f "${candidate}" ]] && { echo "${candidate}"; return 0; }
    done
  fi

  ls -t "${CACHE}"/docs__${kind}__*.md "${CACHE}"/docs__${kind}____hash__*.md 2>/dev/null \
    | grep -v README | grep -v _template | head -1 || true
}

spec=$(find_spec_plan specs)
plan=$(find_spec_plan plans)

if [[ -z "${spec}" || -z "${plan}" ]]; then
  echo "GATE_1: FAIL (missing spec or plan in Plane Pages cache; run plane-pages.sh pull)"
  exit 0
fi

spec_active=false
plan_active=false
grep -qiE '^Status:[[:space:]]*active\b' "${spec}" && spec_active=true
grep -qiE '^Status:[[:space:]]*active\b' "${plan}" && plan_active=true

if [[ "${spec_active}" == true && "${plan_active}" == true ]]; then
  echo "GATE_1: PASS"
  echo "Spec page: ${spec}"
  echo "Plan page: ${plan}"
else
  echo "GATE_1: FAIL"
  echo "Spec active: ${spec_active} (${spec})"
  echo "Plan active: ${plan_active} (${plan})"
fi
