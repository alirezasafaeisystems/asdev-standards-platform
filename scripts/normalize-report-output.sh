#!/usr/bin/env bash
set -euo pipefail

INPUT_FILE="${1:?input file is required}"
OUTPUT_FILE="${2:?output file is required}"
LOGICAL_PATH="${3:-$INPUT_FILE}"

if [[ ! -f "$INPUT_FILE" ]]; then
  echo "Missing input file: $INPUT_FILE" >&2
  exit 1
fi

mkdir -p "$(dirname "$OUTPUT_FILE")"

case "$(basename "$LOGICAL_PATH")" in
  generated-reports.attestation)
    # validated_at is runtime metadata and should not trigger update PR churn.
    grep -v '^validated_at=' "$INPUT_FILE" > "$OUTPUT_FILE"
    ;;
  platform-adoption-dashboard.md)
    # Generated timestamp is runtime metadata and should not trigger update PR churn.
    grep -v '^- Generated at: ' "$INPUT_FILE" > "$OUTPUT_FILE"
    ;;
  *.csv)
    {
      head -n 1 "$INPUT_FILE"
      tail -n +2 "$INPUT_FILE" | LC_ALL=C sort
    } > "$OUTPUT_FILE"
    ;;
  *)
    cat "$INPUT_FILE" > "$OUTPUT_FILE"
    ;;
esac
