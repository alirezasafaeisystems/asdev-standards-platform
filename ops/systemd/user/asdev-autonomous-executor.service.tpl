[Unit]
Description=ASDEV Autonomous Executor
After=default.target

[Service]
Type=simple
WorkingDirectory={{ROOT}}
EnvironmentFile={{ROOT}}/asdev-standards-platform/ops/autonomous-executor.env
ExecStart={{ROOT}}/asdev-standards-platform/platform/scripts/execution/autonomous/autonomous-executor.sh
Restart=always
RestartSec=10

[Install]
WantedBy=default.target
