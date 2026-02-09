#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SYNC_DIR="${1:-${ROOT_DIR}/sync}"
SNAPSHOT_DIR="${SYNC_DIR}/snapshots"
RETENTION_DAYS="${REPORT_SNAPSHOT_RETENTION_DAYS:-14}"
TIMESTAMP="$(date -u +%Y%m%dT%H%M%SZ)"

rotate_snapshot() {
  local current_file="$1"
  local previous_file="$2"
  local snapshot_prefix="$3"
  if [[ -f "$current_file" ]]; then
    cp "$current_file" "$previous_file"
    mkdir -p "$SNAPSHOT_DIR"
    cp "$current_file" "${SNAPSHOT_DIR}/${snapshot_prefix}.${TIMESTAMP}.csv"
  fi
}

rotate_snapshot "${SYNC_DIR}/divergence-report.csv" "${SYNC_DIR}/divergence-report.previous.csv" "divergence-report"
rotate_snapshot "${SYNC_DIR}/divergence-report.combined.csv" "${SYNC_DIR}/divergence-report.combined.previous.csv" "divergence-report.combined"
rotate_snapshot "${SYNC_DIR}/divergence-report.combined.errors.csv" "${SYNC_DIR}/divergence-report.combined.errors.previous.csv" "divergence-report.combined.errors"
rotate_snapshot "${SYNC_DIR}/divergence-report.combined.errors.trend.csv" "${SYNC_DIR}/divergence-report.combined.errors.trend.previous.csv" "divergence-report.combined.errors.trend"

if [[ -d "$SNAPSHOT_DIR" ]]; then
  find "$SNAPSHOT_DIR" -type f -name '*.csv' -mtime "+${RETENTION_DAYS}" -delete
fi

echo "Report snapshots rotated under ${SYNC_DIR}"
