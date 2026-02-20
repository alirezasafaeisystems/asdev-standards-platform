#!/usr/bin/env bash
set -euo pipefail

bash tests/test_validate_manifests.sh
bash tests/test_compliance_report.sh

echo "Test checks passed."
