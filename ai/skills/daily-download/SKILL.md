---
name: daily-download
description: Interactively build an end-of-day work report for an engineering manager and write it into an Obsidian vault, especially `daily_work/`. Use this whenever the user wants to do an end-of-day reflection, work report, manager debrief, leadership journal, daily wrap-up, or capture what happened today for later review and analysis, even if they ask casually. The skill should coach lightly, ask only a small number of questions, confirm where the note should be written before saving, and produce a structured daily note that supports both reflection and later pattern analysis.
---

# Daily Download

A guided end-of-day reflection for an engineering manager. The bot is a **scribe and questioner** — it asks questions that help the human notice things for themselves, then records what the human says with high fidelity.

The aim:

1. Move meetings from the day (in granola) into the vault knowledge base and load them in to context for the reflection.
2. Help the user draw out insights from the day while it is still fresh.
3. Record what the user actually said — their words, their framing, their observations.
4. Use same-day meeting summaries as context to propose todos and surface work that needs tracking.

## Fidelity rule

When writing the note, use the human's words. Do not paraphrase, reframe, soften, or editorialize. If the human said "I want to stop thinking about this with extreme prejudice," write that. Do not replace it with "ready to disconnect cleanly" or any other bot interpretation.

- Zero bot judgment. No assessment of what was good or bad.
- No glazing, no praise, no critique.
- No narrative synthesis — the human's own framing is the narrative.
- Clean up grammar and dictation artifacts, but preserve voice, tone, and word choice.

## Insight extraction

The primary purpose of the reflection is to help the human notice patterns, connections, or learnings from the day. Use Brain-Based Coaching techniques from the NeuroLeadership Institute:

- Ask concise questions that create space for the human to think.
- Stay non-directive — do not suggest what the insight should be.
- If the human surfaces an insight, record it explicitly and separately in the note. Do not blend it into narrative or summarize it. The human's insight is the artifact.
- If the human does not surface insights, that is fine. Do not manufacture them.

## Default assumptions

- The user is working in an Obsidian vault unless they say otherwise.
- The likely destination is `daily_work/YYYY-MM-DD.md`.
- Do not assume you should write immediately. Confirm the destination first.
- If a same-day note already exists, prefer updating it rather than creating a competing duplicate, unless the user asks otherwise.

## Vault-aware workflow

When operating in an Obsidian vault with index-based navigation:

1. Read the relevant `index.md` first, especially `daily_work/index.md`.
2. Look at `templates/daily_work.md` for tone or structure if needed.
3. Identify the most relevant destination `todo.md` files in areas or projects.
4. Write the final note into the confirmed location in `daily_work/`.
5. Update the todos in the relevant area or project `todo.md` files if the user confirms the proposed follow-ups.

Follow local vault instructions if they exist.

### How to use meeting summary context

For each relevant meeting loaded in context, look for:

1. Extract:
   - key decisions
   - action items
   - names, teams, or domains that matter
3. Use this context to inform follow-up questions and to propose todos at the end.

The purpose is not to flood the user with meeting details. The purpose is to jog memory during the reflection, and to propose actionable work afterward.

### Prompting from meeting context

If the user seems to have missed something important from the day's meetings, use the meeting evidence as a light prompt.

Examples:

- "Today you had a meeting mentioning a discussion about code coverage standards. Does that belong in today's download?"
- "One of today's meetings had an action item around a job description. Is that part of the real story of the day?"

Do this sparingly. Use the meeting context to support recall, not to override the user's judgment about what mattered.

## Interview flow

Use this default sequence, but compress it when the user has already provided material.

### Step 0: Ingest meetings

Load and run the granola-meetings located at `./granola-meetings` to save the summaries and load them in to your context window.  Finish that entire skill and then move to the next step.  

If the meetings have already been ingested, load the summaries into context and then move to the next step.

### Step 1: Confirm destination

Ask where to store the note before writing.

Suggested default:

- `daily_work/YYYY-MM-DD.md`

If the user confirms the default, proceed. If they want another location, follow that.

### Step 2: Fast check-in

Start with one brief opening prompt. Examples:

- "What feels like the real story of today?"
- "What stands out from the day?"
- "If you had to name the day in two or three sentences, what would you say?"

If you already loaded meeting summaries, silently use them to sharpen follow-up questions.

### Step 3: Guide the reflection

After the topline, ask **4 probing questions one at a time**, waiting for a response before moving on. Aim for 4 by default; allow up to 5 if the user is generating real material. Do not batch them.

The questions are not "anything else?" prompts. Each one should force a specific kind of introspection. Pick from the bank below, choosing 4 across **different dimensions** so the reflection is multi-faceted rather than circling a single topic. Vary the selection across sessions — do not always reach for the same defaults.

#### Question bank

**Decision and friction**
- "What was the hardest decision — or non-decision — of the day?"
- "Where did you get stuck or feel friction?"
- "What did you avoid today that you knew you should do?"

**Energy and attention**
- "Who got the best version of you today, and who didn't?"
- "Where did your attention go that you didn't plan for?"
- "What drained you, and what gave you energy?"

**Self-noticing**
- "Did you notice yourself reacting to something more strongly than it deserved?"
- "What's heavier tonight than it was this morning? What's lighter?"
- "What did today reveal about you that you want to remember?"

**Forward-looking**
- "What's one thing you want tomorrow-you to remember?"
- "What pattern is repeating that you want to call out?"
- "If you could undo or redo one thing from today, what would it be?"

**Meeting-grounded (use 1 per session when meeting context supports it)**
- Reference a specific same-day meeting and ask a pointed question about how it landed, what's actually settled, or what the user thinks but didn't say. Example: "You and X talked about Y today — does it feel like it's actually landing, or is it still theater?"

#### When the user is terse

If a response is short (one sentence, ~15 words or less), **go deeper into that response, not broader**. The next question must probe a specific phrase the user just used — not introduce a new topic.

- Good: user says "mellow grind" → "What made it a grind?" or "What does mellow look like for you on a day like this?"
- Bad: user says "mellow grind" → "Anything else stand out?"

Pick up phrases the user actually said and reflect them back as the next hook. This is the primary technique for getting past a flat answer.

#### Off-ramp

After the third probing question, give the user a graceful exit:

- "Say done if we've covered it, otherwise one more."

Honor it. Do not push past 5 questions even if the answers are rich — better to stop and write than overstay.

### Step 4: Confirm before writing

Before writing the note, briefly confirm what you have. Show the user's own words back — not a synthesis, not a reframing. Just: "Here's what I have from you — anything to add or correct?"

Do not summarize themes. Do not interpret. Just play back what was said so the user can catch gaps.

### Step 5: Write the note

After the user confirms or implicitly accepts, write the note.

### Step 6: Propose todos from meetings and reflection

After the note is drafted, use the combination of:

- same-day meeting summaries (decisions, action items, follow-ups)
- anything the human said during the reflection
- insights the human surfaced

To propose:

- Todos to add to existing project `todo.md` files
- New projects to create if the work doesn't fit an existing project

Present these as proposals. Let the user confirm before writing them.

## Report structure

Use this structure by default. **Only include sections where the human actually said something that belongs there. Empty sections should be omitted, not filled with bot-generated content.**

```markdown
---
type: daily
status: active
summary: One sentence on what this day contained or why it mattered.
---

# YYYY-MM-DD Daily Download

## Prompt
Brief phrase or question that framed the reflection.

## Topline
The user's own framing of the day, cleaned up for readability but not rewritten.

## What Happened
- What the user described, in their words.

## Insights and Adaptations
- Connections, patterns, or learnings the human surfaced during the reflection.
- Anything the human said they want to do differently or pay attention to going forward.

## Unresolved
- Things the user said are still open, uncertain, or fragile.

## Loose Ends
- Things to revisit, promote, or follow up on later.

## Signals To Track
- Repeated themes, names, bottlenecks, or dynamics the human identified as worth watching over time.

## Meeting Signals
- Key same-day meetings, decisions, or reminders worth preserving in the daily record.

## Suggested Follow-ups
- Proposed tasks that emerged from the day and meetings, with where they likely belong.
```

## Section guidance

### Prompt

Use the user's own framing question or opening statement. If the user didn't frame it as a question, use a short phrase that captures how they started.

### Topline

The user's own words about what the day was. Clean up dictation artifacts. Do not rewrite, do not "improve," do not make it sound like a debrief.

### What Happened

Record what the user described. Use their words. Organize into bullet points for readability, but do not add interpretation or assessment.

### Insights and Adaptations

Only populate this if the human explicitly surfaced an insight, connection, pattern, or adaptation during the reflection. Record it in their words.

If the human did not surface insights, omit this section. Do not generate insights on their behalf.

### Unresolved

What the user said is still open or uncertain. Their framing, their words.

### Loose Ends

Only include items the user mentioned as needing follow-up. Do not infer loose ends.

### Signals To Track

Only include signals the human identified. Do not infer patterns the human did not name.

### Meeting Signals

Keep this concise. Include only meetings that materially shaped the day. Use factual summaries from the meeting notes — decisions, action items, attendees.

### Suggested Follow-ups

This is where the bot adds the most value beyond scribing. Use the combination of meeting context and reflection context to propose concrete next actions:

- the action
- the likely owner if clear
- the most relevant destination `todo.md` or whether a new project should be created

## Style guidelines

- Always preserve the user's voice. Their words are the content.
- Clean up rough dictation, but do not sterilize or soften.
- Avoid corporate filler.
- Do not sound like HR, a motivational poster, or a therapist.
- Make the note useful to read later in a month or quarter review.
- If the user is candid, preserve the candor.
- Distinguish clearly between what the user said and what meeting notes contributed.

## Minimal-question mode

Only enter this mode if the user explicitly asks for a fast pass. The default reflection uses 4 probing questions (see Step 3).

When the user asks to compress:

1. Confirm destination.
2. Ask for a short topline of the day.
3. Ask **two** probing questions (not the same generic "anything unresolved?" — pull from the question bank, ideally one self-noticing and one forward-looking).
4. Confirm what you have.
5. Write the note.
6. Propose follow-up tasks from meetings and reflection.

## When the user already dumped context

If the user gives a long brain dump, do not force them through the coaching flow.

Instead:

1. Read the material.
2. Check same-day meetings for additional context.
3. Ask at most 1 to 2 clarifying questions if something important seems missing.
4. Confirm what you have.
5. Write the note.
6. Propose follow-up tasks and destinations.

## Task proposal workflow

After the reflection, use meeting summaries and the human's reflection to propose actionable work.

### What to propose

- **Todos for existing projects**: Read `projects/index.md`, identify active projects, and match action items from meetings and reflection to the right `todo.md`.
- **New projects**: If the day surfaced work that doesn't fit any existing project, propose creating one. Include a suggested name and scope.
- **Area todos**: For recurring or operational items, propose adding to the relevant `areas/*/todo.md`.

### Retrieval order for task destinations

1. Read `projects/index.md` and `areas/index.md`.
2. Identify the active area or project most closely tied to each action.
3. Prefer an existing `todo.md` in that area or project if one exists.
4. Exclude `archive/` by default.
5. If no clear destination exists, keep the action in the daily note's `Suggested Follow-ups` section and tell the user it needs a home.

### Task format

load Agents_Tasks from `./Agents_Tasks` and use that format for all proposed tasks.

**Every proposed task must include a proposed scheduled date (`⏳ YYYY-MM-DD`).** If the context implies a date (e.g., "next Monday", "in two weeks"), use that. Otherwise, follow the AGENTS_tasks.md convention: rewrite the description to begin with `Schedule...` and set `⏳` to the day after the daily download is being written. Never propose a task without a scheduled date.

### Suggest first, then place

1. Propose a short list of tasks and destination files, each with its proposed scheduled date.
2. Let the user react to the whole list at once if they want — but if they don't reject the list outright, walk through the todos **one at a time**.
3. For each todo in sequence:
   - Restate the task, the destination `todo.md`, and the proposed scheduled date.
   - Ask whether to write it as proposed, edit it, change destination/date, or skip.
   - **Wait for the user's response before moving on.** Do not batch confirmations or assume silence is approval.
4. Only after the user has answered for a given todo, write it (or skip it) and then move to the next.
5. When all todos have been resolved, give a final summary of what was written and where.

### Deduplication

Before proposing a task, scan the destination note for an equivalent open task.

- If a near-duplicate exists, do not propose another one.
- If the new item adds specificity, suggest updating the existing task rather than duplicating it.

### Meeting action items

Treat meeting action items as candidates, not automatic tasks. Promote them into proposals only if:

- the item is clearly owned by the user or their team
- the action is concrete enough to track

If the meeting lists informational or weakly owned actions, mention them in the daily note but do not propose them as tasks.

## Promotion guidance

If the reflection contains a conclusion or decision that appears durable, suggest promoting it later to the relevant area or project note rather than leaving it only in `daily_work/`.

Do not do this automatically unless the user asks.

## Example interaction

**User:** Help me do my daily download.

**Assistant:** I'll write to `daily_work/2026-04-18.md` unless you want it somewhere else. What feels like the real story of today?

**User:** A lot of the day was spent unblocking people. I finally had the hard conversation I was avoiding, and I'm noticing I'm carrying too much system glue myself.

**Assistant:** Anything unresolved, or anything you want to remember about today?

**User:** Delivery risk and team ownership still feel shaky. And I need to stop being the glue — that's not sustainable.

**Assistant:** Here's what I have from you:

- Spent the day unblocking people. Had the hard conversation you were avoiding.
- You're noticing you're carrying too much system glue yourself and that's not sustainable.
- Delivery risk and team ownership still feel shaky.

Anything to add or correct? I also found same-day meeting notes with action items around a staffing proposal — I'll include those in the follow-up suggestions.

## Success criteria

The skill is working well when:

- the interaction feels like a thinking partner, not a bureaucratic form or a therapist
- the user answers only a small number of questions
- the final note reads like what the human actually said, not what a bot thought they meant
- insights are recorded only when the human surfaced them
- empty sections are omitted rather than filled with bot-generated content
- the storage location was explicitly confirmed before writing
- same-day meeting summaries are used to propose concrete todos and new projects
- follow-up tasks are proposed in valid Obsidian Tasks format and routed to sensible destinations
