# Roadmap Execution Unified

Last updated: 2026-02-20
Status: active
Sources:
- `docs/incoming/2026-02-20/technical-blueprint/`
- `docs/incoming/2026-02-20/deep-research-report.md`

## Completed Phases
- [x] Phase A: Compliance pipeline MVP (report generator, contracts, scheduled audit).
- [x] Phase B: Docs platform bootstrap (Sphinx docs-site, docs build workflow, Vercel config).
- [x] Phase C: Release discipline (release workflow + SemVer scripts).
- [x] Phase D: Dashboard + KPI metrics (UI, weekly KPI summary automation).

## Completed Follow-up Execution
- [x] Run docs build workflow manually and verify artifact generation.
- [x] Execute first manual release dry-run from `release.yml`.
- [x] Add compliance report attestation/signature and validation.
- [x] Add compliance history rotation + trend visualization support.
- [x] Add monthly executive summary workflow linked to KPI outputs.

## Active Operational Workflows
- `.github/workflows/pr-validation.yml`
- `.github/workflows/compliance-audit.yml`
- `.github/workflows/docs-build.yml`
- `.github/workflows/release.yml`
- `.github/workflows/monthly-executive-summary.yml`

## Active Artifacts
- `docs/compliance-dashboard/report.json`
- `docs/compliance-dashboard/report.csv`
- `docs/compliance-dashboard/history.json`
- `docs/compliance-dashboard/attestation.json`
- `docs/reports/WEEKLY_COMPLIANCE_SUMMARY.md`
- `docs/reports/MONTHLY_EXECUTIVE_SUMMARY.md`

## Next 5 Execution Tasks (strict order)
1. Enforce required check contexts cleanup so PR checks are emitted consistently.
2. Add provenance metadata (run id / commit sha) to attestation payload.
3. Add alert thresholds and failing policy for compliance score regression.
4. Add monthly release post-check workflow (tag integrity + release note contract).
5. Add executive dashboard markdown digest published from monthly workflow.
