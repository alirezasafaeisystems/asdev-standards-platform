#!/usr/bin/env bash
set -euo pipefail

report_csv="${1:-sync/divergence-report.combined.csv}"
limit="${2:-10}"

if [[ ! -f "$report_csv" ]]; then
  echo "report file not found: $report_csv" >&2
  exit 1
fi

if ! [[ "$limit" =~ ^[0-9]+$ ]] || [[ "$limit" -le 0 ]]; then
  echo "limit must be a positive integer: $limit" >&2
  exit 1
fi

mapfile -t repos < <(
  awk -F, '
    NR==1 {
      for (i = 1; i <= NF; i++) {
        if ($i == "repo") repo_idx = i
        if ($i == "status") status_idx = i
      }
      next
    }
    repo_idx && status_idx && $status_idx == "clone_failed" {print $repo_idx}
  ' "$report_csv" | sort -u
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
