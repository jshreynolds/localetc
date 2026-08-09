#!/usr/bin/env python3
"""Download the official Kdenlive manual EPUB and populate this skill's
local manual cache (resources/manual_cache/), mirroring the manual's own
page structure. Run once — the copilot skill checks the cache before it
checks this script needs re-running; delete resources/manual_cache/ (except
README.md) to force a rebuild.

stdlib only, by design: this only needs to run occasionally, so it isn't
worth a dependency.
"""
import re
import sys
import tempfile
import urllib.request
import zipfile
from html.parser import HTMLParser
from pathlib import Path

EPUB_URL = "https://docs.kdenlive.org/en/epub/KdenliveManual.epub"
SKILL_DIR = Path(__file__).resolve().parent.parent
CACHE_DIR = SKILL_DIR / "resources" / "manual_cache"
SKIP_DIRS = {"_images", "_static", "META-INF"}

HEADINGS = {"h1": "# ", "h2": "## ", "h3": "### ", "h4": "#### ", "h5": "##### ", "h6": "###### "}
SKIP_TAGS = {"script", "style", "head", "nav"}


class ManualParser(HTMLParser):
    """Extracts the Sphinx 'articleBody' content div and renders it as
    lightweight markdown (headings, lists, tables, kbd/code spans)."""

    def __init__(self):
        super().__init__(convert_charrefs=True)
        self.out = []
        self.skip_depth = 0
        self.in_main = 0
        self.main_depth = None
        self.depth = 0
        self.list_stack = []  # [ "ul"|"ol", counter ]
        self.kbd_depth = 0
        self.just_marker = False
        self.in_table = False
        self.row_cells = None
        self.table_rows = None
        self.cell_buf = None

    def handle_starttag(self, tag, attrs):
        self.depth += 1
        attrs = dict(attrs)
        if tag in SKIP_TAGS:
            self.skip_depth += 1
            return
        if self.skip_depth:
            return

        classes = attrs.get("class", "").split()
        if tag == "div" and "body" in classes and attrs.get("role") == "main":
            self.in_main += 1
            self.main_depth = self.depth
            return

        if not self.in_main:
            return

        was_marker, self.just_marker = self.just_marker, False

        if tag in HEADINGS:
            self.out.append("\n" + HEADINGS[tag])
        elif tag == "p":
            if not was_marker:
                self.out.append("\n")
        elif tag == "li":
            indent = "  " * max(0, len(self.list_stack) - 1)
            if self.list_stack and self.list_stack[-1][0] == "ol":
                self.list_stack[-1][1] += 1
                marker = f"{self.list_stack[-1][1]}. "
            else:
                marker = "- "
            self.out.append(f"\n{indent}{marker}")
            self.just_marker = True
        elif tag == "ul":
            self.list_stack.append(["ul", 0])
        elif tag == "ol":
            self.list_stack.append(["ol", 0])
        elif tag == "kbd":
            if self.kbd_depth == 0:
                self.out.append("`")
            self.kbd_depth += 1
        elif tag in ("code", "tt"):
            self.out.append("`")
        elif tag == "pre":
            self.out.append("\n```\n")
        elif tag in ("strong", "b"):
            self.out.append("**")
        elif tag in ("em", "i"):
            self.out.append("*")
        elif tag == "table":
            self.in_table = True
            self.table_rows = []
        elif tag == "tr" and self.in_table:
            self.row_cells = []
        elif tag in ("td", "th") and self.in_table:
            self.cell_buf = []
        elif tag == "img":
            alt = attrs.get("alt", "")
            if alt:
                self.out.append(f"\n[image: {alt}]\n")
        elif tag == "br":
            self.out.append("\n")

    def handle_endtag(self, tag):
        if tag in SKIP_TAGS:
            self.skip_depth = max(0, self.skip_depth - 1)
            self.depth -= 1
            return
        if self.skip_depth:
            self.depth -= 1
            return

        if self.in_main and self.depth == self.main_depth and tag == "div":
            self.in_main -= 1
            self.depth -= 1
            return

        if not self.in_main:
            self.depth -= 1
            return

        if tag in HEADINGS:
            self.out.append("\n")
        elif tag in ("ul", "ol"):
            if self.list_stack:
                self.list_stack.pop()
            self.out.append("\n")
        elif tag == "kbd":
            self.kbd_depth = max(0, self.kbd_depth - 1)
            if self.kbd_depth == 0:
                self.out.append("`")
        elif tag in ("code", "tt"):
            self.out.append("`")
        elif tag == "pre":
            self.out.append("\n```\n")
        elif tag in ("strong", "b"):
            self.out.append("**")
        elif tag in ("em", "i"):
            self.out.append("*")
        elif tag in ("td", "th") and self.in_table and self.cell_buf is not None:
            self.row_cells.append("".join(self.cell_buf).strip())
            self.cell_buf = None
        elif tag == "tr" and self.in_table and self.row_cells is not None:
            self.table_rows.append(self.row_cells)
            self.row_cells = None
        elif tag == "table" and self.in_table:
            self.in_table = False
            self.out.append(self._render_table(self.table_rows))
            self.table_rows = None

        self.depth -= 1

    def handle_data(self, data):
        if self.skip_depth or not self.in_main:
            return
        self.just_marker = False
        if self.cell_buf is not None:
            self.cell_buf.append(data)
        else:
            self.out.append(data)

    def _render_table(self, rows):
        if not rows:
            return ""
        header, *body = rows
        lines = ["\n", "| " + " | ".join(c.replace("|", "\\|") for c in header) + " |"]
        lines.append("| " + " | ".join("---" for _ in header) + " |")
        for r in body:
            lines.append("| " + " | ".join(c.replace("|", "\\|") for c in r) + " |")
        lines.append("\n")
        return "\n".join(lines)

    def get_markdown(self):
        text = "".join(self.out)
        for _ in range(5):  # collapse empty/adjacent backtick pairs from nested <kbd>
            text = re.sub(r"``", "", text)
        text = re.sub(r"[ \t]+", " ", text)
        text = re.sub(r" *\n *", "\n", text)
        text = re.sub(r"\n{3,}", "\n\n", text)
        return text.strip() + "\n"


def title_of(html: str) -> str:
    m = re.search(r"<title>(.*?)</title>", html, re.S)
    return re.sub(r"\s+", " ", m.group(1)).strip() if m else ""


def convert_page(src: Path, dst: Path):
    html = src.read_text(encoding="utf-8", errors="replace")
    parser = ManualParser()
    parser.feed(html)
    body = parser.get_markdown()
    title = title_of(html)
    dst.parent.mkdir(parents=True, exist_ok=True)
    with dst.open("w", encoding="utf-8") as f:
        if title and not body.startswith(f"# {title}\n"):
            f.write(f"# {title}\n\n")
        f.write(body)


def main():
    with tempfile.TemporaryDirectory() as tmp:
        tmp = Path(tmp)
        epub_path = tmp / "KdenliveManual.epub"
        print(f"downloading {EPUB_URL}", file=sys.stderr)
        urllib.request.urlretrieve(EPUB_URL, epub_path)

        extract_dir = tmp / "extracted"
        with zipfile.ZipFile(epub_path) as zf:
            zf.extractall(extract_dir)

        count = 0
        for src in sorted(extract_dir.rglob("*.xhtml")):
            rel = src.relative_to(extract_dir)
            if rel.parts and rel.parts[0] in SKIP_DIRS:
                continue
            convert_page(src, CACHE_DIR / rel.with_suffix(".md"))
            count += 1
        print(f"cached {count} manual pages -> {CACHE_DIR}", file=sys.stderr)


if __name__ == "__main__":
    main()
