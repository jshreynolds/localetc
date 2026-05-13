---
name: daily-briefing
description: Build a morning daily briefing of what's on the schedule today by querying the vault for tasks scheduled or due today, gathering surrounding area/project context, and writing the briefing to `dailies/YYYY-MM-DD-daily-brief.md`. Use whenever the user asks for a daily briefing, morning briefing, start-of-day plan, "what's on today", today's agenda from the vault, or invokes /daily-briefing.
---

# Daily Briefing

A start-of-day orientation tool. Pull every task scheduled or due today from the vault, surround each one with just enough context from its area or project, and produce a concise briefing the user can read in under a minute.

## Output destination

Write the briefing to `dailies/YYYY-MM-DD-daily-brief.md` in the active vault, where `YYYY-MM-DD` is today's date.

- If the file already exists, prefer updating it over creating a competing duplicate. Ask the user whether to overwrite or merge.
- Do not write into `dailies/YYYY-MM-DD.md` (that file is owned by the daily-debrief skill / daily notes).

## Vault assumptions

- The user is working in an Obsidian vault following the conventions in `AGENTS.md` and `AGENTS_tasks.md` at the vault root.
- Tasks use the Obsidian Tasks plugin emoji syntax. Scheduled = `⏳ YYYY-MM-DD`, Due = `📅 YYYY-MM-DD`.
- Tasks live primarily in `todo.md` files inside `projects/<name>/` and `areas/<name>/`.
- Each area or project may have a `summary.md`, a top-of-file description in `todo.md`, or sibling minutes folders that hold relevant context.

## Workflow

### 1. Determine today's date

Use the current local date in `YYYY-MM-DD` form. Do not ask the user — derive it from the environment.

### 2. Find today's tasks

Run ripgrep from the vault root to surface every task scheduled or due today. Use these two queries (per `AGENTS_tasks.md`):

```bash
rg "⏳ $(date +%Y-%m-%d)" --glob '!archive/**' --glob '!cold_storage/**'
rg "📅 $(date +%Y-%m-%d)" --glob '!archive/**' --glob '!cold_storage/**'
```

Capture the file path and the full task line for each hit. Deduplicate tasks that appear in both result sets (a task can be both scheduled and due today).

Skip:
- Tasks already marked `[x]` (done) or `[-]` (cancelled).
- Tasks inside `archive/` or `cold_storage/` directories.

### 3. Group and add context

Group tasks by their containing area or project (the path segment after `areas/` or `projects/`).

For each group, gather lightweight context — enough to ground the user, not a full briefing on the project:

- Read the top of the area's or project's `todo.md` (the title line and any short description).
- If the area/project has a `summary.md` at its root, read its first ~30 lines.
- Look at the most recent meeting summary, if one exists, by listing `minutes/` and reading the newest `summary.md`.

Do not read every file. Two or three short reads per group is plenty. The briefing is meant to orient, not exhaust.

### 4. Compose the briefing

Write a compact markdown document with this structure:

```markdown
# Daily Brief — YYYY-MM-DD

> N tasks on the schedule across M areas/projects.

## <area or project name>

**Context.** One or two sentences drawn from the area/project context — what is this work, what was the most recent movement.

- [ ] Task description ⏳ YYYY-MM-DD — `path/to/todo.md`
- [ ] Another task 📅 YYYY-MM-DD — `path/to/todo.md`

## <next area or project>
...

## Loose threads

Any tasks that didn't map cleanly to an area or project. Same format.
```

Rules for the briefing body:
- Keep "Context" to 1–2 sentences. The point is recall, not summary.
- Preserve the task's original emoji metadata (scheduled, due, priority, tags). Don't rewrite the task text.
- Include the source file path after each task, in backticks, so the user can jump to it.
- If a task has a priority emoji (🔺 ⏫ 🔼 🔽 ⏬), sort tasks within each group by priority (highest first), then by due > scheduled.
- If there are no tasks today, write a one-line briefing saying so and stop. Don't pad the file.

### 5. Confirm and write

Before writing:
- Show the user a one-line summary: "N tasks across M areas. Write to `dailies/YYYY-MM-DD-daily-brief.md`?"
- On confirmation (or if the user asked for the brief directly and clearly wants it written), write the file.

## Scope limits (first pass)

This is a first-pass skill. Keep it tight:

- Only today's `⏳` and `📅` tasks. No look-ahead, no overdue sweep, no calendar integration.
- No interactive question/answer flow. The briefing is generated, not co-authored.
- No editing of `todo.md` files. Read only.
- No Granola / meeting fetching. Use whatever summaries already exist on disk.

If the user asks for any of the above, treat it as a follow-up enhancement rather than expanding this run.
