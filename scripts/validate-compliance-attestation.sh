#!/usr/bin/env bash
set -euo pipefail

attestation_file="${1:-docs/compliance-dashboard/attestation.json}"

[[ -f "$attestation_file" ]] || { echo "Missing $attestation_file"; exit 1; }

python3 - <<'PY' "$attestation_file"
import hashlib
import json
import sys
from pathlib import Path

att = json.loads(Path(sys.argv[1]).read_text(encoding='utf-8'))
meta = att.get('metadata', {})
if not meta:
    raise SystemExit('Attestation metadata missing')
for key in ('git_sha', 'github_run_id', 'generator'):
    if not meta.get(key):
        raise SystemExit(f'Attestation metadata key missing: {key}')
arts = att.get('artifacts', [])
if not arts:
    raise SystemExit('Attestation has no artifacts')

for item in arts:
    p = Path(item['path'])
    if not p.exists():
        raise SystemExit(f'Missing attested file: {p}')
    h = hashlib.sha256(p.read_bytes()).hexdigest()
    if h != item['sha256']:
        raise SystemExit(f'Hash mismatch: {p}')
PY

echo "Compliance attestation validation passed."
