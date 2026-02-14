#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../../.." && pwd)"
source "${REPO_ROOT}/scripts/lib/codex-automation-config.sh"

ROOT="${ROOT:-$(cfg_workspace_root)}"
HUB_REPO="$(cfg_hub_repo)"
HUB="${ROOT}/${HUB_REPO}"

SCRIPTS_ROOT="${HUB}/platform/scripts"
EXEC_ROOT="${SCRIPTS_ROOT}/execution"
TPL="${HUB}/ops/systemd/user/asdev-autonomous-executor.service.tpl"
CONFIG_FILE="${HUB}/ops/automation/codex-automation.yaml"
TARGET_DIR="${HOME}/.config/systemd/user"
TARGET_UNIT="${TARGET_DIR}/asdev-autonomous-executor.service"

REPORTS_REL="$(cfg_get '.paths.reports_dir' 'var/automation/reports')"
REPORT_DIR="${HUB}/${REPORTS_REL}"
DATE_UTC="$(date -u +'%Y-%m-%d %H:%M:%S UTC')"
DATE_LOCAL="$(date +%F)"
REPORT="${REPORT_DIR}/AUTONOMOUS_STACK_SYNC_${DATE_LOCAL}.md"

mkdir -p "${TARGET_DIR}" "${REPORT_DIR}"

if [[ ! -f "${TPL}" ]]; then
  echo "missing template: ${TPL}" >&2
  exit 1
fi
if [[ ! -f "${CONFIG_FILE}" ]]; then
  echo "missing config file: ${CONFIG_FILE}" >&2
  exit 1
fi

find "${EXEC_ROOT}" -type f -name '*.sh' -exec chmod +x {} \;
find "${SCRIPTS_ROOT}" -maxdepth 1 -type f -name '*.sh' -exec chmod +x {} \;

sed "s#{{ROOT}}#${ROOT}#g" "${TPL}" > "${TARGET_UNIT}"

systemctl --user daemon-reload
systemctl --user enable --now asdev-autonomous-executor.service >/dev/null 2>&1 || true
systemctl --user restart asdev-autonomous-executor.service >/dev/null 2>&1 || true

SYNTAX_OK=true
while IFS= read -r f; do
  if ! bash -n "${f}"; then
    SYNTAX_OK=false
  fi
done < <(find "${EXEC_ROOT}" -type f -name '*.sh' | sort)

SERVICE_STATE="$(systemctl --user is-active asdev-autonomous-executor.service 2>/dev/null || echo unknown)"
SERVICE_ENABLED="$(systemctl --user is-enabled asdev-autonomous-executor.service 2>/dev/null || echo unknown)"

{
  echo "# Autonomous Stack Sync (${DATE_LOCAL})"
  echo
  echo "- Generated: ${DATE_UTC}"
  echo "- Root: ${ROOT}"
  echo "- Config: ${CONFIG_FILE}"
  echo "- Service unit: ${TARGET_UNIT}"
  echo "- Service state: ${SERVICE_STATE}"
  echo "- Service enabled: ${SERVICE_ENABLED}"
  echo "- Syntax validation: ${SYNTAX_OK}"
  echo
  echo "## Canonical Execution Scripts"
  find "${EXEC_ROOT}" -type f -name '*.sh' | sed "s#${HUB}/##" | sort | sed 's/^/- `/' | sed 's/$/`/'
  echo
  echo "## Compatibility Wrappers"
  find "${SCRIPTS_ROOT}" -maxdepth 1 -type f -name '*.sh' | sed "s#${HUB}/##" | sort | sed 's/^/- `/' | sed 's/$/`/'
  echo
  echo "## Systemd Unit (Rendered)"
  echo '```ini'
  cat "${TARGET_UNIT}"
  echo '```'
} > "${REPORT}"

echo "synced stack; report: ${REPORT}"
