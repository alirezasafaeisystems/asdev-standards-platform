#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MANIFEST="${1:-${ROOT_DIR}/platform/repo-templates/templates.yaml}"

if ! command -v yq >/dev/null 2>&1; then
  echo "Missing required command: yq" >&2
  exit 1
fi

if [[ ! -f "$MANIFEST" ]]; then
  echo "Manifest not found: $MANIFEST" >&2
  exit 1
fi

mapfile -t known_ids < <(yq -r '.templates[].id' "$MANIFEST")
known_set="$(printf '%s\n' "${known_ids[@]}" | sort -u)"

failed=0
while IFS= read -r target_file; do
  while IFS= read -r id; do
    [[ -z "$id" || "$id" == "null" ]] && continue
    if ! grep -qx "$id" <<< "$known_set"; then
      echo "Unknown template id '$id' in ${target_file}" >&2
      failed=1
    fi
  done < <(yq -r '.targets[].templates[]?, .targets[].optional_features[]?' "$target_file")
done < <(find "${ROOT_DIR}/sync" -maxdepth 1 -type f -name 'targets*.yaml' | sort)

if [[ "$failed" -ne 0 ]]; then
  exit 1
fi

echo "target template ID validation passed."
