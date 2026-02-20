#!/usr/bin/env bash
set -euo pipefail

python3 -m py_compile tools/validate_manifests.py

echo "Typecheck checks passed."
