#!/usr/bin/env bash
set -euo pipefail

ROOT="/home/dev/Project_Me"
TODAY="$(date +%F)"
NOW_UTC="$(date -u +'%Y-%m-%d %H:%M:%S UTC')"
REPORT="$ROOT/asdev-standards-platform/docs/reports/PRIORITY_PIPELINE_RUN_${TODAY}.md"

repos=(
  "asdev-portfolio"
  "asdev-persiantoolbox"
  "asdev-family-rosca"
  "asdev-nexa-vpn"
  "asdev-creator-membership-ir"
  "asdev-automation-hub"
  "asdev-standards-platform"
  "asdev-codex-reviewer"
)

{
  echo "# Priority Pipeline Run (${TODAY})"
  echo
  echo "- Executed (UTC): ${NOW_UTC}"
  echo
  echo "| Repo | Command | Exit |"
  echo "|---|---|---:|"
} > "$REPORT"

run_cmd() {
  local repo="$1"
  local cmd="$2"
  set +e
  (cd "$ROOT/$repo" && bash -lc "$cmd") >/tmp/${repo//\//_}_pipeline.log 2>&1
  local ec=$?
  set -e
  printf '| %s | `%s` | %s |\n' "$repo" "$cmd" "$ec" >> "$REPORT"
}

for repo in "${repos[@]}"; do
  case "$repo" in
    asdev-portfolio)
      run_cmd "$repo" "pnpm -s test"
      run_cmd "$repo" "pnpm -s build"
      ;;
    asdev-persiantoolbox)
      run_cmd "$repo" "pnpm -s test"
      run_cmd "$repo" "pnpm -s build"
      ;;
    asdev-family-rosca)
      run_cmd "$repo" "bun test"
      run_cmd "$repo" "pnpm -s build"
      ;;
    asdev-nexa-vpn)
      run_cmd "$repo" "bun test"
      run_cmd "$repo" "pnpm -s build"
      ;;
    asdev-creator-membership-ir)
      run_cmd "$repo" "pnpm -s test"
      run_cmd "$repo" "pnpm -s build"
      ;;
    asdev-automation-hub)
      run_cmd "$repo" "pnpm -s test"
      run_cmd "$repo" "pnpm -s build"
      ;;
    asdev-standards-platform)
      run_cmd "$repo" "make ci"
      ;;
    asdev-codex-reviewer)
      run_cmd "$repo" "test -f README.md"
      ;;
  esac
done

{
  echo
  echo "## Logs"
  echo
  for repo in "${repos[@]}"; do
    log="/tmp/${repo//\//_}_pipeline.log"
    if [[ -f "$log" ]]; then
      echo "### ${repo}"
      echo '```text'
      tail -n 40 "$log"
      echo '```'
      echo
    fi
  done
} >> "$REPORT"

echo "Pipeline run report: $REPORT"
