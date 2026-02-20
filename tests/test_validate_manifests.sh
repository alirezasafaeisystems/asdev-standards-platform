#!/usr/bin/env bash
set -euo pipefail

python3 tools/validate_manifests.py \
  --schema schemas/targets.schema.json \
  --manifest sync/targets.yaml

set +e
python3 tools/validate_manifests.py \
  --schema schemas/targets.schema.json \
  --manifest tests/fixtures/invalid-targets.yaml
rc=$?
set -e

if [[ "$rc" -eq 0 ]]; then
  echo "Expected invalid fixture to fail"
  exit 1
fi

echo "Manifest validator tests passed."
