# Execution Automation Stack

مرکز رسمی اتوماسیون اجرای محلی/خودکار در این ریپو.

## Canonical Script Tree
- `platform/scripts/execution/`
- `platform/scripts/execution/pipelines/`
- `platform/scripts/execution/autonomous/`

## Backward-Compatible Wrappers
برای جلوگیری از شکستن مسیرهای قبلی، wrapperها در `platform/scripts/` نگه داشته شده‌اند.

## Config Sources
- `ops/autonomous-executor.env`
- `ops/systemd/user/asdev-autonomous-executor.service.tpl`
- `ops/automation/execution-manifest.yaml`

## Git And GitHub Auto Bootstrap
- `platform/scripts/git-github-bootstrap.sh`

این اسکریپت global git config، SSH برای GitHub، `gh` config/auth setup، و migration ریموت‌های GitHub از https به ssh را idempotent اعمال می‌کند.

## One-Command Sync
- `platform/scripts/sync-autonomous-stack.sh`

این دستور:
1. همه اسکریپت‌ها را executable می‌کند.
2. سرویس systemd user را از template رندر و نصب می‌کند.
3. سرویس را enable/restart می‌کند.
4. گزارش همگام‌سازی تولید می‌کند.

## Sync Auth Diagnostics
- `scripts/sync-auth-preflight.sh`
- `docs/automation/sync-auth-failure-runbook.md`
