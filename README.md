# ASDEV Platform

ASDEV Platform is a multi-repo standards and governance hub focused on standardization without monorepo lock-in.

## Scope

This repository defines:
- Governance policy and architecture decisions (`governance/`)
- Technical standards (`standards/`)
- Reusable templates and helper tooling (`platform/`)
- Sync configuration and rollout artifacts (`sync/`)

Core process contracts:

- Agent specification: `standards/process/agent-spec-v1.md`
- Definition of Done policy: `governance/policies/definition-of-done.md`
- CI expectations policy: `governance/policies/ci-expectations.md`
- Security checklist policy: `governance/policies/security-checklist.md`
- External dependency governance policy: `governance/policies/external-dependency-governance.md`
- Agent rollout template pack:
  - `platform/agent/AGENT_TEMPLATE.md`
  - `platform/agent/HUMAN_GATES.md`
  - `platform/agent/REPO_LENSES.md`
  - `platform/scripts/generate-agent-md.py`
- Resource execution policy: `docs/resource-policy.md`
- Repository hygiene policy: `docs/repo-hygiene.md`

This repository does not own consumer-repo business logic.

## Public Scope

- This repository is intended to be public as the standards/governance source of truth.
- Consumer application repositories can remain private/public independently.
- Approved runtime external-dependency exception: `alirezasafaeiiidev/asdev-nexa-vpn` (governed by `governance/policies/external-dependency-governance.md`).

## License

This project is licensed under the MIT License. See `LICENSE`.

## Security

Please report vulnerabilities through the process in `SECURITY.md`.

## Repository Layout

```text
asdev-standards-platform/
├─ governance/
├─ standards/
├─ platform/
├─ sync/
├─ tests/
├─ docs/
└─ scripts/
```

## Quickstart

```bash
make setup
make lint
make typecheck
make ci
make test
make e2e
make build
make security-audit
make coverage
make verify
make reports
make run
make hygiene
make verify-hub
make fast-parallel-local
```

`make test` always runs the full test suite and does not skip `yq`-dependent checks.
`make ci` mirrors CI gating order locally: lint -> policy check -> test.
`make verify` runs deterministic acceptance gates with task-level logs under `logs/{task-id}.log`.
`make reports` runs the local report pipeline: combined report -> trend -> dashboard -> schema checks -> attestation write/validate.
`make fast-parallel-local` runs aggressive parallel verification for the four primary repositories and writes per-repo logs under `asdev-standards-platform/logs/fast-parallel/`.

Automation acceptance contract:

- Spec: `CODEX_AUTOMATION_SPEC.md`
- Criteria mapping: `docs/automation-compliance.md`

## Reporting

```bash
bash platform/scripts/divergence-report.sh sync/targets.yaml platform/repo-templates/templates.yaml platform/repo-templates sync/divergence-report.csv
bash platform/scripts/divergence-report-combined.sh platform/repo-templates/templates.yaml platform/repo-templates sync/divergence-report.combined.csv
bash scripts/generate-dashboard.sh docs/platform-adoption-dashboard.md
```

- Combined trend uses `sync/divergence-report.combined.csv` and optional `sync/divergence-report.combined.previous.csv`.
- If GitHub API is unstable, divergence scripts may emit `clone_failed` rows; rerun after connectivity recovers.

## CI Automation

- CI is stage-gated: reports/docs generation starts only after lint and tests pass.
- On `push` to `main`, CI regenerates:
  - `sync/divergence-report.combined.csv`
  - `sync/divergence-report.combined.errors.csv`
  - `sync/divergence-report.combined.errors.trend.csv`
  - rotates previous snapshots for both combined reports before regeneration
  - `docs/platform-adoption-dashboard.md`
- A weekly scheduled run (Mondays 09:00 UTC) regenerates the same outputs.
- If generated outputs change, CI opens or updates an automated PR.
- For automation PRs, CI enables auto-merge only when changed files are limited to dashboard/report output files.
- If the combined report contains `clone_failed`, CI publishes a warning with the affected repositories.
- CI also publishes transient error fingerprint counts (for example `tls_error`, `http_502`, `timeout`) in logs, produces a compact fingerprint trend CSV artifact, and appends top increasing/decreasing fingerprint deltas to the workflow summary.
- CI validates generated CSV schemas before report artifacts are uploaded and before downstream update PR automation proceeds.
- CI writes and validates a report attestation (`sync/generated-reports.attestation`) so update PR automation is gated on validated artifacts.
- Attestation validation also enforces freshness (`ATTESTATION_MAX_AGE_SECONDS`, default `1800`) to prevent stale reuse.
- Attestation includes explicit `schema_version` and validator compatibility checks (`ATTESTATION_EXPECTED_SCHEMA_VERSION`, default `1`).
- Attestation includes explicit `checksum_algorithm` metadata with compatibility checks (`ATTESTATION_EXPECTED_CHECKSUM_ALGORITHM`, default `sha256`).
- Attestation validation also verifies attested file-path metadata (`combined_file`, `errors_file`, `trend_file`) against validator inputs.
- Weekly digest automation closes stale open digest issues beyond SLA (`DIGEST_STALE_DAYS`, default `8`) and references the active digest issue; dry-run preview is available via `DIGEST_STALE_DRY_RUN=true`.
- Daily stale-digest cleanup workflow (`.github/workflows/digest-stale-cleanup.yml`) is enabled unless `DIGEST_CLEANUP_ENABLED=false`.
- Cleanup workflow toggle vars:
  - `DIGEST_STALE_DRY_RUN` (`true` for preview, `false` to enforce closures)
  - `DIGEST_STALE_DAYS` (stale threshold in days, default `8`)
- Recommended rollout: run cleanup in dry-run mode first, review summary metrics, then switch to enforce mode.
- Dry-run to enforce promotion checklist:
  - `DIGEST_STALE_DRY_RUN=true` and run scheduled/dispatch cleanup.
  - Confirm summary metrics (`evaluated_count`, `dry_run_candidates`) are expected.
  - Switch to `DIGEST_STALE_DRY_RUN=false` only after review.
- Snapshot rotation archives report snapshots under `sync/snapshots/` and prunes by retention (`REPORT_SNAPSHOT_RETENTION_DAYS`, default `14`).
- Dashboard includes recent fingerprint delta history from current/previous trend files and retained snapshot trend files.
- Dashboard also highlights top positive/negative fingerprint deltas from current trend output.
- Dashboard includes per-run `clone_failed` trend from current/previous and retained combined snapshots.
- Dashboard includes per-run `unknown_template` trend from current/previous and retained combined snapshots.
- Dashboard includes per-run `timeout` and `auth_or_access` trends from current/previous and retained trend snapshots.
- Update PR lifecycle automation closes superseded/stale `chore/reports-docs-update` PRs while keeping only the newest active PR.
- Update PR lifecycle supports dry-run mode (`REPORT_UPDATE_PR_STALE_DRY_RUN=true`) and emits candidate/closure counts into workflow summary.
- Weekly digest stale-closure automation emits deterministic lifecycle summary metrics for both active-close and dry-run modes.
- Weekly digest workflow supports CI policy toggle for stale closure dry-run via `DIGEST_STALE_DRY_RUN` and surfaces toggle state in step summary.

## Local Operations

```bash
gh auth status
make digest-cleanup-dry-run
make ci-last-run
make ci-last-run-json
make ci-last-run-compact
```

- `make digest-cleanup-dry-run` resolves the latest open weekly digest and runs stale lifecycle cleanup in dry-run mode.
- `make digest-cleanup-dry-run REPO=<owner/repo>` runs the same helper against another repository.
- `make ci-last-run` prints the latest CI run status summary (`workflow`, `run id`, `status`, `conclusion`).
- `make ci-last-run-json` prints machine-readable latest CI run status.
- `make ci-last-run-compact` prints a compact single line (`run id<TAB>conclusion`).
- `scripts/weekly-governance-digest.sh` supports `DIGEST_REPO` override (defaults to `$GITHUB_REPOSITORY` in CI).
- `scripts/monthly-release.sh` supports `RELEASE_REPO` and `BASE_BRANCH` overrides for reusable rollout automation.
- `make hygiene` runs repository hygiene checks (cache artifacts and empty directory detection).
- `make verify-hub` runs mandatory verification sequence: `make setup` -> `make ci` -> `make test`.

## Public Data Policy

- Report CSVs and dashboard are kept in-repo for transparency.
- Public sanitize policy removes owner prefixes from `repo` fields in tracked report CSV snapshots.
- Use `bash scripts/sanitize-public-reports.sh sync` before public release snapshots.

Example shell automation:

```bash
run_json="$(make --no-print-directory ci-last-run-json)"
run_id="$(printf '%s' "$run_json" | jq -r '.databaseId // "n/a"')"
conclusion="$(printf '%s' "$run_json" | jq -r '.conclusion // "n/a"')"
echo "run_id=${run_id} conclusion=${conclusion}"
```

## Quick Operational Commands

```bash
make ci
make reports
make agent-generate
make ci-last-run
make ci-last-run-compact
make digest-cleanup-dry-run
make hygiene
make verify-hub
```

## Agent Rollout

```bash
# preview summary only
make agent-generate

# apply AGENT.md generation in temp clones
APPLY=true make agent-generate
```

- See `docs/agent-rollout.md` for the end-to-end workflow and PR strategy.

## Phase B Deliverables

- ADR-based governance and scope lock
- Level 0 language-agnostic standards (v1.1.0)
- Versioned repo templates with source traceability
- Sync MVP scripts for PR-driven adoption and divergence reporting
- Level 1 JS/TS baseline kickoff (draft)

## Technical Execution v2

- Execution status report: `docs/technical-execution-v2-status-2026-02-13.md`
- Related rollout PRs:
  - `asdev-standards-platform`: PR #122 (merged), PR #121 (closed as superseded)
  - `asdev-automation-hub`: PR #1 (merged)
  - `asdev-creator-membership-ir`: PR #10 (merged), PR #9 (closed as superseded)
  - `asdev-portfolio`: PR #13 and PR #11 (merged), PR #12 and PR #10 (closed as superseded)
  - `asdev-persiantoolbox`: PR #14, PR #11, and PR #13 (merged), PR #12 (closed as superseded)
