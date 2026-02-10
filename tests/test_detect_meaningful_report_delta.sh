#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORK_DIR="$(mktemp -d)"
trap 'rm -rf "${WORK_DIR}"' EXIT

mkdir -p "${WORK_DIR}/scripts" "${WORK_DIR}/sync" "${WORK_DIR}/docs"
cp "${ROOT_DIR}/scripts/normalize-report-output.sh" "${WORK_DIR}/scripts/normalize-report-output.sh"
cp "${ROOT_DIR}/scripts/detect-meaningful-report-delta.sh" "${WORK_DIR}/scripts/detect-meaningful-report-delta.sh"
chmod +x "${WORK_DIR}/scripts/normalize-report-output.sh" "${WORK_DIR}/scripts/detect-meaningful-report-delta.sh"

cat > "${WORK_DIR}/sync/divergence-report.combined.csv" <<'CSV'
target_file,repo,template_id,expected_version,detected_version,mode,source_ref,status,last_checked_at
t1,org/a,level0,1.0.0,1.0.0,required,main,aligned,2026-02-10T00:00:00Z
t2,org/b,level0,1.0.0,0.9.0,required,main,diverged,2026-02-10T00:00:00Z
CSV
cat > "${WORK_DIR}/sync/divergence-report.combined.errors.csv" <<'CSV'
target_file,repo,error_fingerprint,last_checked_at
t2,org/b,none,2026-02-10T00:00:00Z
CSV
cat > "${WORK_DIR}/sync/divergence-report.combined.errors.trend.csv" <<'CSV'
error_fingerprint,previous,current,delta
none,0,1,1
CSV
cat > "${WORK_DIR}/sync/generated-reports.attestation" <<'TXT'
schema_version=1
checksum_algorithm=sha256
validated_at=2026-02-10T00:00:00Z
combined_file=sync/divergence-report.combined.csv
errors_file=sync/divergence-report.combined.errors.csv
trend_file=sync/divergence-report.combined.errors.trend.csv
combined_sha256=aaa
errors_sha256=bbb
trend_sha256=ccc
TXT
cat > "${WORK_DIR}/docs/platform-adoption-dashboard.md" <<'MD'
# Platform Adoption Dashboard

- Generated at: 2026-02-10T00:00:00Z
- Latest Weekly Governance Digest: https://example.invalid/digest/1

## Level 0 Adoption (from divergence report)
MD

(
  cd "${WORK_DIR}"
  git init >/dev/null
  git config user.name "Test Bot"
  git config user.email "test@example.com"
  git add .
  git commit -m "baseline" >/dev/null
)

# Non-meaningful changes: timestamp metadata and CSV row order only.
cat > "${WORK_DIR}/sync/divergence-report.combined.csv" <<'CSV'
target_file,repo,template_id,expected_version,detected_version,mode,source_ref,status,last_checked_at
t2,org/b,level0,1.0.0,0.9.0,required,main,diverged,2026-02-10T00:00:00Z
t1,org/a,level0,1.0.0,1.0.0,required,main,aligned,2026-02-10T00:00:00Z
CSV
sed -i 's/^validated_at=.*/validated_at=2026-02-10T01:00:00Z/' "${WORK_DIR}/sync/generated-reports.attestation"
sed -i 's/Generated at:.*/Generated at: 2026-02-10T01:00:00Z/' "${WORK_DIR}/docs/platform-adoption-dashboard.md"

non_meaningful_output="$(
  cd "${WORK_DIR}"
  bash scripts/detect-meaningful-report-delta.sh \
    sync/divergence-report.combined.csv \
    sync/divergence-report.combined.errors.csv \
    sync/divergence-report.combined.errors.trend.csv \
    sync/generated-reports.attestation \
    docs/platform-adoption-dashboard.md
)"
echo "${non_meaningful_output}" | grep -q '^has_meaningful_changes=false$' || {
  echo "Expected non-meaningful-only changes to be ignored" >&2
  exit 1
}

# Meaningful change: status changed in combined report.
sed -i 's/,diverged,/,aligned,/' "${WORK_DIR}/sync/divergence-report.combined.csv"
meaningful_output="$(
  cd "${WORK_DIR}"
  bash scripts/detect-meaningful-report-delta.sh \
    sync/divergence-report.combined.csv \
    sync/divergence-report.combined.errors.csv \
    sync/divergence-report.combined.errors.trend.csv \
    sync/generated-reports.attestation \
    docs/platform-adoption-dashboard.md
)"
echo "${meaningful_output}" | grep -q '^has_meaningful_changes=true$' || {
  echo "Expected semantic report changes to be detected" >&2
  exit 1
}
echo "${meaningful_output}" | grep -q '^changed_files=.*sync/divergence-report.combined.csv' || {
  echo "Expected changed_files to include combined report CSV" >&2
  exit 1
}

echo "meaningful report delta checks passed."
