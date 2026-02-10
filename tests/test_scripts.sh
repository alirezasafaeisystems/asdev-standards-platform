#!/usr/bin/env bash
set -euo pipefail

bash -n platform/scripts/sync.sh
bash -n platform/scripts/divergence-report.sh
bash tests/test_sync_behavior.sh
bash tests/test_sync_pr_label_fallback.sh
bash tests/test_divergence_report_columns.sh
bash tests/test_divergence_report_combined.sh
bash tests/test_divergence_report_combined_target_glob.sh
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
bash tests/test_weekly_digest_repo_config_contract.sh
bash tests/test_sync_untracked_detection.sh
bash tests/test_target_template_validation.sh
bash tests/test_template_version_policy.sh
bash tests/test_monthly_release_repo_config_contract.sh
bash tests/test_make_ci_target.sh
bash tests/test_make_reports_target.sh
bash tests/test_summarize_clone_failed.sh
bash tests/test_ci_workflow_contract.sh
bash tests/test_detect_meaningful_report_delta.sh
bash tests/test_status_counter_contract.sh
bash tests/test_clone_failed_summary_contract.sh
bash tests/test_reports_attestation_contract.sh
bash tests/test_digest_stale_cleanup_workflow.sh
bash tests/test_make_digest_cleanup_dry_run_target.sh
bash tests/test_make_digest_cleanup_no_open_digest.sh
bash tests/test_make_ci_last_run_target.sh
bash tests/test_make_ci_last_run_fallback.sh
bash tests/test_make_ci_last_run_compact_target.sh
bash tests/test_make_ci_last_run_compact_fallback.sh
bash scripts/validate-agent-pack.sh

echo "Script checks passed."
