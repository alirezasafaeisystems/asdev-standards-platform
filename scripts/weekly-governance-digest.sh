#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DATE_TAG="$(date -u +%Y-%m-%d)"
TITLE="Weekly Governance Digest ${DATE_TAG}"

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

bash platform/scripts/divergence-report.sh sync/targets.yaml platform/repo-templates/templates.yaml platform/repo-templates sync/divergence-report.csv
bash platform/scripts/divergence-report-combined.sh platform/repo-templates/templates.yaml platform/repo-templates sync/divergence-report.combined.csv
bash scripts/generate-dashboard.sh docs/platform-adoption-dashboard.md

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
cat > "$body_file" <<BODY
## Weekly Governance Digest

- Date: ${DATE_TAG}
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
BODY

existing="$(gh issue list --repo alirezasafaeiiidev/asdev_platform --state open --search "${TITLE} in:title" --json number --jq '.[0].number // empty')"
if [[ -n "$existing" ]]; then
  gh issue comment "$existing" --repo alirezasafaeiiidev/asdev_platform --body-file "$body_file" >/dev/null
  echo "Updated existing weekly digest issue #${existing}"
else
  gh issue create --repo alirezasafaeiiidev/asdev_platform --title "$TITLE" --body-file "$body_file" --label standards >/dev/null
  echo "Created weekly digest issue: ${TITLE}"
fi

rm -f "$body_file"
