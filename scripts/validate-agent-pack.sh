#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

required_files=(
  "AGENTS.md"
  "platform/agent/AGENT_TEMPLATE.md"
  "platform/agent/HUMAN_GATES.md"
  "platform/agent/REPO_LENSES.md"
  "platform/scripts/generate-agent-md.py"
)

for f in "${required_files[@]}"; do
  if [[ ! -f "${ROOT_DIR}/${f}" ]]; then
    echo "Missing required agent-pack file: ${f}" >&2
    exit 1
  fi
done

if [[ ! -x "${ROOT_DIR}/platform/scripts/generate-agent-md.py" ]]; then
  echo "Generator script must be executable: platform/scripts/generate-agent-md.py" >&2
  exit 1
fi

# Ensure AGENTS.md documents runtime gates.
for needle in \
  "Codex Runtime Guidance" \
  "Human Approval Gates" \
  "Auth/permissions/roles/security policy changes" \
  "breaking API/schema/db" \
  "critical UX flow"; do
  if ! grep -qi "$needle" "${ROOT_DIR}/AGENTS.md"; then
    echo "AGENTS.md missing required runtime guidance text: $needle" >&2
    exit 1
  fi
done

# Ensure AGENT template includes mandatory sections.
for section in \
  "## Identity & Mission" \
  "## Repo Commands" \
  "## Workflow Loop" \
  "## Definition of Done" \
  "## Human Approval Gates" \
  "## Quality Checklist" \
  "## Lenses" \
  "## Documentation & Change Log Expectations"; do
  if ! grep -q "$section" "${ROOT_DIR}/platform/agent/AGENT_TEMPLATE.md"; then
    echo "AGENT template missing mandatory section: $section" >&2
    exit 1
  fi
done

# Generator should be invokable without network for CLI contract.
if ! python3 "${ROOT_DIR}/platform/scripts/generate-agent-md.py" --help >/dev/null; then
  echo "Generator CLI contract check failed." >&2
  exit 1
fi

echo "agent pack contract validation passed."
