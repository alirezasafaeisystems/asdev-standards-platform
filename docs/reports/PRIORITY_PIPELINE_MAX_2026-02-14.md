# Priority Pipeline MAX Run (2026-02-14)

- Executed (UTC): 2026-02-14 13:11:35 UTC
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
| asdev-creator-membership-ir | 127 | 0 | `pnpm -s test && pnpm -s build` | `/home/dev/Project_Me/asdev-standards-platform/var/autonomous-executor/logs/pipelines-max-2026-02-14/asdev-creator-membership-ir.log` |
| asdev-automation-hub | 127 | 0 | `pnpm -s test && pnpm -s build` | `/home/dev/Project_Me/asdev-standards-platform/var/autonomous-executor/logs/pipelines-max-2026-02-14/asdev-automation-hub.log` |
| asdev-standards-platform | 2 | 8 | `make ci` | `/home/dev/Project_Me/asdev-standards-platform/var/autonomous-executor/logs/pipelines-max-2026-02-14/asdev-standards-platform.log` |
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
Report attestation validation passed.
Generated report attestation: /tmp/tmp.Mza1hDpFPc/attestation.txt
Generated report attestation: /tmp/tmp.Mza1hDpFPc/attestation.txt
Generated report attestation: /tmp/tmp.Mza1hDpFPc/attestation.txt
Generated report attestation: /tmp/tmp.Mza1hDpFPc/attestation.txt
Generated report attestation: /tmp/tmp.Mza1hDpFPc/attestation.txt
report attestation checks passed.
Report snapshots rotated under /tmp/tmp.YkDssUnm5l/sync
rotate snapshot retention checks passed.
error fingerprint trend summary checks passed.
Closed stale weekly digest #2 (https://example.invalid/issues/2)
stale weekly digest lifecycle checks passed.
stale weekly digest dry-run checks passed.
Keeping newest report update PR #42 open.
Closed superseded report update PR #41 (https://example.invalid/pr/41)
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
make[2]: warning: jobserver unavailable: using -j1.  Add '+' to parent make rule.
make ci target checks passed.
make[2]: warning: jobserver unavailable: using -j1.  Add '+' to parent make rule.
make reports target checks passed.
clone_failed summary checks passed.
ci workflow contract checks passed.
meaningful report delta checks passed.
status counter contract checks passed.
clone_failed summary contract checks passed.
Generated report attestation: /tmp/tmp.9AYjaNh5Wq/attestation.txt
Report attestation validation passed.
reports attestation contract checks passed.
digest stale cleanup workflow checks passed.
make[2]: warning: jobserver unavailable: using -j1.  Add '+' to parent make rule.
make digest-cleanup-dry-run target checks passed.
make[2]: warning: jobserver unavailable: using -j1.  Add '+' to parent make rule.
make digest-cleanup-dry-run no-open-digest checks passed.
make[2]: warning: jobserver unavailable: using -j1.  Add '+' to parent make rule.
make[2]: warning: jobserver unavailable: using -j1.  Add '+' to parent make rule.
make ci-last-run target checks passed.
make ci-last-run-json target checks passed.
make[2]: warning: jobserver unavailable: using -j1.  Add '+' to parent make rule.
make[2]: warning: jobserver unavailable: using -j1.  Add '+' to parent make rule.
Expected ci-last-run-json fallback to output {} when gh is unavailable
make[1]: *** [Makefile:58: test] Error 1
make[1]: Leaving directory '/home/dev/Project_Me/asdev-standards-platform'
make: *** [Makefile:88: ci] Error 2
```

### asdev-codex-reviewer
```text
```

