#!/usr/bin/env bash
set -euo pipefail

required=(
  "ROADMAP_EXECUTION_UNIFIED.md"
  "docs/reports/PROJECT_STATUS_REVIEW_2026-02-20.md"
  "schemas/codex-automation.schema.json"
  "schemas/execution-manifest.schema.json"
  "schemas/targets.schema.json"
  "schemas/templates.schema.json"
)

for file in "${required[@]}"; do
  test -f "$file" || { echo "Build failed: missing $file"; exit 1; }
done

echo "Build checks passed."
