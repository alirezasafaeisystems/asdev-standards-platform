#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# On main without template-version diff, script should pass.
bash "${ROOT_DIR}/scripts/validate-template-version-policy.sh" origin/main

echo "template version policy checks passed."
