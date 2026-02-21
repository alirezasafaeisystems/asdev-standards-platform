#!/usr/bin/env bash
set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

RUN_ID="$(date -u +%Y%m%dT%H%M%SZ)"
SNAPSHOT_DIR="${REPO_ROOT}/.codex/snapshots/${RUN_ID}"
LOG_DIR="${SNAPSHOT_DIR}/logs"
CMD_LOG="${SNAPSHOT_DIR}/cmd.log"
STATUS_FILE="${SNAPSHOT_DIR}/status"
SUMMARY_FILE="${SNAPSHOT_DIR}/summary.md"
REPORT_FILE="${SNAPSHOT_DIR}/report.md"
DIFF_FILE="${SNAPSHOT_DIR}/diff"
BRANCH_FILE="${SNAPSHOT_DIR}/branch"
LAST5_FILE="${SNAPSHOT_DIR}/last5"
LATEST_REPORT="${REPO_ROOT}/docs/reports/AUTONOMOUS_MAX_STATUS.md"

mkdir -p "${LOG_DIR}"

timestamp() {
  date -u +%FT%TZ
}

record_cmd() {
  local label="$1"
  local command="$2"
  printf '%s\t%s\t%s\n' "$(timestamp)" "${label}" "${command}" >> "${CMD_LOG}"
}

run_step() {
  local label="$1"
  local command="$2"
  local required="$3"
  local log_file="${LOG_DIR}/${label}.log"
  local rc=0

  record_cmd "${label}" "${command}"
  if bash -lc "cd \"${REPO_ROOT}\" && ${command}" >"${log_file}" 2>&1; then
    rc=0
    STEP_STATE="${STEP_STATE}|\`${label}\`|pass|\`${required}\`|\`${command}\`|\`${log_file#${REPO_ROOT}/}\`|\n"
    SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
  else
    rc=$?
    if [[ "${required}" == "yes" ]]; then
      REQUIRED_FAILURES=$((REQUIRED_FAILURES + 1))
    else
      OPTIONAL_FAILURES=$((OPTIONAL_FAILURES + 1))
    fi
    STEP_STATE="${STEP_STATE}|\`${label}\`|fail|\`${required}\`|\`${command}\`|\`${log_file#${REPO_ROOT}/}\`|\n"
  fi
  TOTAL_COUNT=$((TOTAL_COUNT + 1))
  return "${rc}"
}

run_step_retry() {
  local label="$1"
  local command="$2"
  local required="$3"
  local attempts="${4:-3}"
  local delay_seconds="${5:-2}"
  local i=1

  while [[ "${i}" -le "${attempts}" ]]; do
    if run_step "${label}" "${command}" "${required}"; then
      return 0
    fi
    if [[ "${i}" -lt "${attempts}" ]]; then
      sleep "${delay_seconds}"
    fi
    i=$((i + 1))
  done
  return 1
}

SUCCESS_COUNT=0
REQUIRED_FAILURES=0
OPTIONAL_FAILURES=0
TOTAL_COUNT=0
STEP_STATE=""

cd "${REPO_ROOT}" || exit 1

run_step "hygiene" "make hygiene" "no" || true
run_step "lint" "make lint" "yes" || true
run_step "typecheck" "make typecheck" "yes" || true
run_step "test" "make test" "yes" || true
run_step "build" "make build" "yes" || true
run_step "security-audit" "make security-audit" "yes" || true
run_step "coverage" "make coverage" "yes" || true
run_step "compliance-report" "make compliance-report" "yes" || true
run_step "automation-slo-status" "make automation-slo-status" "yes" || true
run_step_retry "pr-check-evidence" "make pr-check-evidence" "no" 3 2 || true
run_step_retry "pr-check-audit" "make pr-check-audit" "no" 3 2 || true
run_step "remaining-execution" "make remaining-execution" "no" || true

EXPECTED_TAG="v$(cat VERSION 2>/dev/null || true)"
if [[ -n "${EXPECTED_TAG}" && "${EXPECTED_TAG}" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  run_step "release-post-check" "bash scripts/release/post-check.sh ${EXPECTED_TAG}" "no" || true
else
  STEP_STATE="${STEP_STATE}|\`release-post-check\`|skip|no|\`bash scripts/release/post-check.sh <latest-tag>\`|\`n/a\`|\n"
  TOTAL_COUNT=$((TOTAL_COUNT + 1))
fi

git rev-parse --abbrev-ref HEAD > "${BRANCH_FILE}" 2>/dev/null || echo "unknown" > "${BRANCH_FILE}"
git log --oneline -n 5 > "${LAST5_FILE}" 2>/dev/null || true
git diff > "${DIFF_FILE}" 2>/dev/null || true

OVERALL_STATUS="pass"
if [[ "${REQUIRED_FAILURES}" -gt 0 ]]; then
  OVERALL_STATUS="fail"
fi

{
  echo "generated_at_utc=$(timestamp)"
  echo "run_id=${RUN_ID}"
  echo "overall_status=${OVERALL_STATUS}"
  echo "total_steps=${TOTAL_COUNT}"
  echo "passed_steps=${SUCCESS_COUNT}"
  echo "required_failures=${REQUIRED_FAILURES}"
  echo "optional_failures=${OPTIONAL_FAILURES}"
  echo "snapshot_dir=${SNAPSHOT_DIR#${REPO_ROOT}/}"
} > "${STATUS_FILE}"

{
  echo "# Autonomous Max Summary"
  echo
  echo "- generated_at_utc: $(timestamp)"
  echo "- run_id: ${RUN_ID}"
  echo "- overall_status: ${OVERALL_STATUS}"
  echo "- total_steps: ${TOTAL_COUNT}"
  echo "- passed_steps: ${SUCCESS_COUNT}"
  echo "- required_failures: ${REQUIRED_FAILURES}"
  echo "- optional_failures: ${OPTIONAL_FAILURES}"
  echo "- snapshot_dir: \`${SNAPSHOT_DIR#${REPO_ROOT}/}\`"
  echo
  echo "| Step | Result | Required | Command | Log |"
  echo "|---|---|---|---|---|"
  printf '%b' "${STEP_STATE}"
} > "${SUMMARY_FILE}"

cp "${SUMMARY_FILE}" "${REPORT_FILE}"
cp "${SUMMARY_FILE}" "${LATEST_REPORT}"

echo "Autonomous max run completed: ${SNAPSHOT_DIR}"
echo "Summary report: ${LATEST_REPORT}"

if [[ "${OVERALL_STATUS}" == "fail" ]]; then
  exit 1
fi
