#!/usr/bin/env bash
set -euo pipefail

repo="${1:-alirezasafaeisystems/asdev-standards-platform}"
output="${2:-docs/reports/PR_CHECK_EMISSION_AUDIT.md}"
strict_mode="${3:-${PR_CHECK_AUDIT_STRICT:-false}}"

echo "[deprecation] generate-pr-check-evidence.sh now delegates to audit-pr-check-emission.sh" >&2
bash "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/audit-pr-check-emission.sh" "$repo" "$output" "$strict_mode"
