# Automation Runbook (Codex CLI)

## Scope
This runbook covers the local automation stack in `asdev-standards-platform`:
- `asdev-autopilot.service`
- `asdev-autonomous-executor.service`

Main config file:
- `ops/automation/codex-automation.yaml`

## Start / Stop / Status
From `asdev-standards-platform`:

```bash
# start/enable both services
bash scripts/autopilot-install-user-service.sh
bash platform/scripts/execution/autonomous/sync-autonomous-stack.sh

# stop autopilot
bash scripts/autopilot-stop.sh

# status
systemctl --user status asdev-autopilot.service --no-pager --lines=40
systemctl --user status asdev-autonomous-executor.service --no-pager --lines=40
```

## Logs and Reports
Primary runtime paths:
- `var/automation/autopilot/autopilot.log`
- `var/automation/autopilot/errors.log`
- `var/automation/autonomous-executor/logs/autonomous-executor.log`
- `var/automation/autonomous-executor/error-registry.log`
- `var/automation/reports/`

Quick tail:

```bash
tail -n 80 var/automation/autopilot/autopilot.log
tail -n 80 var/automation/autopilot/errors.log
tail -n 80 var/automation/autonomous-executor/logs/autonomous-executor.log
```

## After Config Changes
If you edit `ops/automation/codex-automation.yaml`:

```bash
systemctl --user daemon-reload
systemctl --user restart asdev-autopilot.service
systemctl --user restart asdev-autonomous-executor.service
```

## Reset Once Tasks
`autopilot` marks `once` tasks as done in `var/automation/autopilot/done/`.
To rerun all once tasks:

```bash
find var/automation/autopilot/done -type f ! -name '.keep' -delete
systemctl --user restart asdev-autopilot.service
```

## Fast Validation
Run all configured tasks once (manual verification):

```bash
bash -lc 'source scripts/lib/codex-automation-config.sh; while IFS=$'\''\t'\'' read -r id mode repo cmd fix; do (cd "$(cfg_workspace_root)/$repo" && bash -lc "$cmd") || { echo "FAIL $id"; exit 1; }; done < <(cfg_task_lines_tsv); echo OK'
```

## Common Failures
- `No such file or directory` for old paths like `docs/reports` or `var/autonomous-executor`:
  - Cause: old scripts/config.
  - Fix: ensure services use current files under `ops/systemd/` and config at `ops/automation/codex-automation.yaml`.

- `autopilot` does not run once tasks again:
  - Cause: done markers exist.
  - Fix: clear `var/automation/autopilot/done/*` (except `.keep`) and restart service.

- Historical errors still visible in `errors.log`:
  - Cause: file is append-only across runs.
  - Fix: archive or truncate logs if needed before a clean verification window.
