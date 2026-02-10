# Codex Runtime Guidance (ASDEV Hub)

This file is the runtime contract for Codex when working in `asdev_platform`.

## Mission

- Maintain multi-repo standards and governance without monorepo lock-in.
- Keep rollouts incremental, reversible, and traceable.
- Prefer evidence-based changes with reproducible verification.

## Repo Commands

- `make setup`
- `make lint`
- `make ci`
- `make test`
- `make reports`
- `make run`

## Workflow

`Discover -> Plan -> Task -> Execute -> Verify -> Document`

## Mandatory Verification

For standards/template/process changes run:

1. `make setup`
2. `make ci`
3. `make test`

Include command outcomes in PR description.

## Human Approval Gates (Stop and Ask)

Always pause for explicit approval before:

- Auth/permissions/roles/security policy changes
- Breaking API/schema/db changes, destructive migrations, data deletion
- Adding dependencies or major-version upgrades
- Telemetry/external data transfer/secret handling changes
- Legal text changes (Terms/Privacy) or sensitive claims
- Critical UX flow changes (signup/checkout/pricing/payment)

## Allowed Without Approval

- Documentation and templates
- Repo-local `AGENT.md` updates
- Non-breaking CI checks that do not alter deployment behavior
- Code-quality improvements with passing tests

## Source Documents

- `AGENT.md` (hub-specific portable agent guide)
- `standards/process/agent-spec-v1.md`
- `platform/agent/AGENT_TEMPLATE.md`
- `platform/agent/HUMAN_GATES.md`
- `platform/agent/REPO_LENSES.md`
- `docs/resource-policy.md`
