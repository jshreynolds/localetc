#!/usr/bin/env python3
"""Validate that every skill carries parseable frontmatter.

Was a heredoc inside run-checks.sh, which meant the repo's own check code was
the only python in the repo that `py_compile` never saw and no test could
reach. As a module it is covered by both, like everything else.

The rules live in `frontmatter_problems`, which takes text rather than a path,
so they can be tested without a fixture tree on disk.

Usage: check_skills.py [SKILLS_ROOT]   (default: ai/skills, relative to cwd)
"""

from __future__ import annotations

import sys
from pathlib import Path

SKILLS_ROOT = Path("ai/skills")

# Substring match on "name:" / "description:", i.e. the frontmatter is scanned,
# not parsed. Deliberate: a real YAML parse would mean a dependency, and the
# question being asked here is only "did someone forget a key".
REQUIRED_KEYS = ("name", "description")


def frontmatter_problems(text: str, label: str) -> list[str]:
    """Complaints about one SKILL.md. An empty list means it is fine."""
    if not text.startswith("---\n"):
        return [f"{label}: missing frontmatter"]
    end = text.find("\n---", 4)
    if end == -1:
        return [f"{label}: unclosed frontmatter"]
    frontmatter = text[4:end]
    return [
        f"{label}: missing {key}:"
        for key in REQUIRED_KEYS
        if f"{key}:" not in frontmatter
    ]


def check(root: Path = SKILLS_ROOT) -> tuple[int, list[str]]:
    """Return (number of skills seen, problems found across all of them)."""
    skills = sorted(root.glob("*/SKILL.md"))
    problems = []
    for path in skills:
        problems += frontmatter_problems(path.read_text(encoding="utf-8"), str(path))
    return len(skills), problems


def main(argv: list[str]) -> int:
    root = Path(argv[1]) if len(argv) > 1 else SKILLS_ROOT
    found, problems = check(root)
    print(f"    {found} SKILL.md files")

    # Same floor as run-checks.sh's _require_found: a check that discovered
    # nothing is a broken check, not a passing one.
    if found == 0:
        print(f"error: no SKILL.md files found under {root}", file=sys.stderr)
        return 1
    if problems:
        print("\n".join(problems), file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
