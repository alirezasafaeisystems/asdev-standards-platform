#!/usr/bin/env bash
set -euo pipefail

version="$(cat VERSION)"
tag="v${version}"

if git rev-parse "$tag" >/dev/null 2>&1; then
  echo "Tag already exists: $tag" >&2
  exit 1
fi

git tag "$tag"
git push origin "$tag"

gh release create "$tag" --generate-notes --title "$tag"
