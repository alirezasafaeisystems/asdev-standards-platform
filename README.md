# asdev-standards-platform

Standards, automation orchestration, and governance tooling for ASDEV repositories.

## Core Commands
- `make lint`
- `make test`
- `make verify`
- `make code-reviews` (runs review preflight + full verify gate)
- `make reports`
- `make p0-stabilization`
- `make enforce-main-sync`

## Management Dashboard
- Launch with auto-report refresh:
  - `make management-dashboard`
- Build dashboard data only:
  - `make management-dashboard-data`
- Default URL:
  - `http://127.0.0.1:4173/docs/dashboard/`

Dashboard docs:
- `docs/management-dashboard.md`
