#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../../.." && pwd)"
source "${REPO_ROOT}/scripts/lib/codex-automation-config.sh"

ROOT="${ROOT:-$(cfg_workspace_root)}"
HUB_REPO="$(cfg_hub_repo)"
HUB="${ROOT}/${HUB_REPO}"
TODAY="$(date +%F)"
NOW_UTC="$(date -u +'%Y-%m-%d %H:%M:%S UTC')"

REPORTS_REL="$(cfg_get '.paths.reports_dir' 'var/automation/reports')"
PIPELINE_LOG_REL="$(cfg_get '.paths.pipeline_log_dir' 'var/automation/pipelines')"
REPORT_DIR="${HUB}/${REPORTS_REL}"
LOG_DIR="${HUB}/${PIPELINE_LOG_REL}/default-${TODAY}"
mkdir -p "${REPORT_DIR}" "${LOG_DIR}"
REPORT="${REPORT_DIR}/PRIORITY_PIPELINE_RUN_${TODAY}.md"

repos=(
  "asdev-portfolio"
  "asdev-persiantoolbox"
  "asdev-family-rosca"
  "asdev-nexa-vpn"
  "asdev-creator-membership-ir"
  "asdev-automation-hub"
  "asdev-standards-platform"
  "asdev-codex-reviewer"
)

{
  echo "# Priority Pipeline Run (${TODAY})"
  echo
  echo "- Executed (UTC): ${NOW_UTC}"
  echo
  echo "| Repo | Command | Exit |"
  echo "|---|---|---:|"
} > "${REPORT}"

run_cmd() {
  local repo="$1"
  local cmd="$2"
  local log_file="${LOG_DIR}/${repo//\//_}.log"
  set +e
  (cd "${ROOT}/${repo}" && bash -lc "${cmd}") > "${log_file}" 2>&1
  local ec=$?
  set -e
  printf '| %s | `%s` | %s |\n' "${repo}" "${cmd}" "${ec}" >> "${REPORT}"
}

for repo in "${repos[@]}"; do
  case "${repo}" in
    asdev-standards-platform)
      run_cmd "${repo}" "find platform/scripts scripts -type f -name '*.sh' -print0 | xargs -0 -n1 bash -n && git rev-parse --is-inside-work-tree >/dev/null"
      ;;
    asdev-portfolio|asdev-persiantoolbox|asdev-family-rosca|asdev-nexa-vpn|asdev-creator-membership-ir|asdev-automation-hub|asdev-codex-reviewer)
      run_cmd "${repo}" "git rev-parse --is-inside-work-tree >/dev/null && git status --porcelain >/dev/null"
      ;;
  esac
done

{
  echo
  echo "## Logs"
  echo
  for repo in "${repos[@]}"; do
    log_file="${LOG_DIR}/${repo//\//_}.log"
    if [[ -f "${log_file}" ]]; then
      echo "### ${repo}"
      echo '```text'
      tail -n 40 "${log_file}"
      echo '```'
      echo
    fi
  done
} >> "${REPORT}"

echo "Pipeline run report: ${REPORT}"
