#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
WORKSPACE_ROOT_DEFAULT="$(cd "${REPO_ROOT}/.." && pwd)"
ZIP_PATH_DEFAULT="/home/dev/Downloads/ASDEV_Strategic_Execution_Blueprint_v1.0.zip"

usage() {
  cat <<USAGE
Usage: $(basename "$0") [options]

Options:
  --workspace-root PATH   Workspace root containing asdev-* repositories.
                          Default: ${WORKSPACE_ROOT_DEFAULT}
  --zip PATH              Path to ASDEV strategic blueprint zip.
                          Default: ${ZIP_PATH_DEFAULT}
  --targets LIST          Comma-separated repository names (example: asdev-portfolio,asdev-persiantoolbox).
                          Default: all asdev-* directories with .git under workspace root.
  --dry-run               Print targets and detected blueprint version, then exit.
  -h, --help              Show this help.
USAGE
}

WORKSPACE_ROOT="${WORKSPACE_ROOT_DEFAULT}"
ZIP_PATH="${ZIP_PATH_DEFAULT}"
TARGETS_CSV=""
DRY_RUN="false"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --workspace-root)
      WORKSPACE_ROOT="$2"
      shift 2
      ;;
    --zip)
      ZIP_PATH="$2"
      shift 2
      ;;
    --targets)
      TARGETS_CSV="$2"
      shift 2
      ;;
    --dry-run)
      DRY_RUN="true"
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

if [[ ! -f "$ZIP_PATH" ]]; then
  echo "Blueprint zip not found: $ZIP_PATH" >&2
  exit 1
fi

if [[ ! -d "$WORKSPACE_ROOT" ]]; then
  echo "Workspace root not found: $WORKSPACE_ROOT" >&2
  exit 1
fi

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

unzip -q "$ZIP_PATH" -d "$TMP_DIR"
BLUEPRINT_BASE="$(find "$TMP_DIR" -mindepth 1 -maxdepth 1 -type d | head -n 1)"

if [[ -z "$BLUEPRINT_BASE" || ! -d "$BLUEPRINT_BASE" ]]; then
  echo "Unable to locate extracted blueprint root in zip." >&2
  exit 1
fi

VERSION="$(tr -d '[:space:]' < "$BLUEPRINT_BASE/VERSION" 2>/dev/null || true)"
if [[ -z "$VERSION" ]]; then
  VERSION="0.0.0"
fi

select_targets() {
  local -a repos=()
  if [[ -n "$TARGETS_CSV" ]]; then
    IFS=',' read -r -a repos <<< "$TARGETS_CSV"
    printf '%s\n' "${repos[@]}"
  else
    find "$WORKSPACE_ROOT" -mindepth 1 -maxdepth 1 -type d -name 'asdev-*' -printf '%f\n' | sort
  fi
}

ensure_csv_header() {
  local file="$1"
  local header="$2"

  if [[ ! -f "$file" ]]; then
    printf '%s\n' "$header" > "$file"
    return
  fi

  local first_line
  first_line="$(head -n 1 "$file" || true)"
  if [[ "$first_line" != "$header" ]]; then
    local tmp_file
    tmp_file="${file}.tmp"
    {
      printf '%s\n' "$header"
      cat "$file"
    } > "$tmp_file"
    mv "$tmp_file" "$file"
  fi
}

repo_has_file() {
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

mark_checkbox() {
  if [[ "$1" == "true" ]]; then
    printf 'x'
  else
    printf ' '
  fi
}

mapfile -t TARGETS < <(select_targets)
if [[ ${#TARGETS[@]} -eq 0 ]]; then
  echo "No target repositories resolved." >&2
  exit 1
fi

if [[ "$DRY_RUN" == "true" ]]; then
  echo "Blueprint version: ${VERSION}"
  echo "Targets:"
  printf -- '- %s\n' "${TARGETS[@]}"
  exit 0
fi

DATE_UTC="$(date -u +%F)"
DATE_LOCAL="$(date +%F)"
REPORT_DIR="$REPO_ROOT/docs/reports"
REPORT_FILE="$REPORT_DIR/STRATEGIC_EXECUTION_ROLLOUT_${DATE_LOCAL}.md"
mkdir -p "$REPORT_DIR"

{
  echo "# Strategic Execution Rollout (${DATE_LOCAL})"
  echo
  echo "- Blueprint version: ${VERSION}"
  echo "- Blueprint source zip: ${ZIP_PATH}"
  echo "- Workspace root: ${WORKSPACE_ROOT}"
  echo "- Executed (UTC): $(date -u +'%Y-%m-%d %H:%M:%S UTC')"
  echo
  echo "## Targets"
  echo
  echo "| Repo | Blueprint | Runtime | Status |"
  echo "|---|---|---|---|"
} > "$REPORT_FILE"

for repo_name in "${TARGETS[@]}"; do
  repo_path="$WORKSPACE_ROOT/$repo_name"

  if [[ ! -d "$repo_path/.git" ]]; then
    {
      echo "| ${repo_name} | n/a | n/a | skipped (missing .git) |"
    } >> "$REPORT_FILE"
    continue
  fi

  execution_root="$repo_path/docs/strategic-execution"
  blueprint_version_root="$execution_root/blueprint-v${VERSION}"
  runtime_root="$execution_root/runtime"

  mkdir -p "$execution_root"
  rsync -a --delete --exclude '.DS_Store' "$BLUEPRINT_BASE/" "$blueprint_version_root/"
  printf '%s\n' "$VERSION" > "$execution_root/CURRENT_VERSION"

  mkdir -p \
    "$runtime_root/Weekly_Reviews" \
    "$runtime_root/GoLive_Evidence" \
    "$runtime_root/Brand_Evidence" \
    "$runtime_root/Sales_Evidence"

  ensure_csv_header "$runtime_root/Outreach_Log.csv" "date,channel,target,status,next_step,evidence"
  ensure_csv_header "$runtime_root/Content_Log.csv" "date,content_type,title,url,status,evidence"
  ensure_csv_header "$runtime_root/Lead_Log.csv" "date,lead_name,company,source,status,owner,next_step"
  ensure_csv_header "$runtime_root/Project_Log.csv" "date,project,stage,status,evidence,owner,notes"

  if ! grep -q "blueprint-rollout-v${VERSION}" "$runtime_root/Project_Log.csv"; then
    printf '%s,%s,%s,%s,%s,%s,%s\n' \
      "$DATE_LOCAL" \
      "$repo_name" \
      "A/B/S baseline" \
      "initialized" \
      "docs/strategic-execution/STAGE_STATUS.md" \
      "automation" \
      "blueprint-rollout-v${VERSION}" >> "$runtime_root/Project_Log.csv"
  fi

  weekly_review_file="$runtime_root/Weekly_Reviews/${DATE_LOCAL}_weekly_review.md"
  if [[ ! -f "$weekly_review_file" ]]; then
    cat > "$weekly_review_file" <<WEEKLY
# Weekly Review - ${repo_name} (${DATE_LOCAL})

## 1) Summary
- Key progress:
- Key risks:

## 2) Metrics
- Leads:
- Qualified leads:
- Proposals:
- Contracts:
- Deliveries:

## 3) Stage Progress
- Stage A (Go-Live):
- Stage B (Brand + Proof):
- Stage S (Sales + Contracts):
- Stage L (Long-term):

## 4) Decisions
- New decisions:

## 5) Next Focus
1.
2.
3.
WEEKLY
  fi

  has_sitemap="false"
  has_robots="false"
  has_services="false"
  has_case_studies="false"
  has_templates="false"
  has_change_request="false"

  if repo_has_file "$repo_path" \( -iname 'sitemap.xml' -o -iname 'sitemap.ts' -o -iname '*sitemap*.js' \); then
    has_sitemap="true"
  fi
  if repo_has_file "$repo_path" \( -iname 'robots.txt' -o -iname 'robots.ts' -o -iname '*robots*.js' \); then
    has_robots="true"
  fi
  if repo_has_file "$repo_path" \( -iname '*services*' -o -path '*/services/*' \); then
    has_services="true"
  fi
  if repo_has_file "$repo_path" \( -iname '*case*study*' -o -iname '*case-studies*' -o -path '*/case-studies/*' \); then
    has_case_studies="true"
  fi
  if repo_has_file "$repo_path" \( -path '*/docs/templates/*' -o -iname '*proposal*.md' -o -iname '*sow*.md' \); then
    has_templates="true"
  fi
  if repo_has_file "$repo_path" \( -iname '*change*request*.md' -o -iname '*change_request*.md' \); then
    has_change_request="true"
  fi

  status_file="$execution_root/STAGE_STATUS.md"
  cat > "$status_file" <<STATUS
# Stage Status - ${repo_name}

Generated: ${DATE_UTC} (UTC)
Blueprint version: ${VERSION}

## Stage A - Go-Live
- [$(mark_checkbox "$has_robots")] robots configuration detected
- [$(mark_checkbox "$has_sitemap")] sitemap configuration detected
- [ ] DNS/TLS/HSTS evidence attached in runtime evidence folder
- [ ] Lead routing/notification evidence attached

## Stage B - Brand + Proof
- [$(mark_checkbox "$has_services")] services page/routes detected
- [$(mark_checkbox "$has_case_studies")] case-study page/routes detected
- [ ] 3 pillar content links logged in runtime/content log
- [ ] PersianToolbox proof asset linked

## Stage S - Sales + Contracts
- [$(mark_checkbox "$has_templates")] proposal/SOW templates detected
- [$(mark_checkbox "$has_change_request")] change request template/process detected
- [ ] Signed sales evidence attached in runtime/sales evidence
- [ ] Handover pack checklist completed

## Stage L - Long-term
- [ ] 3 successful project reports published
- [ ] Proof-based move toward larger contracts documented
- [ ] Product line progress documented without delivery drift
STATUS

  board_file="$execution_root/EXECUTION_BOARD.md"
  cat > "$board_file" <<BOARD
# Execution Board - ${repo_name}

## Workflow
Backlog -> Ready -> In Progress -> Evidence Ready -> Done

## Backlog
- [ ] Stage A: Complete Go-Live evidence pack
- [ ] Stage B: Services + case studies + pillar content
- [ ] Stage S: Discovery/Proposal/SOW/CR process fully operational
- [ ] Stage L: Publish complete project reports and proof assets

## Ready
- [ ] Attach existing evidence to runtime folders
- [ ] Update Outreach/Lead/Project logs for current cycle

## In Progress
- [ ] Fill this section with active tasks only

## Evidence Ready
- [ ] Move tasks here after artifact link is attached

## Done
- [ ] Move tasks here only after acceptance criteria pass
BOARD

  readme_file="$execution_root/README.md"
  cat > "$readme_file" <<README
# Strategic Execution - ${repo_name}

This folder operationalizes ASDEV Strategic Execution Blueprint v${VERSION} for this repository.

## Structure
- blueprint-v${VERSION}/: versioned blueprint snapshot
- CURRENT_VERSION: active blueprint version
- EXECUTION_BOARD.md: stage-gated board template
- STAGE_STATUS.md: detected + manual stage status
- runtime/: weekly reviews, evidence folders, and execution logs

## Runtime policy
- No task is Done without evidence.
- Every out-of-scope item must go through change request process.
- Weekly review is required and stored in runtime/Weekly_Reviews/.
README

  blueprint_file_count="$(find "$blueprint_version_root" -type f | wc -l | tr -d ' ')"
  runtime_file_count="$(find "$runtime_root" -type f | wc -l | tr -d ' ')"

  {
    echo "| ${repo_name} | ${blueprint_file_count} files | ${runtime_file_count} files | applied |"
  } >> "$REPORT_FILE"
done

{
  echo
  echo "## Notes"
  echo
  echo "- Rollout mode: non-destructive; scoped to docs/strategic-execution/ in each target repository."
  echo "- Existing business/application code was not modified by this rollout."
} >> "$REPORT_FILE"

echo "Rollout completed. Report: $REPORT_FILE"
