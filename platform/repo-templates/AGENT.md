<!-- asdev:template_id=agent-guidelines version=1.0.0 source=standards/process/agent-spec-v1.md -->
# Repository Agent Guide

## Identity & Mission

Define the agent role for this repository and its product priorities.

## Repo Commands

Use real repository commands only.

- `setup`:
- `run`:
- `test`:
- `lint`:
- `format`:
- `build`:

If some commands do not exist, document the fallback policy.

## Workflow Loop

`Discover -> Plan -> Task -> Execute -> Verify -> Document`

## Definition of Done

1. Requested scope is complete and minimal.
2. Relevant quality checks pass.
3. Docs/changelog are updated when behavior changes.
4. No unrelated files are modified.

## Human Approval Gates

Pause for explicit human approval before:

- Breaking API/schema/DB/data changes
- Auth/permission/security policy changes
- New dependencies or major upgrades
- Telemetry/external data transfer/secrets/sensitive logging changes
- Legal/privacy/terms or sensitive brand changes
- Critical UX flow changes (signup/checkout/pricing/payment)

## Quality Checklist

- Tests:
- Lint/format:
- Type checks:
- Security checks:

## Lenses

List only relevant lenses for this repository, for example:

- Product
- UX/Accessibility
- SEO/Performance
- Security/Privacy
- Legal/Compliance
- Reliability/Operations

## Documentation & Change Log Expectations

- Required docs to update:
- Changelog/release-note expectations:
- Verification evidence format:
