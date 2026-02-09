#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUTPUT_FILE="${1:-docs/platform-adoption-dashboard.md}"
NOW_UTC="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

cd "$ROOT_DIR"

if [[ ! -f sync/divergence-report.csv ]]; then
  echo "Missing sync/divergence-report.csv" >&2
  exit 1
fi

mkdir -p "$(dirname "$OUTPUT_FILE")"

cat > "$OUTPUT_FILE" <<HEADER
# Platform Adoption Dashboard

- Generated at: ${NOW_UTC}

## Level 0 Adoption (from divergence report)

| Repository | Aligned | Diverged | Missing | Opted-out |
|---|---:|---:|---:|---:|
HEADER

mapfile -t repos < <(awk -F, 'NR>1{print $1}' sync/divergence-report.csv | sort -u)
for repo in "${repos[@]}"; do
  aligned="$(awk -F, -v r="$repo" 'NR>1 && $1==r && $7=="aligned" {c++} END{print c+0}' sync/divergence-report.csv)"
  diverged="$(awk -F, -v r="$repo" 'NR>1 && $1==r && $7=="diverged" {c++} END{print c+0}' sync/divergence-report.csv)"
  missing="$(awk -F, -v r="$repo" 'NR>1 && $1==r && $7=="missing" {c++} END{print c+0}' sync/divergence-report.csv)"
  opted="$(awk -F, -v r="$repo" 'NR>1 && $1==r && $7=="opted_out" {c++} END{print c+0}' sync/divergence-report.csv)"
  echo "| ${repo} | ${aligned} | ${diverged} | ${missing} | ${opted} |" >> "$OUTPUT_FILE"
done

cat >> "$OUTPUT_FILE" <<SECTION

## Level 0 Trend (Current vs Previous Snapshot)

| Status | Previous | Current | Delta |
|---|---:|---:|---:|
SECTION

count_status() {
  local file="$1"
  local status="$2"
  if [[ ! -f "$file" ]]; then
    echo 0
    return
  fi
  awk -F, -v s="$status" 'NR>1 && $7==s {c++} END{print c+0}' "$file"
}

prev_file="sync/divergence-report.previous.csv"
curr_file="sync/divergence-report.csv"

for st in aligned diverged missing opted_out; do
  prev="$(count_status "$prev_file" "$st")"
  curr="$(count_status "$curr_file" "$st")"
  delta=$((curr - prev))
  echo "| ${st} | ${prev} | ${curr} | ${delta} |" >> "$OUTPUT_FILE"
done

combined_prev="sync/divergence-report.combined.previous.csv"
combined_curr="sync/divergence-report.combined.csv"

if [[ -f "$combined_curr" ]]; then
  cat >> "$OUTPUT_FILE" <<SECTION

## Combined Report Trend (Current vs Previous Snapshot)

| Status | Previous | Current | Delta |
|---|---:|---:|---:|
SECTION

  count_combined_status() {
    local file="$1"
    local status="$2"
    if [[ ! -f "$file" ]]; then
      echo 0
      return
    fi
    awk -F, -v s="$status" 'NR>1 && $8==s {c++} END{print c+0}' "$file"
  }

  for st in aligned diverged missing opted_out clone_failed unknown_template unknown; do
    prev="$(count_combined_status "$combined_prev" "$st")"
    curr="$(count_combined_status "$combined_curr" "$st")"
    delta=$((curr - prev))
    echo "| ${st} | ${prev} | ${curr} | ${delta} |" >> "$OUTPUT_FILE"
  done

  cat >> "$OUTPUT_FILE" <<SECTION

## Combined Report Delta by Repo

| Repository | Previous Non-aligned | Current Non-aligned | Delta |
|---|---:|---:|---:|
SECTION

  mapfile -t combined_repos < <(
    {
      if [[ -f "$combined_prev" ]]; then awk -F, 'NR>1{print $2}' "$combined_prev"; fi
      if [[ -f "$combined_curr" ]]; then awk -F, 'NR>1{print $2}' "$combined_curr"; fi
    } | sort -u
  )

  count_non_aligned() {
    local file="$1"
    local repo="$2"
    if [[ ! -f "$file" ]]; then
      echo 0
      return
    fi
    awk -F, -v r="$repo" 'NR>1 && $2==r && $8!="aligned" {c++} END{print c+0}' "$file"
  }

  for repo in "${combined_repos[@]}"; do
    prev="$(count_non_aligned "$combined_prev" "$repo")"
    curr="$(count_non_aligned "$combined_curr" "$repo")"
    delta=$((curr - prev))
    echo "| ${repo} | ${prev} | ${curr} | ${delta} |" >> "$OUTPUT_FILE"
  done
fi

cat >> "$OUTPUT_FILE" <<SECTION

## Level 1 Rollout Targets

| Repository | Level 1 Templates | Target File |
|---|---|---|
SECTION

mapfile -t level1_files < <(find sync -maxdepth 1 -type f -name 'targets.level1*.yaml' | sort)
if [[ "${#level1_files[@]}" -gt 0 ]]; then
  for file in "${level1_files[@]}"; do
    while IFS=$'\t' read -r repo templates; do
      echo "| ${repo} | ${templates} | ${file} |" >> "$OUTPUT_FILE"
    done < <(yq -r '.targets[]? | [.repo, (.templates | join(", "))] | @tsv' "$file")
  done
else
  echo "| n/a | targets.level1 files not found | n/a |" >> "$OUTPUT_FILE"
fi

cat >> "$OUTPUT_FILE" <<'FOOTER'

## Notes

- Level 0 metrics are derived from `sync/divergence-report.csv`.
- Level 1 section reflects configured rollout intent from `sync/targets.level1*.yaml`.
FOOTER
