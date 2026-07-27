#!/usr/bin/env python3
"""ingest-meetings — phase 1: pull completed Muesli meetings into the inbox.

Entirely mechanical: list meetings via `muesli-cli`, skip anything already
present in the vault (matched by `muesli_id` in frontmatter), and write each
new meeting as a pair of files (notes.md, transcript.md) with identical
frontmatter into inbox/meetings_outgest/YYYY-MM-DD-HH-mm_minutes/.

Attendees are inferred from the title where possible (see
meeting_frontmatter.infer_attendees). Meetings where inference fails are
flagged in the report's "needs_attendees" list — fill them in with:

  ingest.py set-attendees <folder> Name1 Name2

Usage:
  ingest.py run [--vault PATH] [--staging PATH] [--limit N]
  ingest.py set-attendees <folder> <name>...
"""

import argparse
import json
import os
import subprocess
import sys
from datetime import datetime
from pathlib import Path

from meeting_frontmatter import (
    duration_str,
    extract_field,
    extract_int_field,
    extract_title,
    folder_stamp,
    infer_attendees,
    normalize_checkboxes,
    render_frontmatter,
    replace_list_field,
    slugify,
    to_local,
)

SKIP_DIRS = {".obsidian", ".trash", ".git"}
MUESLI_CLI = "/Applications/Muesli.app/Contents/MacOS/muesli-cli"


def existing_muesli_ids(vault_root):
    ids = set()
    for root, dirs, files in os.walk(vault_root):
        dirs[:] = [d for d in dirs if d not in SKIP_DIRS and not d.startswith(".")]
        for name in files:
            if not name.endswith(".md"):
                continue
            text = (Path(root) / name).read_text(encoding="utf-8")
            muesli_id = extract_int_field(text, "muesli_id")
            if muesli_id is not None:
                ids.add(muesli_id)
    return ids


def unique_folder(staging_dir, stamp, slug, meeting_id):
    folder = staging_dir / f"{stamp}_{slug}"
    if folder.exists():
        folder = staging_dir / f"{stamp}_{slug}-{meeting_id}"
    return folder


def render_notes(meeting, attendees, local_dt_str):
    frontmatter = render_frontmatter(
        date=local_dt_str.split(" ")[0],
        meeting_time=local_dt_str.split(" ")[1],
        attendees=attendees,
        muesli_id=meeting["id"],
        tags=["meeting"],
    )
    body = [
        frontmatter,
        "",
        f"# {meeting['title']}",
        "",
        f"**Date:** {local_dt_str}",
        f"**Duration:** {duration_str(meeting['durationSeconds'])}",
        "",
        normalize_checkboxes(meeting["formattedNotes"]).strip(),
    ]
    if meeting.get("manualNotes", "").strip():
        body += ["", "## Private Notes", "", meeting["manualNotes"].strip()]
    return "\n".join(body) + "\n"


def render_transcript(meeting, attendees, local_dt_str):
    frontmatter = render_frontmatter(
        date=local_dt_str.split(" ")[0],
        meeting_time=local_dt_str.split(" ")[1],
        attendees=attendees,
        muesli_id=meeting["id"],
        tags=["meeting"],
    )
    body = [
        frontmatter,
        "",
        f"# {meeting['title']} — Transcript",
        "",
        meeting["rawTranscript"].strip(),
    ]
    return "\n".join(body) + "\n"


def ingest_meeting(meeting, staging_dir, tz=None):
    local_dt = to_local(meeting["startTime"], tz=tz)
    local_dt_str = local_dt.strftime("%Y-%m-%d %H:%M")
    attendees = infer_attendees(meeting["title"])
    folder = unique_folder(staging_dir, folder_stamp(local_dt), slugify(meeting["title"]), meeting["id"])
    folder.mkdir(parents=True)
    (folder / "notes.md").write_text(render_notes(meeting, attendees, local_dt_str), encoding="utf-8")
    (folder / "transcript.md").write_text(
        render_transcript(meeting, attendees, local_dt_str), encoding="utf-8"
    )
    return {"folder": folder, "attendees": attendees, "needs_attendees": not attendees}


def run(list_fn, get_fn, vault_root, staging_dir, tz=None, target_date=None):
    known_ids = existing_muesli_ids(vault_root)
    staging_dir.mkdir(parents=True, exist_ok=True)
    report = {"created": [], "skipped_existing": [], "skipped_incomplete": []}
    for summary in list_fn():
        meeting_id = summary["id"]
        if target_date and to_local(summary["startTime"], tz=tz).strftime("%Y-%m-%d") != target_date:
            continue
        if summary["status"] != "completed":
            report["skipped_incomplete"].append(meeting_id)
            continue
        if meeting_id in known_ids:
            report["skipped_existing"].append(meeting_id)
            continue
        meeting = get_fn(meeting_id)
        result = ingest_meeting(meeting, staging_dir, tz=tz)
        report["created"].append(
            {
                "muesli_id": meeting_id,
                "title": meeting["title"],
                "folder": str(result["folder"]),
                "attendees": result["attendees"],
                "needs_attendees": result["needs_attendees"],
            }
        )
    return report


def set_attendees(folder, names):
    for filename in ("notes.md", "transcript.md"):
        path = Path(folder) / filename
        text = path.read_text(encoding="utf-8")
        path.write_text(replace_list_field(text, "attendees", names), encoding="utf-8")


def set_title(folder, new_title):
    folder = Path(folder)
    notes_path = folder / "notes.md"
    notes_text = notes_path.read_text(encoding="utf-8")
    old_title = extract_title(notes_text)
    notes_path.write_text(notes_text.replace(f"# {old_title}", f"# {new_title}", 1), encoding="utf-8")

    transcript_path = folder / "transcript.md"
    transcript_text = transcript_path.read_text(encoding="utf-8")
    transcript_path.write_text(
        transcript_text.replace(f"# {old_title} — Transcript", f"# {new_title} — Transcript", 1),
        encoding="utf-8",
    )

    # the folder name encodes the title, so a rename must move it too
    date = extract_field(notes_text, "date")
    meeting_time = extract_field(notes_text, "meeting_time")
    muesli_id = extract_int_field(notes_text, "muesli_id")
    stamp = f"{date}_{meeting_time.replace(':', '')}"
    target = folder.parent / f"{stamp}_{slugify(new_title)}"
    if target != folder and target.exists():
        target = folder.parent / f"{stamp}_{slugify(new_title)}-{muesli_id}"
    if target != folder:
        folder.rename(target)
    return target


def _muesli_cli(*args):
    result = subprocess.run(
        [MUESLI_CLI, *args], capture_output=True, text=True, check=True
    )
    # muesli-cli occasionally logs warnings (google-cal, iCloud) ahead of the
    # JSON payload on stdout; the payload always starts at the first "{".
    start = result.stdout.find("{")
    return json.loads(result.stdout[start:])


def _live_list(limit):
    return _muesli_cli("meetings", "list", "--limit", str(limit))["data"]


def _live_get(meeting_id):
    return _muesli_cli("meetings", "get", str(meeting_id))["data"]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    sub = parser.add_subparsers(dest="command", required=True)

    run_parser = sub.add_parser("run")
    run_parser.add_argument("--vault", default=".")
    run_parser.add_argument("--staging", default="inbox/meetings_outgest")
    run_parser.add_argument("--limit", type=int, default=50)
    run_parser.add_argument(
        "--date", default=None, help="YYYY-MM-DD; defaults to today (local). Use --all to disable."
    )
    run_parser.add_argument("--all", action="store_true", help="process every completed meeting, ignoring date")

    set_parser = sub.add_parser("set-attendees")
    set_parser.add_argument("folder")
    set_parser.add_argument("names", nargs="+")

    title_parser = sub.add_parser("set-title")
    title_parser.add_argument("folder")
    title_parser.add_argument("title", nargs="+")

    args = parser.parse_args()

    if args.command == "run":
        target_date = None if args.all else (args.date or datetime.now().astimezone().strftime("%Y-%m-%d"))
        report = run(
            lambda: _live_list(args.limit),
            _live_get,
            vault_root=Path(args.vault),
            staging_dir=Path(args.vault) / args.staging,
            target_date=target_date,
        )
        json.dump(report, sys.stdout, indent=2)
        print()
    elif args.command == "set-attendees":
        set_attendees(args.folder, args.names)
    elif args.command == "set-title":
        print(set_title(args.folder, " ".join(args.title)))


if __name__ == "__main__":
    main()
