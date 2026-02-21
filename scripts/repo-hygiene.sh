#!/usr/bin/env bash
set -euo pipefail

MODE="${1:-check}"
ROOT_DIR="${2:-.}"

if [[ "${MODE}" != "check" && "${MODE}" != "fix" ]]; then
  echo "Usage: $0 [check|fix] [root_dir]" >&2
  exit 2
fi

if [[ ! -d "${ROOT_DIR}" ]]; then
  echo "Root directory not found: ${ROOT_DIR}" >&2
  exit 2
fi

cd "${ROOT_DIR}"

mapfile -t CACHE_DIRS < <(find . -type d -name '__pycache__' -not -path './.git/*' -not -path '*/.venv/*' | sort)
mapfile -t CACHE_FILES < <(find . -type f \( -name '*.pyc' -o -name '*.pyo' -o -name '.DS_Store' \) -not -path './.git/*' -not -path '*/.venv/*' | sort)
mapfile -t EMPTY_DIRS < <(find . -depth -type d -empty -not -path './.git*' -not -path '*/.venv*' -not -path '.')

had_issues=0

print_list() {
  local title="$1"
  shift
  local entries=("$@")
  if ((${#entries[@]} > 0)); then
    had_issues=1
    echo "${title}:"
    printf '  %s\n' "${entries[@]}"
  fi
}

print_list "Found cache directories" "${CACHE_DIRS[@]}"
print_list "Found cache/metadata files" "${CACHE_FILES[@]}"
print_list "Found empty directories" "${EMPTY_DIRS[@]}"

if [[ "${MODE}" == "fix" ]]; then
  if ((${#CACHE_DIRS[@]} > 0)); then
    printf '%s\0' "${CACHE_DIRS[@]}" | xargs -0r rm -rf
  fi
  if ((${#CACHE_FILES[@]} > 0)); then
    printf '%s\0' "${CACHE_FILES[@]}" | xargs -0r rm -f
  fi
  if ((${#EMPTY_DIRS[@]} > 0)); then
    for empty_dir in "${EMPTY_DIRS[@]}"; do
      rmdir "${empty_dir}" 2>/dev/null || true
    done
  fi
  # Remove parent directories that became empty after cache/file cleanup.
  while IFS= read -r nested_empty; do
    [[ -z "${nested_empty}" ]] && continue
    rmdir "${nested_empty}" 2>/dev/null || true
  done < <(find . -depth -type d -empty -not -path './.git*' -not -path '*/.venv*' -not -path '.')
  echo "Repo hygiene fix completed."
  exit 0
fi

if [[ "${had_issues}" -eq 1 ]]; then
  echo "Repo hygiene check failed. Run: bash scripts/repo-hygiene.sh fix"
  exit 1
fi

echo "Repo hygiene check passed."
