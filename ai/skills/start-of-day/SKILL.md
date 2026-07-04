---
name: start-of-day
description: Interactive start-of-day walkthrough that guides the user step-by-step through a fixed morning routine — sociotechnical systems health (social, delivery, operational), the day's meeting work, an Eisenhower-matrix project review, taskmaster alignment, and setting a single daily focus. Shows ONE step at a time, captures findings per step, and writes them to a dated log. Use when the user wants to start the day, run the morning routine, says "start my day", "morning checklist", "begin start of day", "let's start the day", or invokes /start-of-day.
---

# Start of Day

An interactive walkthrough of the user's morning routine. The steps live in the
bundled script so they're shown verbatim, and each step's findings are written
straight to `dailies/<today>-sod-log.md` as you go. **Run this from the root of
the worksidian vault (`~/worksidian`).**

Script: `python3 ~/etc/ai/skills/start-of-day/scripts/sod.py <subcommand>`

## How to run it

You track one thing: the current step number `N`, starting at `1`.

Loop, for each step:

1. `sod.py prompt N` — show its output to the user **exactly as printed**. Don't summarize, reword, or add steps.
2. Wait. As the user works the step, collect their findings (whatever they observed or decided). It's fine to ask "anything to log?" once, but don't nag.
3. When the user is ready to move on, write the findings: `sod.py record N "<their findings, their words>"`. If they had nothing, record a short `"—"`.
4. `N = N + 1`, loop.

When `prompt N` reports there's no such step, you're done. Read the user's focus (the "Set the single focus" step) back in one line and stop.

If you ever lose your place — context dropped, unsure of `N` — run `sod.py status`. It reads the log and tells you the next step still awaiting findings. Resume there. Never guess `N` or restart.

## Hard rules

- One step on screen at a time. Never run `prompt` for several numbers at once.
- Never advance on your own — a step ends only when the user says so.
- Record findings in the user's words. Don't editorialize or invent observations.
- Never invent, reorder, or skip steps. If it didn't come from the script, don't say it.
- Don't do the work for the user or fetch anything. The steps are prompts for *the user* to act on.

## Changing the routine

Steps are Python `Step` dataclasses in `scripts/sod.py` — edit that list to add,
remove, or reorder steps, or to replace a `[url TBD]` with a real link. The log
skeleton and `status` tracking follow the list automatically.
