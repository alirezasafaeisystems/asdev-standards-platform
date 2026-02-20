# Roadmap Execution Unified

Last updated: 2026-02-20
Status: active
Sources:
- `docs/incoming/2026-02-20/technical-blueprint/`
- `docs/incoming/2026-02-20/deep-research-report.md`

## Done Baseline
- [x] Ingested blueprint and deep-research inputs.
- [x] Added PR quality gate workflow.
- [x] Added schema validation + policy guard.
- [x] Configured branch protection with required check on `main`.
- [x] Implemented compliance pipeline MVP (report generator + contracts + scheduled audit workflow).

## Phase A - Compliance Pipeline MVP
Goal: تولید خروجی پایدار انطباق در CI
- [x] Add `tools/generate_compliance_report.py` for JSON/CSV output.
- [x] Create `docs/compliance-dashboard/report.json` and `report.csv` generation target.
- [x] Add schema/contract checks for generated reports.
- [x] Wire report generation into a scheduled workflow (`cron` UTC).

## Phase B - Docs Platform Bootstrap
Goal: راه‌اندازی سایت مستندات قابل build/deploy
- [x] Create `docs-site/` skeleton (`conf.py`, `requirements.txt`, `Makefile`, `source/index.rst`).
- [x] Add sections: Overview, Governance, CI/CD, Dashboard, Releases.
- [x] Add CI job for docs build artifact.
- [x] Add `vercel.json` for static deploy output.

## Phase C - Release Discipline
Goal: تثبیت نسخه‌دهی و انتشار
- [x] Add release workflow (`.github/workflows/release.yml`).
- [x] Enforce SemVer bump policy from `VERSION`.
- [x] Auto-generate release notes/changelog update flow.
- [x] Add tag+release scripts in `scripts/release/`.

## Phase D - Dashboard UI + Ops Metrics
Goal: مشاهده سریع وضعیت انطباق و روندها
- [x] Build lightweight dashboard UI (`docs/compliance-dashboard/index.html` + JS/CSS).
- [x] Show per-check status and report metadata from `report.json`.
- [x] Add weekly KPI summary generator in `docs/reports/`.
- [x] Wire KPI summary generation into compliance audit workflow.

## Required Approval Gates
- Auth/permissions/security policy changes.
- Breaking API/schema/db changes.
- Critical UX flow changes.

## Next 5 Execution Tasks (strict order)
1. Run docs build workflow once and verify artifact quality.
2. Execute first manual release dry-run from `release.yml`.
3. Add report attestation/signature for compliance dashboard artifacts.
4. Add trend chart and historical dataset rotation for dashboard.
5. Add monthly executive summary workflow linked to KPI outputs.
