# Autonomous Stack Sync (2026-02-14)

- Generated: 2026-02-14 22:56:38 UTC
- Root: /home/dev/Project_Me
- Service unit: /home/dev/.config/systemd/user/asdev-autonomous-executor.service
- Service state: active
- Service enabled: enabled
- Syntax validation: true

## Canonical Execution Scripts
- `platform/scripts/execution/apply-strategic-execution-blueprint.sh`
- `platform/scripts/execution/autonomous/autonomous-executor.sh`
- `platform/scripts/execution/autonomous/codex-bootstrap.sh`
- `platform/scripts/execution/autonomous/codex-projects-sync.sh`
- `platform/scripts/execution/autonomous/git-github-bootstrap.sh`
- `platform/scripts/execution/autonomous/launch-multitask-tmux.sh`
- `platform/scripts/execution/autonomous/start-autonomous-executor.sh`
- `platform/scripts/execution/autonomous/status-autonomous-executor.sh`
- `platform/scripts/execution/autonomous/stop-autonomous-executor.sh`
- `platform/scripts/execution/autonomous/sync-autonomous-stack.sh`
- `platform/scripts/execution/execute-priority-roadmap.sh`
- `platform/scripts/execution/generate-production-readiness-score.sh`
- `platform/scripts/execution/pipelines/run-priority-pipelines-max.sh`
- `platform/scripts/execution/pipelines/run-priority-pipelines.sh`
- `platform/scripts/execution/prioritize-roadmap-tasks.sh`
- `platform/scripts/execution/run-strategic-execution-autopilot.sh`

## Compatibility Wrappers
- `platform/scripts/apply-strategic-execution-blueprint.sh`
- `platform/scripts/autonomous-executor.sh`
- `platform/scripts/divergence-report-combined.sh`
- `platform/scripts/divergence-report.sh`
- `platform/scripts/execute-priority-roadmap.sh`
- `platform/scripts/git-github-bootstrap.sh`
- `platform/scripts/launch-multitask-tmux.sh`
- `platform/scripts/prioritize-roadmap-tasks.sh`
- `platform/scripts/run-priority-pipelines-max.sh`
- `platform/scripts/run-priority-pipelines.sh`
- `platform/scripts/run-strategic-execution-autopilot.sh`
- `platform/scripts/start-autonomous-executor.sh`
- `platform/scripts/status-autonomous-executor.sh`
- `platform/scripts/stop-autonomous-executor.sh`
- `platform/scripts/sync-autonomous-stack.sh`
- `platform/scripts/sync.sh`

## Systemd Unit (Rendered)
```ini
[Unit]
Description=ASDEV Autonomous Executor
After=default.target

[Service]
Type=simple
WorkingDirectory=/home/dev/Project_Me
EnvironmentFile=/home/dev/Project_Me/asdev-standards-platform/ops/autonomous-executor.env
ExecStart=/home/dev/Project_Me/asdev-standards-platform/platform/scripts/execution/autonomous/autonomous-executor.sh
Restart=always
RestartSec=10

[Install]
WantedBy=default.target
```
