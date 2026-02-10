#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORKFLOW_FILE="${ROOT_DIR}/.github/workflows/ci.yml"

if [[ ! -f "${WORKFLOW_FILE}" ]]; then
  echo "Missing workflow file: ${WORKFLOW_FILE}" >&2
  exit 1
fi

grep -q '^  generate-reports-docs:' "${WORKFLOW_FILE}" || {
  echo "Missing generate-reports-docs job" >&2
  exit 1
}

grep -q "^    if: github.event_name == 'schedule'" "${WORKFLOW_FILE}" || {
  echo "report update jobs must run on schedule only" >&2
  exit 1
}

grep -q '^    needs: lint-and-test' "${WORKFLOW_FILE}" || {
  echo "generate-reports-docs must need lint-and-test" >&2
  exit 1
}

grep -q '^  open-update-pr:' "${WORKFLOW_FILE}" || {
  echo "Missing open-update-pr job" >&2
  exit 1
}

grep -q '^    needs: generate-reports-docs' "${WORKFLOW_FILE}" || {
  echo "open-update-pr must need generate-reports-docs" >&2
  exit 1
}

grep -q 'name: Validate report attestation presence' "${WORKFLOW_FILE}" || {
  echo "Missing attestation validation step" >&2
  exit 1
}

grep -q 'name: Detect generated changes' "${WORKFLOW_FILE}" || {
  echo "Missing generated changes detection step" >&2
  exit 1
}

grep -q 'scripts/detect-meaningful-report-delta.sh' "${WORKFLOW_FILE}" || {
  echo "Missing meaningful delta detector in workflow" >&2
  exit 1
}

grep -q 'name: Append clone_failed summary' "${WORKFLOW_FILE}" || {
  echo "Missing clone_failed summary step" >&2
  exit 1
}

grep -q 'name: Append fingerprint delta summary' "${WORKFLOW_FILE}" || {
  echo "Missing fingerprint delta summary step" >&2
  exit 1
}

grep -q 'name: Enforce attestation file in update PR' "${WORKFLOW_FILE}" || {
  echo "Missing update PR attestation enforcement step" >&2
  exit 1
}

grep -q 'name: Publish workflow summary' "${WORKFLOW_FILE}" || {
  echo "Missing workflow summary step" >&2
  exit 1
}

grep -q 'name: Report auto-merge limitation' "${WORKFLOW_FILE}" || {
  echo "Missing auto-merge limitation reporting step" >&2
  exit 1
}

grep -q 'gh pr list --head chore/reports-docs-update --base main' "${WORKFLOW_FILE}" || {
  echo "Missing existing update-branch PR fallback lookup" >&2
  exit 1
}

echo "ci workflow contract checks passed."
