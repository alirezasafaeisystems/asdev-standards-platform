#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DATE_TAG="$(date -u +%Y-%m-%d)"
TITLE="Weekly Governance Digest ${DATE_TAG}"
DIGEST_OWNER="${DIGEST_OWNER:-@alirezasafaeiiidev}"
DIGEST_REVIEW_SLA="${DIGEST_REVIEW_SLA:-24h from issue update}"

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "Missing required command: $1" >&2
    exit 1
  }
}

count_status() {
  local file="$1"
  local status="$2"
  if [[ ! -f "$file" ]]; then
    echo 0
    return
  fi
  awk -F, -v s="$status" 'NR>1 && $7==s {c++} END{print c+0}' "$file"
}

require_cmd gh
require_cmd yq

cd "$ROOT_DIR"

if [[ "${SKIP_REPORT_REGEN:-false}" != "true" ]]; then
  bash scripts/rotate-report-snapshots.sh
  bash platform/scripts/divergence-report.sh sync/targets.yaml platform/repo-templates/templates.yaml platform/repo-templates sync/divergence-report.csv
  bash platform/scripts/divergence-report-combined.sh \
    platform/repo-templates/templates.yaml \
    platform/repo-templates \
    sync/divergence-report.combined.csv \
    "sync/targets*.yaml" \
    sync/divergence-report.combined.errors.csv
  bash scripts/generate-dashboard.sh docs/platform-adoption-dashboard.md
fi

prev_file="sync/divergence-report.previous.csv"
curr_file="sync/divergence-report.csv"

aligned_prev="$(count_status "$prev_file" aligned)"
aligned_now="$(count_status "$curr_file" aligned)"
diverged_prev="$(count_status "$prev_file" diverged)"
diverged_now="$(count_status "$curr_file" diverged)"
missing_prev="$(count_status "$prev_file" missing)"
missing_now="$(count_status "$curr_file" missing)"
opted_prev="$(count_status "$prev_file" opted_out)"
opted_now="$(count_status "$curr_file" opted_out)"

body_file="$(mktemp)"
actions_file="$(mktemp)"

gh issue list \
  --repo alirezasafaeiiidev/asdev_platform \
  --state open \
  --limit 100 \
  --json number,title,url \
  --jq '.[] | select(.title | test("^(ops|automation|performance|observability|test|reliability):")) | "- [ ] [#\(.number)](\(.url)) \(.title)"' > "$actions_file"

if [[ ! -s "$actions_file" ]]; then
  echo "- [ ] none" > "$actions_file"
fi

cat > "$body_file" <<BODY
## Weekly Governance Digest

- Date: ${DATE_TAG}
- Owner: ${DIGEST_OWNER}
- Review SLA: ${DIGEST_REVIEW_SLA}
- Dashboard: \
  docs/platform-adoption-dashboard.md
- Combined report: \
  sync/divergence-report.combined.csv

### Level 0 Delta (vs previous snapshot)

- aligned: ${aligned_prev} -> ${aligned_now}
- diverged: ${diverged_prev} -> ${diverged_now}
- missing: ${missing_prev} -> ${missing_now}
- opted_out: ${opted_prev} -> ${opted_now}

### Actions

- Review divergence rows with non-aligned status.
- Confirm rollout readiness for next language wave.

### Ownership Checklist

- [ ] Owner reviewed weekly deltas and status changes.
- [ ] Owner triaged clone_failed and non-aligned hotspots.
- [ ] Owner linked/update follow-up issues for this week.

### Linked Operational Issues

$(cat "$actions_file")
BODY

existing="$(gh issue list --repo alirezasafaeiiidev/asdev_platform --state open --search "${TITLE} in:title" --json number --jq '.[0].number // empty')"
if [[ -n "$existing" ]]; then
  gh issue comment "$existing" --repo alirezasafaeiiidev/asdev_platform --body-file "$body_file" >/dev/null
  echo "Updated existing weekly digest issue #${existing}"
else
  gh issue create --repo alirezasafaeiiidev/asdev_platform --title "$TITLE" --body-file "$body_file" --label standards >/dev/null
  echo "Created weekly digest issue: ${TITLE}"
fi

current_issue_number="$(gh issue list --repo alirezasafaeiiidev/asdev_platform --state open --search "${TITLE} in:title" --json number --jq '.[0].number // empty')"
current_issue_url="$(gh issue list --repo alirezasafaeiiidev/asdev_platform --state open --search "${TITLE} in:title" --json url --jq '.[0].url // empty')"
stale_evaluated_count="0"
stale_closed_count="0"
stale_dry_run_candidates="0"
stale_dry_run_enabled="${DIGEST_STALE_DRY_RUN:-false}"
if [[ -n "$current_issue_number" && -n "$current_issue_url" ]]; then
  stale_summary_file="$(mktemp)"
  DIGEST_STALE_SUMMARY_FILE="$stale_summary_file" \
  bash scripts/close-stale-weekly-digests.sh \
    "alirezasafaeiiidev/asdev_platform" \
    "$current_issue_number" \
    "$current_issue_url" \
    "Weekly Governance Digest"
  if [[ -f "$stale_summary_file" ]]; then
    echo "Weekly digest stale lifecycle summary:"
    cat "$stale_summary_file"
    stale_evaluated_count="$(awk -F= '/^evaluated_count=/{print $2}' "$stale_summary_file" | tail -n 1)"
    stale_closed_count="$(awk -F= '/^closed_count=/{print $2}' "$stale_summary_file" | tail -n 1)"
    stale_dry_run_candidates="$(awk -F= '/^dry_run_candidates=/{print $2}' "$stale_summary_file" | tail -n 1)"
    stale_dry_run_enabled="$(awk -F= '/^dry_run_enabled=/{print $2}' "$stale_summary_file" | tail -n 1)"
    rm -f "$stale_summary_file"
  fi
fi

if [[ -n "${GITHUB_STEP_SUMMARY:-}" ]]; then
  {
    echo "## Weekly Digest Stale Lifecycle"
    echo ""
    echo "- stale_evaluated_count: ${stale_evaluated_count}"
    echo "- stale_closed_count: ${stale_closed_count}"
    echo "- stale_dry_run_candidates: ${stale_dry_run_candidates}"
    echo "- stale_dry_run_enabled: ${stale_dry_run_enabled}"
  } >> "$GITHUB_STEP_SUMMARY"
fi

rm -f "$body_file" "$actions_file"
