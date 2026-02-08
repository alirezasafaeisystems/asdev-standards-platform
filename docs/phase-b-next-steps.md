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
- [ ] Create Go pilot repository and execute first Go Level 1 rollout PR. (blocked: GitHub API timeout from execution environment)
- [x] Expand divergence report to include Level 1 targets (`targets.level1*.yaml`) in a combined report mode.
- [x] Add PR comment bot workflow that posts divergence summary on sync PRs.
- [x] Add policy check in CI that prevents template version changes without ADR/standard reference updates.
- [x] Publish a weekly governance digest issue automatically from dashboard + divergence deltas.

## Next Execution Tasks (Phase G)
- [ ] Retry Go pilot repository provisioning and run first Go Level 1 sync PR when GitHub API connectivity is stable.
- [ ] Execute `scripts/weekly-governance-digest.sh` once manually and verify digest issue creation/update.
- [ ] Add combined-report trend section to dashboard (`sync/divergence-report.combined.csv` deltas).
- [ ] Add lightweight retry/backoff to scripts that call GitHub API-heavy operations (`sync.sh`, divergence scripts).
- [ ] Add runbook section for outage handling and recovery steps in `docs/`.
