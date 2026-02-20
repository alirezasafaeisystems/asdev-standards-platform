#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORK_DIR="$(mktemp -d)"
trap 'rm -rf "$WORK_DIR"' EXIT

pushd "$WORK_DIR" >/dev/null
git init >/dev/null
git config user.email "ci@example.invalid"
git config user.name "CI Bot"

echo "0.0.1" > VERSION
cat > CHANGELOG.md <<'EOF_CL'
# Changelog

## 0.0.1 - 2026-02-20
- test entry.
EOF_CL

git add VERSION CHANGELOG.md
git commit -m "init" >/dev/null
git tag v0.0.1

mkdir -p fakebin
cat > fakebin/gh <<'EOF_GH'
#!/usr/bin/env bash
set -euo pipefail
if [[ "$1" == "release" && "$2" == "view" ]]; then
  exit 0
fi
exit 0
EOF_GH
chmod +x fakebin/gh

PATH="$WORK_DIR/fakebin:$PATH" \
  VERSION_FILE="$WORK_DIR/VERSION" \
  CHANGELOG_FILE="$WORK_DIR/CHANGELOG.md" \
  bash "$ROOT_DIR/scripts/release/post-check.sh" "v0.0.1"

echo "0.0.2" > VERSION
if PATH="$WORK_DIR/fakebin:$PATH" \
  VERSION_FILE="$WORK_DIR/VERSION" \
  CHANGELOG_FILE="$WORK_DIR/CHANGELOG.md" \
  bash "$ROOT_DIR/scripts/release/post-check.sh" "v0.0.2"; then
  echo "expected failure for missing changelog/tag contract" >&2
  exit 1
fi

popd >/dev/null
echo "release post-check tests passed."
