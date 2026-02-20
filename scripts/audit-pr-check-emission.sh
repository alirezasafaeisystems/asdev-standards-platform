#!/usr/bin/env bash
set -euo pipefail

repo="${1:-alirezasafaeisystems/asdev-standards-platform}"
output="${2:-docs/reports/PR_CHECK_EMISSION_AUDIT.md}"
strict_mode="${3:-${PR_CHECK_AUDIT_STRICT:-false}}"
required_context="PR Validation / quality-gate"
sample_size="${PR_CHECK_AUDIT_SAMPLE_SIZE:-5}"
min_sample="${PR_CHECK_AUDIT_MIN_SAMPLE:-3}"

checked=0
with_context=0
details=""
protection_context=""

if [[ -n "${PR_CHECK_AUDIT_FIXTURE:-}" ]]; then
  mapfile -t data < <(python3 - <<'PY' "$PR_CHECK_AUDIT_FIXTURE"
import json
import sys
from pathlib import Path

fixture = json.loads(Path(sys.argv[1]).read_text(encoding='utf-8'))
ctx = fixture.get('required_branch_protection_context', '')
prs = fixture.get('merged_prs', [])
with_ctx = sum(1 for p in prs if p.get('context_present'))
print(ctx)
print(len(prs))
print(with_ctx)
for p in prs:
    status = "present" if p.get("context_present") else "missing"
    print(f"- PR #{p.get('number')}: context {status}")
PY
  )

  protection_context="${data[0]}"
  checked="${data[1]}"
  with_context="${data[2]}"
  for line in "${data[@]:3}"; do
    details+="${line}"$'\n'
  done
else
  protection_context="$(gh api "repos/${repo}/branches/main/protection" --jq '.required_status_checks.checks[0].context // ""')"
  mapfile -t prs < <(gh pr list --repo "$repo" --state merged --base main --limit "$sample_size" --json number --jq '.[].number')

  for pr in "${prs[@]}"; do
    sha="$(gh pr view "$pr" --repo "$repo" --json mergeCommit --jq '.mergeCommit.oid // empty')"
    [[ -n "$sha" ]] || continue
    checked=$((checked + 1))
    count="$(gh api "repos/${repo}/commits/${sha}/check-runs" --jq ".check_runs | map(select(.name == \"${required_context}\")) | length")"
    if [[ "$count" -gt 0 ]]; then
      with_context=$((with_context + 1))
      details+=$'- PR #'"${pr}"$': context present\n'
    else
      details+=$'- PR #'"${pr}"$': context missing\n'
    fi
  done
fi

status="pass"
reason="all checked PRs emitted required context"
if [[ "$checked" -lt "$min_sample" ]]; then
  status="warn"
  reason="insufficient sample size (${checked}/${min_sample})"
elif [[ "$with_context" -lt "$checked" ]]; then
  status="warn"
  reason="required context missing on one or more checked PRs"
fi

mkdir -p "$(dirname "$output")"
cat > "$output" <<EOF_SUM
# PR Check Emission Audit

- generated_at_utc: $(date -u +%Y-%m-%dT%H:%M:%SZ)
- repository: ${repo}
- required_branch_protection_context: ${protection_context}
- expected_context: ${required_context}
- strict_mode: ${strict_mode}
- sample_size_target: ${sample_size}
- minimum_sample_required: ${min_sample}
- merged_prs_checked: ${checked}
- prs_with_expected_context: ${with_context}
- status: ${status}
- reason: ${reason}

## PR Sample Audit
${details}
EOF_SUM

if [[ "$strict_mode" == "true" && "$status" != "pass" ]]; then
  echo "PR check emission audit failed in strict mode: ${reason}" >&2
  exit 1
fi

echo "PR check emission audit generated: $output"
