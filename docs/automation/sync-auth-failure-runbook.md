# Standards Sync Auth Failure Runbook

Runbook برای خطاهای احراز هویت/دسترسی در workflow:
- `.github/workflows/standards-sync.yml`

## Scope
- مهاجرت از PAT (`SYNC_TOKEN`) به GitHub App token.
- preflight diagnostics قبل از checkout/create-PR روی هر target.

## Required Secrets
- `SYNC_APP_ID`
- `SYNC_APP_PRIVATE_KEY`

## Required GitHub App Permissions
- Repository permissions:
  - `Contents`: Read and write
  - `Pull requests`: Read and write
  - `Metadata`: Read-only
- Installation scope:
  - `asdev-standards-platform`
  - همه target repoها در `sync/targets.yml`

## Failure Categories (from preflight)
- `missing_token`
  - Cause: token به preflight نرسیده.
  - Action: secrets و step `actions/create-github-app-token` را بررسی کن.
- `token_invalid_or_expired`
  - Cause: app token معتبر نیست یا private key/app-id mismatch دارد.
  - Action: `SYNC_APP_ID` و `SYNC_APP_PRIVATE_KEY` را دوباره set کن.
- `token_scope_or_rate_limit`
  - Cause: permission یا rate-limit.
  - Action: permissionهای App و installation scope را بررسی کن.
- `repo_not_accessible_for_app_installation`
  - Cause: app روی target repo نصب نیست یا repo slug اشتباه است.
  - Action: installation را روی repo فعال کن و `sync/targets.yml` را validate کن.
- `git_transport_auth_failed`
  - Cause: دسترسی git-level برای clone/fetch برقرار نیست.
  - Action: App installation + repo permission (`contents`) را بررسی کن.

## Fast Diagnostics
از workflow summary category را بگیر، سپس:

1. Validate secrets exist:
```bash
gh secret list -R alirezasafaeiiidev/asdev-standards-platform | rg "SYNC_APP_ID|SYNC_APP_PRIVATE_KEY|SYNC_TOKEN"
```

2. Validate targets:
```bash
yq '.targets[].repo' sync/targets.yml
```

3. Local preflight (manual token):
```bash
SYNC_AUTH_TOKEN="<app_installation_token>" \
bash scripts/sync-auth-preflight.sh alirezasafaeiiidev/asdev-automation-hub
```

## Migration Notes
- `SYNC_TOKEN` (PAT) دیگر توسط workflow استفاده نمی‌شود.
- در صورت باقی‌ماندن secret قدیمی، فقط به‌عنوان legacy علامت‌گذاری می‌شود.
