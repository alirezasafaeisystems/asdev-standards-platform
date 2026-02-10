# Repository Agent Guide

## Identity & Mission

- Repository:
- Primary mission:
- High-risk domains:

## Repo Commands

- Setup:
- Run:
- Test:
- Lint:
- Format:
- Build:

If a command class is unavailable, define fallback behavior.

## Workflow Loop

`Discover -> Plan -> Task -> Execute -> Verify -> Document`

## Definition of Done

1. Requested scope is complete and minimal.
2. Relevant quality checks pass.
3. Docs/changelog updated when behavior changes.
4. No unrelated files changed.
5. Risks and follow-ups are documented.

## Human Approval Gates

- Auth/permissions/roles/security policy changes
- Breaking API/schema/db changes, destructive migrations, data deletion
- Adding dependencies or major version upgrades
- Telemetry/external data transfer/secret handling changes
- Legal text (Terms/Privacy) or sensitive claims
- Critical UX flows (signup/checkout/pricing/payment)

## Quality Checklist

- Tests:
- Lint/format:
- Type checks:
- Security checks:

## Lenses

Enable only relevant lenses:

- Quality
- Reliability
- Security
- Documentation
- UX/Accessibility
- SEO/Performance
- Product
- Legal/Compliance
- Risk/Auditability

## Documentation & Change Log Expectations

- Docs to update:
- Changelog requirement:
- Evidence required in PR:
