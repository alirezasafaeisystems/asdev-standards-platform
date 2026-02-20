#!/usr/bin/env bash
set -euo pipefail

report_json="docs/compliance-dashboard/report.json"
history_json="docs/compliance-dashboard/history.json"
output_file="docs/reports/MONTHLY_EXECUTIVE_SUMMARY.md"
slo_status_file="docs/reports/AUTOMATION_SLO_STATUS.md"

bash scripts/generate-automation-slo-status.sh "$report_json" "docs/compliance-dashboard/attestation.json" "$slo_status_file"

python3 - <<'PY' "$report_json" "$history_json" "$output_file" "$slo_status_file"
import json
import statistics
import sys
from pathlib import Path

report = json.loads(Path(sys.argv[1]).read_text(encoding='utf-8'))
history = json.loads(Path(sys.argv[2]).read_text(encoding='utf-8')) if Path(sys.argv[2]).exists() else {'points': []}
output = Path(sys.argv[3])
slo_status_file = sys.argv[4]

points = history.get('points', [])
scores = [float(p.get('compliance_score', 0)) for p in points] if points else [float(report.get('compliance_score', 0))]
current = float(report.get('compliance_score', 0))
previous = float(scores[-2]) if len(scores) > 1 else current
delta = round(current - previous, 2)
avg = round(statistics.mean(scores), 2) if scores else current

content = f'''# Monthly Executive Summary

- repo: {report.get("repo", "asdev-standards-platform")}
- generated_at_utc: {report.get("generated_at_utc", "")}
- current_compliance_score: {current}
- previous_compliance_score: {previous}
- delta: {delta}
- average_score: {avg}
- history_points: {len(scores)}

## Executive Notes
- Compliance trend should remain above baseline threshold.
- Review failed/unknown checks and assign owners.
- Reference automation SLO status: {slo_status_file}
'''

output.parent.mkdir(parents=True, exist_ok=True)
output.write_text(content, encoding='utf-8')
PY

echo "Monthly executive summary generated: $output_file"
