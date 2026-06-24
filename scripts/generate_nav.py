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
import os
import re
from collections import defaultdict
from pathlib import Path

import yaml  # pip install pyyaml


# ── YAML helpers for non-safe tag round-tripping ──────────────────────────────
# mkdocs.yml uses tags that yaml.safe_load rejects:
#   !!python/name:some.module.name   (e.g. for superfences)
#   !ENV [VAR, "default"]            (mkdocs env-var interpolation)
# We stash every occurrence as a quoted sentinel before safe_load, then restore
# the originals verbatim in the dumped output.

_NONSAFE_TAG_RE = re.compile(
    r"!!python/name:\S+"  # !!python/name:... tags
    r"|!ENV\s+\[[^\]]*\]"  # !ENV [VAR, "default"] form
    r"|!ENV\s+\S+"  # !ENV VAR plain form
)


def _load_template(path: Path) -> tuple[dict, list[str]]:
    """
    Load a mkdocs-style YAML template that may contain ``!!python/name:`` or
    ``!ENV`` tags that ``yaml.safe_load`` would reject.

    Each unique tag string is stashed, replaced with an innocuous quoted
    sentinel, parsed safely, then restored after dumping.

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

    safe_text = _NONSAFE_TAG_RE.sub(_stash, text)
    return yaml.safe_load(safe_text), tags


def _dump_config(config: dict, tags: list[str]) -> str:
    """Dump *config* to YAML and restore the original non-safe tags.

    PyYAML may emit the sentinel as a plain scalar (no surrounding quotes),
    single-quoted, or double-quoted depending on the value and context.
    We replace all three forms, most-specific (quoted) first.
    """
    text = yaml.dump(config, allow_unicode=True, sort_keys=False)
    for idx, tag in enumerate(tags):
        sentinel = f"__PYTAG_{idx}__"
        text = text.replace(f"'{sentinel}'", tag)  # single-quoted
        text = text.replace(f'"{sentinel}"', tag)  # double-quoted
        text = text.replace(sentinel, tag)  # bare / plain scalar
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
    Build nav entries for each SDK, grouping files by their immediate
    subdirectory so the left-nav stays two levels deep rather than showing
    every markdown file as a flat list:

      SDK name:
        Getting Started:          # subdirectory label
          - Installation: ...
          - Quick Start: ...
        Guides:
          - Authentication: ...
        Full API Reference ↗: https://...

    Files sitting directly in sdk_out (no subdirectory) are listed first.
    """
    nav = []
    for meta in load_meta(sdk_dir):
        slug = meta["slug"]
        name = meta["name"]
        api_url = meta["github_pages_url"]
        sdk_out = sdk_dir / slug

        top_files: list = []  # .md files directly in sdk_out
        sub_dirs: dict = {}  # {dir_path: [nav_entries]}

        for md_file in sorted(sdk_out.rglob("*.md")):
            if md_file.name.startswith("_"):
                continue
            rel = relative_to_docs(md_file, docs_root)
            label = md_file.stem.replace("-", " ").replace("_", " ").title()

            if md_file.parent == sdk_out:
                top_files.append({label: rel})
            else:
                # Group by the immediate parent directory only
                dir_key = md_file.parent
                sub_dirs.setdefault(dir_key, []).append({label: rel})

        entries: list = list(top_files)
        for dir_path in sorted(sub_dirs.keys()):
            dir_label = dir_path.name.replace("-", " ").replace("_", " ").title()
            entries.append({dir_label: sub_dirs[dir_path]})

        entries.append({"Full API Reference ↗": api_url})
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

    # Inject the deployed git commit SHA so the landing-page badge can display it.
    # The value comes from DOCS_GIT_COMMIT (set by the CI "Get short commit SHA" step).
    # Falls back to "" (badge hidden) when building locally.
    git_commit = os.environ.get("DOCS_GIT_COMMIT", "")
    config.setdefault("extra", {})["git_commit"] = git_commit

    output.write_text(_dump_config(config, python_tags))
    print(f"✓ mkdocs.yml written to {output}")
    print(f"  SDKs:         {len(sdk_nav)}")
    print(f"  Capabilities: {len(capabilities_nav)}")
    print(f"  Examples:     {len(examples_nav)}")


if __name__ == "__main__":
    main()
