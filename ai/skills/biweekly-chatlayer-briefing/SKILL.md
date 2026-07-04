---
name: biweekly-chatlayer-briefing
description: Build a bi-weekly Chatlayer briefing — talking points organized from corporate (Sinch) down through the agentic conversations domain, product (Chatlayer/Engage), and team levels (flow engine, intelligence, platform & integrations, AI agents). Pulls the last two calendar weeks of daily debriefs and meeting summaries. Writes a markdown file to `areas/engineering_management/briefings/`. Use whenever the user asks for a bi-weekly chatlayer briefing, a chatlayer biweekly, a team-level update, a Sinch/Chatlayer roll-up across teams, or invokes /biweekly-chatlayer-briefing. Trigger on phrases like "bi-weekly chatlayer briefing", "biweekly briefing for the teams", or "prep a chatlayer update for the team".
---

# Bi-weekly Chatlayer Briefing

Builds a briefing JR can both **share as text** and **review in person** with the teams. Talking-point format, organized top-down by scope.

The work has two phases:

1. **Fetch** — deterministic, script-driven. Find every relevant source file in the window.
2. **Synthesize** — conversational. Read the files, distill talking points, write the briefing.

## Output destination

`areas/engineering_management/briefings/YYYY-MM-DD-chatlayer-biweekly-briefing.md`
(use today's date as the YYYY-MM-DD prefix; create the `briefings/` directory if it doesn't exist).

If a briefing already exists for today, ask before overwriting.

## Briefing structure

Exactly these sections, in this order:

```markdown
# Chatlayer bi-weekly briefing — YYYY-MM-DD
*Window: YYYY-MM-DD → YYYY-MM-DD*

## Corporate / Sinch
- Talking point.
- ...

## Conversations (agentic orchestration domain)
- ...

## Product
### Chatlayer
- ...
### Engage
- ...

## Teams
### Flow Engine
- ...
### Intelligence
- ...
### Platform & Integrations
- ...
### AI Agents
- ...
```

If a section has no material in the window, write `_(nothing notable this period)_` rather than omitting the heading — the headings are part of the contract with the audience.

Drop the **Engage** subsection if no Engage-related material surfaced (no separate area exists yet; it shows up incidentally via chatlayer/customer notes).

## Workflow

### 1. Confirm the date window

Default to **the last 14 days inclusive** (today minus 13 → today). Show the dates and ask:

> Pulling content from `<start>` to `<end>`. OK, or do you want a different window?

Don't proceed until JR confirms or specifies. He may want calendar weeks (the previous two Mon–Sun) or a custom range.

### 2. Run the fetch script

```bash
python3 ~/.claude/skills/biweekly-chatlayer-briefing/scripts/fetch_content.py <start> <end>
```

Must be run from the vault root (the script will refuse otherwise). It prints a manifest grouped by section:

```
## DAILIES (debriefs and briefings)
2026-05-13  dailies/2026-05-13-debrief.md
...
## CORPORATE / SINCH
2026-05-07  areas/engineering_management/minutes/.../summary.md
...
```

Each line is `YYYY-MM-DD  <path>`. Sections with no material are marked `_(none in window)_`.

### 3. Read the source files

Read every file in the manifest using the Read tool, in parallel batches. Prefer one batch per section (a typical two-week window yields 15–40 files total — well within reason to read them all). Only skip a file if it's obviously irrelevant after seeing the manifest path.

**Read summary.md only** — never transcripts. Summaries are the curated form; transcripts are raw and verbose.

### 4. Distill into talking points

For each section in the briefing structure, write **bulleted talking points** — short enough to read aloud, specific enough to anchor a conversation. Aim for 3–7 bullets per populated section; if there's more substance, group rather than expand.

Each bullet should be one of:

- **A decision or outcome** — "Decided X. Y will own follow-up."
- **A state change worth flagging** — "Grafana down in US cluster, ~2hr fix, top priority given OMF."
- **A risk or open question the audience should know about** — "DataDog contract ends end of year; migration to Prometheus needs an owner."
- **A people/process update** — "Tom drafting formal support-process proposal; target Wed/Thu."

Avoid:

- Restating meeting agendas or attendees.
- "Discussed X" with no outcome.
- Personal/private content from debriefs (e.g., JR's internal reflections about Simon's comp case). **Daily debriefs are inputs for context, not direct quotes**. Use them to understand what mattered and what's recurring; don't surface JR's private observations to the team verbatim.

Order bullets within each section by importance, not chronologically.

### 5. Compose and write

Write the file to `areas/engineering_management/briefings/YYYY-MM-DD-chatlayer-biweekly-briefing.md` with this frontmatter:

```yaml
---
type: briefing
status: active
summary: Bi-weekly chatlayer briefing covering <start> to <end>.
tags:
  - briefing
  - chatlayer
  - biweekly
---
```

Then the structured content from step 4.

After writing, print the briefing back to the chat so JR can scan it without opening the file.

## Source taxonomy (what feeds each section)

The fetch script handles routing automatically — listed here so you know what to expect and can adapt synthesis judgment.

- **Corporate / Sinch** — `areas/colleagues/lars/`, `areas/engineering_management/`, `areas/customers/`, `areas/intramural_teams/`, `areas/saas_suppliers/`. Lars syncs, eng-manager-level conversations, customer/vendor signals that affect the whole org.
- **Conversations (agentic orchestration domain)** — `areas/agentic_conversation_domain/`. The product-area-level domain above individual products.
- **Product (Chatlayer / Engage)** — `areas/chatlayer_product_area/`. Engage doesn't have its own area; surface it as a subsection only if something Engage-specific appears.
- **Team: Flow Engine** — `areas/flow_engine_team/`.
- **Team: Intelligence** — `areas/intelligence_team/`.
- **Team: Platform & Integrations** — `areas/platform_and_integrations_team/`.
- **Team: AI Agents** — `areas/ai_agents_team/`.
- **Dailies** — `dailies/*-debrief.md`, `dailies/*-daily-brief.md`. Context-only — for shaping emphasis and catching recurring threads, not for direct quotation.

## What this skill is not

- Not a meeting-by-meeting recap. It's a synthesis.
- Not personal/reflective — daily debriefs inform but don't appear in the output.
- Not a status report on every project — only what's worth raising with the teams.
- Not interactive line-editing. Generate the full briefing, then let JR ask for edits.
