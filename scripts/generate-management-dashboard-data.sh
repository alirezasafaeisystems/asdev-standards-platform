#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REPORTS_DIR="${ROOT_DIR}/docs/reports"
OUT_FILE="${ROOT_DIR}/docs/dashboard/data.json"
NOW_UTC="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

mkdir -p "$(dirname "$OUT_FILE")"

latest_file() {
  local prefix="$1"
  local suffix="$2"
  ls -1 "${REPORTS_DIR}/${prefix}"*"${suffix}" 2>/dev/null | sort | tail -n 1
}

esc() {
  printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'
}

readiness_file="$(latest_file "PRODUCTION_READINESS_SCORE_" ".md")"
p0_file="$(latest_file "P0_STABILIZATION_" ".md")"
queue_file="$(latest_file "ROADMAP_TASK_QUEUE_" ".csv")"
priority_file="$(latest_file "PRIORITY_EXECUTION_RUN_" ".md")"
autopilot_file="${REPORTS_DIR}/AUTOPILOT_EXECUTION_REPORT.md"

if [[ -z "${readiness_file}" || -z "${p0_file}" || -z "${queue_file}" || -z "${priority_file}" || ! -f "${autopilot_file}" ]]; then
  echo "Missing dashboard source files under ${REPORTS_DIR}" >&2
  exit 1
fi

readiness_avg="$(awk -F': ' '/Average readiness score:/ {print $2; exit}' "$readiness_file" | tr -d '[:space:]')"
[[ -n "${readiness_avg}" ]] || readiness_avg="n/a"

queue_todo="$(awk -F',' 'NR>1{gsub(/"/,"",$5); if ($5=="todo") c++} END{print c+0}' "$queue_file")"
queue_done="$(awk -F',' 'NR>1{gsub(/"/,"",$5); if ($5=="done") c++} END{print c+0}' "$queue_file")"

# Priority buckets
queue_priorities_tmp="$(mktemp)"
awk -F',' 'NR>1{gsub(/"/,"",$2); gsub(/"/,"",$5); p=$2; s=$5; if(s=="todo") c[p]++} END{for (k in c) printf "%s,%d\n", k, c[k]}' "$queue_file" | sort > "$queue_priorities_tmp"

# Readiness rows
readiness_rows_tmp="$(mktemp)"
awk -F'|' '/^\|/ {repo=$2; exitc=$3; rd=$4; sc=$5; gsub(/^ +| +$/, "", repo); gsub(/^ +| +$/, "", exitc); gsub(/^ +| +$/, "", rd); gsub(/^ +| +$/, "", sc); if (repo!="Repo" && repo!="---" && exitc ~ /^[0-9]+$/ && sc ~ /^[0-9]+$/) {printf "%s\t%s\t%s\t%s\n", repo, exitc, rd, sc}}' "$readiness_file" > "$readiness_rows_tmp"

# P0 rows
p0_rows_tmp="$(mktemp)"
awk -F'|' '/^\|/ {c=$2; s=$3; gsub(/^ +| +$/, "", c); gsub(/^ +| +$/, "", s); if (c!="Check" && c!="---" && s!="") printf "%s\t%s\n", c, s}' "$p0_file" > "$p0_rows_tmp"

# Priority run rows
priority_rows_tmp="$(mktemp)"
awk -F'|' '/^\|/ {c=$2; s=$3; gsub(/^ +| +$/, "", c); gsub(/^ +| +$/, "", s); if (c!="Step" && c!="---" && s!="") printf "%s\t%s\n", c, s}' "$priority_file" > "$priority_rows_tmp"

# Autopilot latest section
autopilot_stamp="n/a"
autopilot_phase="n/a"
autopilot_success="0"
autopilot_failed="0"
if awk '/^## /{f=1} f{print}' "$autopilot_file" >/tmp/asdev_autopilot_last.txt 2>/dev/null; then
  autopilot_stamp="$(awk '/^## /{val=substr($0,4)} END{print val}' "$autopilot_file")"
  autopilot_phase="$(awk -F': ' '/phase_state:/ {val=$2} END{print val}' "$autopilot_file" | sed 's/^ *//; s/ *$//')"
  autopilot_success="$(awk -F': ' '/success_count:/ {val=$2} END{print val}' "$autopilot_file" | tr -d '[:space:]')"
  autopilot_failed="$(awk -F': ' '/failed_count:/ {val=$2} END{print val}' "$autopilot_file" | tr -d '[:space:]')"
fi
[[ -n "$autopilot_stamp" ]] || autopilot_stamp="n/a"
[[ -n "$autopilot_phase" ]] || autopilot_phase="n/a"
[[ -n "$autopilot_success" ]] || autopilot_success="0"
[[ -n "$autopilot_failed" ]] || autopilot_failed="0"

{
  echo "{"
  echo "  \"generated_at\": \"${NOW_UTC}\"," 
  echo "  \"kpis\": {"
  echo "    \"readiness_avg\": \"$(esc "$readiness_avg")\"," 
  echo "    \"roadmap_todo\": ${queue_todo},"
  echo "    \"roadmap_done\": ${queue_done},"
  echo "    \"autopilot_failed\": ${autopilot_failed}"
  echo "  },"
  echo "  \"autopilot\": {"
  echo "    \"stamp\": \"$(esc "$autopilot_stamp")\"," 
  echo "    \"phase\": \"$(esc "$autopilot_phase")\"," 
  echo "    \"success\": ${autopilot_success},"
  echo "    \"failed\": ${autopilot_failed}"
  echo "  },"

  echo "  \"p0\": ["
  first=1
  while IFS=$'\t' read -r check status; do
    [[ -z "${check}" ]] && continue
    [[ $first -eq 0 ]] && echo ","
    first=0
    printf '    {"check":"%s","status":"%s"}' "$(esc "$check")" "$(esc "$status")"
  done < "$p0_rows_tmp"
  echo
  echo "  ],"

  echo "  \"priority_steps\": ["
  first=1
  while IFS=$'\t' read -r step status; do
    [[ -z "${step}" ]] && continue
    [[ $first -eq 0 ]] && echo ","
    first=0
    printf '    {"step":"%s","status":"%s"}' "$(esc "$step")" "$(esc "$status")"
  done < "$priority_rows_tmp"
  echo
  echo "  ],"

  echo "  \"queue\": {"
  echo "    \"todo\": ${queue_todo},"
  echo "    \"done\": ${queue_done},"
  echo "    \"by_priority\": ["
  first=1
  while IFS=',' read -r pr count; do
    [[ -z "${pr}" ]] && continue
    [[ $first -eq 0 ]] && echo ","
    first=0
    printf '      {"priority":"%s","todo":%s}' "$(esc "$pr")" "$count"
  done < "$queue_priorities_tmp"
  echo
  echo "    ]"
  echo "  },"

  echo "  \"readiness\": ["
  first=1
  while IFS=$'\t' read -r repo exit_code readiness score; do
    [[ -z "${repo}" ]] && continue
    [[ $first -eq 0 ]] && echo ","
    first=0
    printf '    {"repo":"%s","exit":"%s","readiness":"%s","score":%s}' "$(esc "$repo")" "$(esc "$exit_code")" "$(esc "$readiness")" "$score"
  done < "$readiness_rows_tmp"
  echo
  echo "  ],"

  echo "  \"sources\": ["
  printf '    "%s",\n' "docs/reports/$(basename "$readiness_file")"
  printf '    "%s",\n' "docs/reports/$(basename "$p0_file")"
  printf '    "%s",\n' "docs/reports/$(basename "$priority_file")"
  printf '    "%s",\n' "docs/reports/$(basename "$queue_file")"
  printf '    "%s"\n' "docs/reports/$(basename "$autopilot_file")"
  echo "  ]"
  echo "}"
} > "$OUT_FILE"

rm -f "$queue_priorities_tmp" "$readiness_rows_tmp" "$p0_rows_tmp" "$priority_rows_tmp" /tmp/asdev_autopilot_last.txt

echo "dashboard_data:${OUT_FILE}"
