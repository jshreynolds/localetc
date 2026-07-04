# WorkSidian Index Design Report

Date: 2026-07-04

Scope: read-only inspection of `~/worksidian`, focused on whether the vault can
keep useful `index.md` context while avoiding manually maintained path and
inventory drift.

## Executive Summary

Yes: the vault can have the best parts of the current model, but only if
`index.md` files stop acting as manually maintained inventories.

The better design is a three-part split:

1. `index.md` files describe local meaning and use.
2. frontmatter describes note identity, status, and classification.
3. generated views or reports provide pathing, lists, and inventory.

This is a better fit than the earlier "shared vault layout manifest" idea. A
manifest is useful for stable routing contracts, but it should not become a
hand-maintained catalog of projects, people, meetings, and paths. The
filesystem and frontmatter already contain most of that data. The missing piece
is a thin generated discovery layer.

## Evidence From The Vault

Read-only checks found:

- `106` `index.md` files.
- `122` unresolved wikilink targets inside `index.md` files.
- `27` first-class-ish directories without an `index.md`.
- `projects/index.md` describes itself as the authoritative active project list,
  but it includes archived paths and paths that do not exist under `projects/`.
- `AGENTS.md` still references `daily_work/`, while the vault currently uses
  `dailies/`.

Frontmatter is useful but uneven:

```text
type counts
archive            1
area              47
briefing           3
daily             27
meeting          198
person            38
project           19
resource          19
sod-log            8
sprint planning    1
template           2
todo               3
transcript       103
weekly-briefing    2

status counts
active    138
archived    5
draft      13
```

The strongest signal: many notes already have useful `type` and `status`
properties, but key inventories still depend on hand-maintained links.

## Diagnosis

The core problem is not that the vault has too many indexes. The core problem is
that indexes are doing too many jobs.

Current `index.md` files often combine:

- orientation prose
- child-folder inventory
- active/inactive status
- routing instructions
- links to recent meetings
- links to key documents
- task lists
- historical breadcrumbs

Those jobs age at different speeds.

Context changes slowly:

- what an area is for
- how to reason about a project
- who a person is in the system
- what belongs in a folder
- what should not belong there

Inventory changes quickly:

- child folders
- archived projects
- renamed notes
- meeting summaries
- current people
- active todos
- recent evidence

When slow context and fast inventory live in the same hand-edited file, drift is
inevitable.

## Design Principle

Use this rule:

> Humans write meaning. Machines generate inventory.

This maps cleanly to the vault:

- `index.md` is meaning.
- frontmatter is metadata.
- filesystem paths are facts.
- generated views are inventory.
- agent instructions are retrieval policy.

## Proposed Architecture

### 1. Context Indexes

Every meaningful folder can still have an `index.md`, but its contract changes.

An `index.md` should answer:

- What is this folder for?
- What belongs here?
- What does not belong here?
- What are the important local conventions?
- Which notes are truly canonical?
- What should an agent read before acting here?

An `index.md` should not manually maintain:

- every child folder
- every active project
- every person
- every meeting
- every recent note
- every archived item

Example target shape:

```markdown
---
type: area
status: active
summary: People management notes, 1:1 context, feedback, growth, and sensitive employee matters.
inventory: generated
---

# People Management

This area contains durable context about direct reports and people-management
work. Use it for 1:1 preparation, performance context, growth plans, feedback,
and people-related follow-up.

Do not use this folder for peer-manager relationships; those live under
`areas/colleagues/` or `areas/engineering_management/`.

## Local Rules

- Treat this area as sensitive.
- Prefer person folders for durable context.
- Put actionable items in `areas/people_management/todo.md` unless they belong
  to a specific project.
- Meeting notes live under each person's `minutes/` folder when the person is
  the primary subject.

## Canonical Notes

- [[areas/people_management/todo|People management todo]]
```

That file remains useful even after people join, leave, or move folders.

### 2. Frontmatter As Metadata

Use frontmatter to make notes discoverable.

Minimum useful schema:

```yaml
---
type: project | area | person | meeting | daily | resource | template
status: active | paused | archived | draft
summary: One sentence.
---
```

Recommended additions where useful:

```yaml
---
owner: josrey
area: chatlayer_product_area
team: ai_agents_team
person_role: direct_report
meeting_kind: direct_report_1x1
source: granola
created: 2026-07-04
---
```

Do not over-model. Add fields only when they remove repeated manual work.

High-leverage fields:

- `type`
- `status`
- `summary`
- `area`
- `team`
- `person_role`
- `meeting_kind`
- `source`

### 3. Generated Inventories

Inventories should be generated from the filesystem and frontmatter.

Examples:

- active projects
- archived projects
- direct reports
- colleagues
- people with missing indexes
- meetings by area or person
- stale index links
- notes missing required frontmatter
- project folders missing `todo.md`

Generated inventory can appear as:

- Obsidian Bases for interactive browsing.
- a `vault-doctor` CLI report for agents and maintenance.
- generated markdown snapshots when a static artifact is useful.

Prefer Bases or CLI output over generated markdown unless there is a clear need
to commit the generated result.

## Recommended Generated Views

### Active Projects

Filter:

- path under `projects/`
- `type: project`
- `status: active`

Columns:

- link
- summary
- area
- status
- modified time
- todo exists

### Areas

Filter:

- path under `areas/`
- `type: area`
- `status: active`
- file name is `index.md`

Columns:

- link
- summary
- child folder count
- todo exists
- minutes exists

### People

Filter:

- `type: person`
- path under `areas/people_management/` or `areas/colleagues/`

Columns:

- link
- person_role
- team
- status
- minutes exists
- todo exists

### Meetings

Filter:

- `type: meeting`
- file name is `summary.md`
- path contains `/minutes/`

Columns:

- date
- meeting_time
- file path
- attendees
- source
- area/person/project derived from path

## Agent Retrieval Model

Replace the current "index-first means index inventory" model with:

1. Generate or query the inventory for candidate paths.
2. Pick the relevant folder or note.
3. Read that folder's `index.md` for local context.
4. Read only the relevant child notes.
5. Use search as fallback, not as the first move.

This keeps progressive disclosure, but removes the need for humans to keep
indexes synchronized with the filesystem.

New rule:

> Inventory first for paths. Index first for meaning.

## Why A Full Manifest Is Not The Right First Move

The earlier breadcrumb sketched a shared vault layout manifest. That is still
useful for stable contracts such as:

- where dailies live
- where meetings live
- folder naming conventions
- which roots exist
- how to classify meeting destinations

But a manifest should not list live entities:

- current projects
- current people
- current meetings
- current active areas

Those should be discovered.

A manifest that tries to own live inventory would recreate the same drift
problem in a new file.

Better split:

- `vault_contract.md` or `vault-layout.md`: stable conventions.
- generated reports/Bases: live inventory.
- `index.md`: local context.

## Proposed Files

### `AGENTS_vault.md`

Purpose: agent retrieval and writing contract.

Content:

- indexes are context, not inventories
- how to discover active projects
- how to discover people
- how to discover meetings
- when to read indexes
- when to search
- how to treat archive

### `resources/schemas/vault_note_schema.md`

Purpose: human-readable frontmatter schema.

Content:

- allowed `type` values
- allowed `status` values
- optional fields by type
- examples

### `resources/views/`

Purpose: Obsidian Bases or other generated views.

Candidate files:

- `active_projects.base`
- `areas.base`
- `people.base`
- `meetings.base`

### `bin/vault-doctor` or `ai/skills/vault-doctor/scripts/vault_doctor.py`

Purpose: maintenance report and agent-readable inventory.

Initial checks:

- missing frontmatter on index files
- missing `index.md` in first-class folders
- stale wikilinks inside `index.md`
- active project indexes linking into `archive/`
- project folders missing `todo.md`
- `AGENTS.md` references to nonexistent roots

## Migration Strategy

Do not migrate the whole vault at once.

### Phase 1: Add Read-Only Diagnostics

Create `vault-doctor` and make no content changes.

Output:

- stale links
- missing indexes
- missing frontmatter
- project/todo mismatches
- archive links in active indexes

This creates a feedback loop and prevents speculative cleanup.

### Phase 2: Rewrite One Index Type

Start with `projects/index.md`.

Reason:

- it currently claims to be authoritative
- it has clear drift
- projects are finite and easy to discover from path plus frontmatter
- success is easy to evaluate

New `projects/index.md` should contain:

- what a project is
- what belongs in `projects/`
- what belongs in `archive/`
- required files for each project
- link to generated active-projects view/report

It should not contain the active project list.

### Phase 3: Add Generated Active Projects View

Create an Obsidian Base or CLI report for active projects.

If using a Base:

- filter by `type == "project"`
- filter by `status == "active"`
- filter to `projects/`

If using CLI:

- scan `projects/*/index.md`
- parse frontmatter
- print markdown table

### Phase 4: Repeat For People

Move `areas/people_management/index.md` from direct-report inventory to local
context. Generate the people roster from folders/frontmatter instead.

This phase probably needs a little more schema:

```yaml
---
type: person
status: active
person_role: direct_report
team: ai_agents_team
summary: One sentence.
---
```

### Phase 5: Update Agent Instructions

Update `AGENTS.md`, `AGENTS_projects.md`, and `AGENTS_meetings.md` after the
new model is proven on one or two surfaces.

Important correction:

- Replace stale `daily_work/` references with `dailies/` or whatever the final
  root contract says.

## Design Tradeoffs

### Benefits

- Index files become durable and readable.
- Renames stop breaking hand-maintained path catalogs.
- Agents get better retrieval: generated candidates, then local context.
- Humans keep meaningful notes instead of maintaining file listings.
- Drift becomes measurable.

### Costs

- Frontmatter needs to be more consistent.
- A small script or set of Bases must exist.
- Some old index links will need cleanup or deletion.
- Agent instructions need to be updated after the model is proven.

### Risks

- Too much schema could make the vault feel bureaucratic.
- Generated views can become another surface to maintain if overbuilt.
- Agents may over-trust generated inventory unless local context remains part
  of the retrieval flow.

Mitigation:

- Start read-only.
- Keep schema minimal.
- Migrate one index type first.
- Keep `index.md` local context in the loop.

## Recommended Next Step

Build `vault-doctor` before changing the vault.

Minimum viable output:

```text
WorkSidian Doctor

Indexes:
- 106 index.md files
- 122 unresolved index wikilinks
- 27 first-class folders missing index.md

Projects:
- 10 project folders under projects/
- N project indexes with type/status
- N project folders missing todo.md
- N active project links pointing to archive/

Agent contract:
- AGENTS.md references daily_work/, but dailies/ exists
```

Then use its output to rewrite `projects/index.md` as the first pilot.

## Final Recommendation

Do not proceed with a broad shared vault layout manifest yet.

Proceed with:

1. a stable vault contract for conventions,
2. generated inventory for live pathing,
3. semantic-only `index.md` files,
4. a read-only doctor/reporting tool before any migration.

This gives the intended "best of all worlds":

- human-readable local context,
- agent-readable routing rules,
- generated path discovery,
- measurable drift,
- less manual maintenance.
