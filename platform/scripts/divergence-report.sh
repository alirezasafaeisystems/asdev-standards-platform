#!/usr/bin/env bash
set -euo pipefail

TARGETS_FILE="${1:-sync/targets.example.yaml}"
TEMPLATES_FILE="${2:-platform/repo-templates/templates.yaml}"
TEMPLATES_ROOT="${3:-platform/repo-templates}"
OUTPUT_FILE="${4:-sync/divergence-report.csv}"
DATE_NOW="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

resolve_path() {
  local path_value="$1"
  if [[ "$path_value" = /* ]]; then
    printf "%s\n" "$path_value"
  else
    printf "%s/%s\n" "$(pwd)" "$path_value"
  fi
}

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "Missing required command: $1" >&2
    exit 1
  }
}

require_cmd gh
require_cmd yq
require_cmd git
require_cmd timeout

RETRY_ATTEMPTS="${RETRY_ATTEMPTS:-3}"
RETRY_BASE_DELAY="${RETRY_BASE_DELAY:-2}"
CLONE_TIMEOUT_SECONDS="${CLONE_TIMEOUT_SECONDS:-30}"

retry_cmd() {
  local attempts="$1"
  shift
  local delay="$RETRY_BASE_DELAY"
  local attempt=1

  while true; do
    if "$@"; then
      return 0
    fi

    if [[ "$attempt" -ge "$attempts" ]]; then
      echo "Command failed after ${attempts} attempts: $*" >&2
      return 1
    fi

    echo "Transient failure (attempt ${attempt}/${attempts}). Retrying in ${delay}s..." >&2
    sleep "$delay"
    delay=$((delay * 2))
    attempt=$((attempt + 1))
  done
}

clone_repo() {
  local repo="$1"
  local repo_dir="$2"

  if retry_cmd "$RETRY_ATTEMPTS" timeout "$CLONE_TIMEOUT_SECONDS" gh repo clone "$repo" "$repo_dir" -- -q; then
    return 0
  fi

  local repo_url="https://github.com/${repo}.git"
  if retry_cmd "$RETRY_ATTEMPTS" timeout "$CLONE_TIMEOUT_SECONDS" env GIT_TERMINAL_PROMPT=0 git clone --quiet "$repo_url" "$repo_dir"; then
    return 0
  fi

  return 1
}

TARGETS_FILE="$(resolve_path "$TARGETS_FILE")"
TEMPLATES_FILE="$(resolve_path "$TEMPLATES_FILE")"
TEMPLATES_ROOT="$(resolve_path "$TEMPLATES_ROOT")"
OUTPUT_FILE="$(resolve_path "$OUTPUT_FILE")"

lookup_template_value() {
  local template_id="$1"
  local key="$2"
  yq -r ".templates[] | select(.id == \"${template_id}\") | .${key}" "$TEMPLATES_FILE"
}

extract_detected_version() {
  local file_path="$1"
  if [[ ! -f "$file_path" ]]; then
    echo "missing"
    return
  fi

  local first_line
  first_line="$(head -n 1 "$file_path" || true)"

  if [[ "$first_line" =~ version=([0-9]+\.[0-9]+\.[0-9]+) ]]; then
    echo "${BASH_REMATCH[1]}"
    return
  fi

  echo "unknown"
}

count_targets="$(yq -r '.targets | length' "$TARGETS_FILE")"
if [[ "$count_targets" == "0" ]]; then
  echo "No targets found in $TARGETS_FILE"
  exit 0
fi

work_root="$(mktemp -d)"
trap 'rm -rf "$work_root"' EXIT

mkdir -p "$(dirname "$OUTPUT_FILE")"
echo "repo,template_id,expected_version,detected_version,mode,source_ref,status,last_checked_at" > "$OUTPUT_FILE"

for ((i=0; i<count_targets; i++)); do
  repo="$(yq -r ".targets[$i].repo" "$TARGETS_FILE")"

  [[ -z "$repo" || "$repo" == "null" ]] && continue

  repo_dir="$work_root/${repo##*/}"

  if ! clone_repo "$repo" "$repo_dir"; then
    echo "${repo},all,n/a,n/a,n/a,n/a,clone_failed,${DATE_NOW}" >> "$OUTPUT_FILE"
    continue
  fi

  mapfile -t templates < <(yq -r ".targets[$i].templates[]?" "$TARGETS_FILE")
  mapfile -t optional_features < <(yq -r ".targets[$i].optional_features[]?" "$TARGETS_FILE")
  mapfile -t opt_outs < <(yq -r ".targets[$i].opt_outs[]?" "$TARGETS_FILE")

  all_templates=("${templates[@]}" "${optional_features[@]}")

  for template_id in "${all_templates[@]}"; do
    [[ -z "$template_id" || "$template_id" == "null" ]] && continue

    path="$(lookup_template_value "$template_id" "path")"
    expected_version="$(lookup_template_value "$template_id" "version")"
    mode="$(lookup_template_value "$template_id" "mode")"
    source_ref="$(lookup_template_value "$template_id" "source_ref")"

    if [[ -z "$path" || "$path" == "null" ]]; then
      echo "${repo},${template_id},${expected_version},unknown,${mode},${source_ref},unknown_template,${DATE_NOW}" >> "$OUTPUT_FILE"
      continue
    fi

    is_opted_out="false"
    for opted_path in "${opt_outs[@]}"; do
      if [[ "$path" == "$opted_path" ]]; then
        is_opted_out="true"
        break
      fi
    done

    if [[ "$is_opted_out" == "true" ]]; then
      echo "${repo},${template_id},${expected_version},n/a,${mode},${source_ref},opted_out,${DATE_NOW}" >> "$OUTPUT_FILE"
      continue
    fi

    src="$TEMPLATES_ROOT/$path"
    dst="$repo_dir/$path"

    if [[ ! -f "$dst" ]]; then
      echo "${repo},${template_id},${expected_version},missing,${mode},${source_ref},missing,${DATE_NOW}" >> "$OUTPUT_FILE"
      continue
    fi

    detected_version="$(extract_detected_version "$dst")"

    if cmp -s "$src" "$dst"; then
      echo "${repo},${template_id},${expected_version},${detected_version},${mode},${source_ref},aligned,${DATE_NOW}" >> "$OUTPUT_FILE"
    else
      echo "${repo},${template_id},${expected_version},${detected_version},${mode},${source_ref},diverged,${DATE_NOW}" >> "$OUTPUT_FILE"
    fi
  done
done

echo "Divergence report generated: $OUTPUT_FILE"
