# Platform Adoption Dashboard

- Generated at: 2026-02-14T21:45:17Z
## Level 0 Adoption (from divergence report)

| Repository | Aligned | Diverged | Missing | Opted-out |
|---|---:|---:|---:|---:|
| alirezasafaeiiidev/asdev-creator-membership-ir | 1 | 2 | 4 | 1 |
| alirezasafaeiiidev/asdev-nexa-vpn | 0 | 0 | 8 | 0 |
| alirezasafaeiiidev/asdev-persiantoolbox | 1 | 4 | 4 | 0 |
| alirezasafaeiiidev/asdev-portfolio | 0 | 0 | 8 | 0 |

## Level 0 Trend (Current vs Previous Snapshot)

| Status | Previous | Current | Delta |
|---|---:|---:|---:|
| aligned | 2 | 2 | 0 |
| diverged | 5 | 6 | 1 |
| missing | 25 | 24 | -1 |
| opted_out | 1 | 1 | 0 |

## Combined Report Trend (Current vs Previous Snapshot)

| Status | Previous | Current | Delta |
|---|---:|---:|---:|
| aligned | 0 | 2 | 2 |
| diverged | 0 | 10 | 10 |
| missing | 0 | 35 | 35 |
| opted_out | 0 | 1 | 1 |
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
| current | 0 |
| previous | 0 |

### unknown_template Trend by Run

| Run | unknown_template rows |
|---|---:|
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
| current | none | 0 |

## auth_or_access Trend by Run

| Run | auth_or_access count |
|---|---:|
| current | 0 |

## timeout Trend by Run

| Run | timeout count |
|---|---:|
| current | 0 |

## Combined Report Delta by Repo

| Repository | Previous Non-aligned | Current Non-aligned | Delta |
|---|---:|---:|---:|
| alirezasafaeiiidev/asdev-creator-membership-ir | 0 | 11 | 11 |
| alirezasafaeiiidev/asdev-nexa-vpn | 0 | 8 | 8 |
| alirezasafaeiiidev/asdev-persiantoolbox | 0 | 14 | 14 |
| alirezasafaeiiidev/asdev-portfolio | 0 | 13 | 13 |

## Level 1 Rollout Targets

| Repository | Level 1 Templates | Target File |
|---|---|---|
|  |  | sync/targets.level1.go.yaml |
| alirezasafaeiiidev/asdev-creator-membership-ir | js-ts-level1-ci | sync/targets.level1.patreon.yaml |
|  |  | sync/targets.level1.python.yaml |
| alirezasafaeiiidev/asdev-portfolio | js-ts-level1-ci, brand-footer-attribution, brand-about-page, seo-technical-contract | sync/targets.level1.yaml |
| alirezasafaeiiidev/asdev-persiantoolbox | js-ts-level1-ci, brand-footer-attribution, brand-about-page, seo-technical-contract | sync/targets.level1.yaml |
| alirezasafaeiiidev/asdev-creator-membership-ir | js-ts-level1-ci | sync/targets.level1.yaml |

## Notes

- Level 0 metrics are derived from `sync/divergence-report.csv`.
- Level 1 section reflects configured rollout intent from `sync/targets.level1*.yaml`.
