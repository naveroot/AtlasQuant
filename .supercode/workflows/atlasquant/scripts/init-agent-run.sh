#!/usr/bin/env bash
# Инициализирует Ralph Loop state pack в .agent-run/ для длинной задачи.
# Usage: init-agent-run.sh <task-slug> ["Task title"]
set -euo pipefail

ROOT="$(git rev-parse --show-toplevel)"
TEMPLATE_DIR="${ROOT}/docs/agent-pipeline/templates/agent-run"
RUN_DIR="${ROOT}/.agent-run"

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <task-slug> [task-title]" >&2
  exit 1
fi

SLUG="$1"
TITLE="${2:-${SLUG}}"
DATE="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

mkdir -p "${RUN_DIR}"

for file in PROMPT.md plan.md active-context.md verification-loop.md session-handoff.md; do
  dest="${RUN_DIR}/${file}"
  if [[ -f "${dest}" ]]; then
    echo "Skip (exists): ${dest}"
    continue
  fi
  sed -e "s/{{TASK}}/${TITLE}/g" -e "s/{{DATE}}/${DATE}/g" \
    "${TEMPLATE_DIR}/${file}" > "${dest}"
  echo "Created: ${dest}"
done

echo ""
echo "Ralph Loop initialized for: ${TITLE}"
echo "Spec/plan paths (create via Architect):"
echo "  docs/specs/${SLUG}.md"
echo "  docs/plans/${SLUG}.md"
