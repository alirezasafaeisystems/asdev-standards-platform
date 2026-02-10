#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CSV_FILE="$(mktemp)"
trap 'rm -f "${CSV_FILE}"' EXIT

cat > "${CSV_FILE}" <<'CSV'
repo,template_id,last_checked_at,status
example/a,level0,2026-02-10T00:00:00Z,aligned
example/b,level0,2026-02-10T00:00:00Z,aligned
example/c,level0,2026-02-10T00:00:00Z,diverged
CSV

source "${ROOT_DIR}/scripts/csv-utils.sh"

aligned_count="$(csv_count_eq "${CSV_FILE}" "status" "aligned")"
diverged_count="$(csv_count_eq "${CSV_FILE}" "status" "diverged")"

[[ "${aligned_count}" == "2" ]] || {
  echo "Expected aligned_count=2, got ${aligned_count}" >&2
  exit 1
}

[[ "${diverged_count}" == "1" ]] || {
  echo "Expected diverged_count=1, got ${diverged_count}" >&2
  exit 1
}

grep -q 'source "${ROOT_DIR}/scripts/csv-utils.sh"' "${ROOT_DIR}/scripts/weekly-governance-digest.sh" || {
  echo "weekly-governance-digest.sh must source csv-utils.sh" >&2
  exit 1
}

grep -q 'source "${ROOT_DIR}/scripts/csv-utils.sh"' "${ROOT_DIR}/scripts/monthly-release.sh" || {
  echo "monthly-release.sh must source csv-utils.sh" >&2
  exit 1
}

grep -q 'source "${ROOT_DIR}/scripts/csv-utils.sh"' "${ROOT_DIR}/scripts/generate-dashboard.sh" || {
  echo "generate-dashboard.sh must source csv-utils.sh" >&2
  exit 1
}

grep -q 'source "${ROOT_DIR}/scripts/csv-utils.sh"' "${ROOT_DIR}/scripts/generate-error-fingerprint-trend.sh" || {
  echo "generate-error-fingerprint-trend.sh must source csv-utils.sh" >&2
  exit 1
}

grep -q 'source "${ROOT_DIR}/scripts/csv-utils.sh"' "${ROOT_DIR}/scripts/summarize-error-fingerprint-trend.sh" || {
  echo "summarize-error-fingerprint-trend.sh must source csv-utils.sh" >&2
  exit 1
}

grep -q 'source "${ROOT_DIR}/scripts/csv-utils.sh"' "${ROOT_DIR}/scripts/summarize-clone-failed.sh" || {
  echo "summarize-clone-failed.sh must source csv-utils.sh" >&2
  exit 1
}

echo "status counter contract checks passed."
