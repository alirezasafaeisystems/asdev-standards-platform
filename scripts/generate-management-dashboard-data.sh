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
  find "${REPORTS_DIR}" -maxdepth 1 -type f -name "${prefix}*${suffix}" -print 2>/dev/null | sort | tail -n 1 || true
}

esc() {
  printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'
}

readiness_file="$(latest_file "PRODUCTION_READINESS_SCORE_" ".md")"
p0_file="$(latest_file "P0_STABILIZATION_" ".md")"
queue_file="$(latest_file "ROADMAP_TASK_QUEUE_" ".csv")"
priority_tasks_file="$(latest_file "ROADMAP_PRIORITY_TASKS_" ".md")"
priority_file="$(latest_file "PRIORITY_EXECUTION_RUN_" ".md")"
autopilot_file="${REPORTS_DIR}/AUTOPILOT_EXECUTION_REPORT.md"
autonomous_max_file="${REPORTS_DIR}/AUTONOMOUS_MAX_STATUS.md"
remaining_file="$(latest_file "REMAINING_EXECUTION_AUTORUN_" ".md")"
weekly_file="${REPORTS_DIR}/WEEKLY_COMPLIANCE_SUMMARY.md"
roadmap_file="${ROOT_DIR}/ROADMAP_EXECUTION_UNIFIED.md"

[[ -f "$roadmap_file" ]] || {
  echo "Missing roadmap source: ${roadmap_file}" >&2
  exit 1
}

# Queue metrics and priority distribution
queue_priorities_tmp="$(mktemp)"
if [[ -n "${queue_file}" && -f "${queue_file}" ]]; then
  queue_todo="$(awk -F',' 'NR>1{gsub(/"/,"",$5); if ($5=="todo") c++} END{print c+0}' "$queue_file")"
  queue_done="$(awk -F',' 'NR>1{gsub(/"/,"",$5); if ($5=="done") c++} END{print c+0}' "$queue_file")"
  awk -F',' 'NR>1{gsub(/"/,"",$2); gsub(/"/,"",$5); p=$2; s=$5; if(s=="todo") c[p]++} END{for (k in c) printf "%s,%d\n", k, c[k]}' "$queue_file" | sort > "$queue_priorities_tmp"
else
  queue_todo="$(awk '/^- \[ \]/{c++} END{print c+0}' "$roadmap_file")"
  queue_done="$(awk '/^- \[[xX]\]/{c++} END{print c+0}' "$roadmap_file")"
  if [[ -n "${priority_tasks_file}" && -f "${priority_tasks_file}" ]]; then
    p0_sum="$(awk -F'|' '/^\|/{c2=$3; gsub(/ /,"",c2); if (c2 ~ /^[0-9]+$/) s+=c2} END{print s+0}' "$priority_tasks_file")"
    p1_sum="$(awk -F'|' '/^\|/{c3=$4; gsub(/ /,"",c3); if (c3 ~ /^[0-9]+$/) s+=c3} END{print s+0}' "$priority_tasks_file")"
    p2_sum="$(awk -F'|' '/^\|/{c4=$5; gsub(/ /,"",c4); if (c4 ~ /^[0-9]+$/) s+=c4} END{print s+0}' "$priority_tasks_file")"
    {
      printf "P0,%s\n" "$p0_sum"
      printf "P1,%s\n" "$p1_sum"
      printf "P2,%s\n" "$p2_sum"
    } > "$queue_priorities_tmp"
  else
    {
      printf "P0,0\n"
      printf "P1,0\n"
      printf "P2,0\n"
    } > "$queue_priorities_tmp"
  fi
fi

# Readiness values
readiness_avg="n/a"
readiness_rows_tmp="$(mktemp)"
if [[ -n "${readiness_file}" && -f "${readiness_file}" ]]; then
  readiness_avg="$(awk -F': ' '/Average readiness score:/ {print $2; exit}' "$readiness_file" | tr -d '[:space:]')"
  [[ -n "${readiness_avg}" ]] || readiness_avg="n/a"
  awk -F'|' '/^\|/ {repo=$2; exitc=$3; rd=$4; sc=$5; gsub(/^ +| +$/, "", repo); gsub(/^ +| +$/, "", exitc); gsub(/^ +| +$/, "", rd); gsub(/^ +| +$/, "", sc); if (repo!="Repo" && repo!="---" && exitc ~ /^[0-9]+$/ && sc ~ /^[0-9]+$/) {printf "%s\t%s\t%s\t%s\n", repo, exitc, rd, sc}}' "$readiness_file" > "$readiness_rows_tmp"
else
  if [[ -f "${weekly_file}" ]]; then
    compliance_score="$(awk -F': ' '/- compliance_score:/ {print $2; exit}' "$weekly_file" | tr -d '[:space:]')"
  else
    compliance_score=""
  fi
  if [[ -z "${compliance_score}" || ! "${compliance_score}" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
    compliance_score="0"
  fi
  readiness_avg="$compliance_score"
  readiness_score_int="$(printf '%.0f' "$compliance_score" 2>/dev/null || echo 0)"
  printf 'asdev-standards-platform\t0\toperational-maintenance\t%s\n' "$readiness_score_int" > "$readiness_rows_tmp"
fi

# P0 checklist rows
p0_rows_tmp="$(mktemp)"
if [[ -n "${p0_file}" && -f "${p0_file}" ]]; then
  awk -F'|' '/^\|/ {c=$2; s=$3; gsub(/^ +| +$/, "", c); gsub(/^ +| +$/, "", s); if (c!="Check" && c!="---" && s!="") printf "%s\t%s\n", c, s}' "$p0_file" > "$p0_rows_tmp"
elif [[ -n "${remaining_file}" && -f "${remaining_file}" ]]; then
  ns01_status="$(awk -F'|' '/^\| NS-01 /{s=$3; gsub(/^ +| +$/, "", s); print s; exit}' "$remaining_file")"
  ns02_status="$(awk -F'|' '/^\| NS-02 /{s=$3; gsub(/^ +| +$/, "", s); print s; exit}' "$remaining_file")"
  ns03_status="$(awk -F'|' '/^\| NS-03 /{s=$3; gsub(/^ +| +$/, "", s); print s; exit}' "$remaining_file")"
  [[ "${ns01_status}" == "done" ]] && ns01_status="PASS" || ns01_status="FAIL"
  [[ "${ns02_status}" == "done" ]] && ns02_status="PASS" || ns02_status="FAIL"
  [[ "${ns03_status}" == "done" ]] && ns03_status="PASS" || ns03_status="FAIL"
  {
    printf 'PR Check Audit (strict)\t%s\n' "$ns01_status"
    printf 'Release Post Check\t%s\n' "$ns02_status"
    printf 'Roadmap Maintenance Transition\t%s\n' "$ns03_status"
  } > "$p0_rows_tmp"
else
  printf 'Roadmap Status\tUNKNOWN\n' > "$p0_rows_tmp"
fi

# Priority steps rows
priority_rows_tmp="$(mktemp)"
if [[ -n "${priority_file}" && -f "${priority_file}" ]]; then
  awk -F'|' '/^\|/ {c=$2; s=$3; gsub(/^ +| +$/, "", c); gsub(/^ +| +$/, "", s); if (c!="Step" && c!="---" && s!="") printf "%s\t%s\n", c, s}' "$priority_file" > "$priority_rows_tmp"
elif [[ -n "${remaining_file}" && -f "${remaining_file}" ]]; then
  awk -F'|' '/^\| NS-/{id=$2; st=$3; gsub(/^ +| +$/, "", id); gsub(/^ +| +$/, "", st); if (id!="") printf "%s\t%s\n", id, st}' "$remaining_file" > "$priority_rows_tmp"
else
  printf 'Operational Backlog\tno-priority-report\n' > "$priority_rows_tmp"
fi

# Autopilot summary
autopilot_stamp="n/a"
autopilot_phase="n/a"
autopilot_success="0"
autopilot_failed="0"
autopilot_source=""

if [[ -f "$autopilot_file" ]]; then
  autopilot_stamp="$(awk '/^## /{val=substr($0,4)} END{print val}' "$autopilot_file")"
  autopilot_phase="$(awk -F': ' '/phase_state:/ {val=$2} END{print val}' "$autopilot_file" | sed 's/^ *//; s/ *$//')"
  autopilot_success="$(awk -F': ' '/success_count:/ {val=$2} END{print val}' "$autopilot_file" | tr -d '[:space:]')"
  autopilot_failed="$(awk -F': ' '/failed_count:/ {val=$2} END{print val}' "$autopilot_file" | tr -d '[:space:]')"
  autopilot_source="docs/reports/$(basename "$autopilot_file")"
elif [[ -f "$autonomous_max_file" ]]; then
  autopilot_stamp="$(awk -F': ' '/- generated_at_utc:/ {print $2; exit}' "$autonomous_max_file" | tr -d '[:space:]')"
  autopilot_phase="$(awk -F': ' '/- overall_status:/ {print $2; exit}' "$autonomous_max_file" | tr -d '[:space:]')"
  autopilot_success="$(awk -F': ' '/- passed_steps:/ {print $2; exit}' "$autonomous_max_file" | tr -d '[:space:]')"
  req_fail="$(awk -F': ' '/- required_failures:/ {print $2; exit}' "$autonomous_max_file" | tr -d '[:space:]')"
  opt_fail="$(awk -F': ' '/- optional_failures:/ {print $2; exit}' "$autonomous_max_file" | tr -d '[:space:]')"
  req_fail="${req_fail:-0}"
  opt_fail="${opt_fail:-0}"
  if [[ "$req_fail" =~ ^[0-9]+$ && "$opt_fail" =~ ^[0-9]+$ ]]; then
    autopilot_failed=$((req_fail + opt_fail))
  fi
  autopilot_source="docs/reports/$(basename "$autonomous_max_file")"
fi

[[ -n "$autopilot_stamp" ]] || autopilot_stamp="n/a"
[[ -n "$autopilot_phase" ]] || autopilot_phase="n/a"
[[ "$autopilot_success" =~ ^[0-9]+$ ]] || autopilot_success="0"
[[ "$autopilot_failed" =~ ^[0-9]+$ ]] || autopilot_failed="0"

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
  first=1
  add_source() {
    local src="$1"
    [[ -z "$src" ]] && return
    [[ $first -eq 0 ]] && echo ","
    first=0
    printf '    "%s"' "$src"
  }

  if [[ -n "${readiness_file}" && -f "${readiness_file}" ]]; then
    add_source "docs/reports/$(basename "$readiness_file")"
  elif [[ -f "${weekly_file}" ]]; then
    add_source "docs/reports/$(basename "$weekly_file")"
  fi

  if [[ -n "${p0_file}" && -f "${p0_file}" ]]; then
    add_source "docs/reports/$(basename "$p0_file")"
  elif [[ -n "${remaining_file}" && -f "${remaining_file}" ]]; then
    add_source "docs/reports/$(basename "$remaining_file")"
  fi

  if [[ -n "${priority_file}" && -f "${priority_file}" ]]; then
    add_source "docs/reports/$(basename "$priority_file")"
  elif [[ -n "${remaining_file}" && -f "${remaining_file}" ]]; then
    add_source "docs/reports/$(basename "$remaining_file")"
  fi

  if [[ -n "${queue_file}" && -f "${queue_file}" ]]; then
    add_source "docs/reports/$(basename "$queue_file")"
  elif [[ -n "${priority_tasks_file}" && -f "${priority_tasks_file}" ]]; then
    add_source "docs/reports/$(basename "$priority_tasks_file")"
  else
    add_source "ROADMAP_EXECUTION_UNIFIED.md"
  fi

  add_source "$autopilot_source"

  echo
  echo "  ]"
  echo "}"
} > "$OUT_FILE"

rm -f "$queue_priorities_tmp" "$readiness_rows_tmp" "$p0_rows_tmp" "$priority_rows_tmp"

echo "dashboard_data:${OUT_FILE}"
