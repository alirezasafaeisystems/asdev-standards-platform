#!/usr/bin/env bash
set -euo pipefail

workspace="$(mktemp -d)"
trap 'rm -rf "$workspace"' EXIT

report_csv="$workspace/divergence-report.combined.csv"

cat > "$report_csv" <<'CSV'
repo,template_id,expected_version,detected_version,mode,source_ref,status,last_checked_at
repo-one,level1,1.0.0,1.0.0,target_file,sync/targets.yaml,aligned,2026-01-01T00:00:00Z
repo-two,level1,1.0.0,,target_file,sync/targets.yaml,clone_failed,2026-01-01T00:00:01Z
repo-three,level1,1.0.0,,target_file,sync/targets.yaml,clone_failed,2026-01-01T00:00:02Z
repo-two,level1,1.0.0,,target_file,sync/targets.yaml,clone_failed,2026-01-01T00:00:03Z
CSV

output="$(bash scripts/summarize-clone-failed.sh "$report_csv" 1)"

echo "$output" | grep -q "## clone_failed Repositories"
echo "$output" | grep -q -- "- count: 2"
repo_lines="$(echo "$output" | grep -E '^  - repo-(two|three)$' | wc -l | tr -d ' ')"
if [[ "$repo_lines" != "1" ]]; then
  echo "expected limit to restrict listed repositories to one entry"
  exit 1
fi

empty_csv="$workspace/empty.csv"
cat > "$empty_csv" <<'CSV'
repo,template_id,expected_version,detected_version,mode,source_ref,status,last_checked_at
repo-one,level1,1.0.0,1.0.0,target_file,sync/targets.yaml,aligned,2026-01-01T00:00:00Z
CSV

empty_output="$(bash scripts/summarize-clone-failed.sh "$empty_csv")"
echo "$empty_output" | grep -q -- "- count: 0"
echo "$empty_output" | grep -q -- "- repos: none"

if bash scripts/summarize-clone-failed.sh "$report_csv" 0 >/dev/null 2>&1; then
  echo "expected non-positive limit to fail"
  exit 1
fi

echo "clone_failed summary checks passed."
