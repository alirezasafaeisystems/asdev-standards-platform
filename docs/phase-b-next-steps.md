# Phase B Next Execution Tasks

## T1. Roll out Level 0 v1.1.0 to pilot repos
- [x] Run `DRY_RUN=true` sync against `sync/targets.yaml`.
- [x] Run live sync and open update PRs for all pilot repos.
- [x] Verify `README.md` and `CONTRIBUTING.md` are preserved where already present.

## T2. Adopt JS/TS Level 1 on one pilot repo
- [x] Select first pilot repo (recommended: `persian_tools`).
- [x] Add `platform/ci-templates/.github/workflows/js-ts-level1.yml` as repo CI workflow.
- [x] Ensure `npm run lint`, `npm run test` and optional `npm run typecheck` exist.

## T3. Measure rollout
- [x] Generate `sync/divergence-report.csv` after v1.1.0 rollout.
- [x] Record status counts: `aligned`, `diverged`, `missing`, `opted_out`.
- [x] Publish summary in a short governance update note.

## T4. Governance hardening
- [x] Add ADR-0003 for Level 1 JS/TS adoption policy.
- [x] Define upgrade cadence for template versions (monthly or per-change).

## T5. Automation hardening
- [x] Add shell tests for path resolution and preserve-doc behavior in `sync.sh`.
- [x] Add CI in `asdev_platform` to run `make lint` and `make test` on PRs.

## Next Execution Tasks (Phase C)
- [x] Expand Level 1 JS/TS rollout to `my_portfolio`.
- [x] Add `sync/targets.level1.yaml` with per-repo language-aware template selection.
- [x] Extend divergence report with `mode` and `source_ref` columns.
- [x] Add monthly release task to bump template versions and publish governance update.
- [x] Introduce ADR-0004 for multi-language Level 1 rollout strategy (Python/Go sequencing).

## Phase C Task Breakdown

### C1. JS/TS Level 1 rollout on `my_portfolio`
- [x] Create branch `chore/asdev-js-ts-level1-<date>` in `my_portfolio`.
- [x] Add `.github/workflows/asdev-js-ts-level1.yml` with package-manager-aware steps.
- [x] Verify required scripts exist: `lint`, `test`, `typecheck` (or adjust workflow for conditional typecheck).
- [x] Open PR with labels `asdev-sync` and `standards`.
- [x] Merge PR and delete rollout branch.

### C2. Level 1 target map
- [x] Create `sync/targets.level1.yaml`.
- [x] Add `my_portfolio` and `persian_tools` with JS/TS Level 1 template mapping.
- [x] Keep `patreon_iran` out of Level 1 until stack readiness is confirmed.
- [x] Add optional-feature flags for incremental adoption.

### C3. Divergence report enhancement
- [x] Update `platform/scripts/divergence-report.sh` to include `mode` and `source_ref`.
- [x] Update CSV header to:
  `repo,template_id,expected_version,detected_version,mode,source_ref,status,last_checked_at`.
- [x] Validate report generation against `sync/targets.yaml`.
- [x] Add regression check to tests for the new columns.

### C4. Monthly release automation
- [x] Add `scripts/monthly-release.sh` in `asdev_platform`.
- [x] Include tasks: version bump, divergence snapshot, governance update stub.
- [x] Add a GitHub Actions scheduled workflow (monthly UTC).
- [x] Ensure workflow opens a PR instead of direct push.

### C5. ADR-0004 for multi-language Level 1 strategy
- [x] Draft `governance/ADR/ADR-0004-multilanguage-level1-rollout.md`.
- [x] Define rollout order: JS/TS -> Python -> Go.
- [x] Define entrance criteria per language (toolchain, CI baseline, script contract).
- [x] Record exit criteria and rollback conditions for each rollout wave.

## Next Execution Tasks (Phase D)
- [x] Roll out Level 1 JS/TS workflow to `patreon_iran` after script-contract readiness.
- [x] Add Python Level 1 baseline docs and CI template (`ruff` + `pytest`) per ADR-0004 wave order.
- [x] Add Go Level 1 baseline docs and CI template (`golangci-lint` + `go test`) as draft.
- [x] Add release-note automation to include divergence deltas compared with previous snapshot.
- [x] Create a platform dashboard markdown report summarizing adoption per repo and per level.

## Next Execution Tasks (Phase E)
- [x] Execute first monthly release run and merge resulting PR.
- [x] Roll out Python Level 1 to first Python pilot repository.
- [x] Add `targets.level1.python.yaml` and `targets.level1.go.yaml` for wave-based rollout.
- [x] Extend dashboard with trend section (previous vs current divergence delta).
- [x] Add CI check that validates all target files reference known template IDs.

## Next Execution Tasks (Phase F)
- [x] Create Go pilot repository and execute first Go Level 1 rollout PR. (done: https://github.com/alirezasafaeiiidev/go-level1-pilot/pull/1)
- [x] Expand divergence report to include Level 1 targets (`targets.level1*.yaml`) in a combined report mode.
- [x] Add PR comment bot workflow that posts divergence summary on sync PRs.
- [x] Add policy check in CI that prevents template version changes without ADR/standard reference updates.
- [x] Publish a weekly governance digest issue automatically from dashboard + divergence deltas.

## Next Execution Tasks (Phase G)
- Refer to `docs/phase-g-execution-plan.md` for prioritized execution order and DoD.
- [x] Retry Go pilot repository provisioning and run first Go Level 1 sync PR when GitHub API connectivity is stable. (done: https://github.com/alirezasafaeiiidev/go-level1-pilot/pull/1)
- [x] Execute `scripts/weekly-governance-digest.sh` once manually and verify digest issue creation/update. (done: https://github.com/alirezasafaeiiidev/asdev_platform/issues/99)
- [x] Add combined-report trend section to dashboard (`sync/divergence-report.combined.csv` deltas).
- [x] Add lightweight retry/backoff to scripts that call GitHub API-heavy operations (`sync.sh`, divergence scripts).
- [x] Add runbook section for outage handling and recovery steps in `docs/`.

## Next Execution Tasks (Phase H)
- [x] Make sync PR creation resilient when labels are missing.
- [x] Add regression test for PR label fallback flow.
- [x] Re-run lint/test and confirm no regressions.

## Next Execution Tasks (Phase I)
- [x] Add `make ci-last-run-compact` target.
- [x] Enforce deterministic `ci-last-run-json` fallback contract in tests.
- [x] Add README shell automation example for `ci-last-run-json`.
- [x] Re-run full validation (`make ci`).

## Next Execution Tasks (Phase J)
- [x] (reverted) Do not enable 5-minute auto-recovery workflow globally.
- [x] Re-run full validation (`make lint` + `make test`).

## Next Execution Tasks (Phase K)
- [x] Remove `yq` PATH fragility by auto-bootstrapping it in all operational scripts that require it.
- [x] Re-run reporting and weekly digest flows to verify no runtime `yq` errors remain.
- [x] Stabilize dashboard reliability test by isolating snapshot fixtures from real snapshot history.
- [x] Re-run full validation (`make ci`) after fixes.

## Next Execution Tasks (Phase L)
- [x] Complete public-release hardening for `asdev_platform` (license, security policy, community docs).
- [x] Add release-readiness report and sanitize policy for report artifacts.
- [x] Enable repository-level security controls and branch protection on `main`.
- [x] Switch repository visibility to public after full gate checks.

## Next Execution Tasks (Phase M)
- Refer to `docs/phase-m-execution-plan.md` for prioritized execution order and DoD.
- [x] Merge and close current standardization PR wave (PR-1/PR-2/PR-4/PR-3) in controlled order.
- [x] Refresh hub reports/dashboard and publish rollout governance update.
- [x] Run full verification evidence pass after merge wave (`make setup`, `make ci`, `make test` + target repo CI-equivalent checks).
- [ ] Tighten `patreon_iran` quality scripts from transitional checks to implementation-grade checks.
- [ ] Expand payment webhook replay/signature hardening coverage and runbook guidance.
- [ ] Operationalize resource-policy caps in runtime scripts with traceable logs.
