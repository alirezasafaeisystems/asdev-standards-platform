#!/usr/bin/env bash
set -euo pipefail

workflow=".github/workflows/pr-check-audit.yml"
[[ -f "$workflow" ]] || { echo "missing pr-check-audit workflow"; exit 1; }

grep -q '^name: PR Check Audit$' "$workflow" || { echo "workflow name mismatch"; exit 1; }
grep -q '^  schedule:' "$workflow" || { echo "missing schedule trigger"; exit 1; }
grep -q '^  workflow_dispatch:' "$workflow" || { echo "missing workflow_dispatch trigger"; exit 1; }
grep -q 'scripts/audit-pr-check-emission.sh' "$workflow" || { echo "missing audit script call"; exit 1; }
grep -q 'name: pr-check-audit' "$workflow" || { echo "missing artifact upload"; exit 1; }

echo "PR check audit workflow contract checks passed."
