#!/usr/bin/env bash
set -euo pipefail

report_json="${1:-docs/compliance-dashboard/report.json}"
attestation_json="${2:-docs/compliance-dashboard/attestation.json}"
output_file="${3:-docs/reports/AUTOMATION_SLO_STATUS.md}"
freshness_hours_target="${SLO_FRESHNESS_HOURS_TARGET:-192}"

attestation_status="pass"
if ! bash scripts/validate-compliance-attestation.sh "$attestation_json" >/dev/null 2>&1; then
  attestation_status="fail"
fi

readarray -t metrics < <(python3 - <<'PY' "$report_json" "$freshness_hours_target"
import json
import sys
from datetime import datetime, timezone
from pathlib import Path

report = Path(sys.argv[1])
target_hours = int(sys.argv[2])
obj = json.loads(report.read_text(encoding="utf-8"))
generated = obj.get("generated_at_utc", "")
score = float(obj.get("compliance_score", 0))

dt = datetime.strptime(generated, "%Y-%m-%dT%H:%M:%SZ").replace(tzinfo=timezone.utc)
now = datetime.now(timezone.utc)
age_hours = int((now - dt).total_seconds() // 3600)
freshness = "pass" if age_hours <= target_hours else "warn"

print(generated)
print(age_hours)
print(score)
print(freshness)
PY
)

generated_at="${metrics[0]}"
age_hours="${metrics[1]}"
score="${metrics[2]}"
freshness_status="${metrics[3]}"

overall="pass"
if [[ "$attestation_status" != "pass" ]]; then
  overall="fail"
elif [[ "$freshness_status" != "pass" ]]; then
  overall="warn"
fi

cat > "$output_file" <<EOF_SUM
# Automation SLO Status

- generated_at_utc: ${generated_at}
- overall_status: ${overall}
- required_check_emission: policy_enforced_in_branch_protection
- compliance_artifact_attestation: ${attestation_status}
- compliance_report_freshness_hours: ${age_hours}
- compliance_report_freshness_target_hours: ${freshness_hours_target}
- compliance_report_freshness_status: ${freshness_status}
- current_compliance_score: ${score}
EOF_SUM

echo "Automation SLO status generated: $output_file"
