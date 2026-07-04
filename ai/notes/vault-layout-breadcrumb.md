# Vault Layout Manifest Breadcrumb

This is a placeholder for a possible shared vault layout manifest used by the
vault-related skills:

- `start-of-day`
- `daily-debrief`
- `granola-meetings`
- `biweekly-chatlayer-briefing`
- `decision-helper`

## Why this might be worth doing

These skills all depend on the same work-vault topology:

- `dailies/`
- `areas/`
- `projects/`
- `areas/people_management/`
- `areas/*/minutes/`
- `projects/*/minutes/`
- briefing destinations under `areas/engineering_management/`

Right now that knowledge is split between Python scripts and prose inside
individual `SKILL.md` files. That is fine while the structure is stable, but a
vault rename or routing change would require edits in several places.

A small shared manifest would give the skills one interface for vault layout
and routing. Scripts could parse it; agents could read it. The skills would
declare which parts they consume instead of each restating the structure.

## Possible shape

The manifest could live at `ai/skills/vault-layout.md` or `ai/vault-layout.md`.

```yaml
---
schema: localetc.vault-layout.v1
default_vault: work

vaults:
  work:
    env: WORKSIDIAN
    required_roots:
      - areas
      - projects
      - dailies

  personal:
    env: OBSIDIAN
    required_roots:
      - areas
      - dailies

paths:
  dailies:
    daily_debrief: "dailies/{date}-debrief.md"
    start_of_day_log: "dailies/{date}-sod-log.md"

  decisions:
    note: "areas/decisions/{timestamp}-{slug}.md"
    index: areas/decisions/index.md

  meetings:
    folder_name: "{date}_{time}_{title_slug}"
    summary_file: summary.md
    minutes_dir: minutes
    fallback: daily_work/meetings

  briefings:
    chatlayer_biweekly: "areas/engineering_management/briefings/{date}-chatlayer-biweekly-briefing.md"

routing:
  meeting_destinations:
    direct_report_1x1: "areas/people_management/{person}"
    boss_1x1: "areas/people_management/peers/stefan"
    peer_1x1: "areas/people_management/peers/{person}"
    project_meeting: "projects/{project}/minutes"
    area_meeting: "areas/{area}/minutes"
    unclassified: "daily_work/meetings"

  briefing_sources:
    corporate_sinch:
      - areas/colleagues/lars
      - areas/engineering_management
      - areas/customers
      - areas/intramural_teams
      - areas/saas_suppliers
    conversations:
      - areas/agentic_conversation_domain
    product:
      - areas/chatlayer_product_area
    teams:
      flow_engine:
        - areas/flow_engine_team
      intelligence:
        - areas/intelligence_team
      platform_and_integrations:
        - areas/platform_and_integrations_team
      ai_agents:
        - areas/ai_agents_team

skills:
  start-of-day:
    vault: work
    reads:
      - people_management.direct_reports
    writes:
      - dailies.start_of_day_log

  daily-debrief:
    vault: work
    reads:
      - dailies
      - meetings
      - projects
      - areas
    writes:
      - dailies.daily_debrief
      - project_or_area_todos

  granola-meetings:
    vault: work
    reads:
      - people_management
      - projects
      - areas
    writes:
      - meetings.summary_file

  biweekly-chatlayer-briefing:
    vault: work
    reads:
      - dailies
      - routing.briefing_sources
    writes:
      - briefings.chatlayer_biweekly
---
```

Each skill could then keep only a pointer in its own frontmatter:

```yaml
---
name: start-of-day
description: Interactive start-of-day walkthrough...
vault_layout: localetc.vault-layout.v1
vault_layout_file: ../vault-layout.md
vault: work
---
```

## Smallest next step

Do not migrate everything at once. Start with `biweekly-chatlayer-briefing`,
because it already has deterministic routing in
`scripts/fetch_content.py`. Move its `SECTIONS` list into a manifest, add a
parser test, and leave the skill behavior unchanged.

If that feels better after one use, move `start-of-day` URL groups next.
