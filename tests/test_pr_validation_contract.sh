#!/usr/bin/env bash
set -euo pipefail

workflow=".github/workflows/pr-validation.yml"
[[ -f "$workflow" ]] || { echo "missing workflow"; exit 1; }

grep -q '^name: PR Validation$' "$workflow" || { echo "workflow name mismatch"; exit 1; }
grep -q '^  pull_request:' "$workflow" || { echo "missing pull_request trigger"; exit 1; }
grep -q '^  merge_group:' "$workflow" || { echo "missing merge_group trigger"; exit 1; }
grep -q '^  push:' "$workflow" || { echo "missing push trigger"; exit 1; }
grep -q '^  workflow_dispatch:' "$workflow" || { echo "missing workflow_dispatch trigger"; exit 1; }
grep -q '^  quality-gate:$' "$workflow" || { echo "missing quality-gate job"; exit 1; }
grep -q '^    name: quality-gate$' "$workflow" || { echo "missing job name quality-gate"; exit 1; }

echo "PR validation workflow contract checks passed."
