#!/usr/bin/env bash
# Настройка GitHub для Cursor Cloud Agents.
# Требует: mise, git с credentials в keychain, интерактивный браузер для OAuth.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "${ROOT}"

load_gh_token() {
  if [[ -n "${GH_TOKEN:-}" || -n "${GITHUB_TOKEN:-}" ]]; then
    export GH_TOKEN="${GH_TOKEN:-${GITHUB_TOKEN}}"
    return 0
  fi
  if command -v git >/dev/null && git config --get credential.helper >/dev/null; then
    export GH_TOKEN="$(printf 'protocol=https\nhost=github.com\n\n' | git credential fill | awk -F= '/^password=/ { print $2 }')"
  fi
}

load_gh_token

echo "=== GitHub setup for AtlasQuant Cloud Agents ==="

if mise exec -- gh auth status >/dev/null 2>&1; then
  echo "✓ gh authenticated"
else
  echo "→ gh not logged in. Opening browser for gh auth..."
  mise exec -- gh auth login --web --git-protocol https --scopes repo,read:org
fi

echo
echo "Repository:"
mise exec -- gh repo view naveroot/AtlasQuant --json name,visibility,defaultBranchRef,url

echo
echo "Cursor API repositories (must be non-empty for Cloud Agents):"
CURSOR_API_KEY="$(grep '^CURSOR_API_KEY=' "${ROOT}/.orchestrator/.env" | cut -d= -f2-)"
if [[ -n "${CURSOR_API_KEY}" ]]; then
  curl -sf -H "Authorization: Bearer ${CURSOR_API_KEY}" "https://api.cursor.com/v0/repositories" || true
  echo
else
  echo "(CURSOR_API_KEY not set in .orchestrator/.env)"
fi

echo
echo "=== Required manual steps (one-time) ==="
echo "1. Connect GitHub in Cursor Dashboard → Integrations"
echo "2. Install Cursor GitHub App on naveroot/AtlasQuant"
echo

if command -v open >/dev/null; then
  open "https://cursor.com/dashboard?tab=integrations"
  open "https://github.com/apps/cursor/installations/new"
fi

echo "After connecting GitHub in Cursor, verify:"
echo "  curl -H \"Authorization: Bearer \$CURSOR_API_KEY\" https://api.cursor.com/v0/repositories"
echo
echo "Then run:"
echo "  cd .orchestrator && npm run agent -- --issue=3c26f612-b986-41af-8439-542714b98f0e"
