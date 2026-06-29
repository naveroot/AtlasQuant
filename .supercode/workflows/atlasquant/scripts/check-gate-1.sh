#!/usr/bin/env bash
# Gate 1: TAUS — проверяет active spec/plan на диске (вывод → $prompt для Supercode if).
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

if [[ -f ".agent-run/gate-1.result" ]]; then
  cat ".agent-run/gate-1.result"
  exit 0
fi

spec=$(ls -t docs/specs/*.md 2>/dev/null | grep -v README | grep -v _template | head -1 || true)
plan=$(ls -t docs/plans/*.md 2>/dev/null | grep -v README | grep -v _template | head -1 || true)

if [[ -z "${spec}" || -z "${plan}" ]]; then
  echo "GATE_1: FAIL (missing spec or plan under docs/)"
  exit 0
fi

spec_active=false
plan_active=false
grep -qiE '^Status:[[:space:]]*active[[:space:]]*$' "${spec}" && spec_active=true
grep -qiE '^Status:[[:space:]]*active[[:space:]]*$' "${plan}" && plan_active=true

if [[ "${spec_active}" == true && "${plan_active}" == true ]]; then
  echo "GATE_1: PASS"
  echo "Spec: ${spec}"
  echo "Plan: ${plan}"
else
  echo "GATE_1: FAIL"
  echo "Spec active: ${spec_active} (${spec})"
  echo "Plan active: ${plan_active} (${plan})"
fi
