#!/usr/bin/env bash
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/codex-automation-config.sh"

WORKSPACE_ROOT="${WORKSPACE_ROOT:-$(cfg_workspace_root)}"
HUB_REPO="$(cfg_hub_repo)"
PLATFORM_ROOT="${WORKSPACE_ROOT}/${HUB_REPO}"

AUTOPILOT_LOG_REL="$(cfg_get '.paths.autopilot_log_dir' 'var/automation/autopilot')"
REPORTS_REL="$(cfg_get '.paths.reports_dir' 'var/automation/reports')"
LOG_DIR="${LOG_DIR:-${PLATFORM_ROOT}/${AUTOPILOT_LOG_REL}}"
REPORT_FILE="${REPORT_FILE:-${PLATFORM_ROOT}/${REPORTS_REL}/AUTOPILOT_EXECUTION_REPORT.md}"
RUN_LOG="${LOG_DIR}/autopilot.log"
ERROR_LOG="${LOG_DIR}/errors.log"
DONE_DIR="${LOG_DIR}/done"
PID_FILE="${LOG_DIR}/autopilot.pid"

IDLE_SECONDS="${IDLE_SECONDS:-$(cfg_get '.autopilot.idle_seconds' '180')}"
HEALTHCHECK_SECONDS="${HEALTHCHECK_SECONDS:-$(cfg_get '.autopilot.healthcheck_seconds' '300')}"
POST_COMPLETE_WAIT_SECONDS="${POST_COMPLETE_WAIT_SECONDS:-$(cfg_get '.autopilot.post_complete_wait_seconds' '180')}"

mkdir -p "${LOG_DIR}" "${DONE_DIR}" "$(dirname "${REPORT_FILE}")"
touch "${RUN_LOG}" "${ERROR_LOG}" "${DONE_DIR}/.keep"

if [[ -f "${PID_FILE}" ]]; then
  existing_pid="$(cat "${PID_FILE}" 2>/dev/null || true)"
  if [[ -n "${existing_pid}" ]] && kill -0 "${existing_pid}" >/dev/null 2>&1 && ps -p "${existing_pid}" -o args= | grep -q 'autopilot-orchestrator.sh'; then
    echo "[$(date -u +%FT%TZ)] autopilot already running (pid=${existing_pid})" | tee -a "${RUN_LOG}"
    exit 0
  fi
fi

echo "$$" > "${PID_FILE}"
trap 'rm -f "${PID_FILE}"' EXIT

if [[ ! -f "${REPORT_FILE}" ]]; then
  cat > "${REPORT_FILE}" <<'EOF'
# Autopilot Execution Report

This report is maintained automatically by `scripts/autopilot-orchestrator.sh`.
EOF
fi

timestamp() {
  date -u +%FT%TZ
}

append_report() {
  local phase_state="$1"
  local success_count="$2"
  local failed_count="$3"
  local cycle_log="$4"
  local failed_tasks="${5:-none}"

  {
    echo
    echo "## $(timestamp)"
    echo "- phase_state: ${phase_state}"
    echo "- success_count: ${success_count}"
    echo "- failed_count: ${failed_count}"
    echo "- failed_tasks: ${failed_tasks}"
    echo "- cycle_log: ${cycle_log}"
  } >> "${REPORT_FILE}"
}

run_task() {
  local task_id="$1"
  local mode="$2"
  local repo_path="$3"
  local command="$4"
  local cycle_stamp="$5"
  local attempt="${6:-run}"

  local repo_dir="${WORKSPACE_ROOT}/${repo_path}"
  local task_log="${LOG_DIR}/${cycle_stamp}-${task_id}-${attempt}.log"

  {
    echo "[$(timestamp)] task=${task_id} mode=${mode} repo=${repo_path}"
    echo "[$(timestamp)] command=${command}"
  } >> "${RUN_LOG}"

  if [[ ! -d "${repo_dir}" ]]; then
    echo "[$(timestamp)] task=${task_id} failed repo not found: ${repo_dir}" | tee -a "${ERROR_LOG}" >> "${RUN_LOG}"
    return 2
  fi

  (
    cd "${repo_dir}" || exit 2
    bash -lc "${command}"
  ) > "${task_log}" 2>&1
  local status=$?

  if [[ ${status} -eq 0 ]]; then
    echo "[$(timestamp)] task=${task_id} status=ok log=${task_log}" >> "${RUN_LOG}"
    if [[ "${mode}" == "once" ]]; then
      touch "${DONE_DIR}/${task_id}"
    fi
  else
    echo "[$(timestamp)] task=${task_id} status=failed code=${status} log=${task_log}" | tee -a "${ERROR_LOG}" >> "${RUN_LOG}"
  fi

  return ${status}
}

run_fix_and_retry() {
  local task_id="$1"
  local mode="$2"
  local repo_path="$3"
  local command="$4"
  local fix_command="$5"
  local cycle_stamp="$6"

  [[ -z "${fix_command}" || "${fix_command}" == "-" ]] && return 1

  local repo_dir="${WORKSPACE_ROOT}/${repo_path}"
  local fix_log="${LOG_DIR}/${cycle_stamp}-${task_id}-fix.log"

  {
    echo "[$(timestamp)] task=${task_id} attempting fix"
    echo "[$(timestamp)] fix_command=${fix_command}"
  } >> "${RUN_LOG}"

  if [[ ! -d "${repo_dir}" ]]; then
    echo "[$(timestamp)] task=${task_id} fix failed repo not found: ${repo_dir}" | tee -a "${ERROR_LOG}" >> "${RUN_LOG}"
    return 1
  fi

  (
    cd "${repo_dir}" || exit 2
    bash -lc "${fix_command}"
  ) > "${fix_log}" 2>&1
  local fix_status=$?

  if [[ ${fix_status} -ne 0 ]]; then
    echo "[$(timestamp)] task=${task_id} fix failed code=${fix_status} log=${fix_log}" | tee -a "${ERROR_LOG}" >> "${RUN_LOG}"
    return 1
  fi

  echo "[$(timestamp)] task=${task_id} fix success log=${fix_log}" >> "${RUN_LOG}"
  run_task "${task_id}" "${mode}" "${repo_path}" "${command}" "${cycle_stamp}" "retry"
}

has_pending_once_tasks() {
  local pending=1
  while IFS=$'\t' read -r task_id mode repo_path command fix_command; do
    [[ -z "${task_id}" ]] && continue
    [[ "${mode}" != "once" ]] && continue
    if [[ ! -f "${DONE_DIR}/${task_id}" ]]; then
      pending=0
      break
    fi
  done < <(cfg_task_lines_tsv)

  return ${pending}
}

run_cycle() {
  local target_mode="$1"
  local cycle_stamp
  cycle_stamp="$(date -u +%Y%m%dT%H%M%SZ)"
  local success_count=0
  local failed_count=0
  local failed_tasks=()

  while IFS=$'\t' read -r task_id mode repo_path command fix_command; do
    [[ -z "${task_id}" ]] && continue
    [[ "${mode}" != "${target_mode}" ]] && continue

    if [[ "${mode}" == "once" && -f "${DONE_DIR}/${task_id}" ]]; then
      continue
    fi

    if run_task "${task_id}" "${mode}" "${repo_path}" "${command}" "${cycle_stamp}" "run"; then
      success_count=$((success_count + 1))
    elif run_fix_and_retry "${task_id}" "${mode}" "${repo_path}" "${command}" "${fix_command}" "${cycle_stamp}"; then
      success_count=$((success_count + 1))
    else
      failed_count=$((failed_count + 1))
      failed_tasks+=("${task_id}")
    fi
  done < <(cfg_task_lines_tsv)

  echo "[$(timestamp)] cycle mode=${target_mode} success=${success_count} failed=${failed_count}" >> "${RUN_LOG}"
  if [[ ${#failed_tasks[@]} -eq 0 ]]; then
    append_report "${target_mode}" "${success_count}" "${failed_count}" "${LOG_DIR}/${cycle_stamp}-*.log" "none"
  else
    append_report "${target_mode}" "${success_count}" "${failed_count}" "${LOG_DIR}/${cycle_stamp}-*.log" "$(IFS=,; echo "${failed_tasks[*]}")"
  fi
}

echo "[$(timestamp)] autopilot started pid=$$ idle=${IDLE_SECONDS}s health=${HEALTHCHECK_SECONDS}s" | tee -a "${RUN_LOG}"

while true; do
  if has_pending_once_tasks; then
    run_cycle "once"
    sleep "${IDLE_SECONDS}"
    continue
  fi

  sleep "${POST_COMPLETE_WAIT_SECONDS}"
  run_cycle "health"
  sleep "${HEALTHCHECK_SECONDS}"
done
