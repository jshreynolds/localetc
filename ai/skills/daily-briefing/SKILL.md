---
name: daily-briefing
description: Build a conversational morning briefing — what's on JR's plate today across the vault. Pulls today's tasks grouped by area/project, the list of areas/projects in play, and upcoming meetings from Granola. Writes to `dailies/YYYY-MM-DD-daily-brief.md`. Use whenever the user asks for a daily briefing, morning briefing, start-of-day plan, "what's on today", today's agenda, or invokes /daily-briefing.
---

# Daily Briefing

A global, conversational view of what's ahead today. The goal is **discovery and reassurance** — surface anything that might otherwise be missed (especially upcoming meetings, which are hard to see), and remind JR of what's in play. It is not task triage and it is not a project status report.

## Output destination

Write the briefing to `dailies/YYYY-MM-DD-daily-brief.md` (today's date).

- Distinct from `dailies/YYYY-MM-DD-debrief.md`, which is the end-of-day file owned by the `daily-debrief` skill.
- If the brief already exists for today, ask whether to overwrite.

## What the briefing contains

Exactly three sections, in this order:

1. **Today's tasks, grouped by area/project.**
2. **Areas/projects in play today** — a one-line "what this is" per area/project from section 1.
3. **Upcoming meetings today** — from Granola.

That's it. Do not add a summary banner, a "loose threads" section, recent meeting recaps, blockers, overdue sweeps, or anything else. The user asked for a global view, not a triage.

Tone is conversational and brief. Short sentences. No bot editorializing.

## Vault assumptions

- Obsidian vault. Conventions live in `AGENTS.md` and `AGENTS_tasks.md` at the vault root.
- Tasks use the Obsidian Tasks emoji syntax. Scheduled = `⏳ YYYY-MM-DD`, Due = `📅 YYYY-MM-DD`.
- Task lists live in `todo.md` inside `projects/<name>/` and `areas/<name>/` (areas may be nested, e.g. `areas/people_management/hadrien/`).

## Workflow

### 1. Determine today's date

Derive from the environment in `YYYY-MM-DD` form. Don't ask.

### 2. Find today's tasks

```bash
rg "⏳ $(date +%Y-%m-%d)" --glob '!archive/**' --glob '!cold_storage/**'
rg "📅 $(date +%Y-%m-%d)" --glob '!archive/**' --glob '!cold_storage/**'
```

Keep the line and the file path. Deduplicate across the two queries.

**Filter out:**
- Lines from documentation files (e.g. `AGENTS_tasks.md`, anything in the vault root that contains example/query syntax rather than real tasks).
- Tasks marked `[x]` (done) or `[-]` (cancelled). Keep `[ ]` (open) and `[/]` (in-progress).
- Anything inside `archive/` or `cold_storage/`.

### 3. Group tasks by area/project

Group by the *closest* containing area or project — the path segment immediately after `areas/` or `projects/`. For nested areas (e.g. `areas/people_management/hadrien/`), use the full nested path as the group key so sub-areas stay distinct.

### 4. Get the "what this is" line for each group

For each unique area/project from step 3, get a single short description. Try in order:

1. The `summary:` field in the frontmatter of the area/project's `todo.md`.
2. The first non-frontmatter, non-heading paragraph in `todo.md`.
3. Fall back to the area/project's folder name, prettified.

**Do not** read meeting minutes, recent summaries, or anything under `minutes/`. The user explicitly does not want past-meeting context in the briefing — they want a global "this is what's in play" view, not a recap.

If a group has no usable description and the folder name is ambiguous, write `_(no description on file)_` rather than inventing one.

### 5. Fetch upcoming meetings from Granola

Use the Granola MCP to fetch today's meetings that have not yet happened. Try in order:

1. `mcp__claude_ai_Granol__query_granola_meetings` or `mcp__claude_ai_Granol__list_meetings` with a date filter for today.
2. Filter to meetings whose start time is **later than the current time**. Past meetings are not part of this brief.

For each upcoming meeting, capture:
- Start time (local, `HH:MM` is fine)
- Title
- Other attendees if available

If Granola is unavailable or returns nothing for today, write `_(no upcoming meetings found in Granola)_` and move on. Do not block on this.

### 6. Compose the brief

```markdown
# Daily Brief — YYYY-MM-DD

## Today's tasks

### <area/project path>
- [ ] Task description ⏳ YYYY-MM-DD — `path/to/todo.md`
- [/] In-progress task ⏳ YYYY-MM-DD — `path/to/todo.md`

### <next area/project path>
- ...

## What's in play today

- **<area/project path>** — one short sentence describing what this is.
- **<next area/project path>** — one short sentence.

## Upcoming meetings

- **HH:MM** — Meeting title (attendees if known)
- **HH:MM** — Meeting title
```

Rules:
- Preserve original task text and emoji metadata verbatim. Don't rewrite, re-prioritize, or sort.
- The "what's in play" list is the same set of groups as "today's tasks", in the same order.
- One sentence per group in "what's in play". Not a paragraph. Not a status report.
- If there are zero tasks today, skip sections 1 and 2 entirely and just write the meeting list.
- If there are zero tasks *and* zero upcoming meetings, write a single line: `Nothing on the schedule today.`

### 7. Write the file

Write directly to `dailies/YYYY-MM-DD-daily-brief.md`. Don't ask for confirmation — the user asked for a brief, so generate it. If the file already exists, ask before overwriting.

After writing, output the brief inline to the chat as well so the user can read it without opening the file.

## What this skill is not

- Not task triage. Don't recommend what to do first.
- Not a status report. Don't summarize project state.
- Not a meeting recap. Don't pull from past meeting summaries.
- Not interactive. Generate, don't co-author.
