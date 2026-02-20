#!/usr/bin/env bash
set -euo pipefail

tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

fixture_pass="${tmp_dir}/fixture-pass.json"
fixture_warn="${tmp_dir}/fixture-warn.json"
out="${tmp_dir}/audit.md"

cat > "$fixture_pass" <<'EOF_JSON'
{
  "required_branch_protection_context": "PR Validation / quality-gate",
  "merged_prs": [
    {"number": 1, "context_present": true},
    {"number": 2, "context_present": true},
    {"number": 3, "context_present": true}
  ]
}
EOF_JSON

PR_CHECK_AUDIT_FIXTURE="$fixture_pass" PR_CHECK_AUDIT_MIN_SAMPLE=3 \
  bash scripts/audit-pr-check-emission.sh test/repo "$out" true
grep -q '^- status: pass$' "$out" || { echo "expected pass status"; exit 1; }

cat > "$fixture_warn" <<'EOF_JSON'
{
  "required_branch_protection_context": "PR Validation / quality-gate",
  "merged_prs": [
    {"number": 10, "context_present": true},
    {"number": 11, "context_present": false},
    {"number": 12, "context_present": true}
  ]
}
EOF_JSON

if PR_CHECK_AUDIT_FIXTURE="$fixture_warn" PR_CHECK_AUDIT_MIN_SAMPLE=3 \
  bash scripts/audit-pr-check-emission.sh test/repo "$out" true; then
  echo "expected strict-mode failure when context is missing" >&2
  exit 1
fi

PR_CHECK_AUDIT_FIXTURE="$fixture_warn" PR_CHECK_AUDIT_MIN_SAMPLE=3 \
  bash scripts/audit-pr-check-emission.sh test/repo "$out" false
grep -q '^- status: warn$' "$out" || { echo "expected warn status"; exit 1; }

echo "PR check audit tests passed."
