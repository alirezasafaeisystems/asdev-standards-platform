# Codex Runtime Guidance

## Human Approval Gates
- Auth/permissions/roles/security policy changes
- breaking API/schema/db
- critical UX flow

## Runtime Rules
- Keep changes small and verifiable.
- Run lint/test/build gates before merge.
- Preserve branch protection and PR-based delivery.

## Codex Bootstrap Defaults
- Preferred profiles: `deep-review` for hard tasks, `fast-fix` for quick/small changes.
- Maintain `.codex/snapshots/<timestamp>/` with `status`, `diff`, `branch`, `last5`, `summary.md`, `cmd.log`, and `report.md`.
- Repository skills live in `.agents/skills` and are exposed at `.codex/skills`.

## Hub Disabled Mode
- `asdev-standards-platform` is currently inactive as a hub.
- Do not scan, orchestrate, or control other repositories from this repo.
- `known_repositories` must remain empty until the user provides an explicit allowlist.
- Re-enable only after a direct user instruction that includes repository names.
