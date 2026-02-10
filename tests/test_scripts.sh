#!/usr/bin/env bash
set -euo pipefail

bash -n platform/scripts/sync.sh
bash -n platform/scripts/divergence-report.sh
bash tests/test_sync_behavior.sh
bash tests/test_divergence_report_columns.sh
bash tests/test_divergence_report_combined.sh
bash tests/test_divergence_error_fingerprint.sh
bash tests/test_retry_cmd.sh
bash tests/test_error_fingerprint_trend.sh
bash tests/test_validate_generated_reports.sh
bash tests/test_report_attestation.sh
bash tests/test_rotate_report_snapshots_retention.sh
bash tests/test_summarize_error_fingerprint_trend.sh
bash tests/test_close_stale_weekly_digests.sh
bash tests/test_close_stale_report_update_prs.sh
bash tests/test_dashboard_reliability.sh
bash tests/test_weekly_digest_contract.sh
bash tests/test_sync_untracked_detection.sh
bash tests/test_target_template_validation.sh
bash tests/test_template_version_policy.sh
bash tests/test_make_ci_target.sh
bash tests/test_make_reports_target.sh
bash tests/test_summarize_clone_failed.sh

echo "Script checks passed."
