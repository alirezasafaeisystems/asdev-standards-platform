# Governance Update: Phase N Closure (2026-02-10)

## Scope
- N1: stop report-update recursion on `main`.
- N2: enforce idempotent generated-output contract.
- N3: add CI regression guardrails for update lifecycle.
- N4: publish before/after evidence.

## Evidence (before -> after)
- Repeated report-update PR churn on `main` before stabilization:
  - `#105`, `#107`, `#108`, `#110`, `#111`, `#112`, `#113`
  - Source query: `gh pr list --search "chore: update divergence report and dashboard"`.
- Workflow instability before fix:
  - Failure run: https://github.com/alirezasafaeiiidev/asdev_platform/actions/runs/21880416187
  - Failure run: https://github.com/alirezasafaeiiidev/asdev_platform/actions/runs/21880490687
- Post-fix stable run on `main`:
  - Success run: https://github.com/alirezasafaeiiidev/asdev_platform/actions/runs/21880570333
  - Report update jobs were skipped on push, preventing recursive PR creation.

## Technical controls implemented
- Normalized equivalence for generated artifacts before opening update PR:
  - Ignore runtime-only timestamp lines in:
    - `sync/generated-reports.attestation` (`validated_at`)
    - `docs/platform-adoption-dashboard.md` (`Generated at`)
  - Normalize CSV row ordering before comparison.
- Added detector and wired workflow gate:
  - `scripts/normalize-report-output.sh`
  - `scripts/detect-meaningful-report-delta.sh`
  - `.github/workflows/ci.yml` `Detect generated changes` step now uses meaningful deltas.
- Added guardrail tests:
  - `tests/test_detect_meaningful_report_delta.sh`
  - `tests/test_ci_workflow_contract.sh`

## Verification results
- `make setup`: passed
- `make ci`: passed
- `make test`: passed

## Residual risk and follow-up
- Report-update automation is currently schedule-only by policy; if push-triggered report jobs are reintroduced, keep the meaningful-delta detector in path.
- If dashboard/attestation formats add new runtime metadata fields, extend normalization rules and tests in the same change.
