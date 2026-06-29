#!/usr/bin/env bash
# Gate 2: Grounding — читает результат из .agent-run/gate-2.result или $prompt.
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

result_file=".agent-run/gate-2.result"

if [[ -f "${result_file}" ]]; then
  cat "${result_file}"
  exit 0
fi

for f in .agent-run/active-context.md .agent-run/verification-loop.md; do
  if [[ -f "${f}" ]]; then
    if grep -q "GATE_2: PASS" "${f}"; then
      echo "GATE_2: PASS"
      exit 0
    fi
    if grep -Eq "GATE_2: (FAIL|BLOCKED)" "${f}"; then
      echo "GATE_2: FAIL"
      exit 0
    fi
  fi
done

if echo "${prompt:-}" | grep -q "GATE_2: PASS"; then
  echo "GATE_2: PASS"
elif echo "${prompt:-}" | grep -Eq "GATE_2: (FAIL|BLOCKED)"; then
  echo "GATE_2: FAIL"
else
  echo "GATE_2: FAIL (write GATE_2: PASS or GATE_2: FAIL to .agent-run/gate-2.result)"
fi
