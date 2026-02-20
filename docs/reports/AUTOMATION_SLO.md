# Automation SLO Policy

Last updated: 2026-02-20

## Scope
Applies to repository automation for:
- PR quality gate validation
- Compliance report generation
- Docs build and monthly executive summary refresh

## SLI/SLO
- `required_check_emission`
  - SLI: `PR Validation / quality-gate` appears on PRs.
  - SLO target: 100%.
- `compliance_artifact_attestation`
  - SLI: attestation validates against current generated artifacts.
  - SLO target: 100%.
- `compliance_report_freshness`
  - SLI: age of `docs/compliance-dashboard/report.json`.
  - SLO target: <= 8 days.

## Alert Thresholds
- Critical:
  - Required PR check missing on a PR.
  - Attestation validation failure.
- Warning:
  - Compliance report freshness > 8 days.

## Escalation
1. Open or update incident issue in repository.
2. Link run URL and failing artifact/step.
3. Patch workflow/script with minimal change.
4. Re-run and attach verification output.
