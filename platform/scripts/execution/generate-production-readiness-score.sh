#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"
TODAY="$(date +%F)"
NOW_UTC="$(date -u +'%Y-%m-%d %H:%M:%S UTC')"
PIPELINE_REPORT="${REPO_ROOT}/docs/reports/PRIORITY_PIPELINE_MAX_${TODAY}.md"
P0_REPORT="${REPO_ROOT}/docs/reports/P0_STABILIZATION_${TODAY}.md"
OUT_REPORT="${REPO_ROOT}/docs/reports/PRODUCTION_READINESS_SCORE_${TODAY}.md"

if [[ ! -f "$PIPELINE_REPORT" ]]; then
  echo "Pipeline report missing: $PIPELINE_REPORT" >&2
  exit 1
fi

mkdir -p "${REPO_ROOT}/docs/reports"

p0_ok="no"
if [[ -f "$P0_REPORT" ]] && rg -q 'Baseline Health \(lint/typecheck/test/build\) \| PASS' "$P0_REPORT"; then
  p0_ok="yes"
fi

{
  echo "# Production Readiness Score (${TODAY})"
  echo
  echo "- Generated (UTC): ${NOW_UTC}"
  echo "- Pipeline report: docs/reports/PRIORITY_PIPELINE_MAX_${TODAY}.md"
  echo "- P0 baseline healthy: ${p0_ok}"
  echo
  echo "| Repo | Pipeline Exit | Build Readiness | Score |"
  echo "|---|---:|---|---:|"

  total=0
  count=0

  # Parse only the primary result table and ignore tail logs or binary artifacts.
  while IFS='|' read -r _ repo ec _dur _cmd _log _; do
    repo="$(echo "$repo" | xargs)"
    ec="$(echo "$ec" | xargs)"
    [[ "$repo" == asdev-* ]] || continue
    [[ "$ec" =~ ^[0-9]+$ ]] || continue
    score=40
    readiness="degraded"

    if [[ "$ec" == "0" ]]; then
      score=85
      readiness="pipeline-green"
      if [[ "$p0_ok" == "yes" ]]; then
        score=100
        readiness="ready"
      fi
    fi

    echo "| ${repo} | ${ec} | ${readiness} | ${score} |"
    total=$((total + score))
    count=$((count + 1))
  done < <(
    awk '
      BEGIN { in_table=0 }
      /^\| Repo \| Exit \| Duration\(s\) \| Command \| Log \|$/ { in_table=1; next }
      /^## Tail Logs$/ { in_table=0 }
      in_table && /^\| asdev-/ { print }
    ' "$PIPELINE_REPORT"
  )

  avg=0
  if [[ "$count" -gt 0 ]]; then
    avg=$((total / count))
  fi

  echo
  echo "## Summary"
  echo "- Repositories scored: ${count}"
  echo "- Average readiness score: ${avg}"
} > "$OUT_REPORT"

echo "Production readiness score report: $OUT_REPORT"
