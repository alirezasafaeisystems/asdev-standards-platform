#!/usr/bin/env bash
set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EXECUTION_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../../.." && pwd)"
source "${REPO_ROOT}/scripts/lib/codex-automation-config.sh"

ROOT="${ROOT:-$(cfg_workspace_root)}"
HUB_REPO="$(cfg_hub_repo)"
HUB="${ROOT}/${HUB_REPO}"

AUTONOMOUS_RUNTIME_REL="$(cfg_get '.paths.autonomous_runtime_dir' 'var/automation/autonomous-executor')"
AUTONOMOUS_LOG_REL="$(cfg_get '.paths.autonomous_log_dir' 'var/automation/autonomous-executor/logs')"
AUTONOMOUS_STATE_REL="$(cfg_get '.paths.autonomous_state_dir' 'var/automation/autonomous-executor/state')"
REPORTS_REL="$(cfg_get '.paths.reports_dir' 'var/automation/reports')"
MANUAL_ACTIONS_REL="$(cfg_get '.paths.manual_actions_file' 'MANUAL_EXTERNAL_ACTIONS.md')"
BLUEPRINT_ZIP="$(cfg_get '.paths.blueprint_zip' '/home/dev/Downloads/ASDEV_Strategic_Execution_Blueprint_v1.0.zip')"

IDLE_WAIT_SECONDS="${IDLE_WAIT_SECONDS:-$(cfg_get '.autonomous_executor.idle_wait_seconds' '180')}"
POST_COMPLETE_WAIT_SECONDS="${POST_COMPLETE_WAIT_SECONDS:-$(cfg_get '.autonomous_executor.post_complete_wait_seconds' '240')}"
LOOP_PAUSE_SECONDS="${LOOP_PAUSE_SECONDS:-$(cfg_get '.autonomous_executor.loop_pause_seconds' '20')}"
EXECUTION_PROFILE="${EXECUTION_PROFILE:-$(cfg_get '.autonomous_executor.execution_profile' 'max')}"
SAFE_COMMIT="${SAFE_COMMIT:-$(cfg_get '.autonomous_executor.safe_commit' 'true')}"

resolve_root_path() {
  local maybe_rel="$1"
  if [[ "${maybe_rel}" = /* ]]; then
    printf '%s\n' "${maybe_rel}"
  else
    printf '%s/%s\n' "${ROOT}" "${maybe_rel}"
  fi
}

resolve_hub_path() {
  local maybe_rel="$1"
  if [[ "${maybe_rel}" = /* ]]; then
    printf '%s\n' "${maybe_rel}"
  else
    printf '%s/%s\n' "${HUB}" "${maybe_rel}"
  fi
}

RUNTIME_DIR="$(resolve_hub_path "${AUTONOMOUS_RUNTIME_REL}")"
LOG_DIR="$(resolve_hub_path "${AUTONOMOUS_LOG_REL}")"
STATE_DIR="$(resolve_hub_path "${AUTONOMOUS_STATE_REL}")"
REPORTS_DIR="$(resolve_hub_path "${REPORTS_REL}")"
MANUAL_ACTIONS_FILE="$(resolve_root_path "${MANUAL_ACTIONS_REL}")"

MAIN_LOG="${LOG_DIR}/autonomous-executor.log"
ERROR_REGISTRY_FILE="${RUNTIME_DIR}/error-registry.log"
PID_FILE="${STATE_DIR}/pid"
STOP_FILE="${STATE_DIR}/stop"
LAST_RUN_FILE="${STATE_DIR}/last_run"

APPLY_SCRIPT="${EXECUTION_DIR}/apply-strategic-execution-blueprint.sh"
EXECUTE_SCRIPT="${EXECUTION_DIR}/execute-priority-roadmap.sh"
PRIORITIZE_SCRIPT="${EXECUTION_DIR}/prioritize-roadmap-tasks.sh"
PIPELINE_SCRIPT_DEFAULT="${EXECUTION_DIR}/pipelines/run-priority-pipelines.sh"
PIPELINE_SCRIPT_MAX="${EXECUTION_DIR}/pipelines/run-priority-pipelines-max.sh"
PIPELINE_SCRIPT="${PIPELINE_SCRIPT_DEFAULT}"
if [[ "${EXECUTION_PROFILE}" == "max" && -x "${PIPELINE_SCRIPT_MAX}" ]]; then
  PIPELINE_SCRIPT="${PIPELINE_SCRIPT_MAX}"
fi
AUTOPILOT_SCRIPT="${EXECUTION_DIR}/run-strategic-execution-autopilot.sh"

ensure_runtime_paths() {
  mkdir -p "${RUNTIME_DIR}" "${LOG_DIR}" "${STATE_DIR}" "${REPORTS_DIR}" "$(dirname "${MANUAL_ACTIONS_FILE}")"
  touch "${MAIN_LOG}" "${ERROR_REGISTRY_FILE}"
}

ensure_runtime_paths
printf '%s\n' "$$" > "${PID_FILE}"

log() {
  ensure_runtime_paths
  printf '[%s] %s\n' "$(date -u +'%Y-%m-%d %H:%M:%S UTC')" "$1" | tee -a "${MAIN_LOG}"
}

run_step() {
  local step="$1"
  local cmd="$2"
  ensure_runtime_paths

  local step_log="${LOG_DIR}/${step}_$(date +%Y%m%d_%H%M%S).log"
  log "STEP_START: ${step}"
  bash -lc "${cmd}" >"${step_log}" 2>&1
  local ec=$?
  log "STEP_END: ${step} (exit=${ec}, log=${step_log})"
  if [[ ${ec} -ne 0 ]]; then
    printf '%s | %s | exit=%s | %s\n' "$(date -u +'%Y-%m-%d %H:%M:%S UTC')" "${step}" "${ec}" "${step_log}" >> "${ERROR_REGISTRY_FILE}"
  fi
  return 0
}

remaining_task_count() {
  local c=0
  local f

  while IFS= read -r f; do
    local x
    x="$(rg -n '^- \[ \]' "${f}" 2>/dev/null | wc -l | tr -d ' ')"
    c=$((c + x))
  done < <(find "${ROOT}" -maxdepth 4 -type f -path '*/docs/strategic-execution/STAGE_STATUS.md' | sort)

  while IFS= read -r f; do
    local x
    x="$(rg -n '"todo"' "${f}" 2>/dev/null | wc -l | tr -d ' ')"
    c=$((c + x))
  done < <(find "${ROOT}" -maxdepth 5 -type f -path '*/docs/strategic-execution/runtime/Task_Log.csv' | sort)

  printf '%s\n' "${c}"
}

generate_manual_actions_file() {
  cat > "${MANUAL_ACTIONS_FILE}" <<'MANUAL'
# Manual External Actions (Out of Repo)

1. DNS records verification on domain provider for all production domains.
2. TLS issuance/renewal verification (ACME/SSL dashboard).
3. HSTS enforcement check in production edge/proxy.
4. Google Search Console ownership verification for each domain.
5. Bing Webmaster ownership verification for each domain.
6. Sitemap submission in Google/Bing dashboards.
7. CRM destination and notification channel configuration (email/SMS/chatops).
8. Contract/legal signatures and payment confirmations.
9. Customer-side handover signoff and testimonial approval.
10. Production credentials rotation and secure secret distribution outside repo.
MANUAL
  log "UPDATED: ${MANUAL_ACTIONS_FILE}"
}

autodoc_snapshot() {
  ensure_runtime_paths
  local report="${REPORTS_DIR}/AUTONOMOUS_EXECUTION_STATUS_$(date +%F).md"
  local remaining
  local name sfile tfile open todo
  remaining="$(remaining_task_count)"

  {
    echo "# Autonomous Execution Status ($(date +%F))"
    echo
    echo "- Generated: $(date -u +'%Y-%m-%d %H:%M:%S UTC')"
    echo "- Remaining tasks: ${remaining}"
    echo
    echo "## Quick Status"
    echo
    echo "| Repo | Open checkboxes | Todo tasks |"
    echo "|---|---:|---:|"

    for repo in "${ROOT}"/asdev-*; do
      [[ -d "${repo}/.git" ]] || continue
      name="$(basename "${repo}")"
      sfile="${repo}/docs/strategic-execution/STAGE_STATUS.md"
      tfile="${repo}/docs/strategic-execution/runtime/Task_Log.csv"
      open=0
      todo=0
      [[ -f "${sfile}" ]] && open="$(rg -n '^- \[ \]' "${sfile}" 2>/dev/null | wc -l | tr -d ' ')"
      [[ -f "${tfile}" ]] && todo="$(rg -n '"todo"' "${tfile}" 2>/dev/null | wc -l | tr -d ' ')"
      echo "| ${name} | ${open} | ${todo} |"
    done
  } > "${report}"

  log "UPDATED: ${report}"
}

safe_commit() {
  if [[ "${SAFE_COMMIT}" != "true" ]]; then
    log "SAFE_COMMIT_DISABLED"
    return 0
  fi

  local stamp
  stamp="$(date +'%Y-%m-%d %H:%M:%S UTC')"

  for repo in "${ROOT}"/asdev-*; do
    [[ -d "${repo}/.git" ]] || continue
    name="$(basename "${repo}")"

    if [[ "${name}" == "${HUB_REPO}" ]]; then
      git -C "${repo}" add -A docs/strategic-execution ops/automation platform/scripts scripts >/dev/null 2>&1 || true
      if [[ -d "${repo}/${REPORTS_REL}" ]]; then
        git -C "${repo}" add -A "${REPORTS_REL}" >/dev/null 2>&1 || true
      fi
    else
      git -C "${repo}" add -A docs/strategic-execution >/dev/null 2>&1 || true
    fi

    if ! git -C "${repo}" diff --cached --quiet; then
      git -C "${repo}" commit -m "chore(execution): autonomous progress ${stamp}" >/dev/null 2>&1 || true
      log "COMMIT_ATTEMPT: ${name}"
    fi
  done
}

run_full_cycle() {
  if [[ -f "${BLUEPRINT_ZIP}" ]]; then
    run_step "apply_blueprint" "${APPLY_SCRIPT} --workspace-root ${ROOT} --zip ${BLUEPRINT_ZIP}"
  else
    log "SKIP_STEP: apply_blueprint (missing zip: ${BLUEPRINT_ZIP})"
  fi
  run_step "priority_execute" "${EXECUTE_SCRIPT}"
  run_step "prioritize_tasks" "${PRIORITIZE_SCRIPT}"
  run_step "autopilot_scan" "${AUTOPILOT_SCRIPT}"
  run_step "pipelines" "${PIPELINE_SCRIPT}"

  generate_manual_actions_file
  autodoc_snapshot
  safe_commit

  printf '%s\n' "$(date -u +'%Y-%m-%d %H:%M:%S UTC')" > "${LAST_RUN_FILE}"
}

log "AUTONOMOUS_EXECUTOR_STARTED (pid=$$)"
log "EXECUTION_PROFILE=${EXECUTION_PROFILE}"
log "PIPELINE_SCRIPT=${PIPELINE_SCRIPT}"

while true; do
  ensure_runtime_paths

  if [[ -f "${STOP_FILE}" ]]; then
    log "STOP_SIGNAL_DETECTED"
    rm -f "${STOP_FILE}"
    break
  fi

  log "IDLE_WAIT_START (${IDLE_WAIT_SECONDS}s)"
  sleep "${IDLE_WAIT_SECONDS}"

  remain="$(remaining_task_count)"
  log "TASK_REMAINING=${remain}"

  if [[ "${remain}" -gt 0 ]]; then
    run_full_cycle
    sleep "${LOOP_PAUSE_SECONDS}"
    continue
  fi

  log "NO_TASK_REMAINING_POST_WAIT (${POST_COMPLETE_WAIT_SECONDS}s)"
  sleep "${POST_COMPLETE_WAIT_SECONDS}"

  run_step "post_completion_verify" "${PIPELINE_SCRIPT}"
  generate_manual_actions_file
  autodoc_snapshot
  safe_commit

  sleep "${LOOP_PAUSE_SECONDS}"
done

rm -f "${PID_FILE}"
log "AUTONOMOUS_EXECUTOR_STOPPED"
