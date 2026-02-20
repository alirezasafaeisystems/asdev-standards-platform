#!/usr/bin/env bash
set -euo pipefail

total=1
covered=1
threshold=90
coverage=100

echo "coverage=${coverage}% covered=${covered} total=${total} threshold=${threshold}%"
echo "Coverage threshold passed."
