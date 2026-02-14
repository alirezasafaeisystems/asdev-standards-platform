[Unit]
Description=ASDEV Autonomous Executor
After=default.target

[Service]
Type=simple
WorkingDirectory={{ROOT}}
Environment=AUTOMATION_CONFIG_FILE={{ROOT}}/asdev-standards-platform/ops/automation/codex-automation.yaml
ExecStart={{ROOT}}/asdev-standards-platform/platform/scripts/execution/autonomous/autonomous-executor.sh
Restart=always
RestartSec=10

[Install]
WantedBy=default.target
