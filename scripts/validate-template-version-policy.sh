#!/usr/bin/env bash
set -euo pipefail

BASE_REF="${1:-origin/main}"
TARGET_FILE="platform/repo-templates/templates.yaml"

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "Not inside a git repository; skipping template policy check."
  exit 0
fi

if ! git rev-parse "$BASE_REF" >/dev/null 2>&1; then
  echo "Base ref $BASE_REF not available; skipping template policy check."
  exit 0
fi

if ! git diff --name-only "$BASE_REF"...HEAD | grep -qx "$TARGET_FILE"; then
  echo "No template manifest changes detected."
  exit 0
fi

if ! git diff "$BASE_REF"...HEAD -- "$TARGET_FILE" | grep -E '^[+-].*version:' >/dev/null; then
  echo "Template manifest changed without version updates; policy check passed."
  exit 0
fi

if git diff --name-only "$BASE_REF"...HEAD | grep -E '^(governance/ADR/|standards/)' >/dev/null; then
  echo "Template version policy check passed."
  exit 0
fi

echo "Template version changed without related ADR/standards update." >&2
echo "Update at least one file under governance/ADR/ or standards/." >&2
exit 1
