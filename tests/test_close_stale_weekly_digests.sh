#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORK_DIR="$(mktemp -d)"
trap 'rm -rf "${WORK_DIR}"' EXIT
NOW_EPOCH="$(date -u -d '2026-02-09T00:00:00Z' +%s 2>/dev/null || date -u -jf "%Y-%m-%dT%H:%M:%SZ" '2026-02-09T00:00:00Z' +%s)"

FAKE_BIN="${WORK_DIR}/fakebin"
mkdir -p "${FAKE_BIN}"

COMMENT_LOG="${WORK_DIR}/comment.log"
CLOSE_LOG="${WORK_DIR}/close.log"
DRY_RUN_LOG="${WORK_DIR}/dry-run.log"
SUMMARY_LOG="${WORK_DIR}/summary.log"
DRY_SUMMARY_LOG="${WORK_DIR}/dry-summary.log"

cat > "${FAKE_BIN}/gh" <<'GH'
#!/usr/bin/env bash
set -euo pipefail

if [[ "${1:-}" == "issue" && "${2:-}" == "list" ]]; then
  cat <<'TSV'
2	2026-01-01T00:00:00Z	https://example.invalid/issues/2
30	2026-02-08T00:00:00Z	https://example.invalid/issues/30
31	2026-02-03T00:00:00Z	https://example.invalid/issues/31
TSV
  exit 0
fi

if [[ "${1:-}" == "issue" && "${2:-}" == "comment" ]]; then
  echo "$*" >> "${COMMENT_LOG_PATH:?}"
  exit 0
fi

if [[ "${1:-}" == "issue" && "${2:-}" == "close" ]]; then
  echo "$*" >> "${CLOSE_LOG_PATH:?}"
  exit 0
fi

exit 0
GH
chmod +x "${FAKE_BIN}/gh"

(
  cd "${ROOT_DIR}"
  COMMENT_LOG_PATH="${COMMENT_LOG}" \
  CLOSE_LOG_PATH="${CLOSE_LOG}" \
  DIGEST_STALE_SUMMARY_FILE="${SUMMARY_LOG}" \
  DIGEST_STALE_DAYS=7 \
  DIGEST_STALE_NOW_EPOCH="${NOW_EPOCH}" \
  PATH="${FAKE_BIN}:${PATH}" \
  bash scripts/close-stale-weekly-digests.sh \
    "owner/repo" \
    "30" \
    "https://example.invalid/issues/30" \
    "Weekly Governance Digest"
)

grep -q 'issue comment 2' "${COMMENT_LOG}" || {
  echo "Expected comment on stale digest #2" >&2
  exit 1
}

grep -q 'Latest active digest: https://example.invalid/issues/30' "${COMMENT_LOG}" || {
  echo "Expected latest digest URL reference in stale closure comment" >&2
  exit 1
}

grep -q 'issue close 2' "${CLOSE_LOG}" || {
  echo "Expected closure for stale digest #2" >&2
  exit 1
}

if grep -q 'issue close 31' "${CLOSE_LOG}"; then
  echo "Did not expect closure for recent digest #31" >&2
  exit 1
fi

grep -q '^closed_count=1$' "${SUMMARY_LOG}" || {
  echo "Expected summary closed_count=1" >&2
  exit 1
}

grep -q '^dry_run_candidates=0$' "${SUMMARY_LOG}" || {
  echo "Expected summary dry_run_candidates=0" >&2
  exit 1
}

echo "stale weekly digest lifecycle checks passed."

(
  cd "${ROOT_DIR}"
  COMMENT_LOG_PATH="${COMMENT_LOG}" \
  CLOSE_LOG_PATH="${CLOSE_LOG}" \
  DIGEST_STALE_SUMMARY_FILE="${DRY_SUMMARY_LOG}" \
  DIGEST_STALE_DAYS=7 \
  DIGEST_STALE_DRY_RUN=true \
  DIGEST_STALE_NOW_EPOCH="${NOW_EPOCH}" \
  PATH="${FAKE_BIN}:${PATH}" \
  bash scripts/close-stale-weekly-digests.sh \
    "owner/repo" \
    "30" \
    "https://example.invalid/issues/30" \
    "Weekly Governance Digest" > "${DRY_RUN_LOG}"
)

grep -q 'DRY_RUN stale digest candidate #2' "${DRY_RUN_LOG}" || {
  echo "Expected dry-run stale candidate output for #2" >&2
  exit 1
}

if [[ -s "${COMMENT_LOG}" && "$(wc -l < "${COMMENT_LOG}")" -gt 1 ]]; then
  echo "Dry-run should not add new comment operations" >&2
  exit 1
fi

if [[ -s "${CLOSE_LOG}" && "$(wc -l < "${CLOSE_LOG}")" -gt 1 ]]; then
  echo "Dry-run should not add new close operations" >&2
  exit 1
fi

grep -q '^dry_run_enabled=true$' "${DRY_SUMMARY_LOG}" || {
  echo "Expected summary dry_run_enabled=true" >&2
  exit 1
}

grep -q '^dry_run_candidates=1$' "${DRY_SUMMARY_LOG}" || {
  echo "Expected summary dry_run_candidates=1" >&2
  exit 1
}

echo "stale weekly digest dry-run checks passed."
