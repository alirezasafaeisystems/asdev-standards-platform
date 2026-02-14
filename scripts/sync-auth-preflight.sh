#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <owner/repo>" >&2
  exit 2
fi

target_repo="$1"
if [[ "$target_repo" != */* ]]; then
  echo "Invalid repository slug: ${target_repo} (expected owner/repo)" >&2
  exit 2
fi

sync_auth_token="${SYNC_AUTH_TOKEN:-${GITHUB_TOKEN:-}}"
if [[ -z "$sync_auth_token" ]]; then
  echo "Missing authentication token. Set SYNC_AUTH_TOKEN (or GITHUB_TOKEN)." >&2
  exit 1
fi

github_api_url="${GITHUB_API_URL:-https://api.github.com}"
github_server_url="${GITHUB_SERVER_URL:-https://github.com}"
summary_file="${GITHUB_STEP_SUMMARY:-}"

tmp_repo_body="$(mktemp)"
tmp_git_err="$(mktemp)"
tmp_askpass="$(mktemp)"
cleanup() {
  rm -f "$tmp_repo_body" "$tmp_git_err" "$tmp_askpass"
}
trap cleanup EXIT

summary_line() {
  local line="$1"
  if [[ -n "$summary_file" ]]; then
    echo "$line" >> "$summary_file"
  fi
}

fail_with_summary() {
  local category="$1"
  local detail="$2"
  echo "sync auth preflight failed (${category}): ${detail}" >&2
  summary_line "### Standards Sync Preflight"
  summary_line ""
  summary_line "- Target: \`${target_repo}\`"
  summary_line "- Result: **failed**"
  summary_line "- Category: \`${category}\`"
  summary_line "- Detail: ${detail}"
  exit 1
}

repo_api="${github_api_url%/}/repos/${target_repo}"
http_code="$(
  curl -sS -o "$tmp_repo_body" -w '%{http_code}' \
    -H "Authorization: Bearer ${sync_auth_token}" \
    -H "Accept: application/vnd.github+json" \
    "$repo_api" || true
)"

if [[ "$http_code" != "200" ]]; then
  api_message="$(python3 - "$tmp_repo_body" <<'PY'
import json
import pathlib
import sys
path = pathlib.Path(sys.argv[1])
try:
    data = json.loads(path.read_text(encoding="utf-8"))
except Exception:
    print("Unable to parse GitHub API response body.")
    raise SystemExit(0)
msg = data.get("message")
if isinstance(msg, str) and msg.strip():
    print(msg.strip())
else:
    print("GitHub API returned a non-200 status without a message.")
PY
)"

  case "$http_code" in
    401)
      fail_with_summary "token_invalid_or_expired" "GitHub API returned 401 for ${repo_api}. ${api_message}"
      ;;
    403)
      fail_with_summary "token_scope_or_rate_limit" "GitHub API returned 403 for ${repo_api}. ${api_message}"
      ;;
    404)
      fail_with_summary "repo_not_accessible_for_app_installation" "GitHub API returned 404 for ${repo_api}. ${api_message}"
      ;;
    *)
      fail_with_summary "repo_api_access_failed" "GitHub API returned ${http_code} for ${repo_api}. ${api_message}"
      ;;
  esac
fi

default_branch="$(python3 - "$tmp_repo_body" <<'PY'
import json
import pathlib
import sys
data = json.loads(pathlib.Path(sys.argv[1]).read_text(encoding="utf-8"))
print(data.get("default_branch", "unknown"))
PY
)"

cat > "$tmp_askpass" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
prompt="${1:-}"
if [[ "$prompt" == *"Username"* ]]; then
  echo "x-access-token"
else
  echo "${SYNC_AUTH_TOKEN:?}"
fi
SH
chmod 700 "$tmp_askpass"

if ! SYNC_AUTH_TOKEN="$sync_auth_token" \
  GIT_TERMINAL_PROMPT=0 \
  GIT_ASKPASS="$tmp_askpass" \
  git ls-remote "${github_server_url%/}/${target_repo}.git" HEAD >/dev/null 2>"$tmp_git_err"; then
  git_err_tail="$(tail -n 5 "$tmp_git_err" | sed -E 's#x-access-token:[^@]+@#x-access-token:***@#g')"
  fail_with_summary "git_transport_auth_failed" "git ls-remote failed for ${target_repo}. ${git_err_tail}"
fi

echo "sync auth preflight passed: ${target_repo} (default_branch=${default_branch})"
summary_line "### Standards Sync Preflight"
summary_line ""
summary_line "- Target: \`${target_repo}\`"
summary_line "- Result: **passed**"
summary_line "- Default branch: \`${default_branch}\`"
