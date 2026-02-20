#!/usr/bin/env bash
set -euo pipefail

report_json="docs/compliance-dashboard/report.json"
output_file="docs/reports/WEEKLY_COMPLIANCE_SUMMARY.md"
slo_status_file="docs/reports/AUTOMATION_SLO_STATUS.md"

[[ -f "$report_json" ]] || {
  echo "Missing $report_json" >&2
  exit 1
}

readarray -t metrics < <(python3 - <<'PY'
import json
from pathlib import Path

p = Path("docs/compliance-dashboard/report.json")
obj = json.loads(p.read_text(encoding="utf-8"))
checks = obj.get("checks", [])
success = sum(1 for c in checks if c.get("status") == "success")
skipped = sum(1 for c in checks if c.get("status") == "skipped")
failed = sum(1 for c in checks if c.get("status") == "failed")
unknown = sum(1 for c in checks if c.get("status") == "unknown")
print(obj.get("generated_at_utc", ""))
print(obj.get("repo", ""))
print(obj.get("compliance_score", 0))
print(len(checks))
print(success)
print(skipped)
print(failed)
print(unknown)
PY
)

generated_at="${metrics[0]}"
repo="${metrics[1]}"
score="${metrics[2]}"
total="${metrics[3]}"
success="${metrics[4]}"
skipped="${metrics[5]}"
failed="${metrics[6]}"
unknown="${metrics[7]}"

bash scripts/generate-automation-slo-status.sh "$report_json" "docs/compliance-dashboard/attestation.json" "$slo_status_file"

cat > "$output_file" <<EOF_SUM
# Weekly Compliance Summary

- generated_at_utc: ${generated_at}
- repo: ${repo}
- compliance_score: ${score}
- total_checks: ${total}
- success: ${success}
- skipped: ${skipped}
- failed: ${failed}
- unknown: ${unknown}
- automation_slo_status: ${slo_status_file}
EOF_SUM

echo "Weekly KPI summary generated: $output_file"
