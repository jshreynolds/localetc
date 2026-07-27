---
name: ingest-meetings
description: Pull completed Muesli meetings into the Obsidian work vault inbox, then classify and file them. Two phases — ingest (fully automated) and file (classification proposal + your confirmation). Use when the user wants to process their meetings, sync Muesli meetings to Obsidian, "save today's meetings", or run an end-of-day meeting sync. Also trigger on "process my meetings" or "file my meetings".
---

# Ingest Meetings

Two phases, run separately:

1. **Ingest** — pull completed meetings from Muesli into
   `inbox/meetings_outgest/`, split into `notes.md` + `transcript.md`. Fully
   automated, no judgment involved.
2. **File** — classify each staged meeting and move it into its vault
   destination. The matching itself is code (attendee/title vs. live vault
   folder names); you only confirm or correct the proposed table once before
   anything moves.

Both phases are idempotent — safe to re-run.

## Vault Path

Runs from the root of the Obsidian work vault (the current working
directory). Confirm `areas/` and `dailies/` both exist before doing anything.
If they don't, stop and tell the user to `cd` into the vault root and retry.
Do not guess a path or search other directories.

## Phase 1: Ingest

```bash
python3 scripts/ingest.py run                    # today only (local date)
python3 scripts/ingest.py run --date 2026-07-21   # a specific day
python3 scripts/ingest.py run --all               # every completed meeting, no date filter
```

By default only meetings that started **today** (local time) are processed —
this is meant to run once at end of day, not to backfill history. Use
`--date` for a specific day or `--all` to disable the filter entirely.

This lists completed Muesli meetings, skips any whose `muesli_id` already
appears somewhere in the vault, and writes new ones to
`inbox/meetings_outgest/YYYY-MM-DD_HHmm_{Meeting_Title}/{notes.md,transcript.md}`
with matching frontmatter (`type`, `date`, `meeting_time`, `attendees`,
`source: muesli`, `muesli_id`, `tags`). Same stamp+slug collision → a
`-{muesli_id}` suffix.

The script prints a JSON report: `created`, `skipped_existing`,
`skipped_incomplete`, and each created meeting's inferred `attendees` with a
`needs_attendees` flag.

**If any created meeting has `needs_attendees: true`** (title didn't parse
into two names — e.g. "Orchestral Conversations"), batch them into one
question to the user: "I couldn't infer attendees for: {titles}. Who was in
each?" Also ask if the auto-generated title is wrong (Muesli titles are
often just speaker names, e.g. "Glenn x Josh" for a meeting actually called
something else) — the folder name is derived from the title, so fix title
before attendees:

```bash
python3 scripts/ingest.py set-title <folder> New Meeting Title   # prints the (possibly moved) folder path
python3 scripts/ingest.py set-attendees <folder> Name1 Name2      # use the path set-title printed, if it moved
```

Report what was created — titles and folders — and stop. Don't move to
phase 2 in the same breath; the user may want to review the raw ingest first.

## Phase 2: File

```bash
python3 scripts/classify.py plan
```

Prints a JSON list, one item per meeting sitting in `meetings_outgest/`:
`title`, `type`, `person`, `confidence` (`high`/`medium`/`low`), and
`destination_dir`. Matching order (mirrors `AGENTS_meetings.md`, the
canonical destination table — read it if the two ever disagree):

1. Attendee matches a `areas/colleagues/{person}/` folder → peer 1:1 (or
   boss, if `person` is `stefan`)
2. Attendee matches `areas/people_management/direct_reports/{person}/` →
   direct report 1:1
3. Attendee matches `areas/people_management/domain_staff/{person}/` →
   domain staff 1:1
4. Title word matches a `projects/{name}/` folder → project meeting
5. Title word matches an `areas/{name}/` folder → area meeting
6. No match → unclassified, destination `dailies/meetings/`

Render the plan as a compact table and ask the user to confirm once, with
any corrections (wrong person, wrong project, should be unclassified, etc).
Edit the `type`/`person`/`destination_dir` fields of the JSON directly to
reflect corrections — don't re-derive them by hand.

Once confirmed, apply it:

```bash
python3 scripts/classify.py apply <<'JSON'
{the confirmed/edited plan JSON}
JSON
```

This creates any missing `minutes/` directory, moves each meeting folder to
`{destination_dir}/YYYY-MM-DD_HHmm_{Sanitized_Title}/`, and appends
classification tags to both files' frontmatter. Same-named collisions get a
`-{muesli_id}` suffix automatically.

Report the result table — title, type, destination — to the user.

## Edge Cases

- No meetings to ingest: say so, stop.
- Nothing staged in `meetings_outgest/` for phase 2: say so, stop.
- Low-confidence or unclassified items: still show them in the confirmation
  table — don't silently drop them into `dailies/meetings/` without the user
  seeing it first.
