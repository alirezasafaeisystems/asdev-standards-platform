#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORK_DIR="$(mktemp -d)"
trap 'rm -rf "${WORK_DIR}"' EXIT

combined="${WORK_DIR}/combined.csv"
errors="${WORK_DIR}/errors.csv"
trend="${WORK_DIR}/trend.csv"
attestation="${WORK_DIR}/attestation.txt"

cat > "$combined" <<'CSV'
target_file,repo,template_id,expected_version,detected_version,mode,source_ref,status,last_checked_at
a.yaml,org/repo,pr-template,1.0.0,1.0.0,required,ref,aligned,2026-02-09T00:00:00Z
CSV
cat > "$errors" <<'CSV'
target_file,repo,error_fingerprint,last_checked_at
a.yaml,org/repo,tls_error,2026-02-09T00:00:00Z
CSV
cat > "$trend" <<'CSV'
error_fingerprint,previous,current,delta
tls_error,1,2,1
CSV

(
  cd "$ROOT_DIR"
  bash scripts/write-report-attestation.sh "$combined" "$errors" "$trend" "$attestation"
  bash scripts/validate-report-attestation.sh "$combined" "$errors" "$trend" "$attestation"
)

echo 'error_fingerprint,previous,current,delta' > "$trend"
echo 'tls_error,9,9,0' >> "$trend"

set +e
(
  cd "$ROOT_DIR"
  bash scripts/validate-report-attestation.sh "$combined" "$errors" "$trend" "$attestation"
) >"${WORK_DIR}/out.log" 2>"${WORK_DIR}/err.log"
status=$?
set -e

if [[ "$status" -eq 0 ]]; then
  echo "Expected attestation validation failure after trend mutation" >&2
  exit 1
fi

grep -q 'Attestation hash mismatch for trend report' "${WORK_DIR}/err.log" || {
  echo "Missing attestation mismatch error" >&2
  exit 1
}

echo "report attestation checks passed."
