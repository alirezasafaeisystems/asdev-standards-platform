#!/usr/bin/env bash
set -euo pipefail

ROOT="${ROOT:-/home/dev/Project_Me}"
HUB="$ROOT/asdev-standards-platform"
SYNC_SCRIPT="$HUB/platform/scripts/execution/autonomous/sync-autonomous-stack.sh"
GIT_GH_BOOTSTRAP_SCRIPT="$HUB/platform/scripts/execution/autonomous/git-github-bootstrap.sh"
STATE_DIR="${CODEX_HOME:-$HOME/.codex}/bootstrap-state"
LOG_FILE="$STATE_DIR/codex-bootstrap.log"
LAST_RUN_FILE="$STATE_DIR/last_run_epoch"
MIN_INTERVAL_SECONDS="${CODEX_BOOTSTRAP_MIN_INTERVAL_SECONDS:-600}"

mkdir -p "$STATE_DIR"

log() {
  printf '[%s] %s\n' "$(date -u +'%Y-%m-%d %H:%M:%S UTC')" "$1" >> "$LOG_FILE"
}

now_epoch="$(date +%s)"
if [[ "${CODEX_BOOTSTRAP_FORCE:-0}" != "1" && -f "$LAST_RUN_FILE" ]]; then
  last_epoch="$(cat "$LAST_RUN_FILE" 2>/dev/null || echo 0)"
  if [[ "$last_epoch" =~ ^[0-9]+$ ]]; then
    if (( now_epoch - last_epoch < MIN_INTERVAL_SECONDS )); then
      # Fast path: keep services alive and exit.
      for svc in asdev-autonomous-executor.service asdev-autopilot.service; do
        systemctl --user start "$svc" >/dev/null 2>&1 || true
      done
      exit 0
    fi
  fi
fi

declare -A cmd_to_pkg=(
  [rg]=ripgrep
  [jq]=jq
  [tmux]=tmux
  [clinfo]=clinfo
  [vulkaninfo]=vulkan-tools
  [pnpm]=pnpm
  [bun]=bun
  [node]=nodejs
)

missing_pkgs=()
for cmd in "${!cmd_to_pkg[@]}"; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    missing_pkgs+=("${cmd_to_pkg[$cmd]}")
  fi
done

if [[ ${#missing_pkgs[@]} -gt 0 ]]; then
  unique_pkgs="$(printf '%s\n' "${missing_pkgs[@]}" | sort -u | tr '\n' ' ' | sed 's/[[:space:]]*$//')"
  log "missing packages detected: ${unique_pkgs}"

  if sudo -n true >/dev/null 2>&1; then
    sudo -n apt-get update -y >/dev/null 2>&1 || true
    sudo -n apt-get install -y ${unique_pkgs} >/dev/null 2>&1 || true
  elif [[ -n "${CODEX_SUDO_PASSWORD:-}" ]]; then
    printf '%s\n' "$CODEX_SUDO_PASSWORD" | sudo -S apt-get update -y >/dev/null 2>&1 || true
    printf '%s\n' "$CODEX_SUDO_PASSWORD" | sudo -S apt-get install -y ${unique_pkgs} >/dev/null 2>&1 || true
  else
    log "missing packages could not be auto-installed (no non-interactive sudo)"
  fi
fi

if [[ -x "$SYNC_SCRIPT" ]]; then
  ROOT="$ROOT" "$SYNC_SCRIPT" >/dev/null 2>&1 || log "sync script failed"
fi

if [[ -x "$GIT_GH_BOOTSTRAP_SCRIPT" ]]; then
  ROOT="$ROOT" WORKSPACE_ROOT="$ROOT" "$GIT_GH_BOOTSTRAP_SCRIPT" >/dev/null 2>&1 || log "git/gh bootstrap failed"
fi

# Ensure all asdev user services are up.
while IFS= read -r svc; do
  [[ -n "$svc" ]] || continue
  systemctl --user enable --now "$svc" >/dev/null 2>&1 || log "failed to enable/start $svc"
done < <(systemctl --user list-unit-files 'asdev-*.service' --no-legend --no-pager 2>/dev/null | awk '{print $1}' | sort -u)

systemctl --user daemon-reload >/dev/null 2>&1 || true

printf '%s\n' "$now_epoch" > "$LAST_RUN_FILE"
log "bootstrap completed"
