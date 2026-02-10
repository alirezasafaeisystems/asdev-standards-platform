# Phase N Execution Plan

## N1) Stop report-update recursion on main (high)
- **Task ID:** N1
- **Goal:** Prevent cyclic creation of `chore/reports-docs-update` PRs after each merge on `main`.
- **Scope:**
  - Refine workflow triggers/conditions so report-update flow is not self-recursive.
  - Ensure update mode exits cleanly when change-set is equivalent or already represented by latest update PR.
- **DoD:**
  - No repeated update PR chain for unchanged semantic report state.
  - `ASDEV Platform CI` remains green after report PR merge.

## N2) Idempotent output contract (high)
- **Task ID:** N2
- **Goal:** Open update PR only when generated outputs contain meaningful deltas.
- **Scope:**
  - Define canonical equivalence policy for generated CSV/attestation/dashboard artifacts.
  - Apply normalization before diff checks where needed.
- **DoD:**
  - No-op regeneration does not produce new report-update PR.
  - Contract is test-covered.

## N3) CI regression guardrails for update lifecycle (medium)
- **Task ID:** N3
- **Goal:** Lock non-recursive behavior with tests.
- **Scope:**
  - Add/extend shell tests for workflow lifecycle scripts around update PR open/merge/skip modes.
  - Validate behavior when auto-merge is disabled and when update branch already exists.
- **DoD:**
  - Regression suite fails if update lifecycle reintroduces recursion.

## N4) Closure evidence (medium)
- **Task ID:** N4
- **Goal:** Publish clear before/after evidence for governance traceability.
- **Scope:**
  - Record run IDs showing prior churn pattern and post-fix stabilization.
  - Update governance note with residual risks and follow-ups.
- **DoD:**
  - Governance update published with linked run evidence.

## Suggested execution order
1. N1
2. N2
3. N3
4. N4
