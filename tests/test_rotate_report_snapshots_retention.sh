#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORK_DIR="$(mktemp -d)"
trap 'rm -rf "${WORK_DIR}"' EXIT

sync_dir="${WORK_DIR}/sync"
mkdir -p "${sync_dir}/snapshots"

cat > "${sync_dir}/divergence-report.csv" <<'CSV'
repo,template_id,expected_version,detected_version,mode,source_ref,status,last_checked_at
r,a,1,1,required,ref,aligned,2026-02-09T00:00:00Z
CSV
cat > "${sync_dir}/divergence-report.combined.csv" <<'CSV'
target_file,repo,template_id,expected_version,detected_version,mode,source_ref,status,last_checked_at
a.yaml,r,a,1,1,required,ref,aligned,2026-02-09T00:00:00Z
CSV
cat > "${sync_dir}/divergence-report.combined.errors.csv" <<'CSV'
target_file,repo,error_fingerprint,last_checked_at
a.yaml,r,tls_error,2026-02-09T00:00:00Z
CSV
cat > "${sync_dir}/divergence-report.combined.errors.trend.csv" <<'CSV'
error_fingerprint,previous,current,delta
tls_error,0,1,1
CSV

cat > "${sync_dir}/snapshots/old.csv" <<'CSV'
a,b
CSV
touch -d '20 days ago' "${sync_dir}/snapshots/old.csv"

(
  cd "$ROOT_DIR"
  REPORT_SNAPSHOT_RETENTION_DAYS=7 bash scripts/rotate-report-snapshots.sh "$sync_dir"
)

[[ -f "${sync_dir}/divergence-report.previous.csv" ]] || { echo "missing previous level0 snapshot" >&2; exit 1; }
[[ -f "${sync_dir}/divergence-report.combined.previous.csv" ]] || { echo "missing previous combined snapshot" >&2; exit 1; }
[[ -f "${sync_dir}/divergence-report.combined.errors.previous.csv" ]] || { echo "missing previous errors snapshot" >&2; exit 1; }
[[ -f "${sync_dir}/divergence-report.combined.errors.trend.previous.csv" ]] || { echo "missing previous trend snapshot" >&2; exit 1; }

if [[ -f "${sync_dir}/snapshots/old.csv" ]]; then
  echo "Expected old snapshot pruning" >&2
  exit 1
fi

count_new="$(find "${sync_dir}/snapshots" -maxdepth 1 -type f -name '*.csv' | wc -l)"
if [[ "$count_new" -lt 4 ]]; then
  echo "Expected newly rotated snapshots" >&2
  exit 1
fi

echo "rotate snapshot retention checks passed."
