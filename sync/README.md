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
