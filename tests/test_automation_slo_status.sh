#!/usr/bin/env bash
set -euo pipefail

bash scripts/generate-compliance-report.sh
bash scripts/update-compliance-history.sh
bash scripts/generate-weekly-kpi-summary.sh
bash scripts/generate-monthly-executive-summary.sh
bash scripts/write-compliance-attestation.sh docs/compliance-dashboard/attestation.json
bash scripts/generate-automation-slo-status.sh

status_file="docs/reports/AUTOMATION_SLO_STATUS.md"
[[ -f "$status_file" ]] || { echo "missing automation slo status"; exit 1; }
grep -q '^# Automation SLO Status' "$status_file" || { echo "missing heading"; exit 1; }
grep -q '^- overall_status: ' "$status_file" || { echo "missing overall status"; exit 1; }
grep -q '^- compliance_artifact_attestation: ' "$status_file" || { echo "missing attestation status"; exit 1; }

echo "automation SLO status checks passed."
