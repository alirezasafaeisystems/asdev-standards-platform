#!/usr/bin/env bash
set -euo pipefail

COMBINED_FILE="${1:-sync/divergence-report.combined.csv}"
ERRORS_FILE="${2:-sync/divergence-report.combined.errors.csv}"
TREND_FILE="${3:-sync/divergence-report.combined.errors.trend.csv}"
ATTESTATION_FILE="${4:-sync/generated-reports.attestation}"
ATTESTATION_MAX_AGE_SECONDS="${ATTESTATION_MAX_AGE_SECONDS:-1800}"
ATTESTATION_EXPECTED_SCHEMA_VERSION="${ATTESTATION_EXPECTED_SCHEMA_VERSION:-1}"
ATTESTATION_EXPECTED_CHECKSUM_ALGORITHM="${ATTESTATION_EXPECTED_CHECKSUM_ALGORITHM:-sha256}"

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

require_key "schema_version"
require_key "checksum_algorithm"
require_key "validated_at"
require_key "combined_file"
require_key "errors_file"
require_key "trend_file"
require_key "combined_sha256"
require_key "errors_sha256"
require_key "trend_sha256"

schema_version="$(grep '^schema_version=' "$ATTESTATION_FILE" | cut -d= -f2-)"
if [[ "$schema_version" != "$ATTESTATION_EXPECTED_SCHEMA_VERSION" ]]; then
  echo "Unsupported attestation schema_version=${schema_version}; expected=${ATTESTATION_EXPECTED_SCHEMA_VERSION}" >&2
  exit 1
fi

checksum_algorithm="$(grep '^checksum_algorithm=' "$ATTESTATION_FILE" | cut -d= -f2-)"
if [[ "$checksum_algorithm" != "$ATTESTATION_EXPECTED_CHECKSUM_ALGORITHM" ]]; then
  echo "Unsupported attestation checksum_algorithm=${checksum_algorithm}; expected=${ATTESTATION_EXPECTED_CHECKSUM_ALGORITHM}" >&2
  exit 1
fi

to_epoch() {
  local ts="$1"
  date -u -d "$ts" +%s 2>/dev/null || date -u -jf "%Y-%m-%dT%H:%M:%SZ" "$ts" +%s
}

validated_at="$(grep '^validated_at=' "$ATTESTATION_FILE" | cut -d= -f2-)"
validated_epoch="$(to_epoch "$validated_at")"
now_epoch="$(date -u +%s)"
age_seconds="$((now_epoch - validated_epoch))"
if [[ "$age_seconds" -gt "$ATTESTATION_MAX_AGE_SECONDS" ]]; then
  echo "Attestation is stale: age_seconds=${age_seconds}, max_allowed=${ATTESTATION_MAX_AGE_SECONDS}" >&2
  exit 1
fi

attested_combined="$(grep '^combined_sha256=' "$ATTESTATION_FILE" | cut -d= -f2-)"
attested_errors="$(grep '^errors_sha256=' "$ATTESTATION_FILE" | cut -d= -f2-)"
attested_trend="$(grep '^trend_sha256=' "$ATTESTATION_FILE" | cut -d= -f2-)"
attested_combined_file="$(grep '^combined_file=' "$ATTESTATION_FILE" | cut -d= -f2-)"
attested_errors_file="$(grep '^errors_file=' "$ATTESTATION_FILE" | cut -d= -f2-)"
attested_trend_file="$(grep '^trend_file=' "$ATTESTATION_FILE" | cut -d= -f2-)"

if [[ "$attested_combined_file" != "$COMBINED_FILE" ]]; then
  echo "Attestation path mismatch for combined_file: attested=${attested_combined_file} input=${COMBINED_FILE}" >&2
  exit 1
fi
if [[ "$attested_errors_file" != "$ERRORS_FILE" ]]; then
  echo "Attestation path mismatch for errors_file: attested=${attested_errors_file} input=${ERRORS_FILE}" >&2
  exit 1
fi
if [[ "$attested_trend_file" != "$TREND_FILE" ]]; then
  echo "Attestation path mismatch for trend_file: attested=${attested_trend_file} input=${TREND_FILE}" >&2
  exit 1
fi

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
