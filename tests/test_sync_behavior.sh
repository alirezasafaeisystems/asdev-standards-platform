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
  echo "https://example.invalid/pr/1"
  exit 0
fi

exit 0
GH
chmod +x "${FAKE_BIN}/gh"

REPO_KEY="local__repo-one"
TARGET_REPO="${FAKE_GH_ROOT}/${REPO_KEY}"
mkdir -p "${TARGET_REPO}"
(
  cd "${TARGET_REPO}"
  git init -q
  git checkout -b main >/dev/null
  git config user.name "asdev-test"
  git config user.email "asdev-test@example.com"
  echo "Existing README" > README.md
  echo "Existing CONTRIBUTING" > CONTRIBUTING.md
  mkdir -p .github/ISSUE_TEMPLATE
  echo "Legacy template" > .github/pull_request_template.md
  git add .
  git commit -q -m "test: initial"
)

cat > "${WORK_DIR}/sync/targets-test.yaml" << 'YAML'
targets:
  - repo: local/repo-one
    default_branch: main
    templates:
      - pr-template
      - contributing-minimum
      - readme-minimum
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

if ! grep -q "Preserving existing documentation file: CONTRIBUTING.md" "${OUTPUT_FILE}"; then
  echo "Expected CONTRIBUTING.md preserve message not found" >&2
  exit 1
fi

if ! grep -q "Preserving existing documentation file: README.md" "${OUTPUT_FILE}"; then
  echo "Expected README.md preserve message not found" >&2
  exit 1
fi

if grep -q "Error: open sync/targets-test.yaml" "${OUTPUT_FILE}"; then
  echo "Path resolution regression detected" >&2
  exit 1
fi

if ! grep -q "Sync summary -> success: 1, failed: 0, skipped: 0" "${OUTPUT_FILE}"; then
  echo "Unexpected sync summary" >&2
  exit 1
fi

echo "sync behavior checks passed."
