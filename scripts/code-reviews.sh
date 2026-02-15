#!/usr/bin/env bash
set -euo pipefail

base_ref="${1:-origin/main}"

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "code-reviews must be run inside a git repository" >&2
  exit 1
fi

if ! git rev-parse --verify "$base_ref" >/dev/null 2>&1; then
  echo "Base ref '$base_ref' does not exist locally; falling back to HEAD~1." >&2
  base_ref="HEAD~1"
fi

merge_base="$(git merge-base "$base_ref" HEAD)"
changed_files="$(git diff --name-only "$merge_base"...HEAD)"
changed_count="$(printf '%s\n' "$changed_files" | sed '/^$/d' | wc -l | tr -d ' ')"

cat <<REPORT
Code review preflight
=====================
Base reference : $base_ref
Merge base     : $merge_base
Changed files  : $changed_count
REPORT

if [[ "$changed_count" -gt 0 ]]; then
  echo
  echo "Changed paths:"
  printf '%s\n' "$changed_files" | sed '/^$/d' | sed 's/^/- /'
fi

echo
echo "Running diff hygiene checks..."
git diff --check "$merge_base"...HEAD

if git grep -n '<<<<<<<\|=======\|>>>>>>>' -- . ':(exclude).git' >/dev/null; then
  echo "Potential merge markers found in repository." >&2
  exit 1
fi

echo "No merge conflict markers detected."
echo "Preflight checks passed."
