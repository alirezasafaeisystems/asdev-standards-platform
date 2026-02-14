#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/codex-automation-config.sh"

WORKSPACE_ROOT="${WORKSPACE_ROOT:-$(cfg_workspace_root)}"
HUB_REPO="$(cfg_hub_repo)"
PLATFORM_ROOT="${WORKSPACE_ROOT}/${HUB_REPO}"
AUTOPILOT_LOG_REL="$(cfg_get '.paths.autopilot_log_dir' 'var/automation/autopilot')"
LOG_DIR="${LOG_DIR:-${PLATFORM_ROOT}/${AUTOPILOT_LOG_REL}}"
PID_FILE="${LOG_DIR}/autopilot.pid"
SERVICE_NAME="${SERVICE_NAME:-$(cfg_get '.autopilot.service_name' 'asdev-autopilot.service')}"
USER_SERVICE_FILE="${HOME}/.config/systemd/user/${SERVICE_NAME}"

if command -v systemctl >/dev/null 2>&1 && [[ -f "${USER_SERVICE_FILE}" ]]; then
  if systemctl --user is-active --quiet "${SERVICE_NAME}"; then
    systemctl --user stop "${SERVICE_NAME}"
    echo "autopilot stopped via systemd: ${SERVICE_NAME}"
  fi
fi

if [[ ! -f "${PID_FILE}" ]]; then
  echo "autopilot is not running"
  exit 0
fi

PID="$(cat "${PID_FILE}")"
if kill "${PID}" >/dev/null 2>&1; then
  echo "autopilot stopped: pid=${PID}"
  rm -f "${PID_FILE}"
else
  echo "failed to stop autopilot pid=${PID}"
  exit 1
fi
