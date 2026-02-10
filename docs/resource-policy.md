# Resource Policy

- Status: Active
- Version: 1.0.0

## Purpose

Define safe default execution limits for local automation and CI-equivalent workflows.

## Local Defaults

- Repository clone/fetch parallelism: `3`
- Concurrent heavy jobs (build/test across repos): `2`
- Per-job worker cap for CPU-heavy tools: `6`
- Browser E2E worker count: `1`

These defaults are tuned for mid-range developer machines and should be reduced when system pressure is high.

## GPU Policy

- GPU is **disabled by default**.
- GPU can be used only when the tool explicitly supports the available runtime (for example ROCm/CUDA) and the workload benefits from acceleration.
- If GPU support is uncertain, run CPU-only.

## Remote/Cloud Guidance

- Prefer GitHub Actions for remote-heavy workloads (matrix builds, cross-platform validation, full E2E suites).
- Avoid ad-hoc remote execution outside standard CI unless explicitly approved.

## Operational Notes

- Keep retries bounded and logged for transient network operations.
- Fail fast on deterministic errors; retry only transient classes.
- Record command outcomes in PR evidence.

## Suggested Runtime Environment Variables

- `ASDEV_CLONE_PARALLELISM=3`
- `ASDEV_HEAVY_JOB_PARALLELISM=2`
- `ASDEV_WORKER_CAP=6`
- `ASDEV_E2E_WORKERS=1`
