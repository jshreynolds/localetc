#!/usr/bin/env python3
"""ingest-meetings — phase 2: file staged meetings into the vault.

Matching is deterministic: an inferred attendee against a live
colleague/direct-report/domain-staff folder name, or a title word against a
live project/area folder name. Nothing here guesses beyond exact or
underscore-prefixed slug matches — see AGENTS_meetings.md for the
destination table this mirrors.

Usage:
  classify.py plan [--vault PATH] [--staging PATH]      # prints JSON plan
  classify.py apply [--vault PATH] < plan.json           # applies it
"""

import argparse
import json
import re
import shutil
import sys
from pathlib import Path

from meeting_frontmatter import (
    append_tags,
    extract_field,
    extract_int_field,
    extract_title,
    read_list_field,
    slugify,
)

SKIP_DIRS = {".obsidian", ".trash", ".git"}
AREA_EXCLUDE = {"colleagues", "people_management"}
WORD = re.compile(r"[a-z0-9]+")

# The vault owner attends every meeting, so their own first name would
# otherwise prefix-match unrelated colleague slugs (e.g. "josh" -> "josh_barwise").
OWNER_ALIASES = {"josh", "joshua"}

# Common short words that appear inside underscored slugs (e.g. "migrate_addresses_to_remailer")
# but carry no classification signal on their own.
STOPWORDS = {"a", "an", "the", "to", "of", "in", "on", "and", "or", "for", "with"}


def discover_candidates(vault_root):
    vault_root = Path(vault_root)

    def slugs(rel_path, exclude=frozenset()):
        base = vault_root / rel_path
        if not base.is_dir():
            return {}
        return {
            p.name.lower(): p
            for p in base.iterdir()
            if p.is_dir() and not p.name.startswith(".") and p.name not in exclude
        }

    return {
        "colleagues": slugs("areas/colleagues"),
        "direct_reports": slugs("areas/people_management/direct_reports"),
        "domain_staff": slugs("areas/people_management/domain_staff"),
        "projects": slugs("projects"),
        "areas": slugs("areas", exclude=AREA_EXCLUDE),
    }


def _attendee_tokens(attendees):
    return {a.lower() for a in attendees} - OWNER_ALIASES


def _person_matches(slug, tokens):
    return any(slug == token or slug.startswith(f"{token}_") for token in tokens)


def _title_words(title):
    return set(WORD.findall(title.lower())) - STOPWORDS


def _resolve_person(matches, title_words):
    """Pick one colleague from the slugs that matched an attendee.

    When several slugs share a first name (e.g. ``tom_d`` and ``tom_m`` both
    prefix-matched the token "tom"), the bare first name can't disambiguate
    them, so use the last-initial / extra slug parts corroborated by the
    meeting title ("Tom M x Josh" -> ``tom_m``). Falls back to the first match
    for genuinely distinct people (a multi-person meeting), preserving the
    original behaviour there.

    Returns ``(slug, path, confidence)``.
    """
    if len(matches) == 1:
        slug, path = matches[0]
        return slug, path, "high"

    if len({slug.split("_")[0] for slug, _ in matches}) > 1:
        # Distinct first names — group/multi-person meeting, not an ambiguous
        # 1:1. Keep deterministic first-match behaviour.
        slug, path = matches[0]
        return slug, path, "high"

    scored = sorted(
        (
            (sum(1 for part in slug.split("_")[1:] if part in title_words), slug, path)
            for slug, path in matches
        ),
        key=lambda s: (-s[0], s[1]),
    )
    top_score, slug, path = scored[0]
    unique = top_score > 0 and (len(scored) == 1 or scored[1][0] < top_score)
    return slug, path, "high" if unique else "low"


def classify_meeting(title, attendees, candidates):
    tokens = _attendee_tokens(attendees)
    title_words = _title_words(title)

    for bucket, kind in (
        ("colleagues", "peer"),
        ("direct_reports", "direct_report"),
        ("domain_staff", "domain_staff"),
    ):
        matches = [
            (slug, path)
            for slug, path in candidates[bucket].items()
            if _person_matches(slug, tokens)
        ]
        if matches:
            slug, path, confidence = _resolve_person(matches, title_words)
            actual_kind = "boss" if bucket == "colleagues" and slug == "stefan" else kind
            return {
                "type": actual_kind,
                "person": slug,
                "destination_path": path,
                "confidence": confidence,
            }

    words = _title_words(title)
    for bucket, kind in (("projects", "project"), ("areas", "area")):
        for slug, path in candidates[bucket].items():
            if set(slug.split("_")) & words:
                return {"type": kind, "person": slug, "destination_path": path, "confidence": "medium"}

    return {"type": "unclassified", "person": None, "destination_path": None, "confidence": "low"}


def resolve_destination(vault_root, classification):
    if classification["type"] == "unclassified":
        return Path(vault_root) / "dailies" / "meetings"
    return classification["destination_path"] / "minutes"


def plan(vault_root, staging_dir):
    vault_root = Path(vault_root)
    candidates = discover_candidates(vault_root)
    items = []
    for folder in sorted(Path(staging_dir).iterdir()):
        if not folder.is_dir():
            continue
        text = (folder / "notes.md").read_text(encoding="utf-8")
        title = extract_title(text)
        attendees = read_list_field(text, "attendees")
        classification = classify_meeting(title, attendees, candidates)
        destination_dir = resolve_destination(vault_root, classification)
        items.append(
            {
                "source": str(folder),
                "muesli_id": extract_int_field(text, "muesli_id"),
                "title": title,
                "date": extract_field(text, "date"),
                "meeting_time": extract_field(text, "meeting_time"),
                "type": classification["type"],
                "person": classification["person"],
                "confidence": classification["confidence"],
                "destination_dir": str(destination_dir),
            }
        )
    return items


def _tags_for(kind, person):
    return {
        "peer": ["1x1", "peer", person],
        "boss": ["1x1", "stefan", "manager"],
        "direct_report": ["1x1", "direct-report", person],
        "domain_staff": ["1x1", "domain-staff", person],
        "project": ["project", person],
        "area": [person],
        "unclassified": ["unclassified"],
    }[kind]


def apply(vault_root, items):
    results = []
    for item in items:
        source = Path(item["source"])
        destination_dir = Path(item["destination_dir"])
        destination_dir.mkdir(parents=True, exist_ok=True)

        slug = slugify(item["title"])
        stamp = f"{item['date']}_{item['meeting_time'].replace(':', '')}"
        target = destination_dir / f"{stamp}_{slug}"
        if target.exists():
            target = destination_dir / f"{stamp}_{slug}-{item['muesli_id']}"

        shutil.move(str(source), str(target))

        tags = _tags_for(item["type"], item["person"])
        for filename in ("notes.md", "transcript.md"):
            path = target / filename
            text = path.read_text(encoding="utf-8")
            path.write_text(append_tags(text, tags), encoding="utf-8")

        results.append({"muesli_id": item["muesli_id"], "title": item["title"], "destination": str(target)})
    return results


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    sub = parser.add_subparsers(dest="command", required=True)

    plan_parser = sub.add_parser("plan")
    plan_parser.add_argument("--vault", default=".")
    plan_parser.add_argument("--staging", default="inbox/meetings_outgest")

    apply_parser = sub.add_parser("apply")
    apply_parser.add_argument("--vault", default=".")

    args = parser.parse_args()

    if args.command == "plan":
        items = plan(Path(args.vault), Path(args.vault) / args.staging)
        json.dump(items, sys.stdout, indent=2)
        print()
    elif args.command == "apply":
        items = json.load(sys.stdin)
        results = apply(Path(args.vault), items)
        json.dump(results, sys.stdout, indent=2)
        print()


if __name__ == "__main__":
    main()
