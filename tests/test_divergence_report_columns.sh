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
  mkdir -p .github
  cp "${ROOT_DIR}/platform/repo-templates/.github/pull_request_template.md" .github/pull_request_template.md
  git add .
  git commit -q -m "test: initial"
)

cat > "${WORK_DIR}/sync/targets-test.yaml" << 'YAML'
targets:
  - repo: local/repo-one
    default_branch: main
    templates:
      - pr-template
    optional_features: []
    opt_outs: []
    labels: []
YAML

OUTPUT_CSV="${WORK_DIR}/sync/divergence-report.csv"
(
  cd "${WORK_DIR}"
  export FAKE_GH_ROOT
  PATH="${FAKE_BIN}:$(dirname "${YQ_BIN}"):${PATH}" \
  bash "${ROOT_DIR}/platform/scripts/divergence-report.sh" \
    sync/targets-test.yaml \
    "${ROOT_DIR}/platform/repo-templates/templates.yaml" \
    "${ROOT_DIR}/platform/repo-templates" \
    sync/divergence-report.csv
)

header="$(head -n 1 "${OUTPUT_CSV}")"
expected="repo,template_id,expected_version,detected_version,mode,source_ref,status,last_checked_at"
if [[ "$header" != "$expected" ]]; then
  echo "Unexpected CSV header: $header" >&2
  exit 1
fi

row="$(tail -n +2 "${OUTPUT_CSV}" | head -n 1)"
field_count="$(awk -F, '{print NF}' <<< "$row")"
if [[ "$field_count" -ne 8 ]]; then
  echo "Expected 8 columns, got ${field_count}" >&2
  exit 1
fi

echo "divergence report column checks passed."
