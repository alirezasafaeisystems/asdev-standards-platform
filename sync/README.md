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

## Required secret
In `asdev-standards-platform` repository secrets:
- `SYNC_TOKEN`: token with access to all target repositories.

## Behavior
- Triggered manually (`workflow_dispatch`) or when managed files/config change on `main`.
- Runs a matrix job for each target repository.
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

## Remaining Tasks
- SYNC-OPS token hardening: GitHub App migration (issue `#130`)
  - https://github.com/alirezasafaeiiidev/asdev-standards-platform/issues/130
- SYNC-OPS diagnostics hardening: preflight auth/repo access checks (issue `#131`)
  - https://github.com/alirezasafaeiiidev/asdev-standards-platform/issues/131
- Target repository follow-up: licensing contract gap in `asdev-persiantoolbox` (issue `#20`)
  - https://github.com/alirezasafaeiiidev/asdev-persiantoolbox/issues/20
