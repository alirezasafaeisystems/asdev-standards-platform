#!/usr/bin/env bash
set -euo pipefail

ROOT="${ROOT:-/home/dev/Project_Me}"
HUB="$ROOT/asdev-standards-platform"
SCRIPTS_ROOT="$HUB/platform/scripts"
EXEC_ROOT="$SCRIPTS_ROOT/execution"
TPL="$HUB/ops/systemd/user/asdev-autonomous-executor.service.tpl"
ENV_FILE="$HUB/ops/autonomous-executor.env"
TARGET_DIR="$HOME/.config/systemd/user"
TARGET_UNIT="$TARGET_DIR/asdev-autonomous-executor.service"
DATE_UTC="$(date -u +'%Y-%m-%d %H:%M:%S UTC')"
DATE_LOCAL="$(date +%F)"
REPORT="$HUB/docs/reports/AUTONOMOUS_STACK_SYNC_${DATE_LOCAL}.md"

mkdir -p "$TARGET_DIR"

if [[ ! -f "$TPL" ]]; then
  echo "missing template: $TPL" >&2
  exit 1
fi
if [[ ! -f "$ENV_FILE" ]]; then
  echo "missing env file: $ENV_FILE" >&2
  exit 1
fi

# Ensure script permissions are correct.
find "$EXEC_ROOT" -type f -name '*.sh' -exec chmod +x {} \;
find "$SCRIPTS_ROOT" -maxdepth 1 -type f -name '*.sh' -exec chmod +x {} \;

# Render and sync systemd unit.
sed "s#{{ROOT}}#${ROOT}#g" "$TPL" > "$TARGET_UNIT"

systemctl --user daemon-reload
systemctl --user enable --now asdev-autonomous-executor.service >/dev/null 2>&1 || true
systemctl --user restart asdev-autonomous-executor.service >/dev/null 2>&1 || true

# Validate shell syntax for all execution scripts.
SYNTAX_OK=true
while IFS= read -r f; do
  if ! bash -n "$f"; then
    SYNTAX_OK=false
  fi
done < <(find "$EXEC_ROOT" -type f -name '*.sh' | sort)

SERVICE_STATE="$(systemctl --user is-active asdev-autonomous-executor.service 2>/dev/null || echo unknown)"
SERVICE_ENABLED="$(systemctl --user is-enabled asdev-autonomous-executor.service 2>/dev/null || echo unknown)"

{
  echo "# Autonomous Stack Sync (${DATE_LOCAL})"
  echo
  echo "- Generated: ${DATE_UTC}"
  echo "- Root: ${ROOT}"
  echo "- Service unit: ${TARGET_UNIT}"
  echo "- Service state: ${SERVICE_STATE}"
  echo "- Service enabled: ${SERVICE_ENABLED}"
  echo "- Syntax validation: ${SYNTAX_OK}"
  echo
  echo "## Canonical Execution Scripts"
  find "$EXEC_ROOT" -type f -name '*.sh' | sed "s#${HUB}/##" | sort | sed 's/^/- `/' | sed 's/$/`/'
  echo
  echo "## Compatibility Wrappers"
  find "$SCRIPTS_ROOT" -maxdepth 1 -type f -name '*.sh' | sed "s#${HUB}/##" | sort | sed 's/^/- `/' | sed 's/$/`/'
  echo
  echo "## Systemd Unit (Rendered)"
  echo '```ini'
  cat "$TARGET_UNIT"
  echo '```'
} > "$REPORT"

echo "synced stack; report: $REPORT"
