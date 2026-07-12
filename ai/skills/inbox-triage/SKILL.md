---
name: inbox-triage
description: Route captured items into the Obsidian vault — either a single prompt ("get the gutters cleaned before winter") or a sweep of the inbox. Each item becomes a task in an existing project/area todo.md or a newly scaffolded project; nothing is written without confirmation. Use when the user wants to capture a task or idea, triage the inbox, empty the inbox, "put this somewhere", or invokes /inbox-triage.
---

# Inbox Triage

Every item ends up with exactly one home. **Run from the root of the Obsidian
vault.** Follow the vault's `AGENTS_tasks.md` for task format and
`AGENTS_projects.md` for project creation — load them before writing anything.

## Two entry points

**Direct capture** — the user hands you one thing to do ("triage: fix the
bike light"). Route just that item.

**Sweep** — invoked with nothing to route. Walk `inbox.md` (captured lines)
and `inbox/` (captured files) item by item, oldest first, and route each one.
Remove routed items from the inbox as you go; the goal of a sweep is an empty
inbox — every item gets a destination or is dropped with the user's consent.

## Routing an item

1. **Match against existing work.** Read `projects/index.md` and
   `areas/index.md`, then the candidate folder's `index.md`. If the item
   belongs to an existing project or area, it becomes a task in that
   `todo.md`.
2. **Or scaffold a new project.** If it's genuinely new multi-step work with
   an end state, create a project per `AGENTS_projects.md` — folder,
   `index.md` and `todo.md` (both with frontmatter including `lens`), canvas
   node in the right quadrant. Ask which lens if it isn't obvious.
3. **Or neither.** Reference material goes to `resources/`; dead or
   rhetorical items get dropped. Say so rather than forcing a task.

A task inherits its context from the file it lands in — routing IS the lens
decision, so pick the destination deliberately.

## Task format

Per `AGENTS_tasks.md`: emoji syntax, `➕` today, and **every task gets a
`⏳` scheduled date**. If the item implies a date, use it. If not, do not
guess a fake one — rewrite the description to begin with `Schedule...` and
set `⏳` to tomorrow so a real scheduling decision surfaces.

## Propose first, write second

Same contract as the daily-debrief's task proposals:

1. For each item, state: the item, the destination file (or new project
   name), the exact task line (or scaffold summary).
2. Wait for the user: write as proposed, edit, redirect, or skip. **One item
   at a time; silence is not approval.**
3. Only then write it — and on a sweep, remove the item from the inbox in
   the same step.
4. End with a summary of what went where and what was dropped.

## Hard rules

- Never bulk-move inbox items to another holding file — that's relocating
  the pile, not triage.
- Check the destination `todo.md` for a near-duplicate before proposing;
  prefer updating the existing task.
- Don't invent tasks the user didn't capture. Ambiguous scraps (a bare URL,
  a cryptic phrase) get one clarifying question, and stay in the inbox if
  the user can't place them either.
- Deleting an item always requires explicit consent.
