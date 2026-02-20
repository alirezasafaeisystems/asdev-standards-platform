#!/usr/bin/env bash
set -euo pipefail

base_ref="${1:-origin/main}"
if ! git rev-parse --verify "$base_ref" >/dev/null 2>&1; then
  echo "Policy guard: base ref $base_ref not found, skipping."
  exit 0
fi

if ! git diff --name-only "$base_ref"...HEAD | rg -q '^platform/repo-templates/templates.yaml$'; then
  echo "Policy guard: templates catalog unchanged."
  exit 0
fi

if git diff "$base_ref"...HEAD -- platform/repo-templates/templates.yaml | rg -q '^[+-].*version:'; then
  if git diff --name-only "$base_ref"...HEAD | rg -q '^(standards/|governance/ADR/)'; then
    echo "Policy guard passed."
    exit 0
  fi
  echo "Policy guard failed: template version changed without standards/ADR update."
  exit 1
fi

echo "Policy guard: no version line changed."
