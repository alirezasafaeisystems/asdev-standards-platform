# Cross-Repo Standards Sync

This automation makes `asdev-standards-platform` the source of truth for shared standards files and distributes them to target repositories using Pull Requests.

## Source of truth
- `alirezasafaeiiidev/asdev-standards-platform`

## Targets
- `alirezasafaeiiidev/asdev-automation-hub`
- `alirezasafaeiiidev/asdev-portfolio`
- `alirezasafaeiiidev/asdev-persiantoolbox`

## Config
- Workflow: `.github/workflows/standards-sync.yml`
- Declarative config: `sync/targets.yml`

## Required secrets (GitHub App)
In `asdev-standards-platform` repository secrets:
- `SYNC_APP_ID`: GitHub App ID used for cross-repo sync.
- `SYNC_APP_PRIVATE_KEY`: private key for the same GitHub App installation.

Legacy PAT secret `SYNC_TOKEN` is deprecated and ignored by the workflow.

## Behavior
- Triggered manually (`workflow_dispatch`) or when managed files/config change on `main`.
- Runs a matrix job for each target repository.
- Generates a short-lived GitHub App installation token per target repository.
- Runs preflight auth diagnostics before target checkout/PR creation.
- Copies only `managed_paths` from source into target checkout.
- Creates or updates a PR via `peter-evans/create-pull-request`.
- Requests configured reviewers.
- Attempts to enable auto-merge (subject to target branch protection policy).

## Policy
- No direct push to target `main`.
- Delivery is PR-only and branch-protection-aware.

## Latest Execution Status (2026-02-13)
- Workflow: `Cross-Repo Standards Sync`
- Run: `22002005258` (success)
- URL: https://github.com/alirezasafaeiiidev/asdev-standards-platform/actions/runs/22002005258
- Target outcomes:
  - `alirezasafaeiiidev/asdev-automation-hub`: synced, no PR required (already aligned).
  - `alirezasafaeiiidev/asdev-portfolio`: synced, no PR required (already aligned).
  - `alirezasafaeiiidev/asdev-persiantoolbox`: sync PR created and merged (`#19`).

## Sync-Ops Hardening Status
- SYNC-OPS token hardening (PAT -> GitHub App token): implemented in workflow.
- SYNC-OPS diagnostics hardening (preflight auth/repo checks): implemented via `scripts/sync-auth-preflight.sh`.
- Failure troubleshooting runbook: `docs/automation/sync-auth-failure-runbook.md`.
- Target repository follow-up: licensing contract gap in `asdev-persiantoolbox` (issue `#20`)
  - https://github.com/alirezasafaeiiidev/asdev-persiantoolbox/issues/20
