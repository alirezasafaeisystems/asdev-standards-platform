#!/usr/bin/env bash
set -euo pipefail

CODEX_HOME_DIR="${CODEX_HOME:-$HOME/.codex}"
CONFIG_FILE="$CODEX_HOME_DIR/config.toml"
BACKUP_FILE="$CODEX_HOME_DIR/config.toml.bak-autosync"
WORKSPACE_ROOT="${WORKSPACE_ROOT:-/home/dev/Project_Me}"
BASE_ROOT="${BASE_ROOT:-/home/dev}"

mkdir -p "$CODEX_HOME_DIR"
[[ -f "$CONFIG_FILE" ]] || touch "$CONFIG_FILE"

if [[ ! -f "$BACKUP_FILE" ]]; then
  cp "$CONFIG_FILE" "$BACKUP_FILE" || true
fi

ensure_project_trust() {
  local path="$1"
  [[ -d "$path" ]] || return 0

  if ! grep -Fq "[projects.\"$path\"]" "$CONFIG_FILE"; then
    {
      echo
      echo "[projects.\"$path\"]"
      echo "trust_level = \"trusted\""
    } >> "$CONFIG_FILE"
  fi
}

# Core roots
ensure_project_trust "$BASE_ROOT"
ensure_project_trust "$WORKSPACE_ROOT"

# Existing repos under workspace
while IFS= read -r repo_root; do
  ensure_project_trust "$repo_root"
done < <(find "$WORKSPACE_ROOT" -mindepth 1 -maxdepth 2 -type d -name .git -printf '%h\n' 2>/dev/null | sort -u)

# Auto-trust current git project (new repos become auto-configured on first codex run)
current_repo="$(git rev-parse --show-toplevel 2>/dev/null || true)"
if [[ -n "$current_repo" ]]; then
  ensure_project_trust "$current_repo"
fi

# Auto-trust CWD if inside /home/dev and is a directory.
cwd="$(pwd)"
case "$cwd" in
  "$BASE_ROOT"/*)
    ensure_project_trust "$cwd"
    ;;
esac
