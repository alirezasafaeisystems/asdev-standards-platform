#!/usr/bin/env bash
set -euo pipefail

python3 tools/generate_compliance_report.py \
  --repo asdev-standards-platform \
  --logs-dir logs \
  --output-json docs/compliance-dashboard/report.json \
  --output-csv docs/compliance-dashboard/report.csv

echo "Compliance report generated."
