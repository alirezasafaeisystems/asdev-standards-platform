#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../../.." && pwd)"
source "${REPO_ROOT}/scripts/lib/codex-automation-config.sh"

ROOT="${ROOT:-$(cfg_workspace_root)}"
HUB_REPO="$(cfg_hub_repo)"
HUB="${ROOT}/${HUB_REPO}"
REPORTS_REL="$(cfg_get '.paths.reports_dir' 'var/automation/reports')"
AUTONOMOUS_LOG_REL="$(cfg_get '.paths.autonomous_log_dir' 'var/automation/autonomous-executor/logs')"

SESSION="${1:-asdev-autonomous}"

if ! command -v tmux >/dev/null 2>&1; then
  echo "tmux is required" >&2
  exit 1
fi

if tmux has-session -t "${SESSION}" 2>/dev/null; then
  echo "session_exists: ${SESSION}"
  exit 0
fi

tmux new-session -d -s "${SESSION}" -n "executor" "cd ${ROOT} && bash ${HUB}/platform/scripts/execution/autonomous/autonomous-executor.sh"
tmux new-window -t "${SESSION}" -n "reports" "cd ${ROOT} && watch -n 5 'ls -lt ${HUB}/${REPORTS_REL} 2>/dev/null | head -n 20'; bash"
tmux new-window -t "${SESSION}" -n "logs" "cd ${ROOT} && tail -f ${HUB}/${AUTONOMOUS_LOG_REL}/autonomous-executor.log"

tmux select-window -t "${SESSION}:0"
echo "session_started: ${SESSION}"
