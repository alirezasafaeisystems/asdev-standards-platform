#!/usr/bin/env bash
set -euo pipefail

tmpdir="$(mktemp -d)"
cp VERSION "$tmpdir/VERSION"
cp CHANGELOG.md "$tmpdir/CHANGELOG.md"

pushd "$tmpdir" >/dev/null
mkdir -p scripts/release
cp "$OLDPWD/scripts/release/bump-version.sh" scripts/release/bump-version.sh
bash scripts/release/bump-version.sh patch >/dev/null
new_version="$(cat VERSION)"
[[ "$new_version" != "0.1.0" ]] || { echo "version did not bump"; exit 1; }
grep -q "## ${new_version} - " CHANGELOG.md || { echo "changelog not updated"; exit 1; }
popd >/dev/null
rm -rf "$tmpdir"

echo "release bump checks passed."
