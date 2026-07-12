---
name: vault-doctor
description: Read-only drift report for the work Obsidian vault. Measures the gap between what index files and AGENTS contracts claim and what the filesystem contains — unresolved index wikilinks, folders missing index.md, missing frontmatter, active indexes linking into archive/, projects missing index.md/todo.md, and AGENTS references to nonexistent roots. Use when the user asks for a vault health check, vault doctor, drift report, "is my vault consistent", stale link check, or before any vault reorganization or index cleanup. Never modifies the vault.
---

# Vault Doctor

Read-only diagnostics for the work vault. Run it before and after any vault
reorganization; use its output to drive cleanup, never guesses.

## Usage

Run this from the root of the Obsidian work vault. The script refuses to run if
the current directory has no `areas/` and `dailies/` (i.e. it isn't a vault
root); point it elsewhere with `--vault`.

```bash
python3 scripts/vault_doctor.py            # vault = current directory
python3 scripts/vault_doctor.py --verbose  # list every finding
python3 scripts/vault_doctor.py --vault ~/some/other/vault
```

## Interpreting the report

- **Agent contract: nonexistent roots** — an `AGENTS*.md` file references a
  top-level folder that does not exist. Highest priority: agents are being
  actively misdirected. Fix the contract file (or rename the folder back).
- **Indexes: unresolved wikilinks** — an `index.md` links to a note that is
  gone or renamed. These indexes are drifted inventory; prefer removing the
  inventory list over patching each link (indexes should carry meaning, not
  inventory — see the design principle below).
- **Indexes: archive links from active notes** — an active index lists an
  archived item as if current (only LIST items are flagged; prose references
  to archived work are legitimate provenance). Either the archival was
  incomplete or the list needs pruning.
- **First-class folders missing index.md** — a root, area/project folder, or
  entity folder (person, ex-employee) has no entry point. Add a short
  semantic `index.md` (what belongs here, what does not) — not a file
  listing.
- **Indexes: missing frontmatter** — `type`, `status`, or `summary` absent.
  Frontmatter is what makes generated inventory possible; fill these in.
- **Projects: missing required files** — every `projects/<name>/` needs
  `index.md` (with frontmatter) and `todo.md` per `AGENTS_projects.md`.
- **Lens: missing/illegal/disagreeing declarations** — every project/area
  `index.md` must declare `lens: work | personal | both`, and its `todo.md`
  must declare the same one (task queries read the todo file's own
  frontmatter). Fix the frontmatter.
- **Taskmaster: dashboard drift** — `taskmaster_work.md` and
  `taskmaster_personal.md` must be identical apart from frontmatter and must
  match `taskmaster.md`'s stable sections (above the `# scratchpad` line).
  Edit the master, then re-copy the stable region to the siblings.
- **Lens: both-lens items** — informational, not drift. `both` is legal but
  should stay rare; if this list grows, lenses are blurring.

## Design principle

> Humans write meaning. Machines generate inventory.

`index.md` files should describe what a folder is for and its local rules.
Lists of children, people, projects, and meetings should be generated (this
report, Obsidian Bases) — hand-maintained inventories are what drift.

## Boundaries

- This skill is strictly read-only; it never edits, moves, or deletes notes.
- Do not auto-fix findings in the same run. Report first; fix only what the
  user selects, one category at a time.
