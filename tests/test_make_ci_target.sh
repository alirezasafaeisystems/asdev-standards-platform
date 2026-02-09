#!/usr/bin/env bash
set -euo pipefail

output="$(make -n ci)"

lint_line="$(printf '%s\n' "$output" | grep -n '^make lint$' | cut -d: -f1 | head -n1)"
policy_line="$(printf '%s\n' "$output" | grep -n 'bash scripts/validate-template-version-policy.sh origin/main' | cut -d: -f1 | head -n1)"
test_line="$(printf '%s\n' "$output" | grep -n '^make test$' | cut -d: -f1 | head -n1)"

if [[ -z "$lint_line" || -z "$policy_line" || -z "$test_line" ]]; then
  echo "make ci target wiring is incomplete"
  exit 1
fi

if (( lint_line >= policy_line || policy_line >= test_line )); then
  echo "make ci target order is invalid"
  exit 1
fi

echo "make ci target checks passed."
