#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../../.." && pwd)"
source "${REPO_ROOT}/scripts/lib/codex-automation-config.sh"

ROOT="${ROOT:-$(cfg_workspace_root)}"
HUB_REPO="$(cfg_hub_repo)"
HUB="${ROOT}/${HUB_REPO}"
AUTONOMOUS_STATE_REL="$(cfg_get '.paths.autonomous_state_dir' 'var/automation/autonomous-executor/state')"
AUTONOMOUS_LOG_REL="$(cfg_get '.paths.autonomous_log_dir' 'var/automation/autonomous-executor/logs')"
STATE_DIR="${HUB}/${AUTONOMOUS_STATE_REL}"
LOG_DIR="${HUB}/${AUTONOMOUS_LOG_REL}"
PID_FILE="${STATE_DIR}/pid"
MAIN_LOG="${LOG_DIR}/autonomous-executor.log"

if [[ -f "${PID_FILE}" ]]; then
  pid="$(cat "${PID_FILE}" || true)"
  if [[ -n "${pid}" ]] && kill -0 "${pid}" 2>/dev/null; then
    echo "running pid=${pid}"
  else
    echo "stale_pid=${pid}"
  fi
else
  echo "not_running"
fi

if [[ -f "${MAIN_LOG}" ]]; then
  echo "---"
  tail -n 20 "${MAIN_LOG}"
fi
