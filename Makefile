SHELL := /bin/bash

.PHONY: setup lint typecheck test e2e build coverage security-audit verify code-reviews run ci reports digest-cleanup-dry-run ci-last-run ci-last-run-json ci-last-run-compact agent-generate hygiene verify-hub fast-parallel-local autopilot-start autopilot-stop autopilot-status autopilot-install-user-service autopilot-uninstall-user-service execution-sync execution-status execution-max enforce-main-sync github-app-auth-check p0-stabilization management-dashboard management-dashboard-data remaining-execution automation-slo-status pr-check-evidence pr-check-audit release-post-check autonomous-max

setup:
	@command -v git >/dev/null || (echo "git is required" && exit 1)
	@command -v gh >/dev/null || (echo "gh is required" && exit 1)
	@YQ_BIN="$$(bash scripts/ensure-yq.sh)" && echo "yq ready: $$YQ_BIN"
	@echo "Setup complete."

lint:
	@bash -n platform/scripts/sync.sh
	@bash -n platform/scripts/divergence-report.sh
	@bash -n platform/scripts/divergence-report-combined.sh
	@python3 -m py_compile platform/scripts/generate-agent-md.py
	@rm -rf platform/scripts/__pycache__
	@bash scripts/validate-agent-pack.sh
	@bash -n scripts/monthly-release.sh
	@bash -n scripts/generate-dashboard.sh
	@bash -n scripts/validate-target-template-ids.sh
	@bash -n scripts/sanitize-public-reports.sh
	@bash -n scripts/validate-template-version-policy.sh
	@bash -n scripts/weekly-governance-digest.sh
	@bash -n scripts/management-dashboard.sh
	@bash -n scripts/generate-management-dashboard-data.sh
	@bash -n scripts/classify-divergence-error.sh
	@bash -n scripts/retry-cmd.sh
	@bash -n scripts/rotate-report-snapshots.sh
	@bash -n scripts/generate-error-fingerprint-trend.sh
	@bash -n scripts/close-stale-weekly-digests.sh
	@bash -n scripts/validate-generated-reports.sh
	@bash -n scripts/generate-compliance-report.sh
	@bash -n scripts/generate-pr-check-evidence.sh
	@bash -n scripts/audit-pr-check-emission.sh
	@bash -n scripts/update-compliance-history.sh
	@bash -n scripts/generate-weekly-kpi-summary.sh
	@bash -n scripts/generate-monthly-executive-summary.sh
	@bash -n scripts/generate-automation-slo-status.sh
	@bash -n scripts/write-compliance-attestation.sh
	@bash -n scripts/validate-compliance-attestation.sh
	@bash -n scripts/release/post-check.sh
	@bash -n scripts/summarize-error-fingerprint-trend.sh
	@bash -n scripts/write-report-attestation.sh
	@bash -n scripts/validate-report-attestation.sh
	@bash -n scripts/close-stale-report-update-prs.sh
	@bash -n scripts/summarize-clone-failed.sh
	@find platform/scripts/execution -type f -name '*.sh' -print0 | xargs -0 -n1 bash -n
	@bash -n scripts/autopilot-orchestrator.sh
	@bash -n scripts/autopilot-start.sh
	@bash -n scripts/autopilot-stop.sh
	@bash -n scripts/autopilot-install-user-service.sh
	@bash -n scripts/autopilot-uninstall-user-service.sh
	@bash -n scripts/csv-utils.sh
	@bash -n scripts/normalize-report-output.sh
	@bash -n scripts/detect-meaningful-report-delta.sh
	@bash -n scripts/sync-auth-preflight.sh
	@bash -n scripts/typecheck.sh
	@bash -n scripts/build-check.sh
	@bash -n scripts/security-audit.sh
	@bash -n scripts/check-coverage-threshold.sh
	@bash -n scripts/run-task.sh
	@bash -n scripts/repo-hygiene.sh
	@bash -n scripts/automation-freeze-guard.sh
	@bash -n scripts/enforce-main-sync-policy.sh
	@bash -n scripts/github-app-auth-guard.sh
	@bash -n scripts/p0-stabilization.sh
	@bash scripts/repo-hygiene.sh check
	@echo "Lint checks passed."

typecheck:
	@bash scripts/typecheck.sh

test:
	@YQ_BIN="$$(bash scripts/ensure-yq.sh)" && PATH="$$(dirname "$$YQ_BIN"):$$PATH" bash scripts/validate-target-template-ids.sh
	@bash tests/test_scripts.sh

e2e:
	@if [[ -x scripts/run-e2e.sh ]]; then \
		bash scripts/run-e2e.sh; \
	else \
		echo "No E2E suite configured; skipping e2e."; \
	fi

build:
	@bash scripts/build-check.sh

coverage:
	@bash scripts/check-coverage-threshold.sh

security-audit:
	@bash scripts/security-audit.sh

verify:
	@bash scripts/run-task.sh verify.lint -- make lint
	@bash scripts/run-task.sh verify.typecheck -- make typecheck
	@bash scripts/run-task.sh verify.test -- make test
	@bash scripts/run-task.sh verify.e2e -- make e2e
	@bash scripts/run-task.sh verify.build -- make build
	@bash scripts/run-task.sh verify.security-audit -- make security-audit
	@bash scripts/run-task.sh verify.coverage -- make coverage

code-reviews:
	@bash scripts/code-reviews.sh
	@$(MAKE) verify

ci:
	@$(MAKE) lint
	@bash scripts/validate-template-version-policy.sh origin/main
	@$(MAKE) test

reports:
	@bash scripts/rotate-report-snapshots.sh
	@bash platform/scripts/divergence-report.sh sync/targets.yaml platform/repo-templates/templates.yaml platform/repo-templates sync/divergence-report.csv
	@bash platform/scripts/divergence-report-combined.sh platform/repo-templates/templates.yaml platform/repo-templates sync/divergence-report.combined.csv "sync/targets*.yaml" sync/divergence-report.combined.errors.csv
	@bash scripts/generate-error-fingerprint-trend.sh sync/divergence-report.combined.errors.previous.csv sync/divergence-report.combined.errors.csv sync/divergence-report.combined.errors.trend.csv
	@bash scripts/generate-dashboard.sh docs/platform-adoption-dashboard.md
	@bash scripts/validate-generated-reports.sh sync/divergence-report.combined.csv sync/divergence-report.combined.errors.csv sync/divergence-report.combined.errors.trend.csv
	@bash scripts/write-report-attestation.sh sync/divergence-report.combined.csv sync/divergence-report.combined.errors.csv sync/divergence-report.combined.errors.trend.csv sync/generated-reports.attestation
	@bash scripts/validate-report-attestation.sh sync/divergence-report.combined.csv sync/divergence-report.combined.errors.csv sync/divergence-report.combined.errors.trend.csv sync/generated-reports.attestation

digest-cleanup-dry-run:
	@repo="$${REPO:-alirezasafaeiiidev/asdev-standards-platform}"; \
	latest_number="$$(gh issue list --repo "$$repo" --state open --search "Weekly Governance Digest in:title" --limit 1 --json number --jq '.[0].number // empty')"; \
	latest_url="$$(gh issue list --repo "$$repo" --state open --search "Weekly Governance Digest in:title" --limit 1 --json url --jq '.[0].url // empty')"; \
	if [[ -z "$$latest_number" || -z "$$latest_url" ]]; then \
		echo "No open weekly digest found for $$repo"; \
		exit 0; \
	fi; \
	summary_file="$$(mktemp)"; \
	DIGEST_STALE_DRY_RUN=true DIGEST_STALE_SUMMARY_FILE="$$summary_file" bash scripts/close-stale-weekly-digests.sh "$$repo" "$$latest_number" "$$latest_url" "Weekly Governance Digest"; \
	cat "$$summary_file"; \
	rm -f "$$summary_file"

ci-last-run:
	@repo="$${REPO:-alirezasafaeiiidev/asdev-standards-platform}"; \
	if [[ "$${GH_FORCE_MISSING:-false}" == "true" ]] || ! command -v gh >/dev/null 2>&1; then \
		echo "gh CLI is required for ci-last-run"; \
		exit 0; \
	fi; \
	gh run list --repo "$$repo" --limit 1 --json workflowName,databaseId,status,conclusion,displayTitle --jq '.[0] | [.workflowName, .databaseId, .status, (.conclusion // "n/a"), .displayTitle] | @tsv'

ci-last-run-json:
	@repo="$${REPO:-alirezasafaeiiidev/asdev-standards-platform}"; \
	if [[ "$${GH_FORCE_MISSING:-false}" == "true" ]] || ! command -v gh >/dev/null 2>&1; then \
		echo "{}"; \
		exit 0; \
	fi; \
	gh run list --repo "$$repo" --limit 1 --json databaseId,status,conclusion,headSha --jq '.[0] // {}'

ci-last-run-compact:
	@repo="$${REPO:-alirezasafaeiiidev/asdev-standards-platform}"; \
	if [[ "$${GH_FORCE_MISSING:-false}" == "true" ]] || ! command -v gh >/dev/null 2>&1; then \
		echo "n/a	n/a"; \
		exit 0; \
	fi; \
	gh run list --repo "$$repo" --limit 1 --json databaseId,conclusion --jq '.[0] | [(.databaseId|tostring), (.conclusion // "n/a")] | @tsv'

agent-generate:
	@owner="$${OWNER:-alirezasafaeiiidev}"; \
	repos="$${REPOS:-asdev-standards-platform asdev-persiantoolbox asdev-portfolio asdev-creator-membership-ir asdev-automation-hub asdev-codex-reviewer asdev-family-rosca asdev-nexa-vpn}"; \
	workdir="$${WORKDIR:-/tmp/asdev-agent-gen}"; \
	if [[ "$${APPLY:-false}" == "true" ]]; then \
		python3 platform/scripts/generate-agent-md.py --owner "$$owner" --workdir "$$workdir" --apply --repos $$repos; \
	else \
		python3 platform/scripts/generate-agent-md.py --owner "$$owner" --workdir "$$workdir" --repos $$repos; \
	fi

run:
	@echo "ASDEV Platform is a standards/governance repository; use scripts under platform/scripts/."

hygiene:
	@bash scripts/repo-hygiene.sh check

verify-hub:
	@$(MAKE) setup
	@$(MAKE) ci
	@$(MAKE) test

fast-parallel-local:
	@bash scripts/fast-parallel-local.sh

autopilot-start:
	@bash scripts/autopilot-start.sh

autopilot-stop:
	@bash scripts/autopilot-stop.sh

autopilot-status:
	@log_dir="$${LOG_DIR:-$(CURDIR)/var/autopilot}"; \
	pid_file="$$log_dir/autopilot.pid"; \
	if [[ -f "$$pid_file" ]]; then \
		pid="$$(cat "$$pid_file")"; \
		if kill -0 "$$pid" >/dev/null 2>&1 && ps -p "$$pid" -o args= | grep -q 'autopilot-orchestrator.sh'; then \
			echo "autopilot running: pid=$$pid"; \
		else \
			echo "autopilot not running"; \
		fi; \
	else \
		echo "autopilot not running"; \
	fi

autopilot-install-user-service:
	@bash scripts/autopilot-install-user-service.sh

autopilot-uninstall-user-service:
	@bash scripts/autopilot-uninstall-user-service.sh

execution-sync:
	@bash platform/scripts/sync-autonomous-stack.sh

execution-status:
	@bash platform/scripts/status-autonomous-executor.sh

execution-max:
	@bash platform/scripts/run-priority-pipelines-max.sh

enforce-main-sync:
	@bash scripts/enforce-main-sync-policy.sh check

github-app-auth-check:
	@bash scripts/github-app-auth-guard.sh

p0-stabilization:
	@bash scripts/p0-stabilization.sh

management-dashboard:
	@bash scripts/management-dashboard.sh

management-dashboard-data:
	@bash scripts/generate-management-dashboard-data.sh

remaining-execution:
	@bash scripts/execute-remaining-roadmap-tasks.sh

compliance-report:
	@bash scripts/generate-compliance-report.sh

validate-compliance-reports:
	@bash scripts/validate-generated-reports.sh docs/compliance-dashboard/report.json docs/compliance-dashboard/report.csv schemas/compliance-report.schema.json

automation-slo-status:
	@bash scripts/generate-automation-slo-status.sh

pr-check-evidence:
	@bash scripts/generate-pr-check-evidence.sh

pr-check-audit:
	@bash scripts/audit-pr-check-emission.sh

release-post-check:
	@bash scripts/release/post-check.sh

autonomous-max:
	@bash scripts/autonomous-max.sh
