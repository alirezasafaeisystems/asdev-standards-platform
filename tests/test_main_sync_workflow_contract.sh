#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORKFLOW_FILE="${ROOT_DIR}/.github/workflows/main-sync-policy.yml"

if [[ ! -f "${WORKFLOW_FILE}" ]]; then
  echo "Missing workflow file: ${WORKFLOW_FILE}" >&2
  exit 1
fi

grep -q '^name: Main Sync Policy$' "${WORKFLOW_FILE}" || {
  echo "Unexpected workflow name" >&2
  exit 1
}

grep -q '^  workflow_dispatch:$' "${WORKFLOW_FILE}" || {
  echo "Workflow dispatch trigger is required" >&2
  exit 1
}

grep -q "make enforce-main-sync" "${WORKFLOW_FILE}" || {
  echo "Workflow must execute main sync enforcement" >&2
  exit 1
}

echo "main sync workflow contract checks passed."
