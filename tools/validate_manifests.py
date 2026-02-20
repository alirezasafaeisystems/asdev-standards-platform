#!/usr/bin/env python3
import argparse
import json
from pathlib import Path

import yaml
from jsonschema import Draft202012Validator


def load_yaml(path: Path):
    with path.open("r", encoding="utf-8") as f:
        return yaml.safe_load(f)


def load_json(path: Path):
    with path.open("r", encoding="utf-8") as f:
        return json.load(f)


def validate_pair(schema_path: Path, manifest_path: Path) -> None:
    schema = load_json(schema_path)
    manifest = load_yaml(manifest_path)
    validator = Draft202012Validator(schema)
    errors = sorted(validator.iter_errors(manifest), key=lambda e: e.path)
    if errors:
        print(f"Validation failed: {manifest_path} against {schema_path}")
        for err in errors:
            loc = ".".join(str(x) for x in err.path) or "<root>"
            print(f"- {loc}: {err.message}")
        raise SystemExit(1)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--schema",
        action="append",
        default=[],
        help="Schema path (must be paired with --manifest in same order)",
    )
    parser.add_argument(
        "--manifest",
        action="append",
        default=[],
        help="Manifest path (must be paired with --schema in same order)",
    )
    args = parser.parse_args()

    if len(args.schema) != len(args.manifest) or not args.schema:
        print("Provide equal number of --schema and --manifest arguments")
        raise SystemExit(2)

    for s, m in zip(args.schema, args.manifest):
        validate_pair(Path(s), Path(m))


if __name__ == "__main__":
    main()
