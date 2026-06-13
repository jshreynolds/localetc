#!/usr/bin/env python3
"""Find source material for a bi-weekly Chatlayer briefing.

Prints a manifest of file paths (dailies + meeting summary.md files) within a
date window, grouped by the briefing's hierarchy. The script does not read
file contents — the caller reads the files it cares about via its own tools.

Hierarchy:
    corporate / sinch
    conversations (agentic orchestration domain)
    product (chatlayer / engage)
    teams (flow engine, intelligence, platform and integrations, ai agents)

Plus a dailies section.

Usage:
    fetch_content.py <start-date> <end-date>

Dates are YYYY-MM-DD and inclusive on both ends. File enumeration uses
ripgrep (`rg --files`) for speed; date filtering is done by parsing the
date prefix from each path.
"""

from __future__ import annotations

import argparse
import os
import re
import subprocess
import sys
from pathlib import Path
from typing import Iterable


# Hierarchy of sources. Each entry is (section label, [vault-relative roots]).
# Missing roots are skipped silently so the script keeps working as the
# vault grows or reshuffles.
SECTIONS: list[tuple[str, list[str]]] = [
    (
        "CORPORATE / SINCH",
        [
            "areas/colleagues/lars",
            "areas/engineering_management",
            "areas/customers",
            "areas/intramural_teams",
            "areas/saas_suppliers",
        ],
    ),
    (
        "CONVERSATIONS (AGENTIC ORCHESTRATION DOMAIN)",
        ["areas/agentic_conversation_domain"],
    ),
    (
        "PRODUCT (CHATLAYER / ENGAGE)",
        ["areas/chatlayer_product_area"],
    ),
    ("TEAM: FLOW ENGINE", ["areas/flow_engine_team"]),
    ("TEAM: INTELLIGENCE", ["areas/intelligence_team"]),
    ("TEAM: PLATFORM AND INTEGRATIONS", ["areas/platform_and_integrations_team"]),
    ("TEAM: AI AGENTS", ["areas/ai_agents_team"]),
]

DATE_PREFIX_RE = re.compile(r"^(\d{4}-\d{2}-\d{2})")


def find_vault() -> Path:
    candidate = Path(os.environ.get("VAULT", os.getcwd())).resolve()
    if not (candidate / "areas").is_dir() or not (candidate / "dailies").is_dir():
        sys.exit(
            f"error: {candidate} does not look like the worksidian vault "
            "(missing areas/ or dailies/). Run from the vault root or set $VAULT."
        )
    return candidate


def rg_files(root: Path, *, glob: str | None = None) -> list[Path]:
    """List files under `root` using ripgrep. Empty list if root missing or no matches."""
    if not root.exists():
        return []
    cmd = ["rg", "--files", "--hidden", "--no-ignore-vcs"]
    if glob:
        cmd += ["--glob", glob]
    cmd.append(str(root))
    try:
        out = subprocess.check_output(cmd, text=True)
    except subprocess.CalledProcessError as e:
        if e.returncode == 1:
            return []
        raise
    return [Path(line) for line in out.splitlines() if line]


def in_window(date_str: str, start: str, end: str) -> bool:
    return start <= date_str <= end


def collect_dailies(vault: Path, start: str, end: str) -> list[tuple[str, Path]]:
    results: list[tuple[str, Path]] = []
    for path in rg_files(vault / "dailies", glob="*.md"):
        name = path.name
        if not (
            name.endswith("-debrief.md")
            or name.endswith("-daily-brief.md")
            or name.endswith("-briefing.md")
        ):
            continue
        m = DATE_PREFIX_RE.match(name)
        if not m:
            continue
        if in_window(m.group(1), start, end):
            results.append((m.group(1), path))
    return sorted(results)


def collect_meeting_summaries(
    vault: Path, roots: Iterable[str], start: str, end: str
) -> list[tuple[str, Path]]:
    """summary.md files under YYYY-MM-DD_*-named meeting folders in window."""
    results: list[tuple[str, Path]] = []
    for root_rel in roots:
        root = vault / root_rel
        if not root.is_dir():
            continue
        for summary in rg_files(root, glob="summary.md"):
            if "minutes" not in summary.parts:
                continue
            folder = summary.parent.name
            m = DATE_PREFIX_RE.match(folder)
            if not m:
                continue
            if in_window(m.group(1), start, end):
                results.append((m.group(1), summary))
    return sorted(results)


def emit_group(label: str, entries: list[tuple[str, Path]], vault: Path) -> None:
    print()
    print(f"## {label}")
    if not entries:
        print("_(none in window)_")
        return
    for date, path in entries:
        rel = path.relative_to(vault) if path.is_absolute() else path
        print(f"{date}  {rel}")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("start", help="window start date YYYY-MM-DD (inclusive)")
    parser.add_argument("end", help="window end date YYYY-MM-DD (inclusive)")
    args = parser.parse_args()

    for label, value in (("start", args.start), ("end", args.end)):
        if not re.fullmatch(r"\d{4}-\d{2}-\d{2}", value):
            sys.exit(f"error: {label} must be YYYY-MM-DD, got {value!r}")
    if args.start > args.end:
        sys.exit(f"error: start ({args.start}) is after end ({args.end})")

    vault = find_vault()

    print(f"# Bi-weekly Chatlayer briefing — source manifest")
    print(f"# Window: {args.start} to {args.end} (inclusive)")
    print(f"# Vault:  {vault}")

    emit_group("DAILIES (debriefs and briefings)",
               collect_dailies(vault, args.start, args.end), vault)

    for label, roots in SECTIONS:
        emit_group(label,
                   collect_meeting_summaries(vault, roots, args.start, args.end),
                   vault)

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
