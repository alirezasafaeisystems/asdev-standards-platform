#!/usr/bin/env bash
set -euo pipefail
ROOT="${ROOT:-/home/dev/Project_Me}"
HUB="$ROOT/asdev-standards-platform"
STATE_DIR="$HUB/var/autonomous-executor/state"
PID_FILE="$STATE_DIR/pid"
STOP_FILE="$STATE_DIR/stop"

mkdir -p "$STATE_DIR"
touch "$STOP_FILE"

if [[ -f "$PID_FILE" ]]; then
  pid="$(cat "$PID_FILE" || true)"
  echo "stop_signal_sent pid=${pid:-unknown}"
else
  echo "stop_signal_sent pid=none"
fi
