# Governance Update - 2026-02-10 (Phase L: Public Release)

## Summary

- Completed public-release hardening for `asdev_platform`.
- Added legal/security/community baseline documents.
- Added sanitize policy and script for public report artifacts.
- Enabled branch protection and repository security controls.
- Switched repository visibility to `public`.

## Implemented

- Added:
  - `LICENSE` (MIT)
  - `SECURITY.md`
  - `CODE_OF_CONDUCT.md`
  - `SUPPORT.md`
  - `docs/publication-readiness.md`
  - `scripts/sanitize-public-reports.sh`
- Updated:
  - `README.md` with public scope, license/security references, and sanitize policy.
  - `Makefile` lint scope to include `scripts/sanitize-public-reports.sh`.

## GitHub Controls

- Branch protection (`main`) enabled:
  - required approving reviews: `1`
  - dismiss stale reviews: `true`
  - required conversation resolution: `true`
  - force push: disabled
  - branch deletion: disabled
- Security features enabled:
  - secret scanning
  - push protection
  - dependabot security updates

## Public Release Coordination

- Visibility switched: `alirezasafaeiiidev/asdev_platform` -> `PUBLIC`
- Public release notice issue:
  - `https://github.com/alirezasafaeiiidev/asdev_platform/issues/100`

## Validation Evidence

- `make lint` passed
- `make test` passed
