#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
YQ_BIN="$("${ROOT_DIR}/scripts/ensure-yq.sh")"
export PATH="$(dirname "${YQ_BIN}"):${PATH}"

bash "${ROOT_DIR}/scripts/validate-target-template-ids.sh"

echo "target template validation checks passed."
