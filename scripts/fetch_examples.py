#!/usr/bin/env python3
"""
fetch_examples.py  —  Pull README and key source files from example repos.

For each example in the registry (or a single one if --example is given):
  1. Shallow-clone or update the repo into .cache/<slug>
  2. Copy pull_files into content/examples/<slug>/
  3. Generate a structured index card (index.md) for the capability pages

Usage:
  python scripts/fetch_examples.py --registry config/example-registry.json \
                                    --output content/examples \
                                    --cache .cache \
                                    [--example etl-pipeline-python]
"""

import argparse
import json
import subprocess
import sys
import textwrap
from pathlib import Path


DIFFICULTY_LABEL = {
    "beginner":     "🟢 Beginner",
    "intermediate": "🟡 Intermediate",
    "advanced":     "🔴 Advanced",
}

LANGUAGE_LABEL = {
    "python":     "Python",
    "r":          "R",
    "javascript": "JavaScript",
}


# ── Helpers ───────────────────────────────────────────────────────────────────

def run(cmd: list[str], cwd: Path | None = None) -> subprocess.CompletedProcess:
    print(f"  $ {' '.join(cmd)}")
    return subprocess.run(cmd, cwd=cwd, check=True, capture_output=True, text=True)


def clone_or_update(repo: str, branch: str, cache_dir: Path) -> Path:
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
            "git", "clone", "--depth=1", "--branch", branch,
            f"https://github.com/{repo}.git", str(dest)
        ])
    return dest


def get_last_commit_date(repo_path: Path) -> str:
    try:
        result = subprocess.run(
            ["git", "log", "-1", "--format=%as"],
            cwd=repo_path, capture_output=True, text=True, check=True
        )
        return result.stdout.strip()
    except Exception:
        return "unknown"


def get_github_stars(repo: str) -> int | None:
    """Try to fetch star count via GitHub API (no auth → 60 req/hr limit)."""
    try:
        import urllib.request, json as _json
        url = f"https://api.github.com/repos/{repo}"
        req = urllib.request.Request(url, headers={"User-Agent": "hub-fetch-script"})
        with urllib.request.urlopen(req, timeout=5) as r:
            data = _json.loads(r.read())
            return data.get("stargazers_count")
    except Exception:
        return None


def make_code_snippet(file_path: Path, language: str) -> str:
    """Wrap file content in a fenced code block."""
    ext_to_lang = {
        ".py": "python", ".r": "r", ".R": "r",
        ".js": "javascript", ".ts": "typescript",
    }
    lang = ext_to_lang.get(file_path.suffix, language)
    content = file_path.read_text(encoding="utf-8", errors="replace")
    # Trim very long files to avoid bloating the hub page
    lines = content.splitlines()
    if len(lines) > 80:
        content = "\n".join(lines[:80]) + f"\n\n# ... ({len(lines) - 80} more lines — see full repo)"
    return f"```{lang}\n{content}\n```"


def generate_index_card(example: dict, out_dir: Path, last_updated: str, stars: int | None) -> None:
    """
    Write an index.md for this example — used both as a standalone page
    and as a fragment included by capability pages.
    """
    slug        = example["slug"]
    name        = example["name"]
    repo        = example["repo"]
    difficulty  = example.get("difficulty", "beginner")
    sdks        = example.get("sdks", [])
    capabilities = example.get("capabilities", [])

    sdk_badges = " · ".join(f"`{s}`" for s in sdks)
    cap_tags   = " ".join(f"[{c}](../../capabilities/{c}.md)" for c in capabilities)
    diff_label = DIFFICULTY_LABEL.get(difficulty, difficulty)
    star_str   = f" · ⭐ {stars}" if stars is not None else ""

    # Read the repo README if it was pulled
    readme_path = out_dir / "README.md"
    readme_body = ""
    if readme_path.exists():
        raw = readme_path.read_text(encoding="utf-8")
        # Strip the first H1 (we use `name` as the page title)
        raw = raw.lstrip()
        if raw.startswith("# "):
            raw = "\n".join(raw.splitlines()[1:]).lstrip()
        readme_body = raw

    # Code snippets for non-README pulled files
    snippet_sections = []
    for pull_file in example.get("pull_files", []):
        fpath = out_dir / Path(pull_file).name
        if fpath.exists() and fpath.suffix in {".py", ".r", ".R", ".js", ".ts"}:
            snippet_sections.append(
                f"### `{pull_file}`\n\n{make_code_snippet(fpath, sdks[0] if sdks else '')}"
            )

    snippets_md = "\n\n".join(snippet_sections)

    index_md = textwrap.dedent(f"""\
        ---
        title: "{name}"
        example_slug: {slug}
        capabilities: [{", ".join(capabilities)}]
        sdks: [{", ".join(sdks)}]
        difficulty: {difficulty}
        last_updated: {last_updated}
        ---

        # {name}

        **Difficulty:** {diff_label}  ·  **SDK:** {sdk_badges}{star_str}  ·  **Updated:** {last_updated}

        **Capabilities demonstrated:** {cap_tags}

        [:material-github: View full repo on GitHub](https://github.com/{repo}){{ .md-button }}

        ---

        {readme_body}

        {"## Code" if snippet_sections else ""}

        {snippets_md}
    """)

    (out_dir / "index.md").write_text(index_md, encoding="utf-8")


# ── Main ──────────────────────────────────────────────────────────────────────

def fetch_one(example: dict, output_dir: Path, cache_dir: Path) -> None:
    slug       = example["slug"]
    repo       = example["repo"]
    branch     = example.get("branch", "main")
    pull_files = example.get("pull_files", ["README.md"])

    print(f"\n{'─'*60}")
    print(f"  Example: {example['name']}  ({repo}@{branch})")
    print(f"{'─'*60}")

    repo_path = clone_or_update(repo, branch, cache_dir)
    ex_out    = output_dir / slug
    ex_out.mkdir(parents=True, exist_ok=True)

    for item in pull_files:
        src  = repo_path / item
        dest = ex_out / Path(item).name
        if src.exists():
            import shutil
            shutil.copy2(src, dest)
            print(f"  Copied {src} → {dest}")
        else:
            print(f"  WARNING: {src} not found, skipping.", file=sys.stderr)

    last_updated = get_last_commit_date(repo_path)
    stars        = get_github_stars(repo)

    generate_index_card(example, ex_out, last_updated, stars)

    # Persist metadata for nav generation
    meta = dict(example, last_updated=last_updated, stars=stars)
    (ex_out / "_meta.json").write_text(json.dumps(meta, indent=2), encoding="utf-8")
    print(f"  ✓ {slug} done → {ex_out}")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--registry", required=True)
    parser.add_argument("--output",   required=True)
    parser.add_argument("--cache",    required=True)
    parser.add_argument("--example",  default=None, help="Fetch a single example by slug")
    args = parser.parse_args()

    registry   = json.loads(Path(args.registry).read_text())
    output_dir = Path(args.output)
    cache_dir  = Path(args.cache)

    output_dir.mkdir(parents=True, exist_ok=True)
    cache_dir.mkdir(parents=True, exist_ok=True)

    examples = [e for e in registry if e["slug"] == args.example] if args.example else registry

    if not examples:
        print(f"ERROR: Example '{args.example}' not found in registry.", file=sys.stderr)
        sys.exit(1)

    errors = []
    for ex in examples:
        try:
            fetch_one(ex, output_dir, cache_dir)
        except Exception as e:
            print(f"\nERROR fetching {ex['slug']}: {e}", file=sys.stderr)
            errors.append(ex["slug"])

    if errors:
        print(f"\nFAILED: {', '.join(errors)}", file=sys.stderr)
        sys.exit(1)

    print(f"\n✓ All examples fetched successfully.")


if __name__ == "__main__":
    main()
