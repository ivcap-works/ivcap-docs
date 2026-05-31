#!/usr/bin/env python3
"""
fetch_sdk.py  —  Pull narrative docs from SDK repos into the hub content tree.

For each SDK in the registry (or a single SDK if --sdk is given):
  1. Shallow-clone or update the repo into .cache/<slug>
  2. Copy the files/folders listed in pull_docs into content/sdk/<slug>/
  3. Inject frontmatter (sdk name, link to full API docs) into each page

Usage:
  python scripts/fetch_sdk.py --registry config/sdk-registry.json \
                               --output content/sdk \
                               --cache .cache \
                               [--sdk python]
"""

import argparse
import json
import os
import re
import shutil
import subprocess
import sys
from pathlib import Path


# ── Helpers ───────────────────────────────────────────────────────────────────

def run(cmd: list[str], cwd: Path | None = None, check: bool = True) -> subprocess.CompletedProcess:
    print(f"  $ {' '.join(cmd)}")
    return subprocess.run(cmd, cwd=cwd, check=check, capture_output=True, text=True)


def clone_or_update(repo: str, branch: str, cache_dir: Path) -> Path:
    """Shallow-clone a repo into cache_dir/<repo_slug>, or fetch latest if already cached."""
    slug = repo.replace("/", "__")
    dest = cache_dir / slug

    if dest.exists():
        print(f"  Updating cached clone: {dest}")
        run(["git", "fetch", "--depth=1", "origin", branch], cwd=dest)
        run(["git", "checkout", f"origin/{branch}"], cwd=dest)
    else:
        print(f"  Cloning {repo}@{branch} → {dest}")
        dest.mkdir(parents=True, exist_ok=True)
        run([
            "git", "clone",
            "--depth=1",
            "--branch", branch,
            f"https://github.com/{repo}.git",
            str(dest)
        ])
    return dest


def inject_frontmatter(path: Path, extra: dict) -> None:
    """Add or merge YAML frontmatter into a markdown file."""
    content = path.read_text(encoding="utf-8")
    fm_block = "\n".join(f"{k}: {v}" for k, v in extra.items())

    if content.startswith("---"):
        # Merge into existing frontmatter
        content = re.sub(
            r"^---\n(.*?)\n---",
            f"---\n\\1\n{fm_block}\n---",
            content,
            count=1,
            flags=re.DOTALL,
        )
    else:
        content = f"---\n{fm_block}\n---\n\n{content}"

    path.write_text(content, encoding="utf-8")


def append_api_ref_banner(path: Path, sdk_name: str, api_url: str) -> None:
    """Append a 'Full API reference' callout at the bottom of a page."""
    banner = (
        f"\n\n---\n\n"
        f"!!! info \"Full API Reference\"\n"
        f"    The complete {sdk_name} API reference (all classes, methods, and parameters) "
        f"is available in the [dedicated API docs]({api_url}).\n"
    )
    with path.open("a", encoding="utf-8") as f:
        f.write(banner)


def copy_path(src: Path, dest: Path) -> None:
    """Copy a file or directory tree from src to dest."""
    if src.is_dir():
        if dest.exists():
            shutil.rmtree(dest)
        shutil.copytree(src, dest)
        print(f"  Copied dir  {src} → {dest}")
    elif src.is_file():
        dest.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(src, dest)
        print(f"  Copied file {src} → {dest}")
    else:
        print(f"  WARNING: {src} not found in repo, skipping.", file=sys.stderr)


# ── Main ──────────────────────────────────────────────────────────────────────

def fetch_one(sdk: dict, output_dir: Path, cache_dir: Path) -> None:
    slug      = sdk["slug"]
    name      = sdk["name"]
    repo      = sdk["repo"]
    branch    = sdk.get("branch", "main")
    api_url   = sdk["github_pages_url"]
    pull_docs = sdk["pull_docs"]

    print(f"\n{'─'*60}")
    print(f"  SDK: {name}  ({repo}@{branch})")
    print(f"{'─'*60}")

    repo_path = clone_or_update(repo, branch, cache_dir)
    sdk_out   = output_dir / slug
    sdk_out.mkdir(parents=True, exist_ok=True)

    for item in pull_docs:
        src  = repo_path / item
        # Preserve directory structure under the SDK output folder
        dest = sdk_out / Path(item).relative_to(Path(item).parts[0]) \
               if "/" in item else sdk_out / Path(item).name
        copy_path(src, dest)

    # Post-process: inject metadata and API reference banners into all .md files
    for md_file in sdk_out.rglob("*.md"):
        inject_frontmatter(md_file, {
            "sdk":      slug,
            "sdk_name": f'"{name}"',
        })
        append_api_ref_banner(md_file, name, api_url)

    # Write a _meta.json for use by generate_nav.py
    meta = {
        "slug":             slug,
        "name":             name,
        "github_pages_url": api_url,
        "capabilities":     sdk.get("capabilities", []),
        "language":         sdk.get("language", ""),
        "pulled_files":     pull_docs,
    }
    (sdk_out / "_meta.json").write_text(json.dumps(meta, indent=2), encoding="utf-8")
    print(f"  ✓ {name} done → {sdk_out}")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--registry", required=True, help="Path to sdk-registry.json")
    parser.add_argument("--output",   required=True, help="Output directory for SDK content")
    parser.add_argument("--cache",    required=True, help="Directory for git clones")
    parser.add_argument("--sdk",      default=None,  help="Fetch a single SDK by slug")
    args = parser.parse_args()

    registry   = json.loads(Path(args.registry).read_text())
    output_dir = Path(args.output)
    cache_dir  = Path(args.cache)

    output_dir.mkdir(parents=True, exist_ok=True)
    cache_dir.mkdir(parents=True, exist_ok=True)

    sdks = [s for s in registry if s["slug"] == args.sdk] if args.sdk else registry

    if not sdks:
        print(f"ERROR: SDK '{args.sdk}' not found in registry.", file=sys.stderr)
        sys.exit(1)

    errors = []
    for sdk in sdks:
        try:
            fetch_one(sdk, output_dir, cache_dir)
        except Exception as e:
            print(f"\nERROR fetching {sdk['slug']}: {e}", file=sys.stderr)
            errors.append(sdk["slug"])

    if errors:
        print(f"\n{'─'*60}")
        print(f"FAILED SDKs: {', '.join(errors)}", file=sys.stderr)
        sys.exit(1)

    print(f"\n✓ All SDKs fetched successfully.")


if __name__ == "__main__":
    main()
