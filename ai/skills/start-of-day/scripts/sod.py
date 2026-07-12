#!/usr/bin/env python3
"""start-of-day — walk a fixed morning checklist and log findings.

Run from the root of the Obsidian vault. The log lives at
`dailies/<today>-sod-log.md` and is the source of truth: every step has one
`_Findings:_` line, so the file itself records how far you got. The agent
tracks the current step number in conversation; if it ever loses its place,
`status` reads the file and reports the next step still awaiting findings.

Subcommands:
    prompt N            show step N
    record N "<text>"   write findings into step N's slot (creates the log)
    status              report the next step still awaiting findings

The single daily focus is just a step (see STEPS), recorded like any other.
Edit STEPS to change the routine; the order here is the run order.
"""

import argparse
import os
import sys
from dataclasses import dataclass
from datetime import date
from pathlib import Path

from urls import (
    COST_ANALYSIS_URLS,
    DATADOG_DASHBOARD_URLS,
    GITLAB_MR_URLS,
    INCIDENTS_URLS,
    JIRA_BOARD_URLS,
    SECURITY_URLS,
    UrlEntry,
)

FINDINGS_MARKER: str = "_Findings:_"


def _fmt_urls(label: str, entries: list[UrlEntry]) -> list[str]:
    """Return label + indented 'name: url' lines, or a single '[url TBD]' line when empty."""
    if not entries:
        return [f"{label}  [url TBD]"]
    return [label] + [f"  {e['label']}: {e['url']}" for e in entries]


def _people_in(group: str) -> list[str]:
    """Person folder names under areas/people_management/<group>, sorted."""
    base = Path("areas/people_management") / group
    if not base.is_dir():
        return []
    return sorted(
        p.name for p in base.iterdir() if p.is_dir() and (p / "index.md").exists()
    )


def _people_items() -> list[str]:
    """Grouped roster lines: direct reports first, then the wider domain staff."""
    direct = _people_in("direct_reports")
    domain = _people_in("domain_staff")
    items: list[str] = []
    if direct:
        items.append("Direct reports:")
        items += [f"  {name}" for name in direct]
    if domain:
        items.append("Domain staff (in my org, not direct reports):")
        items += [f"  {name}" for name in domain]
    return items


@dataclass(frozen=True)
class Step:
    phase: str          # which part of the morning this belongs to
    title: str          # the one-line name of the step
    prompt: str         # the question this step is really asking
    look_at: list[str]  # concrete things to check; "[url TBD]" = wire up later


def _build_steps() -> list[Step]:
    people_items = _people_items() or [
        "(no people found in areas/people_management/{direct_reports,domain_staff})"
    ]
    return [
    Step(
        phase="Systems health",
        title="Social health — the people side",
        prompt="How is the team really doing? Scan for mood, energy, friction, and anything left unsaid.",
        look_at=[
            "Think through each person:",
            *[f"  {name}" for name in people_items],
            "Anyone stuck, quiet, overloaded, or in conflict?",
            "Carry anything heavy forward into today's focus.",
        ],
    ),
    Step(
        phase="Systems health",
        title="Delivery health — does work flow?",
        prompt="Is work moving predictably from start to done?",
        look_at=[
            *_fmt_urls("GitLab: open MRs awaiting review, review latency, throughput.", GITLAB_MR_URLS),
            *_fmt_urls("Jira: WIP, lead time, cycle time, epic progress.", JIRA_BOARD_URLS),
        ],
    ),
    Step(
        phase="Systems health",
        title="Operational health — stable, safe, affordable?",
        prompt="Is production healthy and inside its guardrails?",
        look_at=[
            *_fmt_urls("Datadog dashboards.", DATADOG_DASHBOARD_URLS),
            *_fmt_urls("Open incidents / pending RCAs.", INCIDENTS_URLS),
            *_fmt_urls("Cost analysis across tools.", COST_ANALYSIS_URLS),
            *_fmt_urls("Security vulnerabilities.", SECURITY_URLS),
        ],
    ),
    Step(
        phase="Systems health",
        title="Personal health — the life side",
        prompt="How are you really doing, outside the org chart? Free-form — one honest sentence beats a checklist.",
        look_at=[
            "Healthy Mind Platter — which have been fed lately, which are starving?",
            "  sleep time / physical time / focus time / connecting time / play time / down time / time-in",
            "Any personal project or life admin quietly becoming urgent?",
        ],
    ),
    Step(
        phase="The day ahead",
        title="Meeting work for today",
        prompt="What does each of today's meetings actually need from you?",
        look_at=[
            "Per meeting: prep, decisions to drive, materials to bring.",
            "Flag any meeting you're not yet ready for.",
        ],
    ),
    Step(
        phase="The day ahead",
        title="Eisenhower review",
        prompt="Where is your attention going versus where it should go?",
        look_at=[
            "Place projects on urgent x important.",
            "Work and personal share the canvas (blue work, green personal, purple both, red urgent) — let them compete honestly.",
            "Watch for urgent-not-important work crowding out important-not-urgent work.",
        ],
    ),
    Step(
        phase="The day ahead",
        title="Taskmaster alignment",
        prompt="Are you working on what you actually intend to?",
        look_at=[
            "Open taskmaster.md in Obsidian (everything; taskmaster_work.md / taskmaster_personal.md narrow it).",
            "Do the queued projects match where you want your energy this week?",
        ],
    ),
    Step(
        phase="Commit",
        title="Set the single focus",
        prompt="Name the ONE thing that, if it is the only thing that moves today, makes today a win.",
        look_at=[
            "Say it in one sentence. Read it back so it's locked in.",
        ],
    ),
    Step(
        phase="Commit",
        title="Commit & capture",
        prompt="Lock the focus and catch the loose threads.",
        look_at=[
            "Restate the focus out loud.",
            "Capture follow-ups, blockers, or risks surfaced in earlier steps before they evaporate.",
        ],
    ),
    ]


STEPS: list[Step] = _build_steps()


# --------------------------------------------------------------------------- #
# Rendering
# --------------------------------------------------------------------------- #

def render_prompt(step: Step, number: int) -> str:
    lines = [
        f"[{step.phase}]  Step {number} of {len(STEPS)}",
        "",
        step.title,
        step.prompt,
        "",
        "Look at:",
    ]
    lines += [f"- {item}" for item in step.look_at]
    return "\n".join(lines)


def render_skeleton() -> list[str]:
    """The fill-in-the-blanks log: one _Findings:_ line per step, in order."""
    today = date.today().isoformat()
    lines = ["---", f"date: {today}", "type: sod-log", "---", "", f"# Start of Day — {today}"]
    last_phase: str | None = None
    for step in STEPS:
        if step.phase != last_phase:
            lines += ["", f"## {step.phase}"]
            last_phase = step.phase
        lines += ["", f"### {step.title}", FINDINGS_MARKER]
    return lines


# --------------------------------------------------------------------------- #
# Log file — the file on disk is the source of truth
# --------------------------------------------------------------------------- #

def log_path() -> str:
    return os.path.join("dailies", f"{date.today().isoformat()}-sod-log.md")


def load_log() -> list[str]:
    """Read the log, creating today's skeleton on first use."""
    path = log_path()
    if not os.path.exists(path):
        save_log(render_skeleton())
    with open(path, encoding="utf-8") as handle:
        return handle.read().splitlines()


def save_log(lines: list[str]) -> None:
    os.makedirs("dailies", exist_ok=True)
    with open(log_path(), "w", encoding="utf-8") as handle:
        handle.write("\n".join(lines) + "\n")


def findings_slots(lines: list[str]) -> list[int]:
    """Line numbers of every _Findings:_ slot, in step order."""
    return [i for i, line in enumerate(lines) if line.startswith(FINDINGS_MARKER)]


def valid_step(n: int) -> bool:
    return 1 <= n <= len(STEPS)


# --------------------------------------------------------------------------- #
# Subcommands
# --------------------------------------------------------------------------- #

def cmd_prompt(step: int) -> str:
    if not valid_step(step):
        return f"No step {step}. There are {len(STEPS)} (1–{len(STEPS)})."
    return render_prompt(STEPS[step - 1], step)


def cmd_record(step: int, text: str) -> str:
    if not valid_step(step):
        return f"No step {step}. There are {len(STEPS)} (1–{len(STEPS)})."
    lines = load_log()
    lines[findings_slots(lines)[step - 1]] = f"{FINDINGS_MARKER} {text}"
    save_log(lines)
    return f"Recorded step {step}: {STEPS[step - 1].title}"


def cmd_status() -> str:
    lines = load_log()
    for step, slot in enumerate(findings_slots(lines), start=1):
        if lines[slot].strip() == FINDINGS_MARKER:
            return f"Awaiting findings: step {step} of {len(STEPS)} — {STEPS[step - 1].title}"
    return f"All {len(STEPS)} steps recorded — day is logged."


# --------------------------------------------------------------------------- #
# CLI
# --------------------------------------------------------------------------- #

def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(prog="sod.py", description="Start-of-day checklist.")
    sub = parser.add_subparsers(dest="command", required=True)

    p = sub.add_parser("prompt", help="show step N")
    p.add_argument("step", type=int)
    p.set_defaults(run=lambda a: cmd_prompt(a.step))

    r = sub.add_parser("record", help="write findings into step N")
    r.add_argument("step", type=int)
    r.add_argument("text", nargs="+", help="the findings (quote them)")
    r.set_defaults(run=lambda a: cmd_record(a.step, " ".join(a.text)))

    s = sub.add_parser("status", help="report the next step awaiting findings")
    s.set_defaults(run=lambda a: cmd_status())

    return parser


def require_vault_root() -> None:
    """Refuse to run outside an Obsidian work vault root (cwd)."""
    if not Path("areas").is_dir() or not Path("dailies").is_dir():
        sys.exit(
            f"error: {Path.cwd()} does not look like an Obsidian work vault "
            "(missing areas/ or dailies/). Run this from the vault root."
        )


def main() -> None:
    require_vault_root()
    args = build_parser().parse_args()
    print(args.run(args))


if __name__ == "__main__":
    main()
