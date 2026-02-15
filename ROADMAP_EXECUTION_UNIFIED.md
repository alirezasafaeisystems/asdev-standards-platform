# Unified Execution Roadmap (All ASDEV Projects)

## Scope
این نقشه راه تنها سند اجرایی مرجع برای کل پروژه‌ها است:
- asdev-automation-hub
- asdev-codex-reviewer
- asdev-creator-membership-ir
- asdev-family-rosca
- asdev-nexa-vpn
- asdev-persiantoolbox
- asdev-portfolio
- asdev-standards-platform

## Priority Order
1. asdev-standards-platform
2. asdev-portfolio
3. asdev-persiantoolbox
4. asdev-automation-hub
5. asdev-creator-membership-ir
6. asdev-family-rosca
7. asdev-nexa-vpn
8. asdev-codex-reviewer

## Phase 0 - Stabilization (Critical)
### Tasks
- [ ] Freeze runtime automation during release windows.
- [ ] Enforce single-branch sync policy on `main` for all repos.
- [ ] Remove legacy tokens/secrets and validate GitHub App auth only.
- [ ] Baseline health checks: lint, typecheck, test, build.

## Phase 1 - Delivery Core (High)
### Tasks
- [ ] asdev-portfolio: finalize lead funnel + service pages + API stability.
- [ ] asdev-persiantoolbox: stabilize release gates and licensing contracts.
- [ ] asdev-automation-hub: harden orchestration workflows and admin controls.
- [ ] asdev-standards-platform: keep standards sync and governance automation green.

## Phase 2 - Product Reliability (High)
### Tasks
- [ ] Add deterministic CI gates for each repo (quality/security/contracts).
- [ ] Standardize release checklist and rollback drill across projects.
- [ ] Add dependency/security audit cadence with fail-on-critical policy.
- [ ] Track production readiness score per repo weekly.

## Phase 3 - Growth Execution (Medium)
### Tasks
- [ ] asdev-creator-membership-ir: monetization flow and conversion metrics.
- [ ] asdev-family-rosca: onboarding and trust/SEO hardening.
- [ ] asdev-nexa-vpn: acquisition pages + technical SEO + deployment reliability.
- [ ] Cross-repo: shared analytics KPIs (traffic, leads, conversion, retention).

## Phase 4 - Operational Excellence (Medium)
### Tasks
- [ ] Full incident runbook per repo (alerts, triage, owner, SLA).
- [ ] Weekly executive dashboard from one data pipeline.
- [ ] Remove redundant scripts/config drift between repos.
- [ ] Enforce ownership map and bus-factor reduction for critical paths.

## Phase 5 - Scale and Automation (Ongoing)
### Tasks
- [ ] Automatic dependency update and compatibility verification.
- [ ] Scheduled autonomous maintenance PRs with strict merge policies.
- [ ] Cost/performance optimization per service and environment.
- [ ] Quarterly roadmap re-prioritization based on KPI outcomes.

## Definition of Done (Per Task)
- [ ] Code merged to `main`
- [ ] CI green
- [ ] Security checks green
- [ ] Operational owner assigned
- [ ] KPI impact recorded

## Remaining Execution Task Queue (Actionable)

> هدف: تبدیل تمام آیتم‌های باقی‌مانده‌ی نقشه راه به تسک‌های اجرایی قابل پیگیری.

| Task ID | Phase | Scope | Task | Priority | Suggested Owner | Depends On |
| --- | --- | --- | --- | --- | --- | --- |
| EXE-P0-01 | Phase 0 | Cross-repo | Freeze runtime automation during release windows | Critical | DevOps Lead | - |
| EXE-P0-02 | Phase 0 | Cross-repo | Enforce single-branch sync policy on `main` for all repos | Critical | Platform Owner | EXE-P0-01 |
| EXE-P0-03 | Phase 0 | Cross-repo | Remove legacy tokens/secrets and validate GitHub App auth only | Critical | Security Owner | EXE-P0-01 |
| EXE-P0-04 | Phase 0 | Cross-repo | Baseline health checks: lint, typecheck, test, build | Critical | QA/Release Owner | EXE-P0-02 |
| EXE-P1-01 | Phase 1 | asdev-portfolio | Finalize lead funnel + service pages + API stability | High | Product + Backend Lead | EXE-P0-04 |
| EXE-P1-02 | Phase 1 | asdev-persiantoolbox | Stabilize release gates and licensing contracts | High | Product Ops Lead | EXE-P0-04 |
| EXE-P1-03 | Phase 1 | asdev-automation-hub | Harden orchestration workflows and admin controls | High | Automation Lead | EXE-P0-04 |
| EXE-P1-04 | Phase 1 | asdev-standards-platform | Keep standards sync and governance automation green | High | Standards Maintainer | EXE-P0-04 |
| EXE-P2-01 | Phase 2 | Cross-repo | Add deterministic CI gates for each repo (quality/security/contracts) | High | Platform Engineering | EXE-P1-01, EXE-P1-02, EXE-P1-03, EXE-P1-04 |
| EXE-P2-02 | Phase 2 | Cross-repo | Standardize release checklist and rollback drill across projects | High | Release Manager | EXE-P2-01 |
| EXE-P2-03 | Phase 2 | Cross-repo | Add dependency/security audit cadence with fail-on-critical policy | High | Security + DevOps | EXE-P2-01 |
| EXE-P2-04 | Phase 2 | Cross-repo | Track production readiness score per repo weekly | High | PMO/Operations | EXE-P2-02, EXE-P2-03 |
| EXE-P3-01 | Phase 3 | asdev-creator-membership-ir | Implement monetization flow and conversion metrics | Medium | Growth PM | EXE-P2-04 |
| EXE-P3-02 | Phase 3 | asdev-family-rosca | Harden onboarding and trust/SEO foundations | Medium | Product + SEO Lead | EXE-P2-04 |
| EXE-P3-03 | Phase 3 | asdev-nexa-vpn | Build acquisition pages + technical SEO + deployment reliability | Medium | Growth Engineering | EXE-P2-04 |
| EXE-P3-04 | Phase 3 | Cross-repo | Unify analytics KPIs (traffic, leads, conversion, retention) | Medium | Data/Analytics Owner | EXE-P3-01, EXE-P3-02, EXE-P3-03 |
| EXE-P4-01 | Phase 4 | Cross-repo | Build full incident runbook per repo (alerts, triage, owner, SLA) | Medium | SRE Lead | EXE-P2-02 |
| EXE-P4-02 | Phase 4 | Cross-repo | Publish weekly executive dashboard from one data pipeline | Medium | Operations Analytics | EXE-P3-04 |
| EXE-P4-03 | Phase 4 | Cross-repo | Remove redundant scripts/config drift between repos | Medium | Platform Engineering | EXE-P2-01 |
| EXE-P4-04 | Phase 4 | Cross-repo | Enforce ownership map and bus-factor reduction for critical paths | Medium | Engineering Manager | EXE-P4-01 |
| EXE-P5-01 | Phase 5 | Cross-repo | Enable automatic dependency updates + compatibility verification | Ongoing | Platform Engineering | EXE-P2-03 |
| EXE-P5-02 | Phase 5 | Cross-repo | Schedule autonomous maintenance PRs with strict merge policies | Ongoing | Automation Lead | EXE-P5-01 |
| EXE-P5-03 | Phase 5 | Cross-repo | Optimize cost/performance per service and environment | Ongoing | FinOps + DevOps | EXE-P4-02 |
| EXE-P5-04 | Phase 5 | Cross-repo | Quarterly roadmap re-prioritization based on KPI outcomes | Ongoing | Leadership/PMO | EXE-P4-02 |
| EXE-DOD-01 | Definition of Done | Cross-repo | Code merged to `main` | Required | Repo Owner | Related feature task |
| EXE-DOD-02 | Definition of Done | Cross-repo | CI green | Required | Repo Owner | EXE-DOD-01 |
| EXE-DOD-03 | Definition of Done | Cross-repo | Security checks green | Required | Security Owner | EXE-DOD-02 |
| EXE-DOD-04 | Definition of Done | Cross-repo | Operational owner assigned | Required | Engineering Manager | EXE-DOD-01 |
| EXE-DOD-05 | Definition of Done | Cross-repo | KPI impact recorded | Required | Product/PMO | EXE-DOD-03, EXE-DOD-04 |

### Suggested Execution Sprint Order
1. **Sprint A (Stabilization):** EXE-P0-01 .. EXE-P0-04
2. **Sprint B (Delivery Core):** EXE-P1-01 .. EXE-P1-04
3. **Sprint C (Reliability):** EXE-P2-01 .. EXE-P2-04
4. **Sprint D (Growth):** EXE-P3-01 .. EXE-P3-04
5. **Sprint E (Ops Excellence):** EXE-P4-01 .. EXE-P4-04
6. **Sprint F (Scale Automation):** EXE-P5-01 .. EXE-P5-04 + EXE-DOD-01 .. EXE-DOD-05
