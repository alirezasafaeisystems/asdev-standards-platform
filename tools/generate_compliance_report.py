#!/usr/bin/env python3
import argparse
import csv
import json
import re
from datetime import datetime, timezone
from pathlib import Path

RESULT_RE = re.compile(r"result=(success|failed)")
SKIP_RE = re.compile(r"skipping e2e", re.IGNORECASE)


def detect_status(path: Path) -> str:
    content = path.read_text(encoding="utf-8", errors="ignore")
    if SKIP_RE.search(content):
        return "skipped"

    statuses = RESULT_RE.findall(content)
    if not statuses:
        return "unknown"
    return statuses[-1]


def load_checks(logs_dir: Path):
    checks = []
    for path in sorted(logs_dir.glob("verify.*.log")):
        name = path.name.replace("verify.", "").replace(".log", "")
        checks.append(
            {
                "name": name,
                "status": detect_status(path),
                "source": str(path),
            }
        )
    if not checks:
        for name in ["lint", "typecheck", "test", "e2e", "build", "security-audit", "coverage"]:
            checks.append({"name": name, "status": "unknown", "source": "logs/unavailable"})
    return checks


def score(checks) -> float:
    if not checks:
        return 0.0
    ok = sum(1 for c in checks if c["status"] in {"success", "skipped"})
    return round((ok / len(checks)) * 100, 2)


def write_json(path: Path, payload: dict) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def write_csv(path: Path, checks) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=["check", "status", "source"])
        writer.writeheader()
        for c in checks:
            writer.writerow({"check": c["name"], "status": c["status"], "source": c["source"]})


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--repo", default="asdev-standards-platform")
    parser.add_argument("--logs-dir", default="logs")
    parser.add_argument("--output-json", required=True)
    parser.add_argument("--output-csv", required=True)
    args = parser.parse_args()

    logs_dir = Path(args.logs_dir)
    checks = load_checks(logs_dir)

    payload = {
        "generated_at_utc": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        "repo": args.repo,
        "compliance_score": score(checks),
        "checks": checks,
    }

    write_json(Path(args.output_json), payload)
    write_csv(Path(args.output_csv), checks)


if __name__ == "__main__":
    main()
