#!/usr/bin/env bash
set -euo pipefail

ROOT="${ROOT:-/home/dev/Project_Me}"
SESSION="${TMUX_SESSION_NAME:-asdev-max}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if ! command -v tmux >/dev/null 2>&1; then
  echo "tmux not installed"
  exit 1
fi

if tmux has-session -t "$SESSION" 2>/dev/null; then
  echo "session_exists $SESSION"
  exit 0
fi

tmux new-session -d -s "$SESSION" -n "orchestrator" "cd $ROOT && ${SCRIPT_DIR}/status-autonomous-executor.sh; bash"
tmux new-window -t "$SESSION" -n "pipelines-max" "cd $ROOT && ${SCRIPT_DIR}/../pipelines/run-priority-pipelines-max.sh; bash"
tmux new-window -t "$SESSION" -n "reports" "cd $ROOT && watch -n 5 'ls -lt asdev-standards-platform/docs/reports | head -n 20'; bash"
tmux new-window -t "$SESSION" -n "logs" "cd $ROOT && tail -f asdev-standards-platform/var/autonomous-executor/logs/autonomous-executor.log"

echo "tmux_session_started $SESSION"
