#!/usr/bin/env bash
set -euo pipefail

ROOT="${ROOT:-/home/dev/Project_Me}"
HUB="$ROOT/asdev-standards-platform"
WORKSPACE_ROOT="${WORKSPACE_ROOT:-$ROOT}"
CODEX_HOME_DIR="${CODEX_HOME:-$HOME/.codex}"
STATE_DIR="$CODEX_HOME_DIR/bootstrap-state"
LOG_FILE="$STATE_DIR/git-github-bootstrap.log"
DATE_LOCAL="$(date +%F)"
DATE_UTC="$(date -u +'%Y-%m-%d %H:%M:%S UTC')"
REPORT="$HUB/docs/reports/GIT_GITHUB_BOOTSTRAP_${DATE_LOCAL}.md"

mkdir -p "$STATE_DIR" "$HOME/.ssh"
touch "$LOG_FILE"

log() {
  printf '[%s] %s\n' "$(date -u +'%Y-%m-%d %H:%M:%S UTC')" "$1" >> "$LOG_FILE"
}

has_cmd() {
  command -v "$1" >/dev/null 2>&1
}

set_git_cfg() {
  local key="$1"
  local val="$2"
  git config --global "$key" "$val"
}

to_ssh_url() {
  local url="$1"
  case "$url" in
    https://github.com/*)
      local tail="${url#https://github.com/}"
      tail="${tail%.git}"
      printf 'git@github.com:%s.git\n' "$tail"
      return 0
      ;;
    http://github.com/*)
      local tail="${url#http://github.com/}"
      tail="${tail%.git}"
      printf 'git@github.com:%s.git\n' "$tail"
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

gh_authenticated=false
if has_cmd gh && gh auth status -h github.com >/dev/null 2>&1; then
  gh_authenticated=true
fi

if [[ "$gh_authenticated" != "true" ]] && has_cmd gh; then
  token="${GH_TOKEN:-${GITHUB_TOKEN:-}}"
  if [[ -n "$token" ]]; then
    if printf '%s\n' "$token" | gh auth login --hostname github.com --with-token >/dev/null 2>&1; then
      gh_authenticated=true
      log "gh auth restored from token"
    else
      log "gh auth login by token failed"
    fi
  fi
fi

gh_login="$(gh api user --jq '.login' 2>/dev/null || true)"
gh_email="$(gh api user --jq '.email // empty' 2>/dev/null || true)"

current_name="$(git config --global --get user.name || true)"
current_email="$(git config --global --get user.email || true)"
if [[ -z "$current_name" && -n "$gh_login" ]]; then
  set_git_cfg user.name "$gh_login"
fi
if [[ -z "$current_email" ]]; then
  if [[ -n "$gh_email" ]]; then
    set_git_cfg user.email "$gh_email"
  elif [[ -n "$gh_login" ]]; then
    set_git_cfg user.email "${gh_login}@users.noreply.github.com"
  fi
fi

set_git_cfg init.defaultBranch main
set_git_cfg push.autoSetupRemote true
set_git_cfg fetch.prune true
set_git_cfg pull.ff only
set_git_cfg rebase.autoStash true
set_git_cfg rerere.enabled true
set_git_cfg merge.conflictstyle zdiff3
set_git_cfg core.autocrlf input
set_git_cfg core.fileMode false
set_git_cfg url."git@github.com:".insteadOf https://github.com/

if ! git config --global --get credential.helper >/dev/null 2>&1; then
  set_git_cfg credential.helper "cache --timeout=86400"
fi

if has_cmd gh; then
  gh config set git_protocol ssh >/dev/null 2>&1 || true
  gh config set prompt disabled >/dev/null 2>&1 || true
  gh config set pager cat >/dev/null 2>&1 || true
  if gh auth status -h github.com >/dev/null 2>&1; then
    gh auth setup-git >/dev/null 2>&1 || true
    gh_authenticated=true
  fi
fi

key_file="$HOME/.ssh/id_ed25519_github_asdev"
key_pub="${key_file}.pub"
if [[ ! -f "$key_pub" ]]; then
  key_comment="${gh_email:-${gh_login:-$USER}}@$(hostname)-asdev"
  ssh-keygen -t ed25519 -a 64 -f "$key_file" -N "" -C "$key_comment" >/dev/null
  chmod 700 "$HOME/.ssh"
  chmod 600 "$key_file"
  chmod 644 "$key_pub"
  log "generated ssh key: $key_pub"
fi

if has_cmd ssh-add && [[ -f "$key_file" ]]; then
  ssh-add "$key_file" >/dev/null 2>&1 || true
fi

ssh_cfg="$HOME/.ssh/config"
touch "$ssh_cfg"
chmod 600 "$ssh_cfg"
tmp_cfg="$(mktemp)"
awk '
  BEGIN { skip=0 }
  /^# >>> asdev-github >>>$/ { skip=1; next }
  /^# <<< asdev-github <<<$/{ skip=0; next }
  skip==0 { print }
' "$ssh_cfg" > "$tmp_cfg"
cat >> "$tmp_cfg" <<'EOF'
# >>> asdev-github >>>
Host github.com
  HostName github.com
  User git
  IdentityFile ~/.ssh/id_ed25519_github_asdev
  IdentitiesOnly yes
  AddKeysToAgent yes
# <<< asdev-github <<<
EOF
mv "$tmp_cfg" "$ssh_cfg"

ssh_key_uploaded=false
if [[ "$gh_authenticated" == "true" ]] && has_cmd gh && [[ -f "$key_pub" ]]; then
  local_key="$(cat "$key_pub")"
  if gh api user/keys --paginate --jq '.[].key' 2>/dev/null | grep -Fqx "$local_key"; then
    ssh_key_uploaded=true
  else
    title="$(hostname)-asdev-auto-$(date +%Y%m%d)"
    if gh ssh-key add "$key_pub" -t "$title" >/dev/null 2>&1; then
      ssh_key_uploaded=true
      log "uploaded ssh key to github"
    else
      log "failed to upload ssh key to github"
    fi
  fi
fi

repos_changed=0
while IFS= read -r repo_root; do
  while IFS= read -r remote_name; do
    [[ -n "$remote_name" ]] || continue
    remote_url="$(git -C "$repo_root" remote get-url "$remote_name" 2>/dev/null || true)"
    [[ -n "$remote_url" ]] || continue
    if new_url="$(to_ssh_url "$remote_url")"; then
      if [[ "$new_url" != "$remote_url" ]]; then
        git -C "$repo_root" remote set-url "$remote_name" "$new_url"
        repos_changed=$((repos_changed + 1))
      fi
    fi
  done < <(git -C "$repo_root" remote 2>/dev/null || true)
done < <(find "$WORKSPACE_ROOT" -mindepth 1 -maxdepth 3 -type d -name .git -printf '%h\n' 2>/dev/null | sort -u)

{
  echo "# Git/GitHub Bootstrap (${DATE_LOCAL})"
  echo
  echo "- Generated: ${DATE_UTC}"
  echo "- Workspace root: ${WORKSPACE_ROOT}"
  echo "- Git user.name: $(git config --global --get user.name || echo unset)"
  echo "- Git user.email: $(git config --global --get user.email || echo unset)"
  echo "- GitHub CLI installed: $(has_cmd gh && echo yes || echo no)"
  echo "- GitHub auth: ${gh_authenticated}"
  echo "- SSH key file: ${key_pub}"
  echo "- SSH key present on GitHub: ${ssh_key_uploaded}"
  echo "- Repositories updated to SSH remotes: ${repos_changed}"
  echo
  echo "## Active global git settings"
  echo '```ini'
  git config --global --list | sort
  echo '```'
} > "$REPORT"

log "git+github bootstrap completed"
echo "bootstrap complete; report: $REPORT"
