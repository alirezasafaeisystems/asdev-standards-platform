#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
YQ_BIN="$("${ROOT_DIR}/scripts/ensure-yq.sh")"
export PATH="$(dirname "${YQ_BIN}"):${PATH}"

SYNC_DIR="${ROOT_DIR}/sync"
BACKUP_DIR="$(mktemp -d)"
OUTPUT_FILE="$(mktemp)"

cleanup() {
  for name in divergence-report.csv divergence-report.previous.csv divergence-report.combined.csv divergence-report.combined.previous.csv divergence-report.combined.errors.trend.csv divergence-report.combined.errors.trend.previous.csv; do
    if [[ -f "${BACKUP_DIR}/${name}" ]]; then
      cp "${BACKUP_DIR}/${name}" "${SYNC_DIR}/${name}"
    else
      rm -f "${SYNC_DIR}/${name}"
    fi
  done
  if [[ -d "${BACKUP_DIR}/snapshots" ]]; then
    rm -rf "${SYNC_DIR}/snapshots"
    cp -a "${BACKUP_DIR}/snapshots" "${SYNC_DIR}/snapshots"
  else
    rm -rf "${SYNC_DIR}/snapshots"
  fi
  rm -rf "${BACKUP_DIR}" "${OUTPUT_FILE}"
}
trap cleanup EXIT

for name in divergence-report.csv divergence-report.previous.csv divergence-report.combined.csv divergence-report.combined.previous.csv divergence-report.combined.errors.trend.csv divergence-report.combined.errors.trend.previous.csv; do
  if [[ -f "${SYNC_DIR}/${name}" ]]; then
    cp "${SYNC_DIR}/${name}" "${BACKUP_DIR}/${name}"
  fi
done
if [[ -d "${SYNC_DIR}/snapshots" ]]; then
  cp -a "${SYNC_DIR}/snapshots" "${BACKUP_DIR}/snapshots"
fi

cat > "${SYNC_DIR}/divergence-report.csv" <<'CSV'
repo,template_id,expected_version,detected_version,mode,source_ref,status,last_checked_at
example/repo-a,pr-template,1.0.0,1.0.0,required,ref,aligned,2026-02-09T00:00:00Z
CSV

cat > "${SYNC_DIR}/divergence-report.previous.csv" <<'CSV'
repo,template_id,expected_version,detected_version,mode,source_ref,status,last_checked_at
example/repo-a,pr-template,1.0.0,1.0.0,required,ref,aligned,2026-02-08T00:00:00Z
CSV

cat > "${SYNC_DIR}/divergence-report.combined.previous.csv" <<'CSV'
target_file,repo,template_id,expected_version,detected_version,mode,source_ref,status,last_checked_at
targets.yaml,example/repo-a,pr-template,1.0.0,missing,required,ref,clone_failed,2026-02-08T00:00:00Z
targets.yaml,example/repo-c,pr-template,1.0.0,1.0.0,required,ref,aligned,2026-02-08T00:00:00Z
targets.yaml,example/repo-d,pr-template,1.0.0,missing,required,ref,unknown_template,2026-02-08T00:00:00Z
CSV

cat > "${SYNC_DIR}/divergence-report.combined.csv" <<'CSV'
target_file,repo,template_id,expected_version,detected_version,mode,source_ref,status,last_checked_at
targets.yaml,example/repo-a,pr-template,1.0.0,missing,required,ref,clone_failed,2026-02-09T00:00:00Z
targets.yaml,example/repo-a,issue-bug,1.0.0,missing,required,ref,clone_failed,2026-02-09T00:00:00Z
targets.yaml,example/repo-b,pr-template,1.0.0,missing,required,ref,clone_failed,2026-02-09T00:00:00Z
targets.yaml,example/repo-c,pr-template,1.0.0,1.0.0,required,ref,aligned,2026-02-09T00:00:00Z
targets.yaml,example/repo-d,pr-template,1.0.0,missing,required,ref,unknown_template,2026-02-09T00:00:00Z
targets.yaml,example/repo-e,pr-template,1.0.0,missing,required,ref,unknown_template,2026-02-09T00:00:00Z
CSV

cat > "${SYNC_DIR}/divergence-report.combined.errors.trend.csv" <<'CSV'
error_fingerprint,previous,current,delta
tls_error,1,3,2
timeout,2,1,-1
auth_or_access,1,4,3
CSV

cat > "${SYNC_DIR}/divergence-report.combined.errors.trend.previous.csv" <<'CSV'
error_fingerprint,previous,current,delta
tls_error,0,1,1
http_502,1,0,-1
auth_or_access,0,2,2
CSV

mkdir -p "${SYNC_DIR}/snapshots"
cat > "${SYNC_DIR}/snapshots/divergence-report.combined.errors.trend.20260209T100000Z.csv" <<'CSV'
error_fingerprint,previous,current,delta
tls_error,0,2,2
auth_or_access,0,3,3
CSV
cat > "${SYNC_DIR}/snapshots/divergence-report.combined.20260209T100000Z.csv" <<'CSV'
target_file,repo,template_id,expected_version,detected_version,mode,source_ref,status,last_checked_at
targets.yaml,example/repo-a,pr-template,1.0.0,missing,required,ref,clone_failed,2026-02-09T10:00:00Z
targets.yaml,example/repo-b,pr-template,1.0.0,missing,required,ref,clone_failed,2026-02-09T10:00:00Z
targets.yaml,example/repo-d,pr-template,1.0.0,missing,required,ref,unknown_template,2026-02-09T10:00:00Z
CSV

bash "${ROOT_DIR}/scripts/generate-dashboard.sh" "${OUTPUT_FILE}"

grep -q "## Combined Reliability (clone_failed)" "${OUTPUT_FILE}" || {
  echo "Missing Combined Reliability section" >&2
  exit 1
}

grep -q "| clone_failed rows | 1 | 3 | 2 |" "${OUTPUT_FILE}" || {
  echo "Unexpected clone_failed totals/delta row" >&2
  exit 1
}

grep -q "### clone_failed by Repository" "${OUTPUT_FILE}" || {
  echo "Missing clone_failed by Repository section" >&2
  exit 1
}

grep -q "| example/repo-a | 1 | 2 | 1 |" "${OUTPUT_FILE}" || {
  echo "Missing or incorrect repo-a clone_failed row" >&2
  exit 1
}

grep -q "| example/repo-b | 0 | 1 | 1 |" "${OUTPUT_FILE}" || {
  echo "Missing or incorrect repo-b clone_failed row" >&2
  exit 1
}

grep -q "## Fingerprint Delta History (Recent Runs)" "${OUTPUT_FILE}" || {
  echo "Missing Fingerprint Delta History section" >&2
  exit 1
}

grep -q "| current | tls_error | 2 |" "${OUTPUT_FILE}" || {
  echo "Missing current trend history row" >&2
  exit 1
}

grep -q "| previous | http_502 | -1 |" "${OUTPUT_FILE}" || {
  echo "Missing previous trend history row" >&2
  exit 1
}

grep -q "| 20260209T100000Z | tls_error | 2 |" "${OUTPUT_FILE}" || {
  echo "Missing snapshot trend history row" >&2
  exit 1
}

grep -q "## auth_or_access Trend by Run" "${OUTPUT_FILE}" || {
  echo "Missing auth_or_access trend section" >&2
  exit 1
}

grep -q "| current | 4 |" "${OUTPUT_FILE}" || {
  echo "Missing current auth_or_access row" >&2
  exit 1
}

grep -q "| previous | 2 |" "${OUTPUT_FILE}" || {
  echo "Missing previous auth_or_access row" >&2
  exit 1
}

grep -q "| 20260209T100000Z | 3 |" "${OUTPUT_FILE}" || {
  echo "Missing snapshot auth_or_access row" >&2
  exit 1
}

grep -q "## Top Fingerprint Deltas (Current Run)" "${OUTPUT_FILE}" || {
  echo "Missing top fingerprint deltas section" >&2
  exit 1
}

grep -q "### Top Positive Deltas" "${OUTPUT_FILE}" || {
  echo "Missing top positive deltas section" >&2
  exit 1
}

grep -q "| tls_error | 2 |" "${OUTPUT_FILE}" || {
  echo "Missing expected positive delta row" >&2
  exit 1
}

grep -q "### Top Negative Deltas" "${OUTPUT_FILE}" || {
  echo "Missing top negative deltas section" >&2
  exit 1
}

grep -q "| timeout | -1 |" "${OUTPUT_FILE}" || {
  echo "Missing expected negative delta row" >&2
  exit 1
}

grep -q "### clone_failed Trend by Run" "${OUTPUT_FILE}" || {
  echo "Missing clone_failed trend by run section" >&2
  exit 1
}

grep -q "| current | 3 |" "${OUTPUT_FILE}" || {
  echo "Missing current clone_failed trend row" >&2
  exit 1
}

grep -q "| previous | 1 |" "${OUTPUT_FILE}" || {
  echo "Missing previous clone_failed trend row" >&2
  exit 1
}

grep -q "| 20260209T100000Z | 2 |" "${OUTPUT_FILE}" || {
  echo "Missing snapshot clone_failed trend row" >&2
  exit 1
}

grep -q "### unknown_template Trend by Run" "${OUTPUT_FILE}" || {
  echo "Missing unknown_template trend by run section" >&2
  exit 1
}

grep -q "| current | 2 |" "${OUTPUT_FILE}" || {
  echo "Missing current unknown_template trend row" >&2
  exit 1
}

grep -q "| previous | 1 |" "${OUTPUT_FILE}" || {
  echo "Missing previous unknown_template trend row" >&2
  exit 1
}

grep -q "| 20260209T100000Z | 1 |" "${OUTPUT_FILE}" || {
  echo "Missing snapshot unknown_template trend row" >&2
  exit 1
}

echo "dashboard reliability checks passed."
