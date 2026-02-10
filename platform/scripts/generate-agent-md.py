#!/usr/bin/env python3
import argparse
import json
import re
import shutil
import subprocess
from pathlib import Path

OWNER_DEFAULT = "alirezasafaeiiidev"
DEFAULT_REPOS = [
    "asdev_platform",
    "persian_tools",
    "my_portfolio",
    "patreon_iran",
    "go-level1-pilot",
    "python-level1-pilot",
]

BASE_GATES = [
    "Auth/permissions/roles/security policy changes",
    "Breaking API/schema/db changes, destructive migrations, data deletion",
    "Adding dependencies or major-version upgrades",
    "Telemetry/external data transfer/secret handling changes",
    "Legal text (Terms/Privacy) or sensitive claims",
    "Critical UX flows (signup/checkout/pricing/payment)",
]


def run(cmd, cwd=None, check=True):
    return subprocess.run(cmd, cwd=cwd, check=check, text=True, capture_output=True)


def repo_url(owner: str, repo: str) -> str:
    return f"git@github.com:{owner}/{repo}.git"


def clone_repo(owner: str, repo: str, workdir: Path):
    dst = workdir / repo
    if dst.exists():
        shutil.rmtree(dst)
    result = run(["git", "clone", "--depth", "1", repo_url(owner, repo), str(dst)], check=False)
    if result.returncode != 0:
        return None, result.stderr.strip()
    return dst, None


def read_package_commands(repo_dir: Path):
    pkg_file = repo_dir / "package.json"
    if not pkg_file.exists():
        return None, {}
    data = json.loads(pkg_file.read_text(encoding="utf-8"))
    scripts = data.get("scripts", {})

    pm = "npm"
    pm_field = str(data.get("packageManager", ""))
    if pm_field.startswith("pnpm") or (repo_dir / "pnpm-lock.yaml").exists():
        pm = "pnpm"
    elif pm_field.startswith("bun") or (repo_dir / "bun.lock").exists() or (repo_dir / "bun.lockb").exists():
        pm = "bun"

    setup = "npm install"
    if pm == "pnpm":
        setup = "pnpm install --frozen-lockfile"
    elif pm == "bun":
        setup = "bun install --frozen-lockfile"

    def cmd(key):
        return f"{pm} run {key}" if key in scripts else None

    commands = {
        "Setup": setup,
        "Run": cmd("dev") or cmd("start"),
        "Test": cmd("test") or cmd("test:unit"),
        "Lint": cmd("lint"),
        "Format": cmd("format") or cmd("format:check"),
        "Build": cmd("build"),
        "Typecheck": cmd("typecheck"),
        "Security": cmd("security:scan") or cmd("audit"),
    }
    return pm, commands


def read_make_commands(repo_dir: Path):
    makefile = repo_dir / "Makefile"
    if not makefile.exists():
        return {}
    content = makefile.read_text(encoding="utf-8", errors="ignore")
    targets = set(re.findall(r"^([a-zA-Z0-9_.-]+):", content, flags=re.M))

    def mk(t):
        return f"make {t}" if t in targets else None

    return {
        "Setup": mk("setup"),
        "Run": mk("run"),
        "Test": mk("test"),
        "Lint": mk("lint"),
        "Format": mk("format"),
        "Build": mk("build"),
    }


def detect_stack(repo_dir: Path):
    if (repo_dir / "go.mod").exists():
        return "go"
    if (repo_dir / "pyproject.toml").exists() or (repo_dir / "requirements.txt").exists():
        return "python"
    if (repo_dir / "package.json").exists():
        return "javascript-typescript"
    return "unknown"


def workflow_list(repo_dir: Path):
    wf = repo_dir / ".github" / "workflows"
    if not wf.exists():
        return []
    return sorted([p.name for p in wf.glob("*.yml")]) + sorted([p.name for p in wf.glob("*.yaml")])


def lenses_for_repo(repo: str, stack: str):
    base = ["Quality", "Reliability", "Security", "Documentation"]
    if repo in {"my_portfolio", "persian_tools"}:
        return base + ["UX/Accessibility", "SEO/Performance", "Product"]
    if repo == "patreon_iran":
        return base + ["Legal/Compliance", "Risk/Auditability", "Abuse/Fraud resistance", "Payment Integrity"]
    if stack in {"go", "python"}:
        return base + ["Simplicity/Maintainability", "CI baseline parity"]
    if repo == "asdev_platform":
        return base + ["Template traceability", "Cross-repo adoption safety", "Policy coherence"]
    return base


def risks_for_repo(repo: str):
    if repo == "patreon_iran":
        return ["Payment/payout/download flows", "RBAC and authorization", "Compliance and legal wording"]
    if repo == "my_portfolio":
        return ["SEO regressions", "UX/a11y regressions", "security hardening drift"]
    if repo == "persian_tools":
        return ["Local-first/privacy regressions", "consent/analytics violations", "PWA cache/version drift"]
    if repo in {"go-level1-pilot", "python-level1-pilot"}:
        return ["CI baseline drift"]
    if repo == "asdev_platform":
        return ["template-policy drift", "cross-repo rollout breakage"]
    return ["undocumented risk"]


def build_agent_md(repo: str, stack: str, commands: dict, workflows: list):
    lines = []
    lines.append(f"# {repo} Agent Guide")
    lines.append("")
    lines.append("## Identity & Mission")
    lines.append("")
    lines.append(f"You are the implementation and governance agent for `{repo}`.")
    lines.append("Primary mission: deliver safe, incremental, verifiable changes aligned with repository standards.")
    lines.append("")
    lines.append("High-risk domains:")
    for risk in risks_for_repo(repo):
        lines.append(f"- {risk}")
    lines.append("")
    lines.append("## Repo Commands")
    lines.append("")

    ordered = ["Setup", "Run", "Test", "Lint", "Format", "Build", "Typecheck", "Security"]
    for key in ordered:
        value = commands.get(key)
        lines.append(f"- {key}: `{value}`" if value else f"- {key}: `n/a`")

    lines.append("")
    lines.append("## Workflow Loop")
    lines.append("")
    lines.append("`Discover -> Plan -> Task -> Execute -> Verify -> Document`")
    lines.append("")
    lines.append("## Definition of Done")
    lines.append("")
    lines.append("1. Scope is complete and minimal.")
    lines.append("2. Relevant checks pass.")
    lines.append("3. Docs/changelog are updated when behavior changes.")
    lines.append("4. No unrelated file changes.")
    lines.append("5. Risks and follow-ups are documented.")
    lines.append("")
    lines.append("## Human Approval Gates")
    lines.append("")
    for gate in BASE_GATES:
        lines.append(f"- {gate}")
    lines.append("")
    lines.append("## Quality Checklist")
    lines.append("")
    lines.append("- Execute available lint/test/build/typecheck/security commands listed above.")
    lines.append("- Keep CI workflows passing.")
    lines.append("- Record command evidence in PR.")
    lines.append("")
    if workflows:
        lines.append("CI workflows detected:")
        for wf in workflows:
            lines.append(f"- `.github/workflows/{wf}`")
        lines.append("")
    lines.append("## Lenses")
    lines.append("")
    for lens in lenses_for_repo(repo, stack):
        lines.append(f"- {lens}")
    lines.append("")
    lines.append("## Documentation & Change Log Expectations")
    lines.append("")
    lines.append("- Update repository docs for behavior or policy changes.")
    lines.append("- Update changelog/release notes for user-visible changes.")
    lines.append("- Include verification commands and outcomes in PR summary.")
    return "\n".join(lines) + "\n"


def merge_commands(make_cmds: dict, script_cmds: dict, stack: str):
    merged = dict(make_cmds)
    for k, v in script_cmds.items():
        if v and not merged.get(k):
            merged[k] = v

    if stack == "go":
        merged.setdefault("Test", "go test ./...")
        merged.setdefault("Lint", "golangci-lint run")
    if stack == "python":
        merged.setdefault("Lint", "ruff check .")
        merged.setdefault("Test", "pytest")
    return merged


def evaluate_agents_md(repo_dir: Path):
    agents_path = repo_dir / "AGENTS.md"
    if not agents_path.exists():
        return {
            "status": "missing",
            "recommendation": "Add AGENTS.md compatibility pointer to AGENT.md if your tooling reads AGENTS.md.",
        }

    content = agents_path.read_text(encoding="utf-8", errors="ignore")
    lower = content.lower()
    references_agent_md = "agent.md" in lower
    has_runtime_contract = "codex runtime guidance" in lower or "human approval gates" in lower

    if references_agent_md and (has_runtime_contract or "compatibility notice" in lower):
        return {
            "status": "compatible",
            "recommendation": "No action required.",
        }

    if references_agent_md:
        return {
            "status": "review-needed",
            "recommendation": "AGENTS.md references AGENT.md but should be reviewed for runtime guidance completeness.",
        }

    return {
        "status": "review-needed",
        "recommendation": "AGENTS.md exists but does not reference AGENT.md; consider adding a compatibility pointer.",
    }


def process_repo(owner: str, repo: str, workdir: Path, apply: bool):
    repo_dir, err = clone_repo(owner, repo, workdir)
    if err:
        return {
            "repo": repo,
            "accessible": False,
            "error": err,
        }

    stack = detect_stack(repo_dir)
    make_cmds = read_make_commands(repo_dir)
    _, script_cmds = read_package_commands(repo_dir)
    commands = merge_commands(make_cmds, script_cmds, stack)
    workflows = workflow_list(repo_dir)
    agents_md_eval = evaluate_agents_md(repo_dir)

    content = build_agent_md(repo, stack, commands, workflows)
    out = repo_dir / "AGENT.md"

    if apply:
        out.write_text(content, encoding="utf-8")

    missing = [k for k in ["Test", "Lint", "Build"] if not commands.get(k)]
    return {
        "repo": repo,
        "accessible": True,
        "path": str(repo_dir),
        "stack": stack,
        "workflows": workflows,
        "missing": missing,
        "agents_md_status": agents_md_eval["status"],
        "agents_md_recommendation": agents_md_eval["recommendation"],
        "applied": apply,
    }


def main():
    parser = argparse.ArgumentParser(description="Generate repo-specific AGENT.md files")
    parser.add_argument("--owner", default=OWNER_DEFAULT)
    parser.add_argument("--repos", nargs="*", default=DEFAULT_REPOS)
    parser.add_argument("--workdir", default="/tmp/asdev-agent-gen")
    parser.add_argument("--apply", action="store_true")
    args = parser.parse_args()

    workdir = Path(args.workdir)
    workdir.mkdir(parents=True, exist_ok=True)

    summaries = []
    for repo in args.repos:
        summary = process_repo(args.owner, repo, workdir, args.apply)
        summaries.append(summary)

    print(json.dumps(summaries, indent=2))


if __name__ == "__main__":
    main()
