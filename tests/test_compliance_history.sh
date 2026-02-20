#!/usr/bin/env bash
set -euo pipefail

bash scripts/generate-compliance-report.sh
bash scripts/update-compliance-history.sh

history="docs/compliance-dashboard/history.json"
[[ -f "$history" ]] || { echo "missing history"; exit 1; }
python3 - <<'PY' "$history"
import json
import sys
obj = json.load(open(sys.argv[1], encoding='utf-8'))
assert 'points' in obj and len(obj['points']) >= 1
PY

echo "compliance history checks passed."
