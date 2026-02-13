#!/usr/bin/env bash
set -euo pipefail

MAX_PARALLEL="${MAX_PARALLEL:-$(getconf _NPROCESSORS_ONLN 2>/dev/null || echo 4)}"
WORKSPACE_ROOT="${WORKSPACE_ROOT:-$(cd "$(dirname "$0")/../../" && pwd)}"
LOG_DIR="${LOG_DIR:-$WORKSPACE_ROOT/asdev-standards-platform/logs/fast-parallel}"

TARGET_REPOS=(
  "asdev-automation-hub"
  "asdev-portfolio"
  "asdev-persiantoolbox"
  "asdev-standards-platform"
)

mkdir -p "$LOG_DIR"

detect_gpu() {
  if command -v nvidia-smi >/dev/null 2>&1; then
    local names
    names="$(nvidia-smi --query-gpu=name --format=csv,noheader | tr '\n' ',' | sed 's/,$//')"
    if [[ -n "$names" ]]; then
      echo "GPU detected: $names"
      export USE_GPU_ACCELERATION=1
      return
    fi
  fi
  echo "GPU not detected; using CPU parallel profile."
  export USE_GPU_ACCELERATION=0
}

run_repo_pipeline() {
  local repo="$1"
  local repo_path="$WORKSPACE_ROOT/$repo"
  local log_file="$LOG_DIR/$repo.log"

  case "$repo" in
    asdev-automation-hub)
      (
        cd "$repo_path"
        pnpm install --frozen-lockfile
        pnpm lint
        pnpm typecheck
        pnpm test
        pnpm audit:deps
      ) >"$log_file" 2>&1
      ;;
    asdev-portfolio)
      (
        cd "$repo_path"
        bun install --frozen-lockfile
        bun run lint
        bun run type-check
        bun run test
        bun run build
        bun run audit:high
      ) >"$log_file" 2>&1
      ;;
    asdev-persiantoolbox)
      (
        cd "$repo_path"
        pnpm install --frozen-lockfile
        pnpm ci:quick
        pnpm audit --prod --audit-level=high
      ) >"$log_file" 2>&1
      ;;
    asdev-standards-platform)
      (
        cd "$repo_path"
        make lint
        make test
        make security-audit
      ) >"$log_file" 2>&1
      ;;
    *)
      echo "Unsupported repo: $repo" >&2
      return 2
      ;;
  esac
}

detect_gpu
echo "Workspace root: $WORKSPACE_ROOT"
echo "Log directory: $LOG_DIR"
echo "Max parallel workers: $MAX_PARALLEL"

pids=()
declare -A pid_to_repo

for repo in "${TARGET_REPOS[@]}"; do
  while (( $(jobs -pr | wc -l) >= MAX_PARALLEL )); do
    sleep 0.2
  done

  echo "Starting pipeline: $repo"
  run_repo_pipeline "$repo" &
  pid=$!
  pids+=("$pid")
  pid_to_repo["$pid"]="$repo"
done

failed=()
for pid in "${pids[@]}"; do
  if ! wait "$pid"; then
    failed+=("${pid_to_repo[$pid]}")
  fi
done

if (( ${#failed[@]} > 0 )); then
  echo "Parallel run failed for: ${failed[*]}" >&2
  echo "See logs under: $LOG_DIR" >&2
  exit 1
fi

echo "Parallel run completed successfully for all target repositories."
