# CI Expectations Policy

- Status: Active
- Version: 1.0.0

## Minimum Contract

All repositories should provide CI that runs on pull requests and default-branch pushes.

Required categories:

- Lint or static checks
- Tests
- Build (when applicable)

## Progressive Contract

- Level 0: placeholder quality gate is acceptable temporarily.
- Level 1: stack-specific lint/test/typecheck with real commands.

## PR Evidence

PRs must include local verification commands and outcomes matching CI gates.
