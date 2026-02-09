#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORK_DIR="$(mktemp -d)"
trap 'rm -rf "${WORK_DIR}"' EXIT

FAKE_BIN="${WORK_DIR}/fakebin"
mkdir -p "${FAKE_BIN}"

CAPTURED_BODY="${WORK_DIR}/captured-body.md"

cat > "${FAKE_BIN}/yq" <<'YQ'
#!/usr/bin/env bash
set -euo pipefail
echo "/tmp/yq"
YQ
chmod +x "${FAKE_BIN}/yq"

cat > "${FAKE_BIN}/gh" <<'GH'
#!/usr/bin/env bash
set -euo pipefail

if [[ "${1:-}" == "issue" && "${2:-}" == "list" ]]; then
  args="$*"
  if [[ "$args" == *"--search"* ]]; then
    echo ""
    exit 0
  fi
  if [[ "$args" == *"--jq"* ]]; then
    cat <<EOF
- [ ] [#16](https://example.invalid/issues/16) reliability task
- [ ] [#17](https://example.invalid/issues/17) observability task
EOF
    exit 0
  fi
fi

if [[ "${1:-}" == "issue" && "${2:-}" == "create" ]]; then
  body_file=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --body-file)
        body_file="$2"
        shift 2
        ;;
      *)
        shift
        ;;
    esac
  done
  cp "$body_file" "${CAPTURED_BODY_PATH:?}"
  echo "https://example.invalid/issues/weekly"
  exit 0
fi

if [[ "${1:-}" == "issue" && "${2:-}" == "comment" ]]; then
  exit 0
fi

exit 0
GH
chmod +x "${FAKE_BIN}/gh"

(
  cd "${ROOT_DIR}"
  CAPTURED_BODY_PATH="${CAPTURED_BODY}" \
  PATH="${FAKE_BIN}:${PATH}" \
  DIGEST_OWNER="@owner-test" \
  DIGEST_REVIEW_SLA="48h" \
  SKIP_REPORT_REGEN=true \
  bash scripts/weekly-governance-digest.sh
)

grep -q "## Weekly Governance Digest" "${CAPTURED_BODY}" || {
  echo "Missing digest header" >&2
  exit 1
}

grep -q -- "- Owner: @owner-test" "${CAPTURED_BODY}" || {
  echo "Missing owner line" >&2
  exit 1
}

grep -q -- "- Review SLA: 48h" "${CAPTURED_BODY}" || {
  echo "Missing review SLA line" >&2
  exit 1
}

grep -q "### Ownership Checklist" "${CAPTURED_BODY}" || {
  echo "Missing ownership checklist section" >&2
  exit 1
}

grep -q "### Linked Operational Issues" "${CAPTURED_BODY}" || {
  echo "Missing linked operational issues section" >&2
  exit 1
}

grep -q "#16" "${CAPTURED_BODY}" || {
  echo "Missing linked issue #16" >&2
  exit 1
}

grep -q "#17" "${CAPTURED_BODY}" || {
  echo "Missing linked issue #17" >&2
  exit 1
}

echo "weekly digest content contract checks passed."
