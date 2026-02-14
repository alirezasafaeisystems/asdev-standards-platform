#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORK_DIR="$(mktemp -d)"
trap 'rm -rf "${WORK_DIR}"' EXIT

FAKE_BIN="${WORK_DIR}/fakebin"
mkdir -p "${FAKE_BIN}"

cat > "${FAKE_BIN}/curl" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
out_file=""
write_out=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    -o)
      out_file="$2"
      shift 2
      ;;
    -w)
      write_out="$2"
      shift 2
      ;;
    *)
      shift
      ;;
  esac
done

if [[ -n "${out_file}" ]]; then
  if [[ -n "${FAKE_HTTP_BODY:-}" ]]; then
    body="${FAKE_HTTP_BODY}"
  else
    body='{"default_branch":"main"}'
  fi
  printf '%s' "${body}" > "${out_file}"
fi
if [[ -n "${write_out}" ]]; then
  printf '%s' "${FAKE_HTTP_CODE:-200}"
fi
SH
chmod +x "${FAKE_BIN}/curl"

cat > "${FAKE_BIN}/git" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
if [[ "${FAKE_GIT_FAIL:-false}" == "true" ]]; then
  echo "fatal: Authentication failed for 'https://github.com/example/repo.git'" >&2
  exit 1
fi
exit 0
SH
chmod +x "${FAKE_BIN}/git"

run_preflight() {
  local token="${1:-}"
  shift || true
  (
    cd "${ROOT_DIR}"
    PATH="${FAKE_BIN}:${PATH}" \
    SYNC_AUTH_TOKEN="${token}" \
    "$@"
  )
}

set +e
missing_out="$(run_preflight "" bash scripts/sync-auth-preflight.sh owner/repo 2>&1)"
missing_code=$?
set -e
if [[ "${missing_code}" -eq 0 ]]; then
  echo "Expected missing token failure" >&2
  exit 1
fi
grep -q "Missing authentication token" <<< "${missing_out}" || {
  echo "Missing token message not found" >&2
  exit 1
}

set +e
api_fail_out="$(
  export FAKE_HTTP_CODE=404
  export FAKE_HTTP_BODY='{"message":"Not Found"}'
  run_preflight "token-1" bash scripts/sync-auth-preflight.sh owner/repo 2>&1
)"
api_fail_code=$?
set -e
if [[ "${api_fail_code}" -eq 0 ]]; then
  echo "Expected API access failure" >&2
  exit 1
fi
grep -q "repo_not_accessible_for_app_installation" <<< "${api_fail_out}" || {
  echo "API failure category not found" >&2
  exit 1
}

set +e
git_fail_out="$(
  export FAKE_HTTP_CODE=200
  export FAKE_HTTP_BODY='{"default_branch":"main"}'
  export FAKE_GIT_FAIL=true
  run_preflight "token-2" bash scripts/sync-auth-preflight.sh owner/repo 2>&1
)"
git_fail_code=$?
set -e
if [[ "${git_fail_code}" -eq 0 ]]; then
  echo "Expected git transport failure" >&2
  exit 1
fi
grep -q "git_transport_auth_failed" <<< "${git_fail_out}" || {
  echo "Git failure category not found" >&2
  exit 1
}

success_out="$(
  export FAKE_HTTP_CODE=200
  export FAKE_HTTP_BODY='{"default_branch":"main"}'
  export FAKE_GIT_FAIL=false
  run_preflight "token-3" bash scripts/sync-auth-preflight.sh owner/repo 2>&1
)"
grep -q "sync auth preflight passed" <<< "${success_out}" || {
  echo "Expected success message not found" >&2
  exit 1
}

echo "sync auth preflight checks passed."
