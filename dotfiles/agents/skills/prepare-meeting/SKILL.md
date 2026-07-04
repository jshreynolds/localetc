---
name: prepare-meeting
description: Prepares a syncslids meeting folder from a text agenda — creates a YYYY-MM-DD-<title>/ directory containing index.html and a generated meeting.json. Use this skill whenever the user wants to set up, prepare, scaffold, or create a meeting, sync, standup, or agenda — even if they don't say "syncslids". Triggers on phrases like "prepare a meeting", "set up a sync", "create an agenda", "make a meeting folder", "I have a meeting tomorrow", or when the user pastes a text agenda and wants to turn it into a runnable presentation.
---

# Prepare Meeting

Turn a text agenda into a ready-to-run syncslids meeting folder.

## Bundled assets

All template files live alongside this skill:

| File | Purpose |
|---|---|
| `assets/index.html` | The syncslids app — copy this into every new meeting folder |
| `assets/meeting.json` | Seed example — reference only, do not copy |
| `references/meeting.schema.json` | Full schema for the meeting input format |
| `references/export.schema.json` | Schema for the export output format |

Read `references/meeting.schema.json` before generating `meeting.json` to ensure conformance.

The skill directory is: `~/.claude/skills/prepare-meeting/`

---

## Step 1 — Extract what you can

If an agenda was provided (as args or in the conversation), parse it immediately:

| Agenda element | Maps to |
|---|---|
| Top-level items (`1.`, `-`, `*`, `##`) | `items[].topic` |
| Descriptive text beneath a top-level item (before sub-items) | `items[].description` |
| Indented / nested sub-items | `items[].cards[]` with `title` = sub-item text, `notes: ""` |
| Duration hints on items (`15 min`, `(20m)`, `~30`) | `items[].durationMins` |
| Main subject / headline of the agenda | candidate for `title` |
| Meeting type + date if mentioned | candidate for `name` |

If no agenda was provided, ask for one before doing anything else.

---

## Step 2 — Gather missing info, one question at a time

After parsing, ask one question at a time in this order. Skip anything you can confidently infer.

1. **Title** — the hero heading on the agenda slide (e.g. `"Q2 Planning"`, `"Team Sync"`).
2. **Meeting label** — short label for the top bar. Format: `"Type · YYYY-MM-DD"`. If no date was mentioned, offer today's date as the default.
3. **Item durations** — if no durations appear in the agenda, ask once: *"How long per item? (I'll use 15 min as default if you skip this)"*. Accept a single default or per-item values.
4. **Default agenda timer** — countdown on the opening slide. Default 10 min; only ask if the user seems to care about fine-tuning.

Don't batch questions. Don't ask about things you can reasonably infer.

---

## Step 3 — Build meeting.json

Read `references/meeting.schema.json` for the authoritative schema. The shape is:

```json
{
  "title": "string",
  "name": "string — e.g. 'Weekly Sync · 2026-04-13'",
  "defaultTimerMins": 10,
  "items": [
    {
      "topic": "string",
      "description": "string (empty string if none)",
      "durationMins": 15,
      "cards": [
        { "title": "string", "notes": "" }
      ]
    }
  ]
}
```

### Parsing rules

- Strip leading list markers, numbers, bullets, and whitespace from all text.
- An item with no nested sub-items gets `"cards": []`.
- Preserve meaningful parenthetical context in descriptions.
- If the agenda has a preamble before the item list, use it to inform the title or first item's description.

---

## Step 4 — Create the folder and files

Once you have all required info, act without asking for further confirmation:

1. **Create folder** in the current working directory:
   ```
   YYYY-MM-DD-<slug>/
   ```
   Slug = title lowercased, spaces → hyphens, non-alphanumeric removed.
   Use the date from the meeting label, or today's date.

2. **Copy** `~/.claude/skills/prepare-meeting/assets/index.html` into the new folder.

3. **Write** the generated `meeting.json` into the new folder.

---

## Output

Tell the user:
- Full path to the new folder
- Number of items and total estimated duration
- `cd <folder> && npx serve .` to run it
