#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/../../../.." && pwd)"
SYNC_SCRIPT="${SCRIPT_DIR}/sync-plane-on-pr-merge.sh"
UPDATE_SCRIPT="${SCRIPT_DIR}/update-plane-state.sh"
VALIDATE_SCRIPT="${ROOT_DIR}/.github/scripts/validate-plane-pr-link.sh"

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

assert_contains() {
  local haystack="$1"
  local needle="$2"

  [[ "${haystack}" == *"${needle}"* ]] || fail "expected output to contain: ${needle}"
}

assert_not_contains() {
  local haystack="$1"
  local needle="$2"

  [[ "${haystack}" != *"${needle}"* ]] || fail "expected output not to contain: ${needle}"
}

tmp_dir="$(mktemp -d)"
trap 'rm -rf "${tmp_dir}"' EXIT

fake_update="${tmp_dir}/fake-update-plane-state.sh"
cat > "${fake_update}" <<'FAKE'
#!/usr/bin/env bash
set -euo pipefail

if [[ -n "${PLANE_ISSUE_ID:-}" ]]; then
  echo "unexpected stale PLANE_ISSUE_ID=${PLANE_ISSUE_ID}" >&2
  exit 42
fi

if [[ "${PLANE_ISSUE_IDENTIFIER:-}" != "ATLASQUANT-7" ]]; then
  echo "unexpected PLANE_ISSUE_IDENTIFIER=${PLANE_ISSUE_IDENTIFIER:-}" >&2
  exit 43
fi

if [[ "${PLANE_ISSUE_IDENTIFIER_PRECEDENCE:-}" != "1" ]]; then
  echo "missing PLANE_ISSUE_IDENTIFIER_PRECEDENCE=1" >&2
  exit 44
fi

echo "fake update ${PLANE_ISSUE_IDENTIFIER} $*"
FAKE
chmod +x "${fake_update}"

output="$(
  PLANE_ISSUE_ID="stale-plane-uuid" \
  PLANE_UPDATE_SCRIPT="${fake_update}" \
  PR_BRANCH="cursor/ATLASQUANT-7-fix-instrument-charts" \
  PR_TITLE="fix: restore charts" \
  PR_URL="https://github.com/naveroot/AtlasQuant/pull/13" \
  bash "${SYNC_SCRIPT}"
)"
assert_contains "${output}" "Updating Plane: ATLASQUANT-7 → done"
assert_contains "${output}" "fake update ATLASQUANT-7 done"
assert_not_contains "${output}" "stale-plane-uuid"

output="$(
  PR_BRANCH="feature/ATLASQUANT-7-chart" \
  PR_TITLE="fix: chart" \
  bash "${VALIDATE_SCRIPT}"
)"
assert_contains "${output}" "Plane work item link found:"
assert_contains "${output}" "ATLASQUANT-7"

if PR_BRANCH="feature/no-plane-link" PR_TITLE="fix: chart" bash "${VALIDATE_SCRIPT}" > "${tmp_dir}/missing.out" 2>&1; then
  fail "validate-plane-pr-link.sh should fail when metadata has no Plane identifier"
fi
missing_output="$(<"${tmp_dir}/missing.out")"
assert_contains "${missing_output}" "Missing Plane work item identifier"

if PLANE_API_KEY="test" \
  PLANE_WORKSPACE="atlasquant" \
  PLANE_PROJECT_ID="project-id" \
  PLANE_STATE_DONE="done-state" \
  PLANE_ISSUE_ID="stale-plane-uuid" \
  PLANE_ISSUE_IDENTIFIER="ATLASQUANT-7" \
  bash "${UPDATE_SCRIPT}" done > "${tmp_dir}/conflict.out" 2>&1; then
  fail "update-plane-state.sh should fail when both issue id and identifier are set without precedence"
fi
conflict_output="$(<"${tmp_dir}/conflict.out")"
assert_contains "${conflict_output}" "both PLANE_ISSUE_ID and PLANE_ISSUE_IDENTIFIER are set"

echo "Plane sync script tests passed."
