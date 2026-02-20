#!/usr/bin/env bash
set -euo pipefail

json_file="${1:-docs/compliance-dashboard/report.json}"
csv_file="${2:-docs/compliance-dashboard/report.csv}"
schema_file="${3:-schemas/compliance-report.schema.json}"

[[ -f "$json_file" ]] || { echo "Missing $json_file"; exit 1; }
[[ -f "$csv_file" ]] || { echo "Missing $csv_file"; exit 1; }
[[ -f "$schema_file" ]] || { echo "Missing $schema_file"; exit 1; }

python3 - <<'PY' "$json_file" "$schema_file"
import json
import sys
from jsonschema import Draft202012Validator

with open(sys.argv[1], encoding="utf-8") as f:
    payload = json.load(f)
with open(sys.argv[2], encoding="utf-8") as f:
    schema = json.load(f)

errors = sorted(Draft202012Validator(schema).iter_errors(payload), key=lambda e: e.path)
if errors:
    for err in errors:
        loc = ".".join(str(x) for x in err.path) or "<root>"
        print(f"{loc}: {err.message}")
    raise SystemExit(1)
PY

header="$(head -n 1 "$csv_file" | tr -d '\r')"
if [[ "$header" != "check,status,source" ]]; then
  echo "Invalid CSV header: $header"
  exit 1
fi

line_count=$(wc -l < "$csv_file")
if [[ "$line_count" -lt 2 ]]; then
  echo "CSV must contain header + at least one row"
  exit 1
fi

echo "Generated report schema checks passed."
