#!/usr/bin/env bash
set -euo pipefail

bash scripts/generate-compliance-report.sh
bash scripts/validate-generated-reports.sh \
  docs/compliance-dashboard/report.json \
  docs/compliance-dashboard/report.csv \
  schemas/compliance-report.schema.json

echo "Compliance report generation tests passed."
