#!/usr/bin/env bash
set -euo pipefail

output="$(make -n digest-cleanup-dry-run)"

required_patterns=(
  'gh issue list --repo "\$repo" --state open --search "Weekly Governance Digest in:title"'
  'DIGEST_STALE_DRY_RUN=true DIGEST_STALE_SUMMARY_FILE="\$summary_file" bash scripts/close-stale-weekly-digests.sh'
  'cat "\$summary_file"'
)

for pattern in "${required_patterns[@]}"; do
  if ! printf '%s\n' "$output" | grep -Eq "$pattern"; then
    echo "digest-cleanup-dry-run target missing expected command pattern: $pattern" >&2
    exit 1
  fi
done

echo "make digest-cleanup-dry-run target checks passed."
