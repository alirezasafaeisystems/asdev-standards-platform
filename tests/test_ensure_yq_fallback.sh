#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "${TMP_DIR}"' EXIT

FAKE_BIN="${TMP_DIR}/fakebin"
mkdir -p "${FAKE_BIN}"

cat > "${FAKE_BIN}/curl" <<'CURL'
#!/usr/bin/env bash
exit 22
CURL
chmod +x "${FAKE_BIN}/curl"

YQ_INSTALL_PATH="${TMP_DIR}/yq"
resolved_path="$(PATH="${FAKE_BIN}:$PATH" YQ_INSTALL_PATH="${YQ_INSTALL_PATH}" bash "${ROOT_DIR}/scripts/ensure-yq.sh")"

if [[ "${resolved_path}" != "${YQ_INSTALL_PATH}" ]]; then
  echo "expected fallback path ${YQ_INSTALL_PATH}, got ${resolved_path}" >&2
  exit 1
fi

if [[ ! -x "${YQ_INSTALL_PATH}" ]]; then
  echo "fallback yq binary was not created" >&2
  exit 1
fi

cat > "${TMP_DIR}/targets.yaml" <<'YAML'
targets:
  - repo: owner/repo
    templates:
      - foo
      - bar
YAML

actual_repo="$(${YQ_INSTALL_PATH} -r '.targets[0].repo' "${TMP_DIR}/targets.yaml")"
if [[ "${actual_repo}" != "owner/repo" ]]; then
  echo "unexpected repo value from fallback parser: ${actual_repo}" >&2
  exit 1
fi

echo "ensure-yq fallback checks passed."
