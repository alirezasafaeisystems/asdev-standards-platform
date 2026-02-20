#!/usr/bin/env bash
set -euo pipefail

bash scripts/generate-weekly-kpi-summary.sh

summary="docs/reports/WEEKLY_COMPLIANCE_SUMMARY.md"
[[ -f "$summary" ]] || { echo "missing summary"; exit 1; }
grep -q '^# Weekly Compliance Summary' "$summary" || { echo "missing heading"; exit 1; }
grep -q '^- compliance_score: ' "$summary" || { echo "missing score"; exit 1; }

echo "weekly KPI summary checks passed."
