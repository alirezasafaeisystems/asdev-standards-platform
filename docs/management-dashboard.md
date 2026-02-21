# Management Dashboard

## Goal
Provide one operational UI for ASDEV standards execution without replacing existing scripts.

## Data Sources
Dashboard reads generated artifacts from `docs/reports/`:
- `PRODUCTION_READINESS_SCORE_<date>.md` (latest)
- `P0_STABILIZATION_<date>.md` (latest)
- `PRIORITY_EXECUTION_RUN_<date>.md` (latest)
- `ROADMAP_TASK_QUEUE_<date>.csv` (optional; fallback to roadmap/task reports)
- `AUTOPILOT_EXECUTION_REPORT.md`

## What It Shows
- Executive KPIs: readiness average, roadmap todo/done, autopilot failed count
- P0 stabilization status
- Priority execution steps (pass/fail)
- Roadmap queue by priority
- Readiness table per repository

## Run (Automatic)
```bash
make management-dashboard
```
This command:
1. Runs `make reports`
2. Generates `docs/dashboard/data.json`
3. Starts local HTTP server
4. Serves dashboard at: `http://127.0.0.1:4173/docs/dashboard/`

Optional:
```bash
HOST=0.0.0.0 PORT=8080 make management-dashboard
```

Skip report refresh (faster local UI boot):
```bash
REFRESH_REPORTS=false make management-dashboard
```

## Files
- UI entry: `docs/dashboard/index.html`
- UI logic: `docs/dashboard/app.js`
- UI style: `docs/dashboard/styles.css`
- Data snapshot: `docs/dashboard/data.json`
- Launcher: `scripts/management-dashboard.sh`
- Data builder: `scripts/generate-management-dashboard-data.sh`

## Build Data Only
```bash
make management-dashboard-data
```

## Notes
- Dashboard is read-only by design.
- If required source reports are missing, generate them first with `make reports`.
