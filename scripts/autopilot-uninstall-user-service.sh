#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/codex-automation-config.sh"

SERVICE_NAME="$(cfg_get '.autopilot.service_name' 'asdev-autopilot.service')"
USER_SYSTEMD_DIR="${HOME}/.config/systemd/user"
TARGET_SERVICE_FILE="${USER_SYSTEMD_DIR}/${SERVICE_NAME}"

if command -v systemctl >/dev/null 2>&1; then
  systemctl --user disable --now "${SERVICE_NAME}" >/dev/null 2>&1 || true
  systemctl --user daemon-reload || true
fi

rm -f "${TARGET_SERVICE_FILE}"
echo "Autopilot user service removed: ${SERVICE_NAME}"
