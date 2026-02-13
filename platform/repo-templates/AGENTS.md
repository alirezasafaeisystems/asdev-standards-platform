<!-- asdev:template_id=agents-runtime-guidance version=1.0.0 source=standards/process/agent-spec-v1.md -->
# Codex Runtime Guidance

This file is the runtime contract for Codex when working in this repository.

## Mission

- Keep changes incremental, reversible, and traceable.
- Prefer evidence-based decisions with reproducible verification.
- Avoid monorepo lock-in and preserve repository autonomy.

## Workflow

`Discover -> Plan -> Task -> Execute -> Verify -> Document`

## Mandatory Verification

For standards/template/process changes run the repository's setup, CI, and test commands.
Record command outcomes in the PR description.

## Human Approval Gates (Stop and Ask)

Always pause for explicit approval before:

- Auth/permissions/roles/security policy changes
- Breaking API/schema/db changes, destructive migrations, or data deletion
- Adding dependencies or major-version upgrades
- Telemetry/external data transfer/secret handling changes
- Legal text changes (Terms/Privacy) or sensitive claims
- Critical UX flow changes (signup/checkout/pricing/payment)

## Source Documents

- `AGENT.md` (repository-specific execution guide)
- `standards/process/agent-spec-v1.md` (policy source)
