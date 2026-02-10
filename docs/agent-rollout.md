# Agent Rollout Runbook

## Purpose

Define a repeatable process to generate and maintain repository-specific `AGENT.md` files across ASDEV target repositories without monorepo lock-in.

## Inputs

- Hub templates:
  - `platform/agent/AGENT_TEMPLATE.md`
  - `platform/agent/HUMAN_GATES.md`
  - `platform/agent/REPO_LENSES.md`
- Generator:
  - `platform/scripts/generate-agent-md.py`
- Target repository list:
  - `asdev_platform`
  - `persian_tools`
  - `my_portfolio`
  - `patreon_iran`
  - `go-level1-pilot`
  - `python-level1-pilot`

## Execution

Preview summary (no file write):

```bash
make agent-generate
```

Apply mode (writes `AGENT.md` inside temp-cloned repos):

```bash
APPLY=true make agent-generate
```

Custom owner/repos/workdir:

```bash
OWNER=alirezasafaeiiidev \
REPOS="persian_tools my_portfolio" \
WORKDIR=/tmp/asdev-agent-gen \
APPLY=true \
make agent-generate
```

## PR Strategy

- One branch and one PR per repository.
- Keep changes limited to `AGENT.md` (and compatibility `AGENTS.md` only when needed).
- Include verification commands in PR description.

## Verification

Hub validation:

```bash
make setup
make ci
make test
```

Repository validation:

- Run each repository's discovered lint/test/build commands from generated output.
- If commands are placeholders or missing, report explicit gaps in PR notes.

Execution resource defaults:

- Clone/fetch parallelism: `3`
- Concurrent heavy jobs: `2`
- Worker cap per heavy job: `6`
- E2E browser workers: `1`
- GPU disabled unless tool explicitly supports it.

## Approval Gates

Never bypass human approval for:

- auth/security policy changes
- breaking schema/db or data-destructive changes
- dependency additions/major upgrades
- telemetry/external data transfer/secret handling
- legal text changes
- critical signup/checkout/pricing/payment UX flow changes
