#!/usr/bin/env bash
set -euo pipefail

bash scripts/generate-compliance-report.sh
bash scripts/update-compliance-history.sh
bash scripts/generate-weekly-kpi-summary.sh
bash scripts/generate-monthly-executive-summary.sh
bash scripts/write-compliance-attestation.sh docs/compliance-dashboard/attestation.json
bash scripts/validate-compliance-attestation.sh docs/compliance-dashboard/attestation.json

echo "compliance attestation checks passed."
