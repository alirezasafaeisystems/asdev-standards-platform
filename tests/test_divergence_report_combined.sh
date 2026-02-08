#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

ensure_yq() {
  if command -v yq >/dev/null 2>&1; then
    command -v yq
    return
  fi

  if [[ -x /tmp/yq ]]; then
    echo "/tmp/yq"
    return
  fi

  local tmp_bin
  tmp_bin="$(mktemp -d)"
  curl -fsSL https://github.com/mikefarah/yq/releases/download/v4.44.6/yq_linux_amd64 -o "${tmp_bin}/yq"
  chmod +x "${tmp_bin}/yq"
  echo "${tmp_bin}/yq"
}

YQ_BIN="$(ensure_yq)"
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

for key in local__repo-a local__repo-b; do
  repo_dir="${FAKE_GH_ROOT}/${key}"
  mkdir -p "${repo_dir}"
  (
    cd "${repo_dir}"
    git init -q
    git checkout -b main >/dev/null
    git config user.name "asdev-test"
    git config user.email "asdev-test@example.com"
    mkdir -p .github
    cp "${ROOT_DIR}/platform/repo-templates/.github/pull_request_template.md" .github/pull_request_template.md
    git add .
    git commit -q -m "test: init"
  )
done

cat > "${WORK_DIR}/sync/targets.alpha.yaml" << 'YAML'
targets:
  - repo: local/repo-a
    default_branch: main
    templates:
      - pr-template
    optional_features: []
    opt_outs: []
    labels: []
YAML

cat > "${WORK_DIR}/sync/targets.beta.yaml" << 'YAML'
targets:
  - repo: local/repo-b
    default_branch: main
    templates:
      - pr-template
    optional_features: []
    opt_outs: []
    labels: []
YAML

(
  cd "${WORK_DIR}"
  export FAKE_GH_ROOT
  PATH="${FAKE_BIN}:$(dirname "${YQ_BIN}"):${PATH}" \
  bash "${ROOT_DIR}/platform/scripts/divergence-report-combined.sh" \
    "${ROOT_DIR}/platform/repo-templates/templates.yaml" \
    "${ROOT_DIR}/platform/repo-templates" \
    "${WORK_DIR}/sync/divergence-report.combined.csv"
)

header="$(head -n 1 "${WORK_DIR}/sync/divergence-report.combined.csv")"
expected="target_file,repo,template_id,expected_version,detected_version,mode,source_ref,status,last_checked_at"
if [[ "$header" != "$expected" ]]; then
  echo "Unexpected combined CSV header: $header" >&2
  exit 1
fi

rows="$(tail -n +2 "${WORK_DIR}/sync/divergence-report.combined.csv" | wc -l)"
if [[ "$rows" -lt 2 ]]; then
  echo "Expected at least two rows in combined report" >&2
  exit 1
fi

echo "combined divergence report checks passed."
