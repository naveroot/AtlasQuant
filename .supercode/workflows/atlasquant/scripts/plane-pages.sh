#!/usr/bin/env bash
# Plane Pages CLI — read/write project pages via SSH + Django ORM (Plane CE v1.3.x).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ATLAS_ROOT="$(cd "${SCRIPT_DIR}/../../../.." && pwd)"
LIB_DIR="${SCRIPT_DIR}/lib"
ENV_FILE="${SCRIPT_DIR}/../.env"
ORCHESTRATOR_ENV="${ATLAS_ROOT}/.orchestrator/.env"
MANIFEST="${ATLAS_ROOT}/docs/plane-pages/manifest.yml"
CACHE_DIR="${ATLAS_ROOT}/.plane-pages/cache"

load_env() {
  if [[ -f "${ENV_FILE}" ]]; then
    set -a
    # shellcheck disable=SC1090
    source "${ENV_FILE}"
    set +a
  fi
  if [[ -f "${ORCHESTRATOR_ENV}" ]]; then
    set -a
    # shellcheck disable=SC1090
    source "${ORCHESTRATOR_ENV}"
    set +a
  fi
}

load_env

: "${PLANE_PROJECT_ID:?PLANE_PROJECT_ID is required}"
PLANE_SSH_HOST="${PLANE_SSH_HOST:-89.223.122.237}"
PLANE_SSH_USER="${PLANE_SSH_USER:-root}"
PLANE_SSH_KEY="${PLANE_SSH_KEY:-${HOME}/.ssh/id_rsa}"
PLANE_COMPOSE_DIR="${PLANE_COMPOSE_DIR:-/opt/plane/plane-app}"

run_remote() {
  local body_file="$1"
  scp -i "${PLANE_SSH_KEY}" -q "${body_file}" \
    "${PLANE_SSH_USER}@${PLANE_SSH_HOST}:/tmp/atlasquant_pages_cmd.py"
  ssh -n -i "${PLANE_SSH_KEY}" "${PLANE_SSH_USER}@${PLANE_SSH_HOST}" \
    "PLANE_PROJECT_ID=${PLANE_PROJECT_ID} docker compose --env-file ${PLANE_COMPOSE_DIR}/plane.env \
     -f ${PLANE_COMPOSE_DIR}/docker-compose.yaml exec -T api \
     python manage.py shell < /tmp/atlasquant_pages_cmd.py"
  ssh -n -i "${PLANE_SSH_KEY}" "${PLANE_SSH_USER}@${PLANE_SSH_HOST}" \
    "rm -f /tmp/atlasquant_pages_cmd.py"
}

build_remote_script() {
  local cmd="$1"
  local arg="${2:-}"
  local tmp
  tmp="$(mktemp)"
  {
    echo "import json, sys, os"
    echo "from plane.db.models import Page, Project, ProjectPage"
    echo "from django.contrib.auth import get_user_model"
    grep -v '^from __future__' "${LIB_DIR}/plane_pages_remote.py" | \
      sed '/^from plane.db.models import/d' | sed '/^from django.contrib.auth import/d' | \
      sed '/^if __name__ == "__main__":/,$d'
    case "${cmd}" in
      list) echo "print(json.dumps(list_pages()))" ;;
      get)
        python3 -c "import json,sys; print('EXTERNAL_ID = ' + json.dumps(sys.argv[1]))" "${arg}"
        echo "print(json.dumps(get_page_text(EXTERNAL_ID)))"
        ;;
      upsert)
        echo "payload = json.load(open('/tmp/atlasquant_pages_payload.json'))"
        echo "print(json.dumps(upsert_page(**payload)))"
        ;;
    esac
  } > "${tmp}"
  echo "${tmp}"
}

fetch_page_json() {
  local external_id="$1"
  local script
  script="$(build_remote_script get "${external_id}")"
  run_remote "${script}"
  rm -f "${script}"
}

cmd="${1:-help}"
shift || true

case "${cmd}" in
  list)
    script="$(build_remote_script list)"
    run_remote "${script}"
    rm -f "${script}"
    ;;
  get)
    external_id="${1:?external_id required}"
    fetch_page_json "${external_id}"
    ;;
  pull)
    mkdir -p "${CACHE_DIR}"
    if [[ ! -f "${MANIFEST}" ]]; then
      echo "Missing manifest: ${MANIFEST}" >&2
      exit 1
    fi
    while IFS= read -r external_id; do
      [[ -z "${external_id}" ]] && continue
      safe_name="${external_id//\//__}"
      safe_name="${safe_name//#/__hash__}"
      json_file="${CACHE_DIR}/${safe_name}.json"
      md_file="${CACHE_DIR}/${safe_name}.md"
      fetch_page_json "${external_id}" > "${json_file}"
      EXTERNAL_ID="${external_id}" JSON_FILE="${json_file}" MD_FILE="${md_file}" python3 <<'PY'
import json, os
from pathlib import Path
data = json.load(open(os.environ["JSON_FILE"]))
Path(os.environ["MD_FILE"]).write_text(data.get("description_stripped") or "", encoding="utf-8")
print("cached", os.environ["EXTERNAL_ID"])
PY
    done < <(python3 - <<PY
import re
from pathlib import Path
for line in Path("${MANIFEST}").read_text().splitlines():
    m = re.match(r'^  "(docs/[^"]+)": ', line)
    if m:
        print(m.group(1))
PY
)
    ;;
  spec-plan-for)
    slug="${1:?slug required}"
    num="${slug##*-}"
    for candidate in \
      "docs/specs/${num}.md" \
      "docs/specs/-${num}.md" \
      "docs/plans/${num}.md" \
      "docs/plans/-${num}.md" \
      "docs/plans/#${num}.md"; do
      echo "${candidate}"
    done
    ;;
  upsert-json)
    payload_file="$(mktemp)"
    cat > "${payload_file}"
    scp -i "${PLANE_SSH_KEY}" -q "${payload_file}" \
      "${PLANE_SSH_USER}@${PLANE_SSH_HOST}:/tmp/atlasquant_pages_payload.json"
    script="$(build_remote_script upsert)"
    run_remote "${script}"
    rm -f "${script}" "${payload_file}"
    ssh -i "${PLANE_SSH_KEY}" "${PLANE_SSH_USER}@${PLANE_SSH_HOST}" \
      "rm -f /tmp/atlasquant_pages_payload.json"
    ;;
  help|*)
    cat <<EOF
Usage: plane-pages.sh <command>
  list | get <external_id> | pull | spec-plan-for <ATLASQUANT-N> | upsert-json
EOF
    ;;
esac
