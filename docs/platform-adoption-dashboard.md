# Platform Adoption Dashboard

- Generated at: 2026-02-09T21:43:29Z

## Level 0 Adoption (from divergence report)

| Repository | Aligned | Diverged | Missing | Opted-out |
|---|---:|---:|---:|---:|
| alirezasafaeiiidev/my_portfolio | 7 | 0 | 0 | 0 |
| alirezasafaeiiidev/patreon_iran | 6 | 0 | 0 | 1 |
| alirezasafaeiiidev/persian_tools | 8 | 0 | 0 | 0 |

## Level 0 Trend (Current vs Previous Snapshot)

| Status | Previous | Current | Delta |
|---|---:|---:|---:|
| aligned | 21 | 21 | 0 |
| diverged | 0 | 0 | 0 |
| missing | 0 | 0 | 0 |
| opted_out | 1 | 1 | 0 |

## Combined Report Trend (Current vs Previous Snapshot)

| Status | Previous | Current | Delta |
|---|---:|---:|---:|
| aligned | 0 | 23 | 23 |
| diverged | 0 | 0 | 0 |
| missing | 0 | 2 | 2 |
| opted_out | 0 | 1 | 1 |
| clone_failed | 0 | 2 | 2 |
| unknown_template | 0 | 0 | 0 |
| unknown | 0 | 0 | 0 |

## Combined Reliability (clone_failed)

| Metric | Previous | Current | Delta |
|---|---:|---:|---:|
| clone_failed rows | 0 | 2 | 2 |

### clone_failed by Repository

| Repository | Previous | Current | Delta |
|---|---:|---:|---:|
| alirezasafaeiiidev/go-level1-pilot | 0 | 1 | 1 |
| alirezasafaeiiidev/python-level1-pilot | 0 | 1 | 1 |

## Transient Error Fingerprints (Combined)

| Fingerprint | Previous | Current | Delta |
|---|---:|---:|---:|
| auth_or_access | 0 | 2 | 2 |

## Combined Report Delta by Repo

| Repository | Previous Non-aligned | Current Non-aligned | Delta |
|---|---:|---:|---:|
| alirezasafaeiiidev/go-level1-pilot | 0 | 1 | 1 |
| alirezasafaeiiidev/my_portfolio | 0 | 1 | 1 |
| alirezasafaeiiidev/patreon_iran | 0 | 1 | 1 |
| alirezasafaeiiidev/persian_tools | 0 | 1 | 1 |
| alirezasafaeiiidev/python-level1-pilot | 0 | 1 | 1 |

## Level 1 Rollout Targets

| Repository | Level 1 Templates | Target File |
|---|---|---|
| alirezasafaeiiidev/go-level1-pilot | go-level1-ci | sync/targets.level1.go.yaml |
| alirezasafaeiiidev/patreon_iran | js-ts-level1-ci | sync/targets.level1.patreon.yaml |
| alirezasafaeiiidev/python-level1-pilot | python-level1-ci | sync/targets.level1.python.yaml |
| alirezasafaeiiidev/my_portfolio | js-ts-level1-ci | sync/targets.level1.yaml |
| alirezasafaeiiidev/persian_tools | js-ts-level1-ci | sync/targets.level1.yaml |
| alirezasafaeiiidev/patreon_iran | js-ts-level1-ci | sync/targets.level1.yaml |

## Notes

- Level 0 metrics are derived from `sync/divergence-report.csv`.
- Level 1 section reflects configured rollout intent from `sync/targets.level1*.yaml`.
