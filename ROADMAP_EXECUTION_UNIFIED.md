# Roadmap Execution Unified

Last updated: 2026-02-20
Status: active
Sources:
- `docs/incoming/2026-02-20/technical-blueprint/`
- `docs/incoming/2026-02-20/deep-research-report.md`

## Phase 0 - Intake And Baseline (current)
- [x] Ingest blueprint package into repository docs.
- [x] Ingest deep research report into repository docs.
- [x] Review repository operational status (git + existing verify logs).
- [ ] Confirm final scope for first implementation wave (CI gate only vs full package).

## Phase 1 - Enforcement Foundation (Week 1-2)
- [x] Add mandatory PR quality gates (`lint`, `typecheck`, `test`, `security`, `coverage`, `build`).
- [x] Add schema validation step for YAML manifests and enforce in CI.
- [x] Add policy guard for template version changes (requires standards/ADR update).
- [ ] Define required status checks in branch protection policy.

Approval gate: auth/permissions/roles/security policy changes.

## Phase 2 - Compliance Data Pipeline (Week 3-4)
- [ ] Implement scheduled compliance audit workflow (UTC cron).
- [ ] Generate and version `docs/compliance-dashboard/report.json` and `report.csv`.
- [ ] Validate generated report contracts before publish.
- [ ] Add signed/hashed report attestation in `sync/generated-reports.attestation`.

## Phase 3 - Docs Platform (Week 5-6)
- [ ] Build Sphinx docs site structure (`docs-site/`) with sections from blueprint.
- [ ] Add Django-style theming baseline and custom CSS layer.
- [ ] Add docs build job in CI and publishable artifact.
- [ ] Add Vercel config for static docs deploy.

## Phase 4 - Release And Governance (Week 6+)
- [ ] Add SemVer workflow (`VERSION`, tag, release notes/changelog flow).
- [ ] Add/refresh governance docs: `CONTRIBUTING.md`, `SECURITY.md`, `SUPPORT.md`.
- [ ] Add lightweight compliance dashboard UI (JSON + Chart.js).
- [ ] Define KPI trend tracking and operational SLO for automation jobs.

Approval gate: breaking API/schema/db and critical UX flow changes.

## Execution Order (next 3 tasks)
1. Implement minimal PR validation workflow and make it required.
2. Add manifest schema validation and wire it to CI.
3. Stand up compliance `report.json` generation contract.
