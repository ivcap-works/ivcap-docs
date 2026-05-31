#!/usr/bin/env python3
"""
generate_nav.py  —  Build mkdocs.yml from fetched SDK and example content.

Reads the fetched _meta.json files and the mkdocs-template.yml, then:
  - Inserts SDK narrative doc pages into the nav
  - Groups examples under their capabilities
  - Writes the final mkdocs.yml

Usage:
  python scripts/generate_nav.py \
      --sdk-dir content/sdk \
      --examples-dir content/examples \
      --sdk-registry config/sdk-registry.json \
      --example-registry config/example-registry.json \
      --template config/mkdocs-template.yml \
      --output mkdocs.yml
"""

import argparse
import json
import re
from collections import defaultdict
from pathlib import Path

import yaml  # pip install pyyaml


# ── YAML helpers for !!python/name: tag round-tripping ────────────────────────

_PYTHON_TAG_RE = re.compile(r"!!python/name:\S+")


def _load_template(path: Path) -> tuple[dict, list[str]]:
    """
    Load a mkdocs-style YAML template that may contain ``!!python/name:`` tags.

    ``yaml.safe_load`` rejects those tags, so we stash each unique tag string,
    replace it with an innocuous quoted sentinel, parse safely, then restore the
    originals after dumping.

    Returns (config_dict, ordered_tag_list).
    """
    text = path.read_text()
    tags: list[str] = []

    def _stash(m: re.Match) -> str:
        tag = m.group(0)
        if tag not in tags:
            tags.append(tag)
        idx = tags.index(tag)
        return f'"__PYTAG_{idx}__"'

    safe_text = _PYTHON_TAG_RE.sub(_stash, text)
    return yaml.safe_load(safe_text), tags


def _dump_config(config: dict, tags: list[str]) -> str:
    """Dump *config* to YAML and restore the original ``!!python/name:`` tags."""
    text = yaml.dump(config, allow_unicode=True, sort_keys=False)
    for idx, tag in enumerate(tags):
        text = text.replace(f"'__PYTAG_{idx}__'", tag)
        text = text.replace(f'"__PYTAG_{idx}__"', tag)
    return text


def load_meta(directory: Path, glob: str = "*/_meta.json") -> list[dict]:
    metas = []
    for meta_file in sorted(directory.glob(glob)):
        try:
            metas.append(json.loads(meta_file.read_text()))
        except Exception as e:
            print(f"WARNING: Could not read {meta_file}: {e}")
    return metas


def relative_to_docs(path: Path, docs_root: Path) -> str:
    """Convert an absolute path to a docs-relative path for mkdocs nav."""
    return str(path.relative_to(docs_root)).replace("\\", "/")


def build_sdk_nav(sdk_dir: Path, docs_root: Path) -> list:
    """
    Build nav entries for each SDK:
      - SDK name
        - Getting Started: sdk/python/getting-started.md
        - Guides:
          - ...
        - Full API Reference: https://...
    """
    nav = []
    for meta in load_meta(sdk_dir):
        slug = meta["slug"]
        name = meta["name"]
        api_url = meta["github_pages_url"]
        sdk_out = sdk_dir / slug

        entries = []
        for md_file in sorted(sdk_out.rglob("*.md")):
            if md_file.name.startswith("_"):
                continue
            rel = relative_to_docs(md_file, docs_root)
            # Use the filename (without .md) as the label, title-cased
            label = md_file.stem.replace("-", " ").replace("_", " ").title()
            entries.append({label: rel})

        entries.append({f"Full API Reference ↗": api_url})
        nav.append({name: entries})

    return nav


def build_examples_nav(examples_dir: Path, docs_root: Path) -> list:
    """
    Build a flat nav of all examples:
      - Examples:
        - Example Name: examples/slug/index.md
    """
    entries = []
    for meta in load_meta(examples_dir):
        slug = meta["slug"]
        name = meta["name"]
        index = examples_dir / slug / "index.md"
        if index.exists():
            entries.append({name: relative_to_docs(index, docs_root)})
    return entries


def build_capabilities_nav(
    examples_dir: Path, docs_root: Path, capabilities_dir: Path
) -> list:
    """
    Group examples by capability, one nav entry per capability.
    Also links to the hand-authored capability overview page if it exists.
    """
    cap_examples: dict[str, list] = defaultdict(list)

    for meta in load_meta(examples_dir):
        slug = meta["slug"]
        name = meta["name"]
        index = examples_dir / slug / "index.md"
        if not index.exists():
            continue
        rel = relative_to_docs(index, docs_root)
        for cap in meta.get("capabilities", []):
            cap_examples[cap].append({name: rel})

    nav = []
    for cap in sorted(cap_examples.keys()):
        cap_label = cap.replace("-", " ").title()
        overview = capabilities_dir / f"{cap}.md"
        cap_entries = []
        if overview.exists():
            cap_entries.append({"Overview": relative_to_docs(overview, docs_root)})
        cap_entries.extend(cap_examples[cap])
        nav.append({cap_label: cap_entries})

    return nav


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--sdk-dir", required=True)
    parser.add_argument("--examples-dir", required=True)
    parser.add_argument("--sdk-registry", required=True)
    parser.add_argument("--example-registry", required=True)
    parser.add_argument("--template", required=True, help="mkdocs-template.yml")
    parser.add_argument("--output", required=True, help="Output mkdocs.yml path")
    args = parser.parse_args()

    sdk_dir = Path(args.sdk_dir)
    examples_dir = Path(args.examples_dir)
    template = Path(args.template)
    output = Path(args.output)

    # The docs root is always docs/ relative to the project root (mkdocs convention)
    docs_root = Path("docs")
    capabilities_dir = docs_root / "capabilities"

    # Load template (preserving !!python/name: tags that safe_load would reject)
    config, python_tags = _load_template(template)

    # Build nav sections
    sdk_nav = build_sdk_nav(sdk_dir, docs_root)
    examples_nav = build_examples_nav(examples_dir, docs_root)
    capabilities_nav = build_capabilities_nav(examples_dir, docs_root, capabilities_dir)

    # Merge into nav — template uses __SDK__, __CAPABILITIES__, __EXAMPLES__ placeholders.
    # Placeholders may be nested inside section dicts (e.g. {SDKs: [__SDK__]}),
    # so we recurse into dict values that are lists.
    def replace_placeholder(nav: list, placeholder: str, replacement: list) -> list:
        result = []
        for item in nav:
            if item == placeholder:
                result.extend(replacement)
            elif isinstance(item, dict):
                new_item = {}
                for k, v in item.items():
                    if isinstance(v, list):
                        new_item[k] = replace_placeholder(v, placeholder, replacement)
                    else:
                        new_item[k] = v
                result.append(new_item)
            else:
                result.append(item)
        return result

    config["nav"] = replace_placeholder(config.get("nav", []), "__SDK__", sdk_nav)
    config["nav"] = replace_placeholder(
        config["nav"], "__CAPABILITIES__", capabilities_nav
    )
    config["nav"] = replace_placeholder(config["nav"], "__EXAMPLES__", examples_nav)

    output.write_text(_dump_config(config, python_tags))
    print(f"✓ mkdocs.yml written to {output}")
    print(f"  SDKs:         {len(sdk_nav)}")
    print(f"  Capabilities: {len(capabilities_nav)}")
    print(f"  Examples:     {len(examples_nav)}")


if __name__ == "__main__":
    main()
