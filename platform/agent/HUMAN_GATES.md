# Human Approval Gates

Agents must stop and request explicit human approval before making changes in these categories:

1. Auth/permissions/roles/security policy changes.
2. Breaking API/schema/database changes, destructive migrations, or data deletion.
3. Adding dependencies or bumping major versions.
4. Telemetry, external data transfer, secret handling, or sensitive logging.
5. Legal text changes (Terms/Privacy) or sensitive claims.
6. Critical UX flow changes (signup, checkout, pricing, payment).

## Operating Rule

If uncertain whether a change is in-scope for a gate, treat it as gated and ask.
