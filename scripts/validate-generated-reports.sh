#!/usr/bin/env bash
set -euo pipefail

# Mode A (legacy combined reports):
#   validate-generated-reports.sh [combined.csv] [errors.csv] [trend.csv]
# Mode B (compliance dashboard):
#   validate-generated-reports.sh report.json report.csv schema.json

first_arg="${1:-sync/divergence-report.combined.csv}"

validate_legacy_reports() {
  local combined_file="${1:-sync/divergence-report.combined.csv}"
  local errors_file="${2:-sync/divergence-report.combined.errors.csv}"
  local trend_file="${3:-sync/divergence-report.combined.errors.trend.csv}"

  validate_file() {
    local file="$1"
    local expected_header="$2"
    local expected_columns="$3"

    if [[ ! -f "$file" ]]; then
      echo "Missing generated report file: $file" >&2
      exit 1
    fi

    local actual_header
    actual_header="$(head -n 1 "$file")"
    if [[ "$actual_header" != "$expected_header" ]]; then
      echo "Schema header mismatch in $file" >&2
      echo "Expected: $expected_header" >&2
      echo "Actual:   $actual_header" >&2
      exit 1
    fi

    if ! awk -F, -v n="$expected_columns" 'NR>1 && NF!=n {print "Invalid column count at line " NR " in " FILENAME ": expected " n ", got " NF > "/dev/stderr"; exit 1}' "$file"; then
      exit 1
    fi
  }

  validate_file "$combined_file" "target_file,repo,template_id,expected_version,detected_version,mode,source_ref,status,last_checked_at" 9
  validate_file "$errors_file" "target_file,repo,error_fingerprint,last_checked_at" 4
  validate_file "$trend_file" "error_fingerprint,previous,current,delta" 4
}

validate_compliance_reports() {
  local json_file="${1:-docs/compliance-dashboard/report.json}"
  local csv_file="${2:-docs/compliance-dashboard/report.csv}"
  local schema_file="${3:-schemas/compliance-report.schema.json}"

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

  local header
  header="$(head -n 1 "$csv_file" | tr -d '\r')"
  if [[ "$header" != "check,status,source" ]]; then
    echo "Invalid CSV header: $header"
    exit 1
  fi

  local line_count
  line_count=$(wc -l < "$csv_file")
  if [[ "$line_count" -lt 2 ]]; then
    echo "CSV must contain header + at least one row"
    exit 1
  fi
}

if [[ "$first_arg" == *.json ]]; then
  validate_compliance_reports "$@"
else
  validate_legacy_reports "$@"
fi

echo "Generated report schema checks passed."
