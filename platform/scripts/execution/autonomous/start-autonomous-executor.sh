#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="${ROOT:-/home/dev/Project_Me}"
HUB="${ROOT}/asdev-standards-platform"
RUNTIME_DIR="$HUB/var/autonomous-executor"
LOG_DIR="$RUNTIME_DIR/logs"
STATE_DIR="$RUNTIME_DIR/state"
PID_FILE="$STATE_DIR/pid"
OUT_LOG="$LOG_DIR/runner.out"

mkdir -p "$LOG_DIR" "$STATE_DIR"

if [[ -f "$PID_FILE" ]]; then
  old_pid="$(cat "$PID_FILE" || true)"
  if [[ -n "$old_pid" ]] && kill -0 "$old_pid" 2>/dev/null; then
    echo "already_running pid=$old_pid"
    exit 0
  fi
fi

nohup "${SCRIPT_DIR}/autonomous-executor.sh" >> "$OUT_LOG" 2>&1 &
new_pid=$!
printf '%s\n' "$new_pid" > "$PID_FILE"
echo "started pid=$new_pid log=$OUT_LOG"
