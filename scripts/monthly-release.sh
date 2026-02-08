#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DATE_TAG="$(date -u +%Y-%m-%d)"
BRANCH_NAME="chore/asdev-monthly-release-${DATE_TAG}"

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "Missing required command: $1" >&2
    exit 1
  }
}

bump_patch() {
  local version="$1"
  local major minor patch
  IFS='.' read -r major minor patch <<< "$version"
  echo "${major}.${minor}.$((patch + 1))"
}

status_count() {
  local csv_file="$1"
  local status="$2"
  if [[ ! -f "$csv_file" ]]; then
    echo 0
    return
  fi
  awk -F, -v s="$status" 'NR>1 && $7==s {c++} END{print c+0}' "$csv_file"
}

require_cmd git
require_cmd gh
require_cmd yq

cd "$ROOT_DIR"

git fetch origin main
if git show-ref --verify --quiet "refs/heads/${BRANCH_NAME}"; then
  git checkout "$BRANCH_NAME"
else
  git checkout -b "$BRANCH_NAME" origin/main
fi

# 1) Save previous divergence snapshot for delta calculation
previous_csv="$(mktemp)"
if [[ -f sync/divergence-report.csv ]]; then
  cp sync/divergence-report.csv "$previous_csv"
  cp sync/divergence-report.csv sync/divergence-report.previous.csv
else
  : > "$previous_csv"
  : > sync/divergence-report.previous.csv
fi

# 2) Generate current divergence snapshot
bash platform/scripts/divergence-report.sh sync/targets.yaml platform/repo-templates/templates.yaml platform/repo-templates sync/divergence-report.csv

# 3) Patch bump all template versions in manifest
count="$(yq -r '.templates | length' platform/repo-templates/templates.yaml)"
for ((i=0; i<count; i++)); do
  current="$(yq -r ".templates[$i].version" platform/repo-templates/templates.yaml)"
  next="$(bump_patch "$current")"
  yq -i ".templates[$i].version = \"$next\"" platform/repo-templates/templates.yaml
done

# 4) Divergence delta stats
aligned_prev="$(status_count "$previous_csv" aligned)"
diverged_prev="$(status_count "$previous_csv" diverged)"
missing_prev="$(status_count "$previous_csv" missing)"
opted_prev="$(status_count "$previous_csv" opted_out)"

aligned_now="$(status_count sync/divergence-report.csv aligned)"
diverged_now="$(status_count sync/divergence-report.csv diverged)"
missing_now="$(status_count sync/divergence-report.csv missing)"
opted_now="$(status_count sync/divergence-report.csv opted_out)"

aligned_delta=$((aligned_now - aligned_prev))
diverged_delta=$((diverged_now - diverged_prev))
missing_delta=$((missing_now - missing_prev))
opted_delta=$((opted_now - opted_prev))

# 5) Governance release note
update_file="governance/updates-${DATE_TAG}-monthly.md"
cat > "$update_file" <<STUB
# Monthly Governance Update (${DATE_TAG})

## Summary

- Monthly template version bump executed.
- Divergence snapshot regenerated.

## Divergence Delta (vs previous snapshot)

- aligned: ${aligned_prev} -> ${aligned_now} (delta: ${aligned_delta})
- diverged: ${diverged_prev} -> ${diverged_now} (delta: ${diverged_delta})
- missing: ${missing_prev} -> ${missing_now} (delta: ${missing_delta})
- opted_out: ${opted_prev} -> ${opted_now} (delta: ${opted_delta})

## Action Items

- Review pilot adoption and pending divergence entries.
- Confirm next wave rollout status.
STUB

# 6) Commit and PR
if git diff --quiet; then
  echo "No changes to release."
  rm -f "$previous_csv"
  exit 0
fi

git add platform/repo-templates/templates.yaml sync/divergence-report.previous.csv "$update_file"
git add -f sync/divergence-report.csv
git commit -m "chore: monthly ASDEV release ${DATE_TAG}"
git push -u origin "$BRANCH_NAME"

gh pr create \
  --repo alirezasafaeiiidev/asdev_platform \
  --head "$BRANCH_NAME" \
  --base main \
  --title "chore: monthly ASDEV release ${DATE_TAG}" \
  --body "Monthly release: template version bump, divergence snapshot, and governance update with divergence delta." \
  --label standards

rm -f "$previous_csv"
