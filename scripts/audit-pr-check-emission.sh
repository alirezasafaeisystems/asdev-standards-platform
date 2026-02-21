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
required_context_short="${required_context##*/ }"

context_matches() {
  local ctx="${1:-}"
  [[ "$ctx" == "$required_context" || "$ctx" == "$required_context_short" ]]
}

has_required_context_for_ref() {
  local ref="${1:-}"
  [[ -n "$ref" ]] || return 1

  mapfile -t check_names < <(gh api "repos/${repo}/commits/${ref}/check-runs" --jq '.check_runs[].name' 2>/dev/null || true)
  for name in "${check_names[@]}"; do
    if context_matches "$name"; then
      return 0
    fi
  done

  mapfile -t status_contexts < <(gh api "repos/${repo}/commits/${ref}/status" --jq '.statuses[].context' 2>/dev/null || true)
  for ctx in "${status_contexts[@]}"; do
    if context_matches "$ctx"; then
      return 0
    fi
  done

  return 1
}

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
    pr_data="$(gh pr view "$pr" --repo "$repo" --json headRefOid,mergeCommit --jq '[.headRefOid, (.mergeCommit.oid // "")] | @tsv')"
    head_sha="$(printf '%s' "$pr_data" | cut -f1)"
    merge_sha="$(printf '%s' "$pr_data" | cut -f2)"
    mapfile -t rollup_contexts < <(gh pr view "$pr" --repo "$repo" --json statusCheckRollup --jq '.statusCheckRollup[].context // empty')
    [[ -n "$head_sha" || -n "$merge_sha" ]] || continue
    checked=$((checked + 1))

    context_found="false"
    context_source="none"

    for ctx in "${rollup_contexts[@]}"; do
      if context_matches "$ctx"; then
        context_found="true"
        context_source="pr-rollup"
        break
      fi
    done

    if [[ "$context_found" == "false" ]] && has_required_context_for_ref "$head_sha"; then
      context_found="true"
      context_source="head-sha"
    fi

    if [[ "$context_found" == "false" ]] && has_required_context_for_ref "$merge_sha"; then
      context_found="true"
      context_source="merge-sha"
    fi

    if [[ "$context_found" == "true" ]]; then
      with_context=$((with_context + 1))
      details+=$'- PR #'"${pr}"$': context present ('"${context_source}"$')\n'
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
