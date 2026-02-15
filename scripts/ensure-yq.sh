#!/usr/bin/env bash
set -euo pipefail

YQ_VERSION="${YQ_VERSION:-v4.44.6}"
YQ_INSTALL_PATH="${YQ_INSTALL_PATH:-/tmp/yq}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
YQ_LITE_PATH="${SCRIPT_DIR}/yq-lite"

if command -v yq >/dev/null 2>&1; then
  command -v yq
  exit 0
fi

if [[ -x "${YQ_INSTALL_PATH}" ]]; then
  echo "${YQ_INSTALL_PATH}"
  exit 0
fi

if [[ "$(uname -s)" != "Linux" ]]; then
  echo "yq is required but auto-install is only supported on Linux." >&2
  echo "Install yq manually: https://github.com/mikefarah/yq/#install" >&2
  exit 1
fi

if command -v curl >/dev/null 2>&1; then
  download_url="https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/yq_linux_amd64"
  if curl -fsSL "${download_url}" -o "${YQ_INSTALL_PATH}"; then
    chmod +x "${YQ_INSTALL_PATH}"
    echo "${YQ_INSTALL_PATH}"
    exit 0
  fi
fi

if [[ -x "${YQ_LITE_PATH}" ]]; then
  cp "${YQ_LITE_PATH}" "${YQ_INSTALL_PATH}"
  chmod +x "${YQ_INSTALL_PATH}"
  echo "${YQ_INSTALL_PATH}"
  exit 0
fi

echo "Failed to provision yq and no local fallback is available." >&2
exit 1
