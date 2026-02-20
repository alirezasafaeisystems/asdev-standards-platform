#!/usr/bin/env bash
set -euo pipefail

workflow=".github/workflows/release-post-check.yml"
[[ -f "$workflow" ]] || { echo "missing release post-check workflow"; exit 1; }

grep -q '^name: Release Post Check$' "$workflow" || { echo "workflow name mismatch"; exit 1; }
grep -q '^  release:' "$workflow" || { echo "missing release trigger"; exit 1; }
grep -q '^    types: \[published\]$' "$workflow" || { echo "missing release published trigger"; exit 1; }
grep -q '^  workflow_dispatch:' "$workflow" || { echo "missing workflow_dispatch trigger"; exit 1; }
grep -q 'scripts/release/post-check.sh' "$workflow" || { echo "missing release post-check script call"; exit 1; }

echo "release post-check workflow contract checks passed."
