#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PORT="${PORT:-4173}"
HOST="${HOST:-127.0.0.1}"
REFRESH_REPORTS="${REFRESH_REPORTS:-true}"

cd "${ROOT_DIR}"

if [[ "${REFRESH_REPORTS}" == "true" ]]; then
  echo "[dashboard] refreshing reports..."
  make reports >/dev/null
else
  echo "[dashboard] skipping report refresh (REFRESH_REPORTS=false)"
fi

echo "[dashboard] generating dashboard data..."
bash scripts/generate-management-dashboard-data.sh >/dev/null

echo "[dashboard] serving http://${HOST}:${PORT}/docs/dashboard/"
python3 -m http.server "${PORT}" --bind "${HOST}"
