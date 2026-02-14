# Local Max Execution Config (2026-02-14)

## Applied Components
- Codex CLI wrapper auto-start hook: `/home/dev/.local/bin/codex`
- Persistent user service: `~/.config/systemd/user/asdev-autonomous-executor.service`
- Runtime env profile: `asdev-standards-platform/ops/autonomous-executor.env`
- Continuous executor: `asdev-standards-platform/platform/scripts/autonomous-executor.sh`
- Max pipeline runner: `asdev-standards-platform/platform/scripts/run-priority-pipelines-max.sh`

## Performance Profile
- Execution profile: `max`
- CPU threads detected: `12`
- Max parallel jobs: `12`
- Node old-space: `12288 MB`
- UV threadpool size: `48`
- Turbo concurrency: `12`

## Network Safety Controls
- Prefer local caches for npm/pnpm
- Reduced package manager network concurrency
- Retry throttled for fetch operations
- No aggressive external crawling/scanning enabled

## GPU Note
- NVIDIA GPU not detected on this host (`nvidia-smi` unavailable)
- Pipeline currently uses CPU-max mode

## Validation
- Max pipeline report: `asdev-standards-platform/docs/reports/PRIORITY_PIPELINE_MAX_2026-02-14.md`
- Service status: active/running (`asdev-autonomous-executor.service`)
