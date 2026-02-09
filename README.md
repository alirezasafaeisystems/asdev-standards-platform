# ASDEV Platform

ASDEV Platform is a multi-repo standards and governance hub focused on standardization without monorepo lock-in.

## Scope

This repository defines:
- Governance policy and architecture decisions (`governance/`)
- Technical standards (`standards/`)
- Reusable templates and helper tooling (`platform/`)
- Sync configuration and rollout artifacts (`sync/`)

This repository does not own consumer-repo business logic.

## Repository Layout

```text
asdev_platform/
├─ governance/
├─ standards/
├─ platform/
├─ sync/
├─ brand/
├─ src/
├─ tests/
├─ docs/
├─ scripts/
└─ assets/
```

## Quickstart

```bash
make setup
make lint
make test
make run
```

`make test` always runs the full test suite and does not skip `yq`-dependent checks.

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
- Weekly digest automation closes stale open digest issues beyond SLA (`DIGEST_STALE_DAYS`, default `8`) and references the active digest issue; dry-run preview is available via `DIGEST_STALE_DRY_RUN=true`.
- Snapshot rotation archives report snapshots under `sync/snapshots/` and prunes by retention (`REPORT_SNAPSHOT_RETENTION_DAYS`, default `14`).
- Dashboard includes recent fingerprint delta history from current/previous trend files and retained snapshot trend files.

## Phase B Deliverables

- ADR-based governance and scope lock
- Level 0 language-agnostic standards (v1.1.0)
- Versioned repo templates with source traceability
- Sync MVP scripts for PR-driven adoption and divergence reporting
- Level 1 JS/TS baseline kickoff (draft)
