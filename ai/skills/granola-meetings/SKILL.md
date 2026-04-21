---
name: granola-meetings
description: Extract and organize Granola meeting notes into the Obsidian work vault. Use when the user wants to process their meetings at end of day, sync Granola meetings to Obsidian, archive meeting notes, or mentions "granola" in context of saving/organizing meetings. Also trigger when the user says things like "process my meetings", "save today's meetings", or "end of day meeting sync".
---

# Granola Meetings Skill

Extract meetings from Granola via MCP, classify them using metadata and summary content, and save both the AI summary and full transcript into the correct location in the Obsidian work vault.

This is a user-assisted automation workflow:

- Automate the repetitive file creation and transcript export steps.
- Use the Granola metadata, AI summary, and private notes for classification.
- Ask the user to confirm classifications or fill gaps when metadata is incomplete.
- Do not load transcript content into agent context.

## Vault Path

The vault root is set by the environment variable `WORKSIDIAN`. If `WORKSIDIAN` is not set, stop immediately and tell the user:

> "The `WORKSIDIAN` environment variable is not set. Please set it to your Obsidian vault path before running this skill (e.g. `export WORKSIDIAN=/path/to/vault`)."

Do not guess a path or fall back to the current directory. All paths below are relative to `$WORKSIDIAN`.

## Workflow

### Step 1: List and fetch meetings

1. Call `mcp__claude_ai_Granol__list_meetings` with the narrowest appropriate `time_range` for the user's request.
   - For "today", prefer the smallest supported range and then filter to the exact date.
   - For date ranges like "this week", filter to the exact requested dates after listing.
2. For each matching meeting, fetch the summary data in parallel with `mcp__claude_ai_Granol__get_meetings`.
3. Do not fetch transcript content through MCP or any tool that would place the transcript into model context.

### Step 2: Build meeting context

For each meeting, build a working record from:

- Meeting title
- Start and end time
- Granola meeting ID
- Any attendees present in metadata
- AI summary
- Private notes

If attendees are missing or incomplete in Granola metadata, proceed with what you have. Do not try to infer speakers from transcripts.

### Step 3: Discover available destinations

Before classifying meetings, inspect the Obsidian vault so the skill uses the current vault structure instead of stale hardcoded lists.

Discover:

- Direct report folders under `areas/people_management/`
- Peer folders under `areas/people_management/peers/`
- Area folders under `areas/`
- Project folders under `projects/`

Ignore folders that are clearly infrastructure folders such as `minutes/` children when building the candidate lists.

Use the live vault folders as the source of truth. If a person or project is not present, treat it as unknown and ask the user where it belongs.

### Step 4: Propose classification

Present the meetings to the user in a compact review list before writing anything. For each meeting, show:

- Title
- Date/time
- Known attendees from metadata, if any
- Proposed type
- Proposed destination folder
- Confidence: `high`, `medium`, or `low`

Use this classification order:

1. Direct report 1x1
   - Match a metadata attendee or clear title reference to a folder under `areas/people_management/{person}/`
   - Destination: `areas/people_management/{person}/`

2. Boss 1x1
   - If the meeting is clearly with Stefan
   - Destination: `areas/people_management/peers/stefan/`

3. Peer 1x1
   - Match a metadata attendee or clear title reference to a folder under `areas/people_management/peers/{person}/`
   - Destination: `areas/people_management/peers/{person}/`

4. Project meeting
   - Match title, summary, or notes to a folder under `projects/{project_name}/`
   - Destination: `projects/{project_name}/minutes/`

5. Area meeting
   - Match title, summary, or notes to a folder under `areas/{area_name}/`
   - Destination: `areas/{area_name}/minutes/`

6. Unclassified
   - Destination: `daily_work/meetings/`

Ask the user to confirm the list once, with any skips or reclassifications. Do not ask one classification question per meeting unless the user response is still ambiguous.

### Step 5: Create the meeting folder and files

For each confirmed meeting, create a datetime-stamped folder inside the destination folder:

```text
{destination}/YYYY-MM-DD_HHmm_{Meeting_Title}/
├── summary.md
└── transcript.md
```

Folder naming rules:

- Use the meeting start time for `YYYY-MM-DD_HHmm`
- Sanitize the meeting title by replacing spaces with `_`, removing special characters, and truncating to 60 characters
- If a folder with the same datetime prefix already exists in the destination, ask the user whether to overwrite or skip

Create missing `minutes/` directories automatically for project and area meetings.

### Step 6: Write `summary.md`

Use Obsidian Flavored Markdown with this structure:

```markdown
---
type: meeting
date: YYYY-MM-DD
meeting_time: "HH:mm"
attendees:
  - Name 1
  - Name 2
source: granola
granola_id: {meeting_uuid}
tags:
  - meeting
  - {classification_tag}
---

# {Meeting Title}

**Date:** {Day of week}, {Date}
**Time:** {Start time} - {End time}
**Attendees:** {comma-separated list if available}

## Summary

{AI-generated summary from Granola}

## Private Notes

{Private notes if any, otherwise omit this section}

## Action Items

{Extract action items only if they are explicit in the summary or notes. Omit if none.}
```

Classification tags:

- Direct report 1x1: `1x1`, `direct-report`, `{person_name}`
- Boss 1x1: `1x1`, `stefan`, `manager`
- Peer 1x1: `1x1`, `peer`, `{person_name}`
- Project: `project`, `{project_name}`
- Area: `{area_name}`
- Unclassified: `meeting`, `unclassified`

Do not invent attendees. If none are available, use an empty list in frontmatter and omit the inline attendee line or render it as `Unknown`.

### Step 7: Write `transcript.md`

Never fetch or load transcript content into agent context. Use the local helper script to write the transcript directly to disk.

The helper script lives relative to this skill at `fetch_transcript.py`.

It requires the `GRANOLA_API_KEY` environment variable to be set. If it is not set, tell the user:

> "Please set `GRANOLA_API_KEY` in your environment (e.g. `export GRANOLA_API_KEY=grn_...`) before running this skill."

For each meeting, invoke:

```bash
python3 /absolute/path/to/fetch_transcript.py \
  "{full_destination_path}/transcript.md" \
  "YYYY-MM-DD" \
  "{Meeting Title}" \
  "{Day of week}" \
  "{granola_mcp_uuid}" \
  "{HH:MM}"
```

Notes:

- Pass the meeting start time when available. It improves note matching.
- The script calls the Granola public API directly and writes `transcript.md` without exposing transcript content to the agent.
- If transcript export fails for a meeting, do not discard `summary.md`. Report the meeting as partially saved and include the error.

Run transcript fetches in parallel where practical, but do not describe them as fire-and-forget unless your environment actually supports background execution without losing visibility into failures. Prefer collecting success or failure for each meeting.

### Step 8: Optional user additions

After the files are written, offer the user a single batched follow-up:

> "I saved the meeting summaries. If you want, I can add personal notes to any of them. Reply with the meeting name and what to add, or say skip."

Only do per-meeting follow-up if the user opts in.

If the user wants custom notes, append them under:

```markdown
## My Notes
```

### Step 9: Report results

After processing all meetings, present a concise summary table:

| Meeting | Type | Destination | Status |
|---------|------|-------------|--------|
| Javier x Josh 1x1 | Direct report 1x1 | areas/people_management/javier/ | Saved |
| Sprint Planning | Area | areas/chatlayer/minutes/ | Saved |

For each meeting, include:

- Full created folder path
- Whether `summary.md` was written
- Whether `transcript.md` was written
- Any meetings skipped or left unclassified

## Edge Cases

- No meetings in range: tell the user there are no Granola meetings for the requested date or date range.
- Existing meeting folder: ask whether to overwrite or skip.
- Missing attendees: continue without them; ask the user only if classification depends on the missing information.
- Unknown person or project: ask the user where to file it.
- Missing `minutes/` subfolder: create it automatically.
- Transcript export failure: keep the saved summary, report the failure, and include the command inputs needed for retry if useful.
