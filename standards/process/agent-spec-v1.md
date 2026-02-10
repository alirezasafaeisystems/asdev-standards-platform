# AGENT Specification v1

- Status: Active
- Version: 1.0.0
- Owner: ASDEV Platform

## Purpose

Define a transferable, repo-specific contract for AI coding agents that is explicit, auditable, and safe.

## Required Sections

Every repository `AGENT.md` must include these sections in this order:

1. Identity & Mission
2. Repo Commands
3. Workflow Loop
4. Definition of Done
5. Human Approval Gates
6. Quality Checklist
7. Lenses (only relevant lenses)
8. Documentation & Change Log Expectations

## Section Contract

### 1) Identity & Mission

- Describe agent role in this repository.
- State key product or engineering priorities.
- Explicitly call out high-risk domains.

### 2) Repo Commands

- List real setup/run/test/lint/format/build commands.
- Commands must exist in repo scripts, Makefile, or toolchain config.
- If a command class is unavailable, document fallback behavior.

### 3) Workflow Loop

Use this fixed loop:

`Discover -> Plan -> Task -> Execute -> Verify -> Document`

### 4) Definition of Done

Minimum DoD:

- Scope is complete and minimal.
- Relevant tests and checks pass.
- No unrelated files are modified.
- Docs/changelog are updated when behavior changes.
- Risks and follow-ups are documented.

### 5) Human Approval Gates

Agents must pause for explicit human approval when work includes:

- Breaking API/schema/DB/data changes.
- Auth, permission, role, or security policy changes.
- New dependencies or major upgrades.
- Telemetry, external data transfer, secret handling, or sensitive logging.
- Legal/privacy/terms or sensitive branding text.
- Critical UX flow changes (signup, checkout, pricing, payment).

### 6) Quality Checklist

Must define repository-specific checks for:

- Tests
- Lint/format
- Type checks where applicable
- Security checks available in repo

### 7) Lenses

Only include relevant lenses, such as:

- Product
- UX/Accessibility
- SEO/Performance
- Security/Privacy
- Legal/Compliance
- Reliability/Operations

### 8) Documentation & Change Log Expectations

- List required docs to update for behavioral changes.
- List changelog/release-note expectations.
- State evidence requirements (commands run, outputs, file references).

## Naming and Compatibility

- Canonical file: `AGENT.md`
- Compatibility file (optional but recommended): `AGENTS.md` with a pointer to `AGENT.md`

## Non-Goals

- Do not encode stack-agnostic placeholder commands as final repo commands.
- Do not duplicate all governance docs in AGENT files.
