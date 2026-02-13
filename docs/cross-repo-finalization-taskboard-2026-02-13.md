# Cross-Repo Finalization Taskboard (2026-02-13)

Scope: `asdev-automation-hub`, `asdev-portfolio`, `asdev-persiantoolbox`, `asdev-standards-platform`

## Current Snapshot

- All four repositories have open PRs with green CI.
- `main` branch protection is enabled in all four repositories.
- Merge is currently blocked only by `REVIEW_REQUIRED` (minimum one approving review with CODEOWNERS requirement).
- Auto-merge is enabled for all four PRs with squash strategy.

## Repo Matrix

| Repository | PR | CI State | Merge Gate | Auto-Merge |
| --- | --- | --- | --- | --- |
| `asdev-automation-hub` | #2 | Pass | 1 approval + CODEOWNERS review + resolved conversations | Enabled |
| `asdev-portfolio` | #14 | Pass | 1 approval + CODEOWNERS review + resolved conversations | Enabled |
| `asdev-persiantoolbox` | #15 | Pass | 1 approval + CODEOWNERS review + resolved conversations | Enabled |
| `asdev-standards-platform` | #123 | Pass | 1 approval + CODEOWNERS review + resolved conversations | Enabled |

## Phase-Based Execution (No Calendar Dependency)

### Phase 1: Merge Gate Completion

- [ ] Get one non-author approving review on each PR.
- [ ] Ensure review satisfies CODEOWNERS requirement.
- [ ] Ensure all PR conversations are resolved.

### Phase 2: Automatic Merge Confirmation

- [ ] Confirm each PR is merged by auto-merge.
- [ ] Confirm remote branch is deleted after merge.
- [ ] Confirm required checks remain green on merge commit.

### Phase 3: Post-Merge Stabilization

- [ ] Pull latest `main` locally in all four repositories.
- [ ] Tag release candidate or patch version where applicable.
- [ ] Run smoke verification on merged `main`.
- [ ] Confirm branch protection contexts still match active workflow names.

### Phase 4: Hardening Follow-Up

- [ ] Add reviewer rotation policy for CODEOWNERS paths.
- [ ] Add merge runbook references to each repository README.
- [ ] Archive this taskboard after all checkboxes are complete.

## Parallel Execution Profile

Use these in parallel sessions to maximize local throughput:

```bash
# Session A: watch PR checks
watch -n 20 'gh pr checks 2 --repo alirezasafaeiiidev/asdev-automation-hub && echo && gh pr checks 14 --repo alirezasafaeiiidev/asdev-portfolio'

# Session B: watch remaining repos
watch -n 20 'gh pr checks 15 --repo alirezasafaeiiidev/asdev-persiantoolbox && echo && gh pr checks 123 --repo alirezasafaeiiidev/asdev-standards-platform'

# Session C: watch merge state
watch -n 20 'gh pr view 2 --repo alirezasafaeiiidev/asdev-automation-hub --json mergeStateStatus,reviewDecision && echo && gh pr view 14 --repo alirezasafaeiiidev/asdev-portfolio --json mergeStateStatus,reviewDecision && echo && gh pr view 15 --repo alirezasafaeiiidev/asdev-persiantoolbox --json mergeStateStatus,reviewDecision && echo && gh pr view 123 --repo alirezasafaeiiidev/asdev-standards-platform --json mergeStateStatus,reviewDecision'
```

## Definition of Done

- [ ] All 4 PRs merged to `main`.
- [ ] No required check is failing on `main` after merge.
- [ ] Protection policies are still active and aligned with workflows.
- [ ] Remaining follow-up issue list is empty or moved to backlog.
