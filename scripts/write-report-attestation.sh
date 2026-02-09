#!/usr/bin/env bash
set -euo pipefail

COMBINED_FILE="${1:-sync/divergence-report.combined.csv}"
ERRORS_FILE="${2:-sync/divergence-report.combined.errors.csv}"
TREND_FILE="${3:-sync/divergence-report.combined.errors.trend.csv}"
ATTESTATION_FILE="${4:-sync/generated-reports.attestation}"

for file in "$COMBINED_FILE" "$ERRORS_FILE" "$TREND_FILE"; do
  if [[ ! -f "$file" ]]; then
    echo "Missing report artifact for attestation: $file" >&2
    exit 1
  fi
done

mkdir -p "$(dirname "$ATTESTATION_FILE")"
{
  echo "validated_at=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "combined_file=${COMBINED_FILE}"
  echo "errors_file=${ERRORS_FILE}"
  echo "trend_file=${TREND_FILE}"
  echo "combined_sha256=$(sha256sum "$COMBINED_FILE" | awk '{print $1}')"
  echo "errors_sha256=$(sha256sum "$ERRORS_FILE" | awk '{print $1}')"
  echo "trend_sha256=$(sha256sum "$TREND_FILE" | awk '{print $1}')"
} > "$ATTESTATION_FILE"

echo "Generated report attestation: $ATTESTATION_FILE"
