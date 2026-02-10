#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 3 ]]; then
  echo "Usage: $0 <repo> <current_issue_number> <current_issue_url> [title_prefix]" >&2
  exit 2
fi

REPO="$1"
CURRENT_ISSUE="$2"
CURRENT_URL="$3"
TITLE_PREFIX="${4:-Weekly Governance Digest}"
STALE_DAYS="${DIGEST_STALE_DAYS:-8}"
STALE_DRY_RUN="${DIGEST_STALE_DRY_RUN:-false}"
SUMMARY_FILE="${DIGEST_STALE_SUMMARY_FILE:-}"

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "Missing required command: $1" >&2
    exit 1
  }
}

to_epoch() {
  local ts="$1"
  date -u -d "$ts" +%s 2>/dev/null || date -u -jf "%Y-%m-%dT%H:%M:%SZ" "$ts" +%s
}

require_cmd gh
require_cmd date
require_cmd awk
require_cmd grep

now_epoch="${DIGEST_STALE_NOW_EPOCH:-$(date -u +%s)}"
closed_count=0
dry_run_candidates=0
evaluated_count=0

mapfile -t digest_rows < <(
  gh issue list \
    --repo "$REPO" \
    --state open \
    --limit 100 \
    --search "${TITLE_PREFIX} in:title" \
    --json number,title,updatedAt,url \
    --jq '.[] | [.number, .updatedAt, .url] | @tsv'
)

for row in "${digest_rows[@]}"; do
  issue_number="$(awk -F$'\t' '{print $1}' <<< "$row")"
  updated_at="$(awk -F$'\t' '{print $2}' <<< "$row")"
  issue_url="$(awk -F$'\t' '{print $3}' <<< "$row")"

  if [[ -z "$issue_number" || "$issue_number" == "$CURRENT_ISSUE" ]]; then
    continue
  fi
  evaluated_count=$((evaluated_count + 1))

  updated_epoch="$(to_epoch "$updated_at")"
  age_days="$(( (now_epoch - updated_epoch) / 86400 ))"

  if [[ "$age_days" -lt "$STALE_DAYS" ]]; then
    continue
  fi

  if [[ "$STALE_DRY_RUN" == "true" ]]; then
    dry_run_candidates=$((dry_run_candidates + 1))
    echo "DRY_RUN stale digest candidate #${issue_number} (${issue_url}) age_days=${age_days} threshold=${STALE_DAYS}"
    continue
  fi

  gh issue comment "$issue_number" --repo "$REPO" --body "Auto-closing stale weekly digest (>${STALE_DAYS} days without update). Latest active digest: ${CURRENT_URL}."
  gh issue close "$issue_number" --repo "$REPO" --reason completed
  closed_count=$((closed_count + 1))
  echo "Closed stale weekly digest #${issue_number} (${issue_url})"
done

if [[ -n "$SUMMARY_FILE" ]]; then
  {
    echo "evaluated_count=${evaluated_count}"
    echo "closed_count=${closed_count}"
    echo "dry_run_candidates=${dry_run_candidates}"
    echo "dry_run_enabled=${STALE_DRY_RUN}"
  } > "$SUMMARY_FILE"
fi
