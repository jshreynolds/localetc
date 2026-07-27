"""Shared helpers for building and patching ingest-meetings frontmatter.

Frontmatter is parsed and rewritten with plain line scanning, not a YAML
library — the shape is fixed (a handful of scalar fields plus two list
fields, `attendees` and `tags`) since we are the only writer.
"""

import re
from datetime import datetime

OWNER_NAMES = frozenset({"josh", "joshua"})

SEPARATOR = re.compile(r"\s+(?:x|vs\.?|&|and)\s+|\s*/\s*", re.IGNORECASE)
NON_SLUG_CHAR = re.compile(r"[^A-Za-z0-9_-]")
CHECKBOX = re.compile(r"^- \[[ xX]\] ", re.MULTILINE)


def to_local(iso_utc, tz=None):
    dt = datetime.fromisoformat(iso_utc.replace("Z", "+00:00"))
    return dt.astimezone(tz)


def folder_stamp(dt):
    return dt.strftime("%Y-%m-%d_%H%M")


def duration_str(seconds):
    minutes_total = int(seconds) // 60
    hours, minutes = divmod(minutes_total, 60)
    return f"{hours}h {minutes}m" if hours else f"{minutes}m"


def normalize_checkboxes(text):
    return CHECKBOX.sub("- ", text)


def infer_attendees(title, owner_names=OWNER_NAMES):
    parts = SEPARATOR.split(title, maxsplit=1)
    if len(parts) != 2:
        return []

    def first_name(segment):
        words = segment.strip().split()
        if not words:
            return None
        token = words[0]
        return token if token.isalpha() and token[0].isupper() else None

    left, right = first_name(parts[0]), first_name(parts[1])
    if not left or not right:
        return []
    return [name for name in (left, right) if name.lower() not in owner_names]


def slugify(text, max_len=60):
    slug = text.strip().replace(" ", "_")
    slug = NON_SLUG_CHAR.sub("", slug)
    return slug[:max_len]


def render_list_field(field, items):
    if not items:
        return f"{field}: []"
    body = "\n".join(f"  - {item}" for item in items)
    return f"{field}:\n{body}"


def read_list_field(text, field):
    lines = text.split("\n")
    for i, line in enumerate(lines):
        if line.startswith(f"{field}:"):
            rest = line[len(field) + 1 :].strip()
            if rest == "[]":
                return []
            items = []
            j = i + 1
            while j < len(lines) and lines[j].startswith("  - "):
                items.append(lines[j][4:].strip())
                j += 1
            return items
    return []


def replace_list_field(text, field, items):
    lines = text.split("\n")
    start = next(i for i, line in enumerate(lines) if line.startswith(f"{field}:"))
    end = start + 1
    while end < len(lines) and lines[end].startswith("  - "):
        end += 1
    new_block = render_list_field(field, items).split("\n")
    return "\n".join(lines[:start] + new_block + lines[end:])


def append_tags(text, new_tags):
    existing = read_list_field(text, "tags")
    merged = existing + [tag for tag in new_tags if tag not in existing]
    return replace_list_field(text, "tags", merged)


def extract_field(text, field):
    for line in text.split("\n"):
        if line.startswith(f"{field}:"):
            return line[len(field) + 1 :].strip().strip('"')
    return None


def extract_int_field(text, field):
    value = extract_field(text, field)
    return int(value) if value and value.isdigit() else None


def extract_title(text):
    for line in text.split("\n"):
        if line.startswith("# "):
            return line[2:].strip()
    return ""


def render_frontmatter(date, meeting_time, attendees, muesli_id, tags):
    lines = [
        "---",
        "type: meeting",
        f"date: {date}",
        f'meeting_time: "{meeting_time}"',
        render_list_field("attendees", attendees),
        "source: muesli",
        f"muesli_id: {muesli_id}",
        render_list_field("tags", tags),
        "---",
    ]
    return "\n".join(lines)
