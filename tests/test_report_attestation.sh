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

(
  cd "$ROOT_DIR"
  bash scripts/write-report-attestation.sh "$combined" "$errors" "$trend" "$attestation"
)

tmp_attestation="${WORK_DIR}/attestation-stale.txt"
awk '
  BEGIN{changed=0}
  /^validated_at=/{print "validated_at=2020-01-01T00:00:00Z"; changed=1; next}
  {print}
  END{if(changed==0) exit 1}
' "$attestation" > "$tmp_attestation"
mv "$tmp_attestation" "$attestation"

set +e
(
  cd "$ROOT_DIR"
  ATTESTATION_MAX_AGE_SECONDS=60 bash scripts/validate-report-attestation.sh "$combined" "$errors" "$trend" "$attestation"
) >"${WORK_DIR}/stale.out" 2>"${WORK_DIR}/stale.err"
stale_status=$?
set -e

if [[ "$stale_status" -eq 0 ]]; then
  echo "Expected attestation freshness validation failure" >&2
  exit 1
fi

grep -q 'Attestation is stale' "${WORK_DIR}/stale.err" || {
  echo "Missing attestation stale error" >&2
  exit 1
}

(
  cd "$ROOT_DIR"
  ATTESTATION_SCHEMA_VERSION=2 bash scripts/write-report-attestation.sh "$combined" "$errors" "$trend" "$attestation"
)

set +e
(
  cd "$ROOT_DIR"
  ATTESTATION_EXPECTED_SCHEMA_VERSION=1 bash scripts/validate-report-attestation.sh "$combined" "$errors" "$trend" "$attestation"
) >"${WORK_DIR}/schema.out" 2>"${WORK_DIR}/schema.err"
schema_status=$?
set -e

if [[ "$schema_status" -eq 0 ]]; then
  echo "Expected schema version compatibility failure" >&2
  exit 1
fi

grep -q 'Unsupported attestation schema_version' "${WORK_DIR}/schema.err" || {
  echo "Missing schema version mismatch error" >&2
  exit 1
}

(
  cd "$ROOT_DIR"
  ATTESTATION_SCHEMA_VERSION=1 bash scripts/write-report-attestation.sh "$combined" "$errors" "$trend" "$attestation"
)

renamed_combined="${WORK_DIR}/combined-renamed.csv"
cp "$combined" "$renamed_combined"

set +e
(
  cd "$ROOT_DIR"
  bash scripts/validate-report-attestation.sh "$renamed_combined" "$errors" "$trend" "$attestation"
) >"${WORK_DIR}/path.out" 2>"${WORK_DIR}/path.err"
path_status=$?
set -e

if [[ "$path_status" -eq 0 ]]; then
  echo "Expected attestation path consistency failure" >&2
  exit 1
fi

grep -q 'Attestation path mismatch for combined_file' "${WORK_DIR}/path.err" || {
  echo "Missing path mismatch error" >&2
  exit 1
}

(
  cd "$ROOT_DIR"
  ATTESTATION_CHECKSUM_ALGORITHM=sha1 bash scripts/write-report-attestation.sh "$combined" "$errors" "$trend" "$attestation"
)

set +e
(
  cd "$ROOT_DIR"
  ATTESTATION_EXPECTED_CHECKSUM_ALGORITHM=sha256 bash scripts/validate-report-attestation.sh "$combined" "$errors" "$trend" "$attestation"
) >"${WORK_DIR}/algo.out" 2>"${WORK_DIR}/algo.err"
algo_status=$?
set -e

if [[ "$algo_status" -eq 0 ]]; then
  echo "Expected checksum algorithm compatibility failure" >&2
  exit 1
fi

grep -q 'Unsupported attestation checksum_algorithm' "${WORK_DIR}/algo.err" || {
  echo "Missing checksum algorithm mismatch error" >&2
  exit 1
}

echo "report attestation checks passed."
