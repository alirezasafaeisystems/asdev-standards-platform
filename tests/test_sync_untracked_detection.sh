#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

YQ_BIN="$("${ROOT_DIR}/scripts/ensure-yq.sh")"
WORK_DIR="$(mktemp -d)"
trap 'rm -rf "${WORK_DIR}"' EXIT

FAKE_BIN="${WORK_DIR}/fakebin"
FAKE_GH_ROOT="${WORK_DIR}/fake-gh-repos"
mkdir -p "${FAKE_BIN}" "${FAKE_GH_ROOT}" "${WORK_DIR}/sync"

cat > "${FAKE_BIN}/gh" << 'GH'
#!/usr/bin/env bash
set -euo pipefail

if [[ "${1:-}" == "repo" && "${2:-}" == "clone" ]]; then
  repo="${3:-}"
  dest="${4:-}"
  key="${repo//\//__}"
  cp -a "${FAKE_GH_ROOT}/${key}" "${dest}"
  exit 0
fi

if [[ "${1:-}" == "pr" && "${2:-}" == "create" ]]; then
  echo "https://example.invalid/pr/2"
  exit 0
fi

exit 0
GH
chmod +x "${FAKE_BIN}/gh"

REPO_KEY="local__repo-two"
TARGET_REPO="${FAKE_GH_ROOT}/${REPO_KEY}"
mkdir -p "${TARGET_REPO}"
(
  cd "${TARGET_REPO}"
  git init -q
  git checkout -b main >/dev/null
  git config user.name "asdev-test"
  git config user.email "asdev-test@example.com"
  echo "# repo" > README.md
  git add README.md
  git commit -q -m "test: initial"
)

cat > "${WORK_DIR}/sync/targets-test.yaml" << 'YAML'
targets:
  - repo: local/repo-two
    default_branch: main
    templates:
      - js-ts-level1-ci
    optional_features: []
    opt_outs: []
    labels: []
YAML

OUTPUT_FILE="${WORK_DIR}/sync.out"
(
  cd "${WORK_DIR}"
  export FAKE_GH_ROOT
  PATH="${FAKE_BIN}:$(dirname "${YQ_BIN}"):${PATH}" \
  DRY_RUN=true \
  bash "${ROOT_DIR}/platform/scripts/sync.sh" \
    sync/targets-test.yaml \
    "${ROOT_DIR}/platform/repo-templates/templates.yaml" \
    "${ROOT_DIR}/platform/repo-templates"
) | tee "${OUTPUT_FILE}"

if ! grep -q "DRY_RUN=true -> skipping push and PR for local/repo-two" "${OUTPUT_FILE}"; then
  echo "Expected dry-run success for untracked template file" >&2
  exit 1
fi

if ! grep -q "Sync summary -> success: 1, failed: 0, skipped: 0" "${OUTPUT_FILE}"; then
  echo "Unexpected summary for untracked detection case" >&2
  exit 1
fi

echo "sync untracked detection checks passed."
