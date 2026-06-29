#!/usr/bin/env bash
# Generate project .cursor/mcp.json for self-hosted Plane MCP (stdio).
# Merges with ~/.cursor/mcp.json so timeweb/context7 etc. stay available.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ATLAS_ROOT="$(cd "${SCRIPT_DIR}/../../../.." && pwd)"
PLANE_ROOT="$(cd "${ATLAS_ROOT}/.." && pwd)"
MCP_DIR="${PLANE_ROOT}/.cursor"
MCP_FILE="${MCP_DIR}/mcp.json"
WRAPPER="${SCRIPT_DIR}/plane-mcp-server.sh"
USER_MCP="${HOME}/.cursor/mcp.json"

chmod +x "${SCRIPT_DIR}/plane-mcp-server.sh"
chmod +x "${SCRIPT_DIR}/plane-mcp-context.sh"

mkdir -p "${MCP_DIR}"

python3 <<PY
import json
from pathlib import Path

mcp_file = Path("${MCP_FILE}")
user_mcp = Path("${USER_MCP}")
wrapper = "${WRAPPER}"

servers = {}
if user_mcp.is_file():
    try:
        data = json.loads(user_mcp.read_text())
        servers = data.get("mcpServers", {})
    except json.JSONDecodeError:
        pass

# Self-hosted Plane via stdio (overrides cloud mcp.plane.so entry)
servers["plane"] = {"command": wrapper, "args": []}

mcp_file.write_text(json.dumps({"mcpServers": servers}, indent=2) + "\n")
print(f"Wrote {mcp_file}")
print(f"Merged {len(servers)} MCP server(s): {', '.join(sorted(servers))}")
PY

echo ""
echo "Plane MCP: stdio → plane.alfapulse.ru (credentials from .supercode/workflows/atlasquant/.env)"
echo "Reload Cursor: Cmd+Shift+P → Developer: Reload Window"
