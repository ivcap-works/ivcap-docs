#!/usr/bin/env python3
"""
validate_registry.py  —  Validate a registry JSON file against a JSON schema.

Usage:
  python scripts/validate_registry.py \
      --registry config/sdk-registry.json \
      --schema   config/sdk-schema.json
"""

import argparse
import json
import sys
from pathlib import Path


def validate(registry_path: Path, schema_path: Path) -> list[str]:
    """Return a list of error messages (empty = valid)."""
    try:
        import jsonschema
    except ImportError:
        print("ERROR: jsonschema not installed. Run: pip install jsonschema", file=sys.stderr)
        sys.exit(1)

    registry = json.loads(registry_path.read_text())
    schema   = json.loads(schema_path.read_text())

    errors = []
    validator = jsonschema.Draft7Validator(schema)
    for i, item in enumerate(registry):
        for error in validator.iter_errors(item):
            errors.append(f"  [{i}] {' → '.join(str(p) for p in error.path)}: {error.message}")

    # Additional cross-entry checks
    slugs = [item.get("slug") for item in registry]
    seen  = set()
    for slug in slugs:
        if slug in seen:
            errors.append(f"  Duplicate slug: '{slug}'")
        seen.add(slug)

    return errors


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--registry", required=True)
    parser.add_argument("--schema",   required=True)
    args = parser.parse_args()

    registry_path = Path(args.registry)
    schema_path   = Path(args.schema)

    if not registry_path.exists():
        print(f"ERROR: Registry not found: {registry_path}", file=sys.stderr)
        sys.exit(1)
    if not schema_path.exists():
        print(f"ERROR: Schema not found: {schema_path}", file=sys.stderr)
        sys.exit(1)

    errors = validate(registry_path, schema_path)

    if errors:
        print(f"VALIDATION FAILED: {registry_path}", file=sys.stderr)
        for e in errors:
            print(e, file=sys.stderr)
        sys.exit(1)
    else:
        print(f"  ✓ {registry_path} is valid.")


if __name__ == "__main__":
    main()
