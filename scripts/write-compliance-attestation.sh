#!/usr/bin/env bash
set -euo pipefail

output_file="${1:-docs/compliance-dashboard/attestation.json}"
shift || true

if [[ "$#" -eq 0 ]]; then
  files=(
    "docs/compliance-dashboard/report.json"
    "docs/compliance-dashboard/report.csv"
    "docs/compliance-dashboard/history.json"
    "docs/reports/WEEKLY_COMPLIANCE_SUMMARY.md"
    "docs/reports/MONTHLY_EXECUTIVE_SUMMARY.md"
  )
else
  files=("$@")
fi

python3 - <<'PY' "$output_file" "${files[@]}"
import hashlib
import json
import sys
from datetime import datetime, timezone
from pathlib import Path

out = Path(sys.argv[1])
files = [Path(p) for p in sys.argv[2:]]

artifacts = []
for p in files:
    if not p.exists():
        continue
    h = hashlib.sha256(p.read_bytes()).hexdigest()
    artifacts.append({'path': str(p), 'sha256': h})

payload = {
    'generated_at_utc': datetime.now(timezone.utc).strftime('%Y-%m-%dT%H:%M:%SZ'),
    'artifacts': artifacts,
}

out.parent.mkdir(parents=True, exist_ok=True)
out.write_text(json.dumps(payload, indent=2) + '\n', encoding='utf-8')
PY

echo "Compliance attestation written: $output_file"
