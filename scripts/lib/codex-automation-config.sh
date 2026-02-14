#!/usr/bin/env bash

_AUTOMATION_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AUTOMATION_REPO_ROOT="$(cd "${_AUTOMATION_LIB_DIR}/../.." && pwd)"
AUTOMATION_CONFIG_FILE="${AUTOMATION_CONFIG_FILE:-${AUTOMATION_REPO_ROOT}/ops/automation/codex-automation.yaml}"

if [[ ! -f "${AUTOMATION_CONFIG_FILE}" ]]; then
  echo "Missing automation config: ${AUTOMATION_CONFIG_FILE}" >&2
  return 1 2>/dev/null || exit 1
fi

AUTOMATION_YQ_BIN="$("${AUTOMATION_REPO_ROOT}/scripts/ensure-yq.sh")"
PATH="$(dirname "${AUTOMATION_YQ_BIN}"):${PATH}"

cfg_get() {
  local expr="$1"
  local default_value="${2:-}"
  local value

  value="$("${AUTOMATION_YQ_BIN}" e -r "${expr}" "${AUTOMATION_CONFIG_FILE}" 2>/dev/null || true)"
  if [[ -z "${value}" || "${value}" == "null" ]]; then
    printf '%s\n' "${default_value}"
    return
  fi

  printf '%s\n' "${value}"
}

cfg_workspace_root() {
  cfg_get '.workspace.root' '/home/dev/Project_Me'
}

cfg_hub_repo() {
  cfg_get '.workspace.hub_repo' 'asdev-standards-platform'
}

cfg_task_lines_tsv() {
  "${AUTOMATION_YQ_BIN}" e -r '.autopilot.tasks[] | [.id, .mode, .repo_path, .command, (.fix_command // "-")] | @tsv' "${AUTOMATION_CONFIG_FILE}"
}
