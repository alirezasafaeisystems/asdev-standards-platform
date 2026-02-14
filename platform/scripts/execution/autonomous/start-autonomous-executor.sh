#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../../.." && pwd)"
source "${REPO_ROOT}/scripts/lib/codex-automation-config.sh"

ROOT="${ROOT:-$(cfg_workspace_root)}"
HUB_REPO="$(cfg_hub_repo)"
HUB="${ROOT}/${HUB_REPO}"
AUTONOMOUS_RUNTIME_REL="$(cfg_get '.paths.autonomous_runtime_dir' 'var/automation/autonomous-executor')"
AUTONOMOUS_LOG_REL="$(cfg_get '.paths.autonomous_log_dir' 'var/automation/autonomous-executor/logs')"
AUTONOMOUS_STATE_REL="$(cfg_get '.paths.autonomous_state_dir' 'var/automation/autonomous-executor/state')"

RUNTIME_DIR="${HUB}/${AUTONOMOUS_RUNTIME_REL}"
LOG_DIR="${HUB}/${AUTONOMOUS_LOG_REL}"
STATE_DIR="${HUB}/${AUTONOMOUS_STATE_REL}"
PID_FILE="${STATE_DIR}/pid"
OUT_LOG="${LOG_DIR}/runner.out"

mkdir -p "${RUNTIME_DIR}" "${LOG_DIR}" "${STATE_DIR}"

if [[ -f "${PID_FILE}" ]]; then
  old_pid="$(cat "${PID_FILE}" || true)"
  if [[ -n "${old_pid}" ]] && kill -0 "${old_pid}" 2>/dev/null; then
    echo "already_running pid=${old_pid}"
    exit 0
  fi
fi

nohup "${SCRIPT_DIR}/autonomous-executor.sh" >> "${OUT_LOG}" 2>&1 &
new_pid=$!
printf '%s\n' "${new_pid}" > "${PID_FILE}"
echo "started pid=${new_pid} log=${OUT_LOG}"
