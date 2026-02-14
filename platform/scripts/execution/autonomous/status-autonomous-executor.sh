#!/usr/bin/env bash
set -euo pipefail
ROOT="${ROOT:-/home/dev/Project_Me}"
HUB="$ROOT/asdev-standards-platform"
STATE_DIR="$HUB/var/autonomous-executor/state"
LOG_DIR="$HUB/var/autonomous-executor/logs"
PID_FILE="$STATE_DIR/pid"
MAIN_LOG="$LOG_DIR/autonomous-executor.log"

if [[ -f "$PID_FILE" ]]; then
  pid="$(cat "$PID_FILE" || true)"
  if [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null; then
    echo "running pid=$pid"
  else
    echo "stale_pid=$pid"
  fi
else
  echo "not_running"
fi

if [[ -f "$MAIN_LOG" ]]; then
  echo "---"
  tail -n 20 "$MAIN_LOG"
fi
