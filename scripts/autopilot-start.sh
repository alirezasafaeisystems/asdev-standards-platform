#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/codex-automation-config.sh"

WORKSPACE_ROOT="${WORKSPACE_ROOT:-$(cfg_workspace_root)}"
HUB_REPO="$(cfg_hub_repo)"
PLATFORM_ROOT="${WORKSPACE_ROOT}/${HUB_REPO}"
AUTOPILOT_LOG_REL="$(cfg_get '.paths.autopilot_log_dir' 'var/automation/autopilot')"
LOG_DIR="${LOG_DIR:-${PLATFORM_ROOT}/${AUTOPILOT_LOG_REL}}"
SERVICE_NAME="${SERVICE_NAME:-$(cfg_get '.autopilot.service_name' 'asdev-autopilot.service')}"
USER_SERVICE_FILE="${HOME}/.config/systemd/user/${SERVICE_NAME}"
mkdir -p "${LOG_DIR}" "${LOG_DIR}/done"
touch "${LOG_DIR}/done/.keep"

PID_FILE="${LOG_DIR}/autopilot.pid"
if command -v systemctl >/dev/null 2>&1 && [[ -f "${USER_SERVICE_FILE}" ]]; then
  if systemctl --user is-active --quiet "${SERVICE_NAME}"; then
    echo "autopilot already running via systemd: ${SERVICE_NAME}"
    exit 0
  fi
  systemctl --user start "${SERVICE_NAME}"
  sleep 1
  if systemctl --user is-active --quiet "${SERVICE_NAME}"; then
    echo "autopilot started via systemd: ${SERVICE_NAME}"
    exit 0
  fi
fi

if [[ -f "${PID_FILE}" ]] && ps -p "$(cat "${PID_FILE}")" >/dev/null 2>&1; then
  echo "autopilot already running: pid=$(cat "${PID_FILE}")"
  exit 0
fi

if [[ "${RESET_DONE:-true}" == "true" ]]; then
  find "${LOG_DIR}/done" -type f ! -name '.keep' -delete
fi

if command -v setsid >/dev/null 2>&1; then
  setsid bash "${SCRIPT_DIR}/autopilot-orchestrator.sh" > "${LOG_DIR}/stdout.log" 2>&1 < /dev/null &
  PID=$!
else
  nohup bash "${SCRIPT_DIR}/autopilot-orchestrator.sh" > "${LOG_DIR}/stdout.log" 2>&1 < /dev/null &
  PID=$!
fi
echo "${PID}" > "${LOG_DIR}/launcher.pid"
echo "autopilot started: pid=${PID}"
