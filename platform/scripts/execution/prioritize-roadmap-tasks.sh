#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
WORKSPACE_ROOT="$(cd "${REPO_ROOT}/.." && pwd)"
TODAY="$(date +%F)"
NOW_UTC="$(date -u +'%Y-%m-%d %H:%M:%S UTC')"
REPORT_FILE="${REPO_ROOT}/docs/reports/ROADMAP_PRIORITY_TASKS_${TODAY}.md"

escape_csv() {
  local val="$1"
  val="${val//\"/\"\"}"
  printf '"%s"' "$val"
}

owner_for_task() {
  local stage="$1"
  local item="$2"
  local lower
  lower="$(printf '%s' "$item" | tr '[:upper:]' '[:lower:]')"

  if [[ "$lower" == *"dns"* || "$lower" == *"tls"* || "$lower" == *"sitemap"* || "$lower" == *"robots"* ]]; then
    printf 'DevOps'
    return
  fi

  if [[ "$lower" == *"service"* || "$lower" == *"case"* || "$lower" == *"pillar"* || "$lower" == *"proof"* ]]; then
    printf 'Brand/Product'
    return
  fi

  if [[ "$lower" == *"proposal"* || "$lower" == *"sow"* || "$lower" == *"change request"* || "$lower" == *"handover"* || "$lower" == *"sales"* ]]; then
    printf 'Sales/PM'
    return
  fi

  case "$stage" in
    A) printf 'DevOps' ;;
    B) printf 'Brand/Product' ;;
    S) printf 'Sales/PM' ;;
    L) printf 'Leadership' ;;
    *) printf 'Owner' ;;
  esac
}

priority_for_stage() {
  case "$1" in
    A) printf 'P0' ;;
    B) printf 'P1' ;;
    S) printf 'P1' ;;
    L) printf 'P2' ;;
    *) printf 'P2' ;;
  esac
}

rank_for_stage() {
  case "$1" in
    A) printf '0' ;;
    B) printf '1' ;;
    S) printf '1' ;;
    L) printf '2' ;;
    *) printf '9' ;;
  esac
}

phase_for_stage() {
  case "$1" in
    A) printf 'Stage A (Go-Live)' ;;
    B) printf 'Stage B (Brand + Proof)' ;;
    S) printf 'Stage S (Sales + Contracts)' ;;
    L) printf 'Stage L (Long-term)' ;;
    *) printf 'Unknown Stage' ;;
  esac
}

{
  echo "# Roadmap Priority Tasks (${TODAY})"
  echo
  echo "- Generated (UTC): ${NOW_UTC}"
  echo "- Scope: all local asdev-* repositories with docs/strategic-execution"
  echo
  echo "| Repo | P0 | P1 | P2 | Total |"
  echo "|---|---:|---:|---:|---:|"
} > "$REPORT_FILE"

for repo in "$WORKSPACE_ROOT"/asdev-*; do
  [[ -d "$repo/.git" ]] || continue
  name="$(basename "$repo")"

  status_file="$repo/docs/strategic-execution/STAGE_STATUS.md"
  runtime_dir="$repo/docs/strategic-execution/runtime"
  [[ -f "$status_file" ]] || continue
  mkdir -p "$runtime_dir"

  tmp_tasks="$(mktemp)"
  stage=""

  while IFS= read -r line; do
    case "$line" in
      "## Stage A"*) stage="A" ;;
      "## Stage B"*) stage="B" ;;
      "## Stage S"*) stage="S" ;;
      "## Stage L"*) stage="L" ;;
    esac

    if [[ "$line" =~ ^-\ \[\ \]\ (.*)$ ]]; then
      item="${BASH_REMATCH[1]}"
      priority="$(priority_for_stage "$stage")"
      rank="$(rank_for_stage "$stage")"
      phase="$(phase_for_stage "$stage")"
      owner="$(owner_for_task "$stage" "$item")"
      dod="Artifact linked and accepted"
      evidence="docs/strategic-execution/runtime"
      acceptance="Checkbox promoted to [x] in STAGE_STATUS.md"
      printf '%s|%s|%s|%s|%s|%s|%s|%s\n' "$rank" "$priority" "$phase" "$item" "$owner" "$dod" "$evidence" "$acceptance" >> "$tmp_tasks"
    fi
  done < "$status_file"

  task_md="$repo/docs/strategic-execution/ROADMAP_TASKS_PRIORITIZED.md"
  task_csv="$runtime_dir/Task_Log.csv"

  {
    echo "# Prioritized Roadmap Tasks - ${name}"
    echo
    echo "- Generated: ${TODAY}"
    echo "- Source: docs/strategic-execution/STAGE_STATUS.md"
    echo "- Rule: P0 (Stage A), P1 (Stage B/S), P2 (Stage L)"
    echo
    echo "| Priority | Stage | Task | Owner | DoD | Evidence | Acceptance |"
    echo "|---|---|---|---|---|---|---|"

    sort -t'|' -k1,1n -k2,2 "$tmp_tasks" | while IFS='|' read -r rank priority phase item owner dod evidence acceptance; do
      printf '| %s | %s | %s | %s | %s | %s | %s |\n' "$priority" "$phase" "$item" "$owner" "$dod" "$evidence" "$acceptance"
    done

    echo
    echo "## Top 5 Now"
    sort -t'|' -k1,1n -k2,2 "$tmp_tasks" | head -n 5 | while IFS='|' read -r rank priority phase item owner dod evidence acceptance; do
      printf '1. [%s] %s (%s)\n' "$priority" "$item" "$phase"
    done
  } > "$task_md"

  {
    echo 'date,priority,stage,task,status,owner,evidence,acceptance,source'
    sort -t'|' -k1,1n -k2,2 "$tmp_tasks" | while IFS='|' read -r rank priority phase item owner dod evidence acceptance; do
      printf '%s,%s,%s,%s,%s,%s,%s,%s,%s\n' \
        "$(escape_csv "$TODAY")" \
        "$(escape_csv "$priority")" \
        "$(escape_csv "$phase")" \
        "$(escape_csv "$item")" \
        "$(escape_csv "todo")" \
        "$(escape_csv "$owner")" \
        "$(escape_csv "$evidence")" \
        "$(escape_csv "$acceptance")" \
        "$(escape_csv "STAGE_STATUS.md")"
    done
  } > "$task_csv"

  p0_count="$(grep -c '|P0|' "$tmp_tasks" || true)"
  p1_count="$(grep -c '|P1|' "$tmp_tasks" || true)"
  p2_count="$(grep -c '|P2|' "$tmp_tasks" || true)"
  total_count="$((p0_count + p1_count + p2_count))"

  printf '| %s | %s | %s | %s | %s |\n' "$name" "$p0_count" "$p1_count" "$p2_count" "$total_count" >> "$REPORT_FILE"

  rm -f "$tmp_tasks"
done

echo "Prioritized tasks generated: $REPORT_FILE"
