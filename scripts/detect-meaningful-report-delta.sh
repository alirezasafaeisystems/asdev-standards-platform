#!/usr/bin/env bash
set -euo pipefail

if [[ "$#" -lt 1 ]]; then
  echo "Usage: $0 <file> [<file> ...]" >&2
  exit 1
fi

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
NORMALIZE_SCRIPT="${ROOT_DIR}/scripts/normalize-report-output.sh"

if [[ ! -x "$NORMALIZE_SCRIPT" ]]; then
  echo "Missing executable normalize script: $NORMALIZE_SCRIPT" >&2
  exit 1
fi

WORK_DIR="$(mktemp -d)"
trap 'rm -rf "$WORK_DIR"' EXIT

has_meaningful_changes="false"
changed_files=()

for rel_path in "$@"; do
  rel_path="${rel_path#./}"
  current_file="${ROOT_DIR}/${rel_path}"
  baseline_file="${WORK_DIR}/baseline-$(echo "$rel_path" | tr '/.' '__')"
  norm_current="${WORK_DIR}/norm-current-$(echo "$rel_path" | tr '/.' '__')"
  norm_baseline="${WORK_DIR}/norm-baseline-$(echo "$rel_path" | tr '/.' '__')"

  if [[ ! -f "$current_file" ]]; then
    has_meaningful_changes="true"
    changed_files+=("$rel_path")
    continue
  fi

  if ! git -C "$ROOT_DIR" show "HEAD:${rel_path}" > "$baseline_file" 2>/dev/null; then
    has_meaningful_changes="true"
    changed_files+=("$rel_path")
    continue
  fi

  bash "$NORMALIZE_SCRIPT" "$current_file" "$norm_current" "$rel_path"
  bash "$NORMALIZE_SCRIPT" "$baseline_file" "$norm_baseline" "$rel_path"

  if ! diff -u "$norm_baseline" "$norm_current" > /dev/null; then
    has_meaningful_changes="true"
    changed_files+=("$rel_path")
  fi
done

echo "has_meaningful_changes=${has_meaningful_changes}"
if [[ "${#changed_files[@]}" -gt 0 ]]; then
  changed_csv="$(printf '%s\n' "${changed_files[@]}" | paste -sd ',' -)"
else
  changed_csv=""
fi
echo "changed_files=${changed_csv}"
