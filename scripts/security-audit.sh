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

if rg -n --glob '!scripts/security-audit.sh' '(AKIA[0-9A-Z]{16}|BEGIN PRIVATE KEY|xox[baprs]-|ghp_[A-Za-z0-9]{36,})' "${paths[@]}" >/dev/null; then
  echo "Security audit failed: potential secret pattern found"
  exit 1
fi

echo "Security audit passed."
