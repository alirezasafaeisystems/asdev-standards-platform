#!/usr/bin/env bash
set -euo pipefail

paths=(
  ".github"
  "scripts"
  "tools"
  "schemas"
  "tests"
  "ops"
  "sync"
  "platform"
  "docs/README.md"
  "docs/reports/README.md"
  "docs/reports/PROJECT_STATUS_REVIEW_2026-02-20.md"
  "AGENTS.md"
  "ROADMAP_EXECUTION_UNIFIED.md"
  "CHANGELOG.md"
  "CONTRIBUTING.md"
  "SECURITY.md"
  "SUPPORT.md"
)

if rg -n "[[:blank:]]$" \
  --glob '*.md' --glob '*.yml' --glob '*.yaml' --glob '*.sh' --glob '*.py' \
  "${paths[@]}" >/dev/null; then
  echo "Lint failed: trailing whitespace found"
  exit 1
fi

echo "Lint checks passed."
