#!/usr/bin/env bash
# Обязательный CI gate — вывод попадает в $prompt для Supercode condition.
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

echo "=== AtlasQuant CI Gate ==="
if bin/ci 2>&1; then
  echo ""
  echo "Exit code: 0"
else
  code=$?
  echo ""
  echo "Exit code: ${code}"
  exit "${code}"
fi
