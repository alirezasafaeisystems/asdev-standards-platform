#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../../.." && pwd)"
source "${REPO_ROOT}/scripts/lib/codex-automation-config.sh"

ROOT="${ROOT:-$(cfg_workspace_root)}"
HUB_REPO="$(cfg_hub_repo)"
HUB="${ROOT}/${HUB_REPO}"
AUTONOMOUS_STATE_REL="$(cfg_get '.paths.autonomous_state_dir' 'var/automation/autonomous-executor/state')"
STATE_DIR="${HUB}/${AUTONOMOUS_STATE_REL}"
PID_FILE="${STATE_DIR}/pid"
STOP_FILE="${STATE_DIR}/stop"

mkdir -p "${STATE_DIR}"
touch "${STOP_FILE}"

if [[ -f "${PID_FILE}" ]]; then
  pid="$(cat "${PID_FILE}" || true)"
  echo "stop_signal_sent pid=${pid:-unknown}"
else
  echo "stop_signal_sent pid=none"
fi
