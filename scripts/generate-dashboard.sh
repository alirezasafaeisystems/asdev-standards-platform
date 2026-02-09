#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUTPUT_FILE="${1:-docs/platform-adoption-dashboard.md}"
NOW_UTC="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
LATEST_WEEKLY_DIGEST_URL="${LATEST_WEEKLY_DIGEST_URL:-}"
FINGERPRINT_HISTORY_LIMIT="${FINGERPRINT_HISTORY_LIMIT:-3}"
FINGERPRINT_HISTORY_ROW_LIMIT="${FINGERPRINT_HISTORY_ROW_LIMIT:-40}"
FINGERPRINT_TOP_DELTA_LIMIT="${FINGERPRINT_TOP_DELTA_LIMIT:-5}"
CLONE_FAILED_HISTORY_LIMIT="${CLONE_FAILED_HISTORY_LIMIT:-5}"
UNKNOWN_TEMPLATE_HISTORY_LIMIT="${UNKNOWN_TEMPLATE_HISTORY_LIMIT:-5}"
AUTH_OR_ACCESS_HISTORY_LIMIT="${AUTH_OR_ACCESS_HISTORY_LIMIT:-5}"

cd "$ROOT_DIR"

if [[ ! -f sync/divergence-report.csv ]]; then
  echo "Missing sync/divergence-report.csv" >&2
  exit 1
fi

mkdir -p "$(dirname "$OUTPUT_FILE")"

cat > "$OUTPUT_FILE" <<HEADER
# Platform Adoption Dashboard

- Generated at: ${NOW_UTC}
HEADER

if [[ -n "$LATEST_WEEKLY_DIGEST_URL" ]]; then
  {
    echo "- Latest Weekly Governance Digest: ${LATEST_WEEKLY_DIGEST_URL}"
    echo ""
  } >> "$OUTPUT_FILE"
fi

cat >> "$OUTPUT_FILE" <<'HEADER'
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

  clone_prev="$(count_combined_status "$combined_prev" "clone_failed")"
  clone_curr="$(count_combined_status "$combined_curr" "clone_failed")"
  clone_delta=$((clone_curr - clone_prev))

  cat >> "$OUTPUT_FILE" <<SECTION

## Combined Reliability (clone_failed)

| Metric | Previous | Current | Delta |
|---|---:|---:|---:|
| clone_failed rows | ${clone_prev} | ${clone_curr} | ${clone_delta} |
SECTION

  cat >> "$OUTPUT_FILE" <<SECTION

### clone_failed Trend by Run

| Run | clone_failed rows |
|---|---:|
SECTION

  clone_failed_history_tmp="$(mktemp)"
  : > "$clone_failed_history_tmp"
  echo "current,${clone_curr}" >> "$clone_failed_history_tmp"
  echo "previous,${clone_prev}" >> "$clone_failed_history_tmp"
  if [[ -d "sync/snapshots" ]]; then
    mapfile -t combined_history_files < <(find sync/snapshots -maxdepth 1 -type f -name 'divergence-report.combined.[0-9]*T[0-9]*Z.csv' | sort | tail -n "$CLONE_FAILED_HISTORY_LIMIT")
    for file in "${combined_history_files[@]}"; do
      run_tag="$(basename "$file" | sed -E 's/^divergence-report\.combined\.([0-9TZ]+)\.csv$/\1/')"
      run_clone_failed="$(count_combined_status "$file" "clone_failed")"
      echo "${run_tag},${run_clone_failed}" >> "$clone_failed_history_tmp"
    done
  fi

  if [[ -s "$clone_failed_history_tmp" ]]; then
    awk -F, '{printf "| %s | %s |\n", $1, $2}' "$clone_failed_history_tmp" | sort -u | head -n "$((CLONE_FAILED_HISTORY_LIMIT + 2))" >> "$OUTPUT_FILE"
  else
    echo "| n/a | 0 |" >> "$OUTPUT_FILE"
  fi
  rm -f "$clone_failed_history_tmp"

  unknown_template_prev="$(count_combined_status "$combined_prev" "unknown_template")"
  unknown_template_curr="$(count_combined_status "$combined_curr" "unknown_template")"

  cat >> "$OUTPUT_FILE" <<SECTION

### unknown_template Trend by Run

| Run | unknown_template rows |
|---|---:|
SECTION

  unknown_template_history_tmp="$(mktemp)"
  : > "$unknown_template_history_tmp"
  echo "current,${unknown_template_curr}" >> "$unknown_template_history_tmp"
  echo "previous,${unknown_template_prev}" >> "$unknown_template_history_tmp"
  if [[ -d "sync/snapshots" ]]; then
    mapfile -t unknown_template_history_files < <(find sync/snapshots -maxdepth 1 -type f -name 'divergence-report.combined.[0-9]*T[0-9]*Z.csv' | sort | tail -n "$UNKNOWN_TEMPLATE_HISTORY_LIMIT")
    for file in "${unknown_template_history_files[@]}"; do
      run_tag="$(basename "$file" | sed -E 's/^divergence-report\.combined\.([0-9TZ]+)\.csv$/\1/')"
      run_unknown_template="$(count_combined_status "$file" "unknown_template")"
      echo "${run_tag},${run_unknown_template}" >> "$unknown_template_history_tmp"
    done
  fi

  if [[ -s "$unknown_template_history_tmp" ]]; then
    awk -F, '{printf "| %s | %s |\n", $1, $2}' "$unknown_template_history_tmp" | sort -u | head -n "$((UNKNOWN_TEMPLATE_HISTORY_LIMIT + 2))" >> "$OUTPUT_FILE"
  else
    echo "| n/a | 0 |" >> "$OUTPUT_FILE"
  fi
  rm -f "$unknown_template_history_tmp"

  cat >> "$OUTPUT_FILE" <<SECTION

### clone_failed by Repository

| Repository | Previous | Current | Delta |
|---|---:|---:|---:|
SECTION

  mapfile -t clone_failed_repos < <(
    {
      if [[ -f "$combined_prev" ]]; then awk -F, 'NR>1 && $8=="clone_failed" {print $2}' "$combined_prev"; fi
      if [[ -f "$combined_curr" ]]; then awk -F, 'NR>1 && $8=="clone_failed" {print $2}' "$combined_curr"; fi
    } | sort -u
  )

  count_clone_failed_repo() {
    local file="$1"
    local repo="$2"
    if [[ ! -f "$file" ]]; then
      echo 0
      return
    fi
    awk -F, -v r="$repo" 'NR>1 && $2==r && $8=="clone_failed" {c++} END{print c+0}' "$file"
  }

  if [[ "${#clone_failed_repos[@]}" -eq 0 ]]; then
    echo "| n/a | 0 | 0 | 0 |" >> "$OUTPUT_FILE"
  else
    for repo in "${clone_failed_repos[@]}"; do
      prev="$(count_clone_failed_repo "$combined_prev" "$repo")"
      curr="$(count_clone_failed_repo "$combined_curr" "$repo")"
      delta=$((curr - prev))
      echo "| ${repo} | ${prev} | ${curr} | ${delta} |" >> "$OUTPUT_FILE"
    done
  fi

  combined_errors_prev="sync/divergence-report.combined.errors.previous.csv"
  combined_errors_curr="sync/divergence-report.combined.errors.csv"
  if [[ -f "$combined_errors_curr" ]]; then
    cat >> "$OUTPUT_FILE" <<SECTION

## Transient Error Fingerprints (Combined)

| Fingerprint | Previous | Current | Delta |
|---|---:|---:|---:|
SECTION

    count_error_fingerprint() {
      local file="$1"
      local fingerprint="$2"
      if [[ ! -f "$file" ]]; then
        echo 0
        return
      fi
      awk -F, -v f="$fingerprint" 'NR>1 && $3==f {c++} END{print c+0}' "$file"
    }

    mapfile -t fingerprints < <(
      {
        if [[ -f "$combined_errors_prev" ]]; then awk -F, 'NR>1{print $3}' "$combined_errors_prev"; fi
        if [[ -f "$combined_errors_curr" ]]; then awk -F, 'NR>1{print $3}' "$combined_errors_curr"; fi
      } | sort -u
    )

    if [[ "${#fingerprints[@]}" -eq 0 ]]; then
      echo "| n/a | 0 | 0 | 0 |" >> "$OUTPUT_FILE"
    else
      for fingerprint in "${fingerprints[@]}"; do
        prev="$(count_error_fingerprint "$combined_errors_prev" "$fingerprint")"
        curr="$(count_error_fingerprint "$combined_errors_curr" "$fingerprint")"
        delta=$((curr - prev))
        echo "| ${fingerprint} | ${prev} | ${curr} | ${delta} |" >> "$OUTPUT_FILE"
      done
    fi
  fi

  trend_current="sync/divergence-report.combined.errors.trend.csv"
  if [[ -f "$trend_current" ]]; then
    cat >> "$OUTPUT_FILE" <<SECTION

## Top Fingerprint Deltas (Current Run)

### Top Positive Deltas

| Fingerprint | Delta |
|---|---:|
SECTION

    mapfile -t top_positive_rows < <(awk -F, 'NR>1 && ($4+0)>0 {print $1 "," $4}' "$trend_current" | sort -t, -k2,2nr | head -n "$FINGERPRINT_TOP_DELTA_LIMIT")
    if [[ "${#top_positive_rows[@]}" -eq 0 ]]; then
      echo "| none | 0 |" >> "$OUTPUT_FILE"
    else
      for row in "${top_positive_rows[@]}"; do
        IFS=',' read -r fp delta <<< "$row"
        echo "| ${fp} | ${delta} |" >> "$OUTPUT_FILE"
      done
    fi

    cat >> "$OUTPUT_FILE" <<SECTION

### Top Negative Deltas

| Fingerprint | Delta |
|---|---:|
SECTION

    mapfile -t top_negative_rows < <(awk -F, 'NR>1 && ($4+0)<0 {print $1 "," $4}' "$trend_current" | sort -t, -k2,2n | head -n "$FINGERPRINT_TOP_DELTA_LIMIT")
    if [[ "${#top_negative_rows[@]}" -eq 0 ]]; then
      echo "| none | 0 |" >> "$OUTPUT_FILE"
    else
      for row in "${top_negative_rows[@]}"; do
        IFS=',' read -r fp delta <<< "$row"
        echo "| ${fp} | ${delta} |" >> "$OUTPUT_FILE"
      done
    fi
  fi

  trend_previous="sync/divergence-report.combined.errors.trend.previous.csv"
  if [[ -f "$trend_current" || -f "$trend_previous" ]]; then
    cat >> "$OUTPUT_FILE" <<SECTION

## Fingerprint Delta History (Recent Runs)

| Run | Fingerprint | Delta |
|---|---|---:|
SECTION

    trend_tmp="$(mktemp)"
    : > "$trend_tmp"

    if [[ -f "$trend_current" ]]; then
      awk -F, 'NR>1 {print "current," $1 "," $4}' "$trend_current" >> "$trend_tmp"
    fi
    if [[ -f "$trend_previous" ]]; then
      awk -F, 'NR>1 {print "previous," $1 "," $4}' "$trend_previous" >> "$trend_tmp"
    fi
    if [[ -d "sync/snapshots" ]]; then
      mapfile -t trend_history_files < <(find sync/snapshots -maxdepth 1 -type f -name 'divergence-report.combined.errors.trend.*.csv' | sort | tail -n "$FINGERPRINT_HISTORY_LIMIT")
      for file in "${trend_history_files[@]}"; do
        run_tag="$(basename "$file" | sed -E 's/^divergence-report\.combined\.errors\.trend\.([0-9TZ]+)\.csv$/\1/')"
        awk -F, -v run="$run_tag" 'NR>1 {print run "," $1 "," $4}' "$file" >> "$trend_tmp"
      done
    fi

    if [[ -s "$trend_tmp" ]]; then
      awk -F, '{printf "| %s | %s | %s |\n", $1, $2, $3}' "$trend_tmp" | sort -u | head -n "$FINGERPRINT_HISTORY_ROW_LIMIT" >> "$OUTPUT_FILE"
    else
      echo "| n/a | n/a | 0 |" >> "$OUTPUT_FILE"
    fi
    rm -f "$trend_tmp"

    cat >> "$OUTPUT_FILE" <<SECTION

## auth_or_access Trend by Run

| Run | auth_or_access count |
|---|---:|
SECTION

    auth_history_tmp="$(mktemp)"
    : > "$auth_history_tmp"
    get_auth_or_access_current_count() {
      local file="$1"
      if [[ ! -f "$file" ]]; then
        echo 0
        return
      fi
      awk -F, 'NR>1 && $1=="auth_or_access" {print $3; found=1} END{if(!found) print 0}' "$file"
    }

    if [[ -f "$trend_current" ]]; then
      echo "current,$(get_auth_or_access_current_count "$trend_current")" >> "$auth_history_tmp"
    fi
    if [[ -f "$trend_previous" ]]; then
      echo "previous,$(get_auth_or_access_current_count "$trend_previous")" >> "$auth_history_tmp"
    fi
    if [[ -d "sync/snapshots" ]]; then
      mapfile -t auth_history_files < <(find sync/snapshots -maxdepth 1 -type f -name 'divergence-report.combined.errors.trend.*.csv' | sort | tail -n "$AUTH_OR_ACCESS_HISTORY_LIMIT")
      for file in "${auth_history_files[@]}"; do
        run_tag="$(basename "$file" | sed -E 's/^divergence-report\.combined\.errors\.trend\.([0-9TZ]+)\.csv$/\1/')"
        echo "${run_tag},$(get_auth_or_access_current_count "$file")" >> "$auth_history_tmp"
      done
    fi

    if [[ -s "$auth_history_tmp" ]]; then
      awk -F, '{printf "| %s | %s |\n", $1, $2}' "$auth_history_tmp" | sort -u | head -n "$((AUTH_OR_ACCESS_HISTORY_LIMIT + 2))" >> "$OUTPUT_FILE"
    else
      echo "| n/a | 0 |" >> "$OUTPUT_FILE"
    fi
    rm -f "$auth_history_tmp"
  fi

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
