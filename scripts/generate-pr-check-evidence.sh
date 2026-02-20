#!/usr/bin/env bash
set -euo pipefail

repo="${1:-alirezasafaeisystems/asdev-standards-platform}"
output="${2:-docs/reports/PR_CHECK_EMISSION_EVIDENCE.md}"
required_context="PR Validation / quality-gate"
sample_size="${PR_CHECK_EVIDENCE_SAMPLE_SIZE:-5}"

protection_context="$(gh api "repos/${repo}/branches/main/protection" --jq '.required_status_checks.checks[0].context // ""')"
workflow_trigger_summary="$(awk '
  /^on:/ {in_on=1}
  in_on && NF==0 {in_on=0}
  in_on {print}
' .github/workflows/pr-validation.yml | sed 's/^/  /')"

mapfile -t prs < <(gh pr list --repo "$repo" --state merged --base main --limit "$sample_size" --json number --jq '.[].number')

checked=0
with_context=0
details=""
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

mkdir -p "$(dirname "$output")"
cat > "$output" <<EOF_SUM
# PR Check Emission Evidence

- generated_at_utc: $(date -u +%Y-%m-%dT%H:%M:%SZ)
- repository: ${repo}
- required_branch_protection_context: ${protection_context}
- expected_context: ${required_context}
- merged_prs_checked: ${checked}
- prs_with_expected_context: ${with_context}

## Workflow Trigger Snapshot
\`\`\`yaml
${workflow_trigger_summary}
\`\`\`

## PR Sample Evidence
${details}
EOF_SUM

echo "PR check evidence generated: $output"
