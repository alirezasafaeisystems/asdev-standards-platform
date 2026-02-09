SHELL := /bin/bash

.PHONY: setup lint test run

setup:
	@command -v git >/dev/null || (echo "git is required" && exit 1)
	@command -v gh >/dev/null || (echo "gh is required" && exit 1)
	@YQ_BIN="$$(bash scripts/ensure-yq.sh)" && echo "yq ready: $$YQ_BIN"
	@echo "Setup complete."

lint:
	@bash -n platform/scripts/sync.sh
	@bash -n platform/scripts/divergence-report.sh
	@bash -n platform/scripts/divergence-report-combined.sh
	@bash -n scripts/monthly-release.sh
	@bash -n scripts/generate-dashboard.sh
	@bash -n scripts/validate-target-template-ids.sh
	@bash -n scripts/validate-template-version-policy.sh
	@bash -n scripts/weekly-governance-digest.sh
	@bash -n scripts/classify-divergence-error.sh
	@bash -n scripts/retry-cmd.sh
	@bash -n scripts/rotate-report-snapshots.sh
	@bash -n scripts/generate-error-fingerprint-trend.sh
	@bash -n scripts/close-stale-weekly-digests.sh
	@bash -n scripts/validate-generated-reports.sh
	@bash -n scripts/summarize-error-fingerprint-trend.sh
	@bash -n scripts/write-report-attestation.sh
	@bash -n scripts/validate-report-attestation.sh
	@echo "Lint checks passed."

test:
	@YQ_BIN="$$(bash scripts/ensure-yq.sh)" && PATH="$$(dirname "$$YQ_BIN"):$$PATH" bash scripts/validate-target-template-ids.sh
	@bash tests/test_scripts.sh

run:
	@echo "ASDEV Platform is a standards/governance repository; use scripts under platform/scripts/."
