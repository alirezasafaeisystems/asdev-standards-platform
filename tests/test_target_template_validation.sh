#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if ! command -v yq >/dev/null 2>&1; then
  if [[ -x /tmp/yq ]]; then
    export PATH="/tmp:${PATH}"
  else
    echo "Skipping target template validation test (yq not found)."
    exit 0
  fi
fi

bash "${ROOT_DIR}/scripts/validate-target-template-ids.sh"

echo "target template validation checks passed."
