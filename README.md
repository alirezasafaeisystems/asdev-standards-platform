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

## Reporting

```bash
bash platform/scripts/divergence-report.sh sync/targets.yaml platform/repo-templates/templates.yaml platform/repo-templates sync/divergence-report.csv
bash platform/scripts/divergence-report-combined.sh platform/repo-templates/templates.yaml platform/repo-templates sync/divergence-report.combined.csv
bash scripts/generate-dashboard.sh docs/platform-adoption-dashboard.md
```

- Combined trend uses `sync/divergence-report.combined.csv` and optional `sync/divergence-report.combined.previous.csv`.
- If GitHub API is unstable, divergence scripts may emit `clone_failed` rows; rerun after connectivity recovers.

## Phase B Deliverables

- ADR-based governance and scope lock
- Level 0 language-agnostic standards (v1.1.0)
- Versioned repo templates with source traceability
- Sync MVP scripts for PR-driven adoption and divergence reporting
- Level 1 JS/TS baseline kickoff (draft)
