#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"
WORKSPACE_ROOT="$(cd "${REPO_ROOT}/.." && pwd)"
ZIP_PATH="/home/dev/Downloads/ASDEV_Strategic_Execution_Blueprint_v1.0.zip"
APPLY_SCRIPT="${SCRIPT_DIR}/apply-strategic-execution-blueprint.sh"
TODAY="$(date +%F)"
NOW_UTC="$(date -u +'%Y-%m-%d %H:%M:%S UTC')"
REPORT_FILE="${REPO_ROOT}/docs/reports/STRATEGIC_EXECUTION_AUTOPILOT_${TODAY}.md"

if [[ ! -x "$APPLY_SCRIPT" ]]; then
  echo "Missing apply script: $APPLY_SCRIPT" >&2
  exit 1
fi

"$APPLY_SCRIPT" --workspace-root "$WORKSPACE_ROOT" --zip "$ZIP_PATH" >/dev/null

append_csv_row_if_missing() {
  local file="$1"
  local key="$2"
  local row="$3"
  if [[ ! -f "$file" ]]; then
    return
  fi
  if ! grep -q "$key" "$file"; then
    printf '%s\n' "$row" >> "$file"
  fi
}

checkbox() {
  if [[ "$1" == "true" ]]; then
    printf 'x'
  else
    printf ' '
  fi
}

has_path() {
  local repo="$1"
  shift
  find "$repo" \
    -path '*/.git' -prune -o \
    -path '*/node_modules' -prune -o \
    -path '*/.next' -prune -o \
    -path '*/dist' -prune -o \
    -path '*/build' -prune -o \
    -type f "$@" -print -quit | grep -q .
}

count_path() {
  local repo="$1"
  shift
  find "$repo" \
    -path '*/.git' -prune -o \
    -path '*/node_modules' -prune -o \
    -path '*/.next' -prune -o \
    -path '*/dist' -prune -o \
    -path '*/build' -prune -o \
    -type f "$@" -print | wc -l | tr -d ' '
}

{
  echo "# Strategic Execution Autopilot (${TODAY})"
  echo
  echo "- Executed (UTC): ${NOW_UTC}"
  echo "- Workspace: ${WORKSPACE_ROOT}"
  echo
  echo "| Repo | Stage A | Stage B | Stage S | Notes |"
  echo "|---|---:|---:|---:|---|"
} > "$REPORT_FILE"

for repo in "$WORKSPACE_ROOT"/asdev-*; do
  [[ -d "$repo/.git" ]] || continue
  name="$(basename "$repo")"
  root="$repo/docs/strategic-execution"
  runtime="$root/runtime"
  [[ -d "$runtime" ]] || continue

  golive_dir="$runtime/GoLive_Evidence"
  brand_dir="$runtime/Brand_Evidence"
  sales_dir="$runtime/Sales_Evidence"
  mkdir -p "$golive_dir" "$brand_dir" "$sales_dir"

  has_robots="false"
  has_sitemap="false"
  has_services="false"
  has_case_studies="false"
  has_proposal="false"
  has_sow="false"
  has_cr="false"

  if has_path "$repo" \( -iname 'robots.txt' -o -iname 'robots.ts' -o -iname '*robots*.js' \); then has_robots="true"; fi
  if has_path "$repo" \( -iname 'sitemap.xml' -o -iname 'sitemap.ts' -o -iname '*sitemap*.js' \); then has_sitemap="true"; fi
  if has_path "$repo" \( -path '*/services/*' -o -iname '*services*' \); then has_services="true"; fi
  if has_path "$repo" \( -path '*/case-studies/*' -o -iname '*case*study*' -o -iname '*case-studies*' \); then has_case_studies="true"; fi
  if has_path "$repo" \( -iname '*proposal*.md' \); then has_proposal="true"; fi
  if has_path "$repo" \( -iname '*sow*.md' -o -iname '*scope*of*work*.md' \); then has_sow="true"; fi
  if has_path "$repo" \( -iname '*change*request*.md' -o -iname '*change_request*.md' \); then has_cr="true"; fi

  services_count="$(count_path "$repo" \( -path '*/services/*' -o -iname '*services*' \))"
  case_count="$(count_path "$repo" \( -path '*/case-studies/*' -o -iname '*case*study*' -o -iname '*case-studies*' \))"
  robots_count="$(count_path "$repo" \( -iname 'robots.txt' -o -iname 'robots.ts' -o -iname '*robots*.js' \))"
  sitemap_count="$(count_path "$repo" \( -iname 'sitemap.xml' -o -iname 'sitemap.ts' -o -iname '*sitemap*.js' \))"

  golive_file="$golive_dir/${TODAY}_auto_golive_scan.md"
  brand_file="$brand_dir/${TODAY}_auto_brand_scan.md"
  sales_file="$sales_dir/${TODAY}_auto_sales_scan.md"

  cat > "$golive_file" <<GO
# Auto GoLive Scan - ${name}

- Date: ${TODAY}
- Executed: ${NOW_UTC}
- robots detected: ${has_robots} (count=${robots_count})
- sitemap detected: ${has_sitemap} (count=${sitemap_count})
- Evidence source: local repository scan
GO

  cat > "$brand_file" <<BR
# Auto Brand Scan - ${name}

- Date: ${TODAY}
- Executed: ${NOW_UTC}
- services routes/assets detected: ${has_services} (count=${services_count})
- case-study routes/assets detected: ${has_case_studies} (count=${case_count})
- Evidence source: local repository scan
BR

  cat > "$sales_file" <<SA
# Auto Sales Scan - ${name}

- Date: ${TODAY}
- Executed: ${NOW_UTC}
- proposal template detected: ${has_proposal}
- SOW template detected: ${has_sow}
- change request process/template detected: ${has_cr}
- Evidence source: local repository scan
SA

  stage_a_score=0
  stage_b_score=0
  stage_s_score=0

  [[ "$has_robots" == "true" ]] && stage_a_score=$((stage_a_score + 1))
  [[ "$has_sitemap" == "true" ]] && stage_a_score=$((stage_a_score + 1))
  [[ -f "$golive_file" ]] && stage_a_score=$((stage_a_score + 1))

  [[ "$has_services" == "true" ]] && stage_b_score=$((stage_b_score + 1))
  [[ "$has_case_studies" == "true" ]] && stage_b_score=$((stage_b_score + 1))
  [[ -f "$brand_file" ]] && stage_b_score=$((stage_b_score + 1))

  [[ "$has_proposal" == "true" ]] && stage_s_score=$((stage_s_score + 1))
  [[ "$has_sow" == "true" ]] && stage_s_score=$((stage_s_score + 1))
  [[ "$has_cr" == "true" ]] && stage_s_score=$((stage_s_score + 1))
  [[ -f "$sales_file" ]] && stage_s_score=$((stage_s_score + 1))

  status_file="$root/STAGE_STATUS.md"
  cat > "$status_file" <<STATUS
# Stage Status - ${name}

Generated: ${TODAY} (UTC)
Autopilot run: ${NOW_UTC}

## Stage A - Go-Live
- [$(checkbox "$has_robots")] robots configuration detected
- [$(checkbox "$has_sitemap")] sitemap configuration detected
- [x] automated GoLive evidence generated (${golive_file#${repo}/})
- [ ] DNS/TLS/HSTS evidence attached
- [ ] lead routing/notification evidence attached

## Stage B - Brand + Proof
- [$(checkbox "$has_services")] services page/routes detected
- [$(checkbox "$has_case_studies")] case-study page/routes detected
- [x] automated brand evidence generated (${brand_file#${repo}/})
- [ ] 3 pillar content links logged in runtime/content log
- [ ] PersianToolbox proof asset linked

## Stage S - Sales + Contracts
- [$(checkbox "$has_proposal")] proposal template detected
- [$(checkbox "$has_sow")] SOW/scope template detected
- [$(checkbox "$has_cr")] change request template/process detected
- [x] automated sales evidence generated (${sales_file#${repo}/})
- [ ] signed sales evidence attached
- [ ] handover pack checklist completed

## Stage L - Long-term
- [ ] 3 successful project reports published
- [ ] proof-based move toward larger contracts documented
- [ ] product line progress documented without delivery drift
STATUS

  p_log="$runtime/Project_Log.csv"
  c_log="$runtime/Content_Log.csv"

  append_csv_row_if_missing "$p_log" "stage-a-auto-scan-${TODAY}" "${TODAY},${name},Stage A,auto-validated,${golive_file#${repo}/},autopilot,stage-a-auto-scan-${TODAY}"
  append_csv_row_if_missing "$p_log" "stage-b-auto-scan-${TODAY}" "${TODAY},${name},Stage B,auto-validated,${brand_file#${repo}/},autopilot,stage-b-auto-scan-${TODAY}"
  append_csv_row_if_missing "$p_log" "stage-s-auto-scan-${TODAY}" "${TODAY},${name},Stage S,auto-validated,${sales_file#${repo}/},autopilot,stage-s-auto-scan-${TODAY}"

  append_csv_row_if_missing "$c_log" "brand-scan-${TODAY}" "${TODAY},inventory_scan,services+case-study assets (${services_count}/${case_count}),internal://scan,completed,${brand_file#${repo}/}"

  board_file="$root/EXECUTION_BOARD.md"
  cat > "$board_file" <<BOARD
# Execution Board - ${name}

## Workflow
Backlog -> Ready -> In Progress -> Evidence Ready -> Done

## Backlog
- [ ] Attach DNS/TLS/HSTS evidence
- [ ] Configure/verify lead routing and notifications
- [ ] Log 3 pillar content links in runtime/Content_Log.csv
- [ ] Link PersianToolbox proof asset
- [ ] Attach signed sales evidence and handover checklist

## Ready
- [x] Automated Stage A scan completed
- [x] Automated Stage B scan completed
- [x] Automated Stage S scan completed

## In Progress
- [ ] Fill business-side evidence items

## Evidence Ready
- [x] ${golive_file#${repo}/}
- [x] ${brand_file#${repo}/}
- [x] ${sales_file#${repo}/}

## Done
- [x] Blueprint installed and runtime logs initialized
- [x] Stage status auto-generated for current repository
BOARD

  notes="A=${stage_a_score}/3, B=${stage_b_score}/3, S=${stage_s_score}/4"
  printf '| %s | %s | %s | %s | %s |\n' "$name" "$stage_a_score/3" "$stage_b_score/3" "$stage_s_score/4" "$notes" >> "$REPORT_FILE"
done

echo "Autopilot completed: $REPORT_FILE"
