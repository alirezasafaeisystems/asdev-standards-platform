# ADR 0001: Next Implementation Wave Scope

## Status
Accepted

## Context
Execution phases A/B/C/D are completed and merged into `main`.
The next wave must focus on reliability and operational governance instead of adding new feature surface.

## Decision
The next implementation wave includes only:

1. PR required-check reliability for `PR Validation / quality-gate`.
2. Compliance attestation contract hardening (metadata/provenance + validation).
3. Automation SLO policy and recurring status publication.
4. Roadmap/docs synchronization and removal of stale duplicate artifacts.

Excluded from this wave:

1. Breaking API/schema/db changes.
2. Critical UX redesign.
3. Cross-repository orchestration expansion (hub remains disabled).

## Scope Change Rule
Any new workstream outside this scope requires:

1. New ADR file in `governance/ADR/`.
2. Explicit update in `ROADMAP_EXECUTION_UNIFIED.md`.
3. Linked issue in the canonical backlog tracker.

## Consequences
- Keeps changes small, verifiable, and aligned with `AGENTS.md`.
- Reduces repeated work by enforcing one active canonical backlog.
