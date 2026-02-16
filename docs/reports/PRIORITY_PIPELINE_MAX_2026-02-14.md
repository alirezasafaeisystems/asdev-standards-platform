# Priority Pipeline MAX Run (2026-02-14)

- Executed (UTC): 2026-02-14 22:53:37 UTC
- CPU threads: 12
- Max parallel jobs: 12
- Node max old space: 12288 MB
- UV thread pool size: 48
- Turbo concurrency: 12
- GPU mode: cpu
- GPU vendor: unknown
- GPU OpenCL: no

| Repo | Exit | Duration(s) | Command | Log |
|---|---:|---:|---|---|
| asdev-portfolio | 127 | 0 | `pnpm -s test && pnpm -s build` | `/home/dev/Project_Me/asdev-standards-platform/var/autonomous-executor/logs/pipelines-max-2026-02-14/asdev-portfolio.log` |
| asdev-persiantoolbox | 127 | 0 | `pnpm -s test && pnpm -s build` | `/home/dev/Project_Me/asdev-standards-platform/var/autonomous-executor/logs/pipelines-max-2026-02-14/asdev-persiantoolbox.log` |
| asdev-family-rosca | 127 | 0 | `bun test && pnpm -s build` | `/home/dev/Project_Me/asdev-standards-platform/var/autonomous-executor/logs/pipelines-max-2026-02-14/asdev-family-rosca.log` |
| asdev-nexa-vpn | 127 | 0 | `bun test && pnpm -s build` | `/home/dev/Project_Me/asdev-standards-platform/var/autonomous-executor/logs/pipelines-max-2026-02-14/asdev-nexa-vpn.log` |
| asdev-creator-membership-ir | 127 | 0 | `pnpm -s lint && pnpm -s typecheck && pnpm -s test` | `/home/dev/Project_Me/asdev-standards-platform/var/autonomous-executor/logs/pipelines-max-2026-02-14/asdev-creator-membership-ir.log` |
| asdev-automation-hub | 127 | 0 | `pnpm -s test && pnpm -s build` | `/home/dev/Project_Me/asdev-standards-platform/var/autonomous-executor/logs/pipelines-max-2026-02-14/asdev-automation-hub.log` |
| asdev-standards-platform | 0 | 9 | `MAKEFLAGS= make ci` | `/home/dev/Project_Me/asdev-standards-platform/var/autonomous-executor/logs/pipelines-max-2026-02-14/asdev-standards-platform.log` |
| asdev-codex-reviewer | 0 | 0 | `test -f README.md` | `/home/dev/Project_Me/asdev-standards-platform/var/autonomous-executor/logs/pipelines-max-2026-02-14/asdev-codex-reviewer.log` |

## Tail Logs

### asdev-portfolio
```text
bash: line 1: pnpm: command not found
```

### asdev-persiantoolbox
```text
bash: line 1: pnpm: command not found
```

### asdev-family-rosca
```text
bash: line 1: bun: command not found
```

### asdev-nexa-vpn
```text
bash: line 1: bun: command not found
```

### asdev-creator-membership-ir
```text
bash: line 1: pnpm: command not found
```

### asdev-automation-hub
```text
bash: line 1: pnpm: command not found
```

### asdev-standards-platform
```text
Closed stale report update PR #40 (https://example.invalid/pr/40)
close stale report update PR checks passed.
dashboard reliability checks passed.
Created weekly digest issue: Weekly Governance Digest 2026-02-14
Created weekly digest issue: Weekly Governance Digest 2026-02-14
weekly digest content contract checks passed.
weekly digest repo config contract checks passed.
Switched to a new branch 'main'
Resource policy (sync): clone_parallelism=3 heavy_job_parallelism=2 worker_cap=6 e2e_workers=1 clone_timeout_seconds=90
Processing: local/repo-two
DRY_RUN=true -> skipping push and PR for local/repo-two
Sync summary -> success: 1, failed: 0, skipped: 0
sync untracked detection checks passed.
target template ID validation passed.
target template validation checks passed.
No template manifest changes detected.
template version policy checks passed.
monthly release repo config contract checks passed.
make ci target checks passed.
make reports target checks passed.
clone_failed summary checks passed.
ci workflow contract checks passed.
meaningful report delta checks passed.
status counter contract checks passed.
clone_failed summary contract checks passed.
Generated report attestation: /tmp/tmp.qCxbYeF8do/attestation.txt
Report attestation validation passed.
reports attestation contract checks passed.
digest stale cleanup workflow checks passed.
make digest-cleanup-dry-run target checks passed.
make digest-cleanup-dry-run no-open-digest checks passed.
make ci-last-run target checks passed.
make ci-last-run-json target checks passed.
ci-last-run fallback checks passed.
make ci-last-run-compact target checks passed.
ci-last-run-compact fallback checks passed.
make hygiene target checks passed.
make verify-hub target checks passed.
make verify target checks passed.
attempt=1/3
ok
result=success
attempt=1/3
fail
result=failed status=1 fingerprint=2056a28ea38a000f3a3328cb7fabe330638d3258affe1a869e3f92986222d997
attempt=2/3
fail
result=failed status=1 fingerprint=2056a28ea38a000f3a3328cb7fabe330638d3258affe1a869e3f92986222d997
halt_reason=repeated_failure_fingerprint
HALT: repeated failure detected for task demo.failure
run-task logging checks passed.
Security audit passed.
security audit checks passed.
coverage=95% covered=19 total=20 threshold=90%
Coverage threshold passed.
coverage threshold checks passed.
repo hygiene script works as expected.
agent pack contract validation passed.
Script checks passed.
make[1]: Leaving directory '/home/dev/Project_Me/asdev-standards-platform'
```

### asdev-codex-reviewer
```text
```

