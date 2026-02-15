#!/usr/bin/env bash
set -euo pipefail

output="$(make -n code-reviews)"

preflight_line="$(printf '%s\n' "$output" | grep -n 'bash scripts/code-reviews.sh' | cut -d: -f1 | head -n1)"
verify_line="$(printf '%s\n' "$output" | grep -n 'make verify' | cut -d: -f1 | head -n1)"

if [[ -z "$preflight_line" || -z "$verify_line" ]]; then
  echo "make code-reviews target wiring is incomplete"
  exit 1
fi

if (( preflight_line >= verify_line )); then
  echo "make code-reviews target order is invalid"
  exit 1
fi

echo "make code-reviews target checks passed."
