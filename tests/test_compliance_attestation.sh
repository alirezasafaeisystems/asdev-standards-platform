#!/usr/bin/env bash
set -euo pipefail

bash scripts/generate-compliance-report.sh
bash scripts/update-compliance-history.sh
bash scripts/generate-weekly-kpi-summary.sh
bash scripts/generate-monthly-executive-summary.sh
bash scripts/write-compliance-attestation.sh docs/compliance-dashboard/attestation.json
bash scripts/validate-compliance-attestation.sh docs/compliance-dashboard/attestation.json

python3 - <<'PY'
import json
from pathlib import Path
att = json.loads(Path("docs/compliance-dashboard/attestation.json").read_text(encoding="utf-8"))
meta = att.get("metadata", {})
assert meta.get("git_sha"), "missing git_sha"
assert meta.get("github_run_id"), "missing github_run_id"
assert meta.get("generator") == "scripts/write-compliance-attestation.sh", "invalid generator"
paths = {a.get("path") for a in att.get("artifacts", [])}
assert "docs/reports/AUTOMATION_SLO_STATUS.md" in paths, "missing SLO status artifact"
PY

echo "compliance attestation checks passed."
