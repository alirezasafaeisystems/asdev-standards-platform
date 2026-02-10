# Phase L Execution Plan

## L1) Public release hardening baseline (high)
- **Task ID:** L1
- **Goal:** Add minimum legal/security/community files required for public operation.
- **DoD:**
  - `LICENSE` (MIT) exists.
  - `SECURITY.md` exists with responsible disclosure and SLA.
  - `CODE_OF_CONDUCT.md` and `SUPPORT.md` exist.
  - `README.md` documents public scope, license, and security links.

## L2) Data sanitize and release-readiness evidence (high)
- **Task ID:** L2
- **Goal:** Keep transparent report artifacts while removing non-essential identity detail.
- **DoD:**
  - `scripts/sanitize-public-reports.sh` exists and is linted.
  - Tracked report CSV artifacts under `sync/` are sanitized.
  - `docs/publication-readiness.md` records checks and evidence.

## L3) Policy controls on GitHub (high)
- **Task ID:** L3
- **Goal:** Enforce basic protection and security scanning defaults.
- **DoD:**
  - Branch protection enabled on `main` (PR review + conversation resolution).
  - Secret scanning + push protection + dependabot security updates enabled.

## L4) Visibility switch and coordination (high)
- **Task ID:** L4
- **Goal:** Make repository public with release communication.
- **DoD:**
  - `asdev_platform` visibility switched to `public`.
  - Public release notice issue created and linked.

## Status
- [x] L1 done
- [x] L2 done
- [x] L3 done
- [x] L4 done
