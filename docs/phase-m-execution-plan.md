# Phase M Execution Plan

## Execution Status (2026-02-10)
- M1 complete: PR wave merged in required order (PR-1 -> PR-2 -> PR-4 -> PR-3).
- M2 complete: reports regenerated and dashboard refreshed.
- M6 complete: hub verification commands and target-repo CI-equivalent status snapshot recorded.
- M3/M4/M5 remain open follow-up tasks.

## M1) Merge and close current standardization PR wave (high)
- **Task ID:** M1
- **Goal:** Land the open PR sequence (PR-1/PR-2/PR-4/PR-3) in a controlled order and verify repository health after each merge.
- **Scope:**
  - Merge docs/templates PRs first.
  - Merge CI normalization PRs second.
  - Merge hub resource policy PR third.
  - Merge high-risk hardening PRs last.
- **DoD:**
  - All target PRs are merged (or explicitly closed with rationale).
  - No merge conflicts remain on rollout branches.
  - Post-merge CI is green per repository.

## M2) Hub alignment after merge wave (high)
- **Task ID:** M2
- **Goal:** Refresh governance evidence and keep hub status current after upstream repo merges.
- **Scope:**
  - Regenerate combined divergence outputs.
  - Refresh platform adoption dashboard.
  - Add governance update note summarizing this rollout wave.
- **DoD:**
  - `make reports` succeeds.
  - `docs/platform-adoption-dashboard.md` reflects latest merged state.
  - Governance update note is added under `governance/updates-*`.

## M3) CI policy tightening follow-up for `patreon_iran` (medium)
- **Task ID:** M3
- **Goal:** Replace temporary no-code quality gates with real lint/typecheck/test commands as implementation code lands.
- **Scope:**
  - Track each placeholder-equivalent command and map to real toolchain checks.
  - Update CI/docs to reflect actual contract.
- **DoD:**
  - `lint`, `typecheck`, `test:unit`, `test:integration`, `test:e2e` run real checks against source code.
  - No TODO-like script placeholders remain in `package.json`.

## M4) Payment webhook hardening expansion (medium)
- **Task ID:** M4
- **Goal:** Extend webhook hardening pattern to end-to-end safety controls.
- **Scope:**
  - Add replay-id/timestamp policy and runbook notes.
  - Expand tests for duplicate callback and stale signature scenarios.
  - Verify no sensitive webhook payload data is logged.
- **DoD:**
  - Security test coverage includes replay and stale-signature paths.
  - Runbook/documentation updated with operational handling guidance.

## M5) Resource-policy operationalization (medium)
- **Task ID:** M5
- **Goal:** Move resource defaults from documentation into enforceable script behavior.
- **Scope:**
  - Add optional env-driven caps in long-running scripts (`sync`, combined divergence/report generation).
  - Emit runtime cap values in script logs for traceability.
- **DoD:**
  - Script execution respects documented defaults when env vars are unset.
  - Runtime logs include active resource policy values.

## M6) Full verification and closure report (high)
- **Task ID:** M6
- **Goal:** Close the wave with reproducible evidence.
- **Scope:**
  - Hub: `make setup`, `make ci`, `make test`
  - Target repos: run each repository’s CI-equivalent command set.
  - Record outcomes and known residual risks.
- **DoD:**
  - Verification summary exists and links to command outcomes.
  - Residual risks/open follow-ups are explicitly listed.

## Suggested execution order
1. M1
2. M2
3. M6
4. M3
5. M4
6. M5
