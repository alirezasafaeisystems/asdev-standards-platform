#!/usr/bin/env bash
set -euo pipefail

bash scripts/generate-compliance-report.sh
bash scripts/update-compliance-history.sh
bash scripts/generate-monthly-executive-summary.sh

summary="docs/reports/MONTHLY_EXECUTIVE_SUMMARY.md"
[[ -f "$summary" ]] || { echo "missing monthly summary"; exit 1; }
grep -q '^# Monthly Executive Summary' "$summary" || { echo "missing heading"; exit 1; }
grep -q '^- current_compliance_score: ' "$summary" || { echo "missing score"; exit 1; }

echo "monthly executive summary checks passed."
