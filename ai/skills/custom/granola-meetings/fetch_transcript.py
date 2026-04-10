#!/usr/bin/env python3
"""
Fetch a Granola meeting transcript via the public API and write it directly
to a transcript.md file. Transcript content never passes through agent context.

Usage:
    python3 fetch_transcript.py <output_file> <date> <title> <day_of_week> [granola_mcp_uuid] [meeting_time]

    - output_file     : full path to write transcript.md
    - date            : YYYY-MM-DD (used for note lookup and frontmatter)
    - title           : meeting title (used for note lookup and frontmatter)
    - day_of_week     : e.g. "Monday" (frontmatter only)
    - granola_mcp_uuid: optional UUID from the Granola MCP (stored in frontmatter)
    - meeting_time     : optional HH:MM start time, used to narrow note lookup

Environment:
    GRANOLA_API_KEY  — required. Granola API key (grn_...).

How note lookup works:
    The Granola public API uses different IDs (not_xxx) from the MCP (UUIDs).
    This script lists notes created on the given date, scores candidate titles,
    and fetches the transcript only when the best match is sufficiently distinct.

Exit codes:
    0  success
    1  error (printed to stderr)
"""

import sys
import os
import json
import urllib.request
import urllib.error
import re
import time
from datetime import datetime, timedelta, timezone

BASE_URL = "https://public-api.granola.ai/v1"
MIN_SCORE = 0.35
MIN_SCORE_GAP = 0.15


def api_get(path, api_key, retries=4):
    url = f"{BASE_URL}{path}"
    req = urllib.request.Request(url, headers={"Authorization": f"Bearer {api_key}"})
    for attempt in range(retries):
        try:
            with urllib.request.urlopen(req, timeout=30) as resp:
                return json.loads(resp.read().decode())
        except urllib.error.HTTPError as e:
            body = e.read().decode()
            if e.code in (429, 500, 502, 503, 504) and attempt < retries - 1:
                time.sleep(5 * (attempt + 1))
                continue
            raise RuntimeError(f"HTTP {e.code}: {body}")
        except urllib.error.URLError as e:
            if attempt < retries - 1:
                time.sleep(5 * (attempt + 1))
                continue
            raise RuntimeError(f"Network error: {e.reason}")
    raise RuntimeError("Max retries exceeded")


def normalize_title(value):
    value = (value or "").lower()
    value = re.sub(r"[^a-z0-9]+", " ", value)
    return [token for token in value.split() if token]


def find_note_id(title, date_str, api_key, meeting_time=None):
    """Search notes created on date_str and return the best title match.

    meeting_time: optional "HH:MM" in local time (UTC assumed) — narrows the search
    window to ±90 minutes around the meeting start for disambiguation.
    """
    if meeting_time:
        dt = datetime.strptime(f"{date_str}T{meeting_time}", "%Y-%m-%dT%H:%M").replace(tzinfo=timezone.utc)
        created_after  = (dt - timedelta(minutes=90)).strftime("%Y-%m-%dT%H:%M:%SZ")
        created_before = (dt + timedelta(hours=3)).strftime("%Y-%m-%dT%H:%M:%SZ")
    else:
        day = datetime.strptime(date_str, "%Y-%m-%d").replace(tzinfo=timezone.utc)
        created_after  = (day - timedelta(hours=1)).strftime("%Y-%m-%dT%H:%M:%SZ")
        created_before = (day + timedelta(days=1)).strftime("%Y-%m-%dT%H:%M:%SZ")

    params = f"?created_after={created_after}&created_before={created_before}&limit=30"
    cursor = None
    candidates = []

    while True:
        p = params + (f"&cursor={cursor}" if cursor else "")
        data = api_get(f"/notes{p}", api_key)
        candidates.extend(data.get("notes", []))
        if not data.get("hasMore"):
            break
        cursor = data.get("cursor")

    if not candidates:
        return None, None

    # Score by normalized title similarity.
    def score(note):
        note_title = note.get("title") or ""
        a = set(normalize_title(title))
        b = set(normalize_title(note_title))
        return len(a & b) / max(len(a | b), 1)

    ranked = sorted(
        ((score(note), note) for note in candidates),
        key=lambda item: item[0],
        reverse=True,
    )
    best_score, best = ranked[0]
    next_score = ranked[1][0] if len(ranked) > 1 else 0.0

    if best_score < MIN_SCORE:
        raise RuntimeError(
            f"No confident transcript match for '{title}' on {date_str}; "
            f"best candidate was '{best.get('title', '')}' with score {best_score:.2f}"
        )

    if next_score and (best_score - next_score) < MIN_SCORE_GAP:
        raise RuntimeError(
            f"Ambiguous transcript match for '{title}' on {date_str}; "
            f"top candidates are too close ({best_score:.2f} vs {next_score:.2f})"
        )

    return best["id"], best["title"]


def format_transcript(segments):
    if not segments:
        return "_No transcript available._"
    lines = []
    prev_speaker = None
    for seg in segments:
        speaker = seg.get("speaker", {}).get("source", "unknown").strip()
        text = seg.get("text", "").strip()
        if not text:
            continue
        if speaker != prev_speaker and prev_speaker is not None:
            lines.append("")
        lines.append(f"**{speaker}:** {text}")
        prev_speaker = speaker
    return "\n".join(lines)


def main():
    if len(sys.argv) < 5:
        print("Usage: fetch_transcript.py <output_file> <date> <title> <day_of_week> [mcp_uuid] [meeting_time]",
              file=sys.stderr)
        sys.exit(1)

    output_file  = sys.argv[1]
    date         = sys.argv[2]   # YYYY-MM-DD
    title        = sys.argv[3]
    day_of_week  = sys.argv[4]
    mcp_uuid     = sys.argv[5] if len(sys.argv) > 5 else ""
    meeting_time = sys.argv[6] if len(sys.argv) > 6 else None  # optional HH:MM

    api_key = os.environ.get("GRANOLA_API_KEY")
    if not api_key:
        print("Error: GRANOLA_API_KEY environment variable not set", file=sys.stderr)
        sys.exit(1)

    # 1. Find the public API note ID
    note_id, matched_title = find_note_id(title, date, api_key, meeting_time)
    if not note_id:
        print(f"Error: no note found for '{title}' on {date}", file=sys.stderr)
        sys.exit(1)

    # 2. Fetch the transcript
    data = api_get(f"/notes/{note_id}?include=transcript", api_key)
    segments = data.get("transcript") or []

    # 3. Format and write
    granola_id = mcp_uuid if mcp_uuid else note_id
    transcript_body = format_transcript(segments)

    content = f"""---
type: transcript
date: {date}
source: granola
granola_id: {granola_id}
parent: "[[summary]]"
---

# Transcript: {title}

**Date:** {day_of_week}, {date}

---

{transcript_body}
"""

    os.makedirs(os.path.dirname(os.path.abspath(output_file)), exist_ok=True)
    with open(output_file, "w", encoding="utf-8") as f:
        f.write(content)

    print(f"OK: {output_file} (matched: '{matched_title}')")


if __name__ == "__main__":
    main()
