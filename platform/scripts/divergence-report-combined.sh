#!/usr/bin/env bash
set -euo pipefail

TEMPLATES_FILE="${1:-platform/repo-templates/templates.yaml}"
TEMPLATES_ROOT="${2:-platform/repo-templates}"
OUTPUT_FILE="${3:-sync/divergence-report.combined.csv}"
TARGET_GLOB="${4:-sync/targets*.yaml}"

resolve_path() {
  local path_value="$1"
  if [[ "$path_value" = /* ]]; then
    printf "%s\n" "$path_value"
  else
    printf "%s/%s\n" "$(pwd)" "$path_value"
  fi
}

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "Missing required command: $1" >&2
    exit 1
  }
}

require_cmd bash
require_cmd find

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TEMPLATES_FILE="$(resolve_path "$TEMPLATES_FILE")"
TEMPLATES_ROOT="$(resolve_path "$TEMPLATES_ROOT")"
OUTPUT_FILE="$(resolve_path "$OUTPUT_FILE")"

mkdir -p "$(dirname "$OUTPUT_FILE")"

echo "target_file,repo,template_id,expected_version,detected_version,mode,source_ref,status,last_checked_at" > "$OUTPUT_FILE"

mapfile -t target_files < <(find "${ROOT_DIR}/sync" -maxdepth 1 -type f -name 'targets*.yaml' ! -name 'targets.example.yaml' | sort)
if [[ "${#target_files[@]}" -eq 0 ]]; then
  echo "No target files found under sync/"
  exit 0
fi

for target_file in "${target_files[@]}"; do
  tmp_csv="$(mktemp)"
  bash "${ROOT_DIR}/platform/scripts/divergence-report.sh" "$target_file" "$TEMPLATES_FILE" "$TEMPLATES_ROOT" "$tmp_csv"
  if [[ -s "$tmp_csv" ]]; then
    tail -n +2 "$tmp_csv" | awk -F, -v tf="$(basename "$target_file")" 'BEGIN{OFS=","} {print tf,$0}' >> "$OUTPUT_FILE"
  fi
  rm -f "$tmp_csv"
done

echo "Combined divergence report generated: $OUTPUT_FILE"
