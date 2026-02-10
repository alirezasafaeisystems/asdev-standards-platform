# Platform Adoption Dashboard

- Generated at: 2026-02-10T00:41:00Z
- Latest Weekly Governance Digest: https://github.com/alirezasafaeiiidev/asdev_platform/issues/2

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
| aligned | 23 | 23 | 0 |
| diverged | 0 | 0 | 0 |
| missing | 2 | 2 | 0 |
| opted_out | 1 | 1 | 0 |
| clone_failed | 2 | 2 | 0 |
| unknown_template | 0 | 0 | 0 |
| unknown | 0 | 0 | 0 |

## Combined Reliability (clone_failed)

| Metric | Previous | Current | Delta |
|---|---:|---:|---:|
| clone_failed rows | 2 | 2 | 0 |

### clone_failed Trend by Run

| Run | clone_failed rows |
|---|---:|
| 20260210T003955Z | 2 |
| current | 2 |
| previous | 2 |

### unknown_template Trend by Run

| Run | unknown_template rows |
|---|---:|
| 20260210T003955Z | 0 |
| current | 0 |
| previous | 0 |

### clone_failed by Repository

| Repository | Previous | Current | Delta |
|---|---:|---:|---:|
| alirezasafaeiiidev/go-level1-pilot | 1 | 1 | 0 |
| alirezasafaeiiidev/python-level1-pilot | 1 | 1 | 0 |

## Transient Error Fingerprints (Combined)

| Fingerprint | Previous | Current | Delta |
|---|---:|---:|---:|
| auth_or_access | 2 | 2 | 0 |

## Top Fingerprint Deltas (Current Run)

### Top Positive Deltas

| Fingerprint | Delta |
|---|---:|
| none | 0 |

### Top Negative Deltas

| Fingerprint | Delta |
|---|---:|
| none | 0 |

## Fingerprint Delta History (Recent Runs)

| Run | Fingerprint | Delta |
|---|---|---:|
| 20260210T003955Z | auth_or_access | 0 |
| current | auth_or_access | 0 |
| previous | auth_or_access | 0 |

## auth_or_access Trend by Run

| Run | auth_or_access count |
|---|---:|
| 20260210T003955Z | 2 |
| current | 2 |
| previous | 2 |

## timeout Trend by Run

| Run | timeout count |
|---|---:|
| 20260210T003955Z | 0 |
| current | 0 |
| previous | 0 |

## Combined Report Delta by Repo

| Repository | Previous Non-aligned | Current Non-aligned | Delta |
|---|---:|---:|---:|
| alirezasafaeiiidev/go-level1-pilot | 1 | 1 | 0 |
| alirezasafaeiiidev/my_portfolio | 1 | 1 | 0 |
| alirezasafaeiiidev/patreon_iran | 1 | 1 | 0 |
| alirezasafaeiiidev/persian_tools | 1 | 1 | 0 |
| alirezasafaeiiidev/python-level1-pilot | 1 | 1 | 0 |

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
