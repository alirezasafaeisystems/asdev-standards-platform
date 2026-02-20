#!/usr/bin/env bash
set -euo pipefail

repo="${GITHUB_REPOSITORY:-alirezasafaeisystems/asdev-standards-platform}"
version_file="${VERSION_FILE:-VERSION}"
changelog_file="${CHANGELOG_FILE:-CHANGELOG.md}"
tag_input="${1:-}"

version="$(cat "$version_file")"
if [[ ! "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "Invalid VERSION format: $version" >&2
  exit 1
fi

expected_tag="v${version}"
tag="${tag_input:-$expected_tag}"

if [[ "$tag" != "$expected_tag" ]]; then
  echo "Tag and VERSION mismatch: tag=$tag expected=$expected_tag" >&2
  exit 1
fi

if ! git rev-parse "$tag" >/dev/null 2>&1; then
  echo "Missing git tag: $tag" >&2
  exit 1
fi

if ! grep -q "^## ${version} - " "$changelog_file"; then
  echo "Missing changelog entry for version $version in $changelog_file" >&2
  exit 1
fi

if command -v gh >/dev/null 2>&1; then
  if ! gh release view "$tag" --repo "$repo" >/dev/null 2>&1; then
    echo "Missing GitHub release for tag $tag in $repo" >&2
    exit 1
  fi
fi

echo "Release post-check passed for $tag"
