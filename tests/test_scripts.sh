#!/usr/bin/env bash
set -euo pipefail

bash -n platform/scripts/sync.sh
bash -n platform/scripts/divergence-report.sh
bash tests/test_sync_behavior.sh
bash tests/test_divergence_report_columns.sh
bash tests/test_sync_untracked_detection.sh
bash tests/test_target_template_validation.sh

echo "Script checks passed."
