#!/usr/bin/env bash
set -euo pipefail

output="$(make -n reports)"

required_patterns=(
  '^bash scripts/rotate-report-snapshots.sh$'
  '^bash platform/scripts/divergence-report-combined.sh '
  '^bash scripts/generate-error-fingerprint-trend.sh '
  '^bash scripts/generate-dashboard.sh docs/platform-adoption-dashboard.md$'
  '^bash scripts/validate-generated-reports.sh '
  '^bash scripts/write-report-attestation.sh '
  '^bash scripts/validate-report-attestation.sh '
)

for pattern in "${required_patterns[@]}"; do
  if ! printf '%s\n' "$output" | grep -Eq "$pattern"; then
    echo "make reports target is missing expected command pattern: $pattern"
    exit 1
  fi
done

echo "make reports target checks passed."
