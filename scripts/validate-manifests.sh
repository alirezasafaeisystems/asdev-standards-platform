#!/usr/bin/env bash
set -euo pipefail

python3 tools/validate_manifests.py \
  --schema schemas/codex-automation.schema.json --manifest ops/automation/codex-automation.yaml \
  --schema schemas/execution-manifest.schema.json --manifest ops/automation/execution-manifest.yaml \
  --schema schemas/targets.schema.json --manifest sync/targets.yaml \
  --schema schemas/templates.schema.json --manifest platform/repo-templates/templates.yaml

echo "Manifest schema validation passed."
