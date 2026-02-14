#!/usr/bin/env bash
set -u -o pipefail

ROOT="${ROOT:-/home/dev/Project_Me}"
HUB="$ROOT/asdev-standards-platform"
TODAY="$(date +%F)"
NOW_UTC="$(date -u +'%Y-%m-%d %H:%M:%S UTC')"
CPU_THREADS="$(nproc 2>/dev/null || echo 4)"
MAX_PARALLEL_JOBS="${MAX_PARALLEL_JOBS:-$CPU_THREADS}"
NODE_MAX_OLD_SPACE_MB="${NODE_MAX_OLD_SPACE_MB:-12288}"
UV_THREADS_DEFAULT=$((CPU_THREADS * 4))
if [[ "$UV_THREADS_DEFAULT" -gt 128 ]]; then UV_THREADS_DEFAULT=128; fi
UV_THREADPOOL_SIZE_OVERRIDE="${UV_THREADPOOL_SIZE_OVERRIDE:-$UV_THREADS_DEFAULT}"
TURBO_CONCURRENCY="${TURBO_CONCURRENCY:-$CPU_THREADS}"
GPU_MODE="cpu"
GPU_VENDOR="unknown"
GPU_OPENCL="no"

if command -v nvidia-smi >/dev/null 2>&1; then
  GPU_MODE="nvidia"
  GPU_VENDOR="nvidia"
elif lspci 2>/dev/null | rg -qi 'amd/ati|radeon'; then
  GPU_VENDOR="amd"
  if command -v clinfo >/dev/null 2>&1 && clinfo 2>/dev/null | rg -qi 'Device Vendor\\s+AMD'; then
    GPU_MODE="amd-opencl"
    GPU_OPENCL="yes"
  elif [[ -e /dev/dri/renderD128 ]]; then
    GPU_MODE="amd-drm"
  else
    GPU_MODE="amd"
  fi
fi

REPORT="$HUB/docs/reports/PRIORITY_PIPELINE_MAX_${TODAY}.md"
LOG_DIR="$HUB/var/autonomous-executor/logs/pipelines-max-${TODAY}"
RESULTS_DIR="$LOG_DIR/results"
mkdir -p "$LOG_DIR" "$RESULTS_DIR"

repos=(
  "asdev-portfolio"
  "asdev-persiantoolbox"
  "asdev-family-rosca"
  "asdev-nexa-vpn"
  "asdev-creator-membership-ir"
  "asdev-automation-hub"
  "asdev-standards-platform"
  "asdev-codex-reviewer"
)

repo_command() {
  case "$1" in
    asdev-portfolio)
      printf '%s' "pnpm -s test && pnpm -s build"
      ;;
    asdev-persiantoolbox)
      printf '%s' "pnpm -s test && pnpm -s build"
      ;;
    asdev-family-rosca)
      printf '%s' "bun test && pnpm -s build"
      ;;
    asdev-nexa-vpn)
      printf '%s' "bun test && pnpm -s build"
      ;;
    asdev-creator-membership-ir)
      printf '%s' "pnpm -s lint && pnpm -s typecheck && pnpm -s test"
      ;;
    asdev-automation-hub)
      printf '%s' "pnpm -s test && pnpm -s build"
      ;;
    asdev-standards-platform)
      printf '%s' "MAKEFLAGS= make ci"
      ;;
    asdev-codex-reviewer)
      printf '%s' "test -f README.md"
      ;;
    *)
      printf '%s' "true"
      ;;
  esac
}

run_repo_pipeline() {
  local repo="$1"
  local cmd="$2"
  local start_ts end_ts dur ec
  local log_file="$LOG_DIR/${repo}.log"
  local result_file="$RESULTS_DIR/${repo}.tsv"

  start_ts="$(date +%s)"
  (
    cd "$ROOT/$repo" || exit 97
    export CI=1
    export NODE_OPTIONS="--max-old-space-size=${NODE_MAX_OLD_SPACE_MB}"
    export UV_THREADPOOL_SIZE="$UV_THREADPOOL_SIZE_OVERRIDE"
    export TURBO_CONCURRENCY="$TURBO_CONCURRENCY"
    export MAKEFLAGS="-j${CPU_THREADS}"
    export PNPM_FETCH_RETRIES=1
    export PNPM_NETWORK_CONCURRENCY=4
    export NPM_CONFIG_PREFER_OFFLINE=true
    export NPM_CONFIG_AUDIT=false
    export NPM_CONFIG_FUND=false
    export PLAYWRIGHT_JOBS="$CPU_THREADS"
    export PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD=1
    export LIBGL_ALWAYS_SOFTWARE=0
    export GPU_ACCELERATION_HINT="$GPU_MODE"
    export GPU_VENDOR_HINT="$GPU_VENDOR"
    if [[ "$GPU_VENDOR" == "amd" ]]; then
      export GALLIUM_DRIVER=radeonsi
      export RUSTICL_ENABLE=radeonsi
    fi
    if [[ "$GPU_MODE" == "amd-opencl" ]]; then
      export OCL_ICD_VENDORS=/etc/OpenCL/vendors
    fi

    # Prefer local caches and avoid unnecessary network bursts.
    bash -lc "$cmd"
  ) >"$log_file" 2>&1
  ec=$?
  end_ts="$(date +%s)"
  dur=$((end_ts - start_ts))
  printf '%s\t%s\t%s\t%s\t%s\n' "$repo" "$ec" "$dur" "$cmd" "$log_file" > "$result_file"
}

{
  echo "# Priority Pipeline MAX Run (${TODAY})"
  echo
  echo "- Executed (UTC): ${NOW_UTC}"
  echo "- CPU threads: ${CPU_THREADS}"
  echo "- Max parallel jobs: ${MAX_PARALLEL_JOBS}"
  echo "- Node max old space: ${NODE_MAX_OLD_SPACE_MB} MB"
  echo "- UV thread pool size: ${UV_THREADPOOL_SIZE_OVERRIDE}"
  echo "- Turbo concurrency: ${TURBO_CONCURRENCY}"
  echo "- GPU mode: ${GPU_MODE}"
  echo "- GPU vendor: ${GPU_VENDOR}"
  echo "- GPU OpenCL: ${GPU_OPENCL}"
  echo
  echo "| Repo | Exit | Duration(s) | Command | Log |"
  echo "|---|---:|---:|---|---|"
} > "$REPORT"

for repo in "${repos[@]}"; do
  while [[ "$(jobs -rp | wc -l | tr -d ' ')" -ge "$MAX_PARALLEL_JOBS" ]]; do
    sleep 1
  done
  cmd="$(repo_command "$repo")"
  run_repo_pipeline "$repo" "$cmd" &
done

wait

for repo in "${repos[@]}"; do
  result_file="$RESULTS_DIR/${repo}.tsv"
  if [[ -f "$result_file" ]]; then
    IFS=$'\t' read -r name ec dur cmd log_file < "$result_file"
    printf '| %s | %s | %s | `%s` | `%s` |\n' "$name" "$ec" "$dur" "$cmd" "$log_file" >> "$REPORT"
  else
    printf '| %s | %s | %s | `%s` | `%s` |\n' "$repo" "98" "0" "n/a" "missing-result" >> "$REPORT"
  fi
done

{
  echo
  echo "## Tail Logs"
  echo
  for repo in "${repos[@]}"; do
    log_file="$LOG_DIR/${repo}.log"
    if [[ -f "$log_file" ]]; then
      echo "### ${repo}"
      echo '```text'
      tail -n 60 "$log_file"
      echo '```'
      echo
    fi
  done
} >> "$REPORT"

echo "Pipeline max run report: $REPORT"
