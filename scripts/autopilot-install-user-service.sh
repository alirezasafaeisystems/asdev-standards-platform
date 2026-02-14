#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLATFORM_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
source "${SCRIPT_DIR}/lib/codex-automation-config.sh"

SERVICE_NAME="$(cfg_get '.autopilot.service_name' 'asdev-autopilot.service')"
SOURCE_SERVICE_FILE="${PLATFORM_ROOT}/ops/systemd/${SERVICE_NAME}"
USER_SYSTEMD_DIR="${HOME}/.config/systemd/user"
TARGET_SERVICE_FILE="${USER_SYSTEMD_DIR}/${SERVICE_NAME}"

if [[ ! -f "${SOURCE_SERVICE_FILE}" ]]; then
  echo "Service template not found: ${SOURCE_SERVICE_FILE}" >&2
  exit 1
fi

mkdir -p "${USER_SYSTEMD_DIR}"
cp "${SOURCE_SERVICE_FILE}" "${TARGET_SERVICE_FILE}"

if ! command -v systemctl >/dev/null 2>&1; then
  echo "systemctl is not available. Service file copied to ${TARGET_SERVICE_FILE}."
  exit 0
fi

systemctl --user daemon-reload
systemctl --user enable --now "${SERVICE_NAME}"
systemctl --user status "${SERVICE_NAME}" --no-pager --lines=5 || true

echo "Autopilot user service installed and enabled: ${SERVICE_NAME}"
