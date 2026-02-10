#!/usr/bin/env bash
set -euo pipefail

report_csv="${1:-sync/divergence-report.combined.csv}"
limit="${2:-10}"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${ROOT_DIR}/scripts/csv-utils.sh"

if [[ ! -f "$report_csv" ]]; then
  echo "report file not found: $report_csv" >&2
  exit 1
fi

if ! [[ "$limit" =~ ^[0-9]+$ ]] || [[ "$limit" -le 0 ]]; then
  echo "limit must be a positive integer: $limit" >&2
  exit 1
fi

status_idx="$(csv_col_idx "$report_csv" "status")"
repo_idx="$(csv_col_idx "$report_csv" "repo")"
mapfile -t repos < <(
  if [[ -n "$status_idx" && -n "$repo_idx" ]]; then
    awk -F, -v si="$status_idx" -v ri="$repo_idx" 'NR>1 && $si=="clone_failed" {print $ri}' "$report_csv" | sort -u
  fi
)
count="${#repos[@]}"

echo "## clone_failed Repositories"
echo ""
if [[ "$count" -eq 0 ]]; then
  echo "- count: 0"
  echo "- repos: none"
  exit 0
fi

echo "- count: $count"
echo "- top_repos:"
shown=0
for repo in "${repos[@]}"; do
  echo "  - $repo"
  shown=$((shown + 1))
  if [[ "$shown" -ge "$limit" ]]; then
    break
  fi
done
