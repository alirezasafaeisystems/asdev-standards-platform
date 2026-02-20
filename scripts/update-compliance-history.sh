#!/usr/bin/env bash
set -euo pipefail

report_json="${1:-docs/compliance-dashboard/report.json}"
history_json="${2:-docs/compliance-dashboard/history.json}"
max_entries="${MAX_HISTORY_ENTRIES:-52}"

python3 - <<'PY' "$report_json" "$history_json" "$max_entries"
import json
import sys
from datetime import datetime, timezone
from pathlib import Path

report_path = Path(sys.argv[1])
history_path = Path(sys.argv[2])
max_entries = int(sys.argv[3])

report = json.loads(report_path.read_text(encoding='utf-8'))
point = {
    'generated_at_utc': report.get('generated_at_utc'),
    'compliance_score': float(report.get('compliance_score', 0)),
}

if history_path.exists():
    history = json.loads(history_path.read_text(encoding='utf-8'))
else:
    history = {'repo': report.get('repo', 'asdev-standards-platform'), 'points': []}

points = history.get('points', [])
points = [p for p in points if p.get('generated_at_utc') != point['generated_at_utc']]
points.append(point)
points.sort(key=lambda p: p.get('generated_at_utc', ''))
points = points[-max_entries:]

history['repo'] = report.get('repo', history.get('repo', 'asdev-standards-platform'))
history['points'] = points
history['updated_at_utc'] = datetime.now(timezone.utc).strftime('%Y-%m-%dT%H:%M:%SZ')

history_path.parent.mkdir(parents=True, exist_ok=True)
history_path.write_text(json.dumps(history, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
PY

echo "Compliance history updated: $history_json"
