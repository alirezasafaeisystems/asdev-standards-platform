# Platform Adoption Dashboard

- Generated at: 2026-02-10T18:36:39Z
## Level 0 Adoption (from divergence report)

| Repository | Aligned | Diverged | Missing | Opted-out |
|---|---:|---:|---:|---:|
| my_portfolio | 7 | 0 | 0 | 0 |
| patreon_iran | 6 | 0 | 0 | 1 |
| persian_tools | 8 | 0 | 0 | 0 |

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
| aligned | 27 | 13 | -14 |
| diverged | 0 | 20 | 20 |
| missing | 0 | 3 | 3 |
| opted_out | 1 | 1 | 0 |
| clone_failed | 0 | 0 | 0 |
| unknown_template | 0 | 0 | 0 |
| unknown | 0 | 0 | 0 |

## Combined Reliability (clone_failed)

| Metric | Previous | Current | Delta |
|---|---:|---:|---:|
| clone_failed rows | 0 | 0 | 0 |

### clone_failed Trend by Run

| Run | clone_failed rows |
|---|---:|
| 20260209T100000Z | 2 |
| 20260210T134011Z | 2 |
| 20260210T183518Z | 0 |
| current | 0 |
| previous | 0 |

### unknown_template Trend by Run

| Run | unknown_template rows |
|---|---:|
| 20260209T100000Z | 1 |
| 20260210T134011Z | 0 |
| 20260210T183518Z | 0 |
| current | 0 |
| previous | 0 |

### clone_failed by Repository

| Repository | Previous | Current | Delta |
|---|---:|---:|---:|
| n/a | 0 | 0 | 0 |

## Transient Error Fingerprints (Combined)

| Fingerprint | Previous | Current | Delta |
|---|---:|---:|---:|
| n/a | 0 | 0 | 0 |

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
| 20260209T100000Z | auth_or_access | 3 |
| 20260209T100000Z | timeout | 5 |
| 20260209T100000Z | tls_error | 2 |
| 20260210T134011Z | auth_or_access | 3 |
| 20260210T134011Z | timeout | -1 |
| 20260210T134011Z | tls_error | 2 |
| 20260210T183518Z | auth_or_access | -2 |
| current | none | 0 |
| previous | auth_or_access | -2 |

## auth_or_access Trend by Run

| Run | auth_or_access count |
|---|---:|
| 20260209T100000Z | 3 |
| 20260210T134011Z | 4 |
| 20260210T183518Z | 0 |
| current | 0 |
| previous | 0 |

## timeout Trend by Run

| Run | timeout count |
|---|---:|
| 20260209T100000Z | 5 |
| 20260210T134011Z | 1 |
| 20260210T183518Z | 0 |
| current | 0 |
| previous | 0 |

## Combined Report Delta by Repo

| Repository | Previous Non-aligned | Current Non-aligned | Delta |
|---|---:|---:|---:|
| alirezasafaeiiidev/go-level1-pilot | 0 | 1 | 1 |
| alirezasafaeiiidev/my_portfolio | 0 | 7 | 7 |
| alirezasafaeiiidev/patreon_iran | 0 | 8 | 8 |
| alirezasafaeiiidev/persian_tools | 0 | 7 | 7 |
| alirezasafaeiiidev/python-level1-pilot | 0 | 1 | 1 |
| go-level1-pilot | 0 | 0 | 0 |
| my_portfolio | 0 | 0 | 0 |
| patreon_iran | 1 | 0 | -1 |
| persian_tools | 0 | 0 | 0 |
| python-level1-pilot | 0 | 0 | 0 |

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
