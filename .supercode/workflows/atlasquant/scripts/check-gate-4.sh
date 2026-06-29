#!/usr/bin/env bash
# Gate 4: Spec conformance — читает результат из .agent-run/gate-4.result или $prompt.
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

result_file=".agent-run/gate-4.result"

if [[ -f "${result_file}" ]]; then
  cat "${result_file}"
  exit 0
fi

for f in .agent-run/verification-loop.md .agent-run/active-context.md; do
  if [[ -f "${f}" ]]; then
    if grep -q "GATE_4: PASS" "${f}"; then
      echo "GATE_4: PASS"
      exit 0
    fi
    if grep -q "GATE_4: FAIL" "${f}"; then
      echo "GATE_4: FAIL"
      exit 0
    fi
  fi
done

if echo "${prompt:-}" | grep -q "GATE_4: PASS"; then
  echo "GATE_4: PASS"
elif echo "${prompt:-}" | grep -q "GATE_4: FAIL"; then
  echo "GATE_4: FAIL"
else
  echo "GATE_4: FAIL (write GATE_4: PASS or GATE_4: FAIL to .agent-run/gate-4.result)"
fi
