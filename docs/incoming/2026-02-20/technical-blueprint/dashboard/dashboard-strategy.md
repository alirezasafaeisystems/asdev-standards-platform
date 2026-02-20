# Compliance Dashboard Strategy

## Goals

Provide visibility into standards adherence across repositories.

## Metrics

- Compliance Status (per repo)
- Policy Violations Count
- Trend over time
- Last Audit Timestamp

## Data Source

Generated report.json from scheduled CI audit.

## Architecture Options

Option A: Static dashboard (Chart.js + JSON)
Option B: Grafana + Prometheus (advanced)
Option C: Lightweight Next.js UI on Vercel

## Recommendation

Start with static JSON + lightweight UI deployed on Vercel.
