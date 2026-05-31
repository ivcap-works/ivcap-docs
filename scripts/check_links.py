#!/usr/bin/env python3
"""
check_links.py  —  Check for broken internal links in the built mkdocs site.

Scans all HTML files under --site-dir, collects href links, and reports
any that point to missing local pages.

External links (http/https) are checked with a HEAD request (optional, slow).

Usage:
  python scripts/check_links.py --site-dir site [--check-external]
"""

import argparse
import sys
from pathlib import Path
from html.parser import HTMLParser
from urllib.parse import urljoin, urlparse
from collections import defaultdict


class LinkExtractor(HTMLParser):
    def __init__(self):
        super().__init__()
        self.links: list[str] = []

    def handle_starttag(self, tag, attrs):
        if tag == "a":
            for name, value in attrs:
                if name == "href" and value:
                    self.links.append(value)


def collect_pages(site_dir: Path) -> set[str]:
    """Return all relative paths of HTML pages in the site."""
    pages = set()
    for html_file in site_dir.rglob("*.html"):
        rel = str(html_file.relative_to(site_dir)).replace("\\", "/")
        pages.add(rel)
        # mkdocs generates /foo/index.html but links use /foo/
        if rel.endswith("/index.html"):
            pages.add(rel[: -len("index.html")])
    return pages


def check_links(site_dir: Path, check_external: bool = False) -> dict[str, list[str]]:
    """
    Returns a dict of {source_page: [broken_link, ...]}
    """
    pages    = collect_pages(site_dir)
    broken   = defaultdict(list)

    for html_file in site_dir.rglob("*.html"):
        source = str(html_file.relative_to(site_dir)).replace("\\", "/")
        text   = html_file.read_text(encoding="utf-8", errors="replace")

        extractor = LinkExtractor()
        extractor.feed(text)

        for href in extractor.links:
            # Skip anchors, mailto, javascript
            if not href or href.startswith(("#", "mailto:", "javascript:")):
                continue

            parsed = urlparse(href)

            if parsed.scheme in ("http", "https"):
                if check_external:
                    try:
                        import urllib.request
                        req = urllib.request.Request(href, method="HEAD",
                              headers={"User-Agent": "hub-link-checker"})
                        urllib.request.urlopen(req, timeout=5)
                    except Exception:
                        broken[source].append(href)
                continue

            # Internal link: resolve relative to source page directory
            source_dir = source.rsplit("/", 1)[0] if "/" in source else ""
            resolved   = urljoin(source_dir + "/", parsed.path).lstrip("/")

            # Normalise: foo/bar → foo/bar/index.html or foo/bar.html
            candidates = {
                resolved,
                resolved.rstrip("/") + "/index.html",
                resolved.rstrip("/") + ".html",
                resolved + "index.html",
            }
            if not candidates.intersection(pages):
                broken[source].append(href)

    return dict(broken)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--site-dir",       required=True, help="Path to built site/ directory")
    parser.add_argument("--check-external", action="store_true", help="Also check external URLs (slow)")
    args = parser.parse_args()

    site_dir = Path(args.site_dir)
    if not site_dir.exists():
        print(f"ERROR: site directory not found: {site_dir}", file=sys.stderr)
        sys.exit(1)

    print(f"Checking links in {site_dir} ...")
    broken = check_links(site_dir, check_external=args.check_external)

    if not broken:
        print("✓ No broken links found.")
        return

    total = sum(len(v) for v in broken.values())
    print(f"\n⚠  {total} broken link(s) in {len(broken)} page(s):\n", file=sys.stderr)
    for page, links in sorted(broken.items()):
        print(f"  {page}", file=sys.stderr)
        for link in links:
            print(f"    → {link}", file=sys.stderr)

    sys.exit(1)


if __name__ == "__main__":
    main()
