#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
WORKSPACE_ROOT="${WORKSPACE_ROOT:-$(cd "${REPO_ROOT}/.." && pwd)}"
TODAY="$(date +%F)"
NOW_UTC="$(date -u +'%Y-%m-%d %H:%M:%S UTC')"
ROADMAP_FILE="${REPO_ROOT}/ROADMAP_EXECUTION_UNIFIED.md"
REPORT_FILE="${REPO_ROOT}/docs/reports/REMAINING_EXECUTION_AUTORUN_${TODAY}.md"
RUNTIME_TASK_LOG="${REPO_ROOT}/docs/strategic-execution/runtime/Task_Log.csv"

mkdir -p "$(dirname "$REPORT_FILE")"
mkdir -p "$(dirname "$RUNTIME_TASK_LOG")"

trim() {
  local s="$1"
  s="${s#${s%%[![:space:]]*}}"
  s="${s%${s##*[![:space:]]}}"
  printf '%s' "$s"
}

run_check() {
  local label="$1"
  shift
  local out rc
  if out="$($@ 2>&1)"; then
    rc=0
  else
    rc=$?
  fi
  printf '%s\n' "$out" > "/tmp/asdev_${label}.log"
  return $rc
}

freeze_status="blocked"
sync_status="blocked"
auth_status="blocked"
lint_status="blocked"
typecheck_status="blocked"
test_status="blocked"
build_status="blocked"

if run_check freeze_guard bash "${SCRIPT_DIR}/automation-freeze-guard.sh"; then freeze_status="done"; fi
if WORKSPACE_ROOT="$WORKSPACE_ROOT" run_check main_sync bash "${SCRIPT_DIR}/enforce-main-sync-policy.sh" check; then sync_status="done"; fi
if run_check gh_auth bash "${SCRIPT_DIR}/github-app-auth-guard.sh"; then auth_status="done"; fi
if run_check lint make -s lint; then lint_status="done"; fi
if run_check typecheck make -s typecheck; then typecheck_status="done"; fi
if run_check test make -s test; then test_status="done"; fi
if run_check build make -s build; then build_status="done"; fi
if run_check pr_check_audit_strict bash "${SCRIPT_DIR}/audit-pr-check-emission.sh" "alirezasafaeisystems/asdev-standards-platform" "/tmp/asdev_pr_check_audit.md" "true"; then pr_check_audit_status="done"; else pr_check_audit_status="blocked"; fi
if run_check release_post_check bash "${SCRIPT_DIR}/release/post-check.sh"; then release_post_check_status="done"; else release_post_check_status="blocked"; fi

baseline_status="done"
if [[ "$lint_status" != "done" || "$typecheck_status" != "done" || "$test_status" != "done" || "$build_status" != "done" ]]; then
  baseline_status="blocked"
fi

standards_sync_status="todo"
if [[ -f "${REPO_ROOT}/docs/strategic-execution/STAGE_STATUS.md" ]] && rg -q 'Status: COMPLETED' "${REPO_ROOT}/docs/strategic-execution/STAGE_STATUS.md"; then
  standards_sync_status="done"
fi

if [[ ! -f "$RUNTIME_TASK_LOG" ]]; then
  echo 'date,priority,stage,task,status,owner,evidence,acceptance,source' > "$RUNTIME_TASK_LOG"
fi

tmp_task_log="$(mktemp)"
{ head -n 1 "$RUNTIME_TASK_LOG"; tail -n +2 "$RUNTIME_TASK_LOG" | grep -E -v "^"${TODAY}".*"execute-remaining-roadmap-tasks.sh"$" || true; } > "$tmp_task_log"
mv "$tmp_task_log" "$RUNTIME_TASK_LOG"

{
  echo "# Remaining Execution Auto-run (${TODAY})"
  echo
  echo "- Executed (UTC): ${NOW_UTC}"
  echo "- Workspace root: ${WORKSPACE_ROOT}"
  echo "- Source roadmap: ${ROADMAP_FILE#${REPO_ROOT}/}"
  echo
  echo "| Task ID | Status | Evidence | Notes |"
  echo "|---|---|---|---|"
} > "$REPORT_FILE"

rows_written=0
if rg -q '^\| EXE-' "$ROADMAP_FILE"; then
  while IFS= read -r line; do
    id="$(trim "$(echo "$line" | cut -d'|' -f2)")"
    phase="$(trim "$(echo "$line" | cut -d'|' -f3)")"
    scope="$(trim "$(echo "$line" | cut -d'|' -f4)")"
    task="$(trim "$(echo "$line" | cut -d'|' -f5)")"
    priority="$(trim "$(echo "$line" | cut -d'|' -f6)")"
    owner="$(trim "$(echo "$line" | cut -d'|' -f7)")"

    status="todo"
    evidence="-"
    notes="Manual follow-up required"

    case "$id" in
      EXE-P0-01)
        status="$freeze_status"
        evidence="scripts/automation-freeze-guard.sh"
        notes="log:/tmp/asdev_freeze_guard.log"
        ;;
      EXE-P0-02)
        status="$sync_status"
        evidence="scripts/enforce-main-sync-policy.sh check"
        notes="log:/tmp/asdev_main_sync.log"
        ;;
      EXE-P0-03)
        status="$auth_status"
        evidence="scripts/github-app-auth-guard.sh"
        notes="log:/tmp/asdev_gh_auth.log"
        ;;
      EXE-P0-04)
        status="$baseline_status"
        evidence="make lint/typecheck/test/build"
        notes="lint=${lint_status},typecheck=${typecheck_status},test=${test_status},build=${build_status}"
        ;;
      EXE-P1-04)
        status="$standards_sync_status"
        evidence="docs/strategic-execution/STAGE_STATUS.md"
        notes="standards-platform auto execution status"
        ;;
      EXE-DOD-02)
        if [[ "$lint_status" == "done" && "$typecheck_status" == "done" && "$test_status" == "done" && "$build_status" == "done" ]]; then
          status="done"
        else
          status="blocked"
        fi
        evidence="make lint/typecheck/test/build"
        notes="ci-local gates"
        ;;
      *)
        if [[ "$scope" == "Cross-repo" || "$scope" == "asdev-portfolio" || "$scope" == "asdev-persiantoolbox" || "$scope" == "asdev-automation-hub" || "$scope" == "asdev-creator-membership-ir" || "$scope" == "asdev-family-rosca" || "$scope" == "asdev-nexa-vpn" || "$scope" == "asdev-codex-reviewer" ]]; then
          status="blocked"
          evidence="workspace limitation"
          notes="target repo not present in current workspace"
        fi
        ;;
    esac

    printf '| %s | %s | %s | %s |\n' "$id" "$status" "$evidence" "$notes" >> "$REPORT_FILE"
    rows_written=$((rows_written + 1))

    safe_task="${task//,/; }"
    safe_notes="${notes//,/; }"
    printf '"%s","%s","%s","%s","%s","%s","%s","%s","%s"\n' \
      "$TODAY" "$priority" "$phase" "$safe_task [$id]" "$status" "$owner" "$evidence" "$safe_notes" "execute-remaining-roadmap-tasks.sh" >> "$RUNTIME_TASK_LOG"
  done < <(rg '^\| EXE-' "$ROADMAP_FILE")
else
  roadmap_status="todo"
  if rg -q '^Status: operational maintenance' "$ROADMAP_FILE"; then
    roadmap_status="done"
  fi

  printf '| %s | %s | %s | %s |\n' "NS-01" "$pr_check_audit_status" "scripts/audit-pr-check-emission.sh (strict)" "log:/tmp/asdev_pr_check_audit_strict.log" >> "$REPORT_FILE"
  printf '"%s","%s","%s","%s","%s","%s","%s","%s","%s"\n' \
    "$TODAY" "Critical" "Next Session" "Run PR Check Audit workflow in strict mode and archive result [NS-01]" "$pr_check_audit_status" "Platform Owner" "scripts/audit-pr-check-emission.sh" "strict=true; log:/tmp/asdev_pr_check_audit_strict.log" "execute-remaining-roadmap-tasks.sh" >> "$RUNTIME_TASK_LOG"

  printf '| %s | %s | %s | %s |\n' "NS-02" "$release_post_check_status" "scripts/release/post-check.sh" "log:/tmp/asdev_release_post_check.log" >> "$REPORT_FILE"
  printf '"%s","%s","%s","%s","%s","%s","%s","%s","%s"\n' \
    "$TODAY" "Critical" "Next Session" "Run Release Post Check for latest valid release tag and archive result [NS-02]" "$release_post_check_status" "Release Owner" "scripts/release/post-check.sh" "log:/tmp/asdev_release_post_check.log" "execute-remaining-roadmap-tasks.sh" >> "$RUNTIME_TASK_LOG"

  printf '| %s | %s | %s | %s |\n' "NS-03" "$roadmap_status" "ROADMAP_EXECUTION_UNIFIED.md" "requires final readiness summary and roadmap status transition" >> "$REPORT_FILE"
  printf '"%s","%s","%s","%s","%s","%s","%s","%s","%s"\n' \
    "$TODAY" "High" "Next Session" "Publish final readiness summary and switch roadmap state to operational maintenance [NS-03]" "$roadmap_status" "Repo Owner" "ROADMAP_EXECUTION_UNIFIED.md" "set Status: operational maintenance after NS-01/NS-02 are done" "execute-remaining-roadmap-tasks.sh" >> "$RUNTIME_TASK_LOG"

  rows_written=3
fi

echo "Remaining execution auto-run report: $REPORT_FILE"
