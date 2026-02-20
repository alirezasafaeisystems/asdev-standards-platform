#!/usr/bin/env bash
set -euo pipefail

bump_type="${1:-patch}"
version_file="VERSION"
changelog_file="CHANGELOG.md"

current="$(cat "$version_file")"
IFS='.' read -r major minor patch <<<"$current"

case "$bump_type" in
  major)
    major=$((major + 1)); minor=0; patch=0 ;;
  minor)
    minor=$((minor + 1)); patch=0 ;;
  patch)
    patch=$((patch + 1)) ;;
  *)
    echo "Invalid bump type: $bump_type" >&2
    exit 1 ;;
esac

next="${major}.${minor}.${patch}"
echo "$next" > "$version_file"

today="$(date -u +%Y-%m-%d)"
if ! grep -q "## ${next} - ${today}" "$changelog_file"; then
  tmp="$(mktemp)"
  {
    echo "# Changelog"
    echo
    echo "## ${next} - ${today}"
    echo "- Automated release bump (${bump_type})."
    echo
    tail -n +2 "$changelog_file"
  } > "$tmp"
  mv "$tmp" "$changelog_file"
fi

echo "$next"
