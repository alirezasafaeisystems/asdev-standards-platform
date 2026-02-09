#!/usr/bin/env bash
set -euo pipefail

COMBINED_FILE="${1:-sync/divergence-report.combined.csv}"
ERRORS_FILE="${2:-sync/divergence-report.combined.errors.csv}"
TREND_FILE="${3:-sync/divergence-report.combined.errors.trend.csv}"
ATTESTATION_FILE="${4:-sync/generated-reports.attestation}"

for file in "$COMBINED_FILE" "$ERRORS_FILE" "$TREND_FILE"; do
  if [[ ! -f "$file" ]]; then
    echo "Missing report artifact: $file" >&2
    exit 1
  fi
done

if [[ ! -f "$ATTESTATION_FILE" ]]; then
  echo "Missing report attestation file: $ATTESTATION_FILE" >&2
  exit 1
fi

require_key() {
  local key="$1"
  if ! grep -q "^${key}=" "$ATTESTATION_FILE"; then
    echo "Attestation key missing: ${key}" >&2
    exit 1
  fi
}

require_key "validated_at"
require_key "combined_file"
require_key "errors_file"
require_key "trend_file"
require_key "combined_sha256"
require_key "errors_sha256"
require_key "trend_sha256"

attested_combined="$(grep '^combined_sha256=' "$ATTESTATION_FILE" | cut -d= -f2-)"
attested_errors="$(grep '^errors_sha256=' "$ATTESTATION_FILE" | cut -d= -f2-)"
attested_trend="$(grep '^trend_sha256=' "$ATTESTATION_FILE" | cut -d= -f2-)"

actual_combined="$(sha256sum "$COMBINED_FILE" | awk '{print $1}')"
actual_errors="$(sha256sum "$ERRORS_FILE" | awk '{print $1}')"
actual_trend="$(sha256sum "$TREND_FILE" | awk '{print $1}')"

if [[ "$attested_combined" != "$actual_combined" ]]; then
  echo "Attestation hash mismatch for combined report" >&2
  exit 1
fi
if [[ "$attested_errors" != "$actual_errors" ]]; then
  echo "Attestation hash mismatch for error report" >&2
  exit 1
fi
if [[ "$attested_trend" != "$actual_trend" ]]; then
  echo "Attestation hash mismatch for trend report" >&2
  exit 1
fi

echo "Report attestation validation passed."
