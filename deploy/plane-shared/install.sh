#!/usr/bin/env bash
# Install AtlasQuant route into Plane's Caddy on the shared VPS.
# Usage: ATLAS_APP_HOST=atlas.alfapulse.ru ./install.sh [plane-app-dir]
set -euo pipefail

PLANE_APP_DIR="${1:-/opt/plane/plane-app}"
ATLAS_APP_HOST="${ATLAS_APP_HOST:?Set ATLAS_APP_HOST (e.g. atlas.alfapulse.ru)}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

CADDY_DIR="${PLANE_APP_DIR}/caddy"
COMPOSE="${PLANE_APP_DIR}/docker-compose.yaml"

mkdir -p "${CADDY_DIR}"
sed "s|__ATLAS_APP_HOST__|${ATLAS_APP_HOST}|g" "${SCRIPT_DIR}/Caddyfile" > "${CADDY_DIR}/Caddyfile"

if ! grep -q './caddy/Caddyfile:/etc/caddy/Caddyfile' "${COMPOSE}"; then
  cp "${COMPOSE}" "${COMPOSE}.bak.$(date +%Y%m%d%H%M%S)"
  python3 - "${COMPOSE}" <<'PY'
import sys
path = sys.argv[1]
text = open(path).read()
needle = "    volumes:\n      - proxy_config:/config\n      - proxy_data:/data"
insert = "    volumes:\n      - ./caddy/Caddyfile:/etc/caddy/Caddyfile:ro\n      - proxy_config:/config\n      - proxy_data:/data"
if needle not in text:
    raise SystemExit("docker-compose.yaml layout changed — add Caddyfile mount manually")
open(path, "w").write(text.replace(needle, insert, 1))
print("Added Caddyfile volume mount to docker-compose.yaml")
PY
fi

cd "${PLANE_APP_DIR}"
docker compose --env-file plane.env up -d proxy
docker compose --env-file plane.env exec proxy caddy validate --config /etc/caddy/Caddyfile
docker compose --env-file plane.env exec proxy caddy reload --config /etc/caddy/Caddyfile

echo "Caddy updated. Ensure DNS: ${ATLAS_APP_HOST} → $(curl -sf ifconfig.me || hostname -I | awk '{print $1}')"
