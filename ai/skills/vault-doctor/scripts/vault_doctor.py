#!/usr/bin/env python3
"""vault-doctor — read-only drift report for an Obsidian work vault.

Inventory should be generated, not hand-maintained. This tool measures the
drift between what index files and agent contracts claim and what the
filesystem actually contains. It never modifies the vault.

Checks:
  1. AGENTS*.md references to vault roots that do not exist
  2. unresolved wikilinks inside index.md files
  3. first-class folders missing an index.md
  4. index.md files missing frontmatter (type / status / summary)
  5. non-archive index.md files linking into archive/
  6. project folders missing index.md or todo.md
  7. lens declarations: every project/area index.md needs a legal lens
     (work | personal | both); todo.md must agree with its index.md
  8. taskmaster dashboards: taskmaster_work.md and taskmaster_personal.md
     must be identical apart from frontmatter, and match taskmaster.md's
     stable sections (everything above the scratchpad)
  9. informational: which items carry lens: both (creep alarm)

Run this from the root of an Obsidian work vault (the default), or point it at
one with --vault.

Usage: vault_doctor.py [--vault PATH] [--verbose]
  --vault    vault root (default: current directory)
  --verbose  list every finding instead of the first few per section
"""

import argparse
import os
import re
import sys
from pathlib import Path

WIKILINK = re.compile(r"!?\[\[([^\]|#^]+)")
FRONTMATTER_KEY = re.compile(r"^([A-Za-z_][\w-]*):", re.MULTILINE)
BACKTICKED_PATH = re.compile(r"`([a-z0-9_]+)/[^`]*`")
DATED_FOLDER = re.compile(r"^\d{4}-\d{2}-\d{2}")

REQUIRED_FRONTMATTER = ("type", "status", "summary")
CONTENT_ROOTS = ("areas", "projects", "resources", "dailies")
# one folder per entity; every child must carry an index.md so `ls` + index
# is all an agent needs to route correctly
ENTITY_CONTAINERS = ("areas/people_management", "areas/colleagues", "archive/ex_employees")
SKIP_DIRS = {".obsidian", ".trash", ".git", "assets", "templates", "Excalidraw"}
DEFAULT_SHOWN = 15


def iter_notes(vault):
    """All markdown files in the vault, skipping hidden and tool dirs."""
    for root, dirs, files in os.walk(vault):
        dirs[:] = [d for d in dirs if d not in SKIP_DIRS and not d.startswith(".")]
        for name in files:
            if name.endswith(".md"):
                yield Path(root) / name


def link_targets(vault):
    """Lowercased keys a wikilink can resolve to: relative paths and basenames.
    Markdown links omit the .md extension; links to any other file type
    (.canvas, .base, .pdf, images) keep theirs. Unlike iter_notes, this walks
    ALL non-hidden folders — templates and assets are valid link targets even
    though we don't analyze their contents."""
    targets = set()
    for root, dirs, files in os.walk(vault):
        dirs[:] = [d for d in dirs if not d.startswith(".")]
        for name in files:
            rel = (Path(root) / name).relative_to(vault).as_posix().lower()
            if rel.endswith(".md"):
                rel = rel[: -len(".md")]
            targets.add(rel)
            targets.add(rel.rsplit("/", 1)[-1])
    return targets


def wikilinks(text):
    return [match.strip() for match in WIKILINK.findall(text)]


def normalize(target):
    target = target.strip().lower()
    return target[: -len(".md")] if target.endswith(".md") else target


def frontmatter_keys(text):
    if not text.startswith("---\n"):
        return None
    end = text.find("\n---", 4)
    if end == -1:
        return None
    return set(FRONTMATTER_KEY.findall(text[4:end]))


def content_children(parent):
    for child in sorted(parent.iterdir()):
        is_content_folder = (
            child.is_dir()
            and child.name != "minutes"
            and not child.name.startswith(".")
            and not DATED_FOLDER.match(child.name)
        )
        if is_content_folder:
            yield child


def first_class_folders(vault):
    """Roots, their immediate child folders, and entity-container children
    (people, ex-employees) — minus minutes/dated folders."""
    folders = []
    for root_name in CONTENT_ROOTS:
        root = vault / root_name
        if root.is_dir():
            folders.append(root)
            folders.extend(content_children(root))
    for container_name in ENTITY_CONTAINERS:
        container = vault / container_name
        if container.is_dir():
            folders.extend(child for child in content_children(container) if child not in folders)
    return folders


def all_folder_names(vault):
    names = set()
    for root, dirs, _files in os.walk(vault):
        dirs[:] = [d for d in dirs if not d.startswith(".")]
        names.update(dirs)
    return names


def check_agents_roots(vault):
    """Backticked `path/` references whose first segment exists nowhere in the
    vault — names like `minutes/` that only exist as subfolders are fine."""
    existing = all_folder_names(vault)
    findings = []
    for contract in sorted(vault.glob("AGENTS*.md")):
        for root_name in set(BACKTICKED_PATH.findall(contract.read_text(encoding="utf-8"))):
            if root_name not in existing:
                findings.append(f"{contract.name}: references `{root_name}/` which does not exist")
    return findings


def check_index_links(vault, indexes, targets):
    """Unresolved links anywhere; archive links only when they appear in a
    LIST item — a bullet pointing into archive/ is stale inventory, while a
    prose reference ("driven through the [[archive/...|liftoff]]") is
    legitimate provenance."""
    unresolved, archive_links = [], []
    for index in indexes:
        rel = index.relative_to(vault).as_posix()
        in_archive = rel.startswith("archive/")
        for line in index.read_text(encoding="utf-8").splitlines():
            is_list_item = line.lstrip().startswith(("-", "*", "+"))
            for target in wikilinks(line):
                key = normalize(target)
                if key not in targets:
                    unresolved.append(f"{rel}: [[{target}]]")
                elif is_list_item and not in_archive and key.startswith("archive/"):
                    archive_links.append(f"{rel}: [[{target}]]")
    return unresolved, archive_links


def check_missing_indexes(folders):
    return [
        f"{folder}/ has no index.md" for folder in folders if not (folder / "index.md").is_file()
    ]


def check_frontmatter(vault, indexes):
    findings = []
    for index in indexes:
        rel = index.relative_to(vault).as_posix()
        keys = frontmatter_keys(index.read_text(encoding="utf-8"))
        if keys is None:
            findings.append(f"{rel}: no frontmatter")
            continue
        missing = [key for key in REQUIRED_FRONTMATTER if key not in keys]
        if missing:
            findings.append(f"{rel}: missing {', '.join(missing)}")
    return findings


LENS_VALUES = {"work", "personal", "both"}
LENS_LINE = re.compile(r"^lens:\s*(\S+)\s*$", re.MULTILINE)
SCRATCHPAD_MARKER = "\n# scratchpad"


def read_lens(path):
    """The lens declared in a file's frontmatter, or None."""
    text = path.read_text(encoding="utf-8")
    if not text.startswith("---\n"):
        return None
    end = text.find("\n---", 4)
    if end == -1:
        return None
    match = LENS_LINE.search(text[4:end])
    return match.group(1) if match else None


def check_lens(vault):
    """Every project/area declares a legal lens; todo.md agrees with index.md.
    Also collects lens: both items — legal, but creep should stay visible."""
    findings, both_items = [], []
    for root_name in ("projects", "areas"):
        root = vault / root_name
        if not root.is_dir():
            continue
        for folder in sorted(root.iterdir()):
            if not folder.is_dir() or folder.name.startswith("."):
                continue
            rel = f"{root_name}/{folder.name}"
            index_lens = read_lens(folder / "index.md") if (folder / "index.md").is_file() else None
            if index_lens is None:
                findings.append(f"{rel}/index.md: no lens declared")
            elif index_lens not in LENS_VALUES:
                findings.append(f"{rel}/index.md: illegal lens '{index_lens}'")
            elif index_lens == "both":
                both_items.append(rel)
            todo = folder / "todo.md"
            if todo.is_file():
                todo_lens = read_lens(todo)
                if todo_lens is None:
                    findings.append(f"{rel}/todo.md: no lens declared")
                elif todo_lens != index_lens:
                    findings.append(
                        f"{rel}/todo.md: lens '{todo_lens}' disagrees with index.md '{index_lens}'"
                    )
    return findings, both_items


def strip_frontmatter(text):
    if not text.startswith("---\n"):
        return text
    end = text.find("\n---\n", 4)
    return text[end + len("\n---\n"):] if end != -1 else text


def check_taskmaster(vault):
    """The lens dashboards must be clones: taskmaster_work.md and
    taskmaster_personal.md identical apart from frontmatter, and both equal to
    taskmaster.md's stable region (everything above the scratchpad marker)."""
    findings = []
    paths = {name: vault / f"{name}.md" for name in ("taskmaster", "taskmaster_work", "taskmaster_personal")}
    missing = [f"{path.name} is missing" for path in paths.values() if not path.is_file()]
    if missing:
        return missing
    bodies = {name: strip_frontmatter(path.read_text(encoding="utf-8")) for name, path in paths.items()}
    stable = bodies["taskmaster"].split(SCRATCHPAD_MARKER)[0].rstrip().removesuffix("---").rstrip()
    if bodies["taskmaster_work"].rstrip() != bodies["taskmaster_personal"].rstrip():
        findings.append("taskmaster_work.md and taskmaster_personal.md differ outside frontmatter")
    for sibling in ("taskmaster_work", "taskmaster_personal"):
        if bodies[sibling].rstrip() != stable:
            findings.append(f"{sibling}.md does not match taskmaster.md's stable sections")
    return findings


def check_projects(vault):
    findings = []
    projects_root = vault / "projects"
    if not projects_root.is_dir():
        return findings
    for project in sorted(projects_root.iterdir()):
        if not project.is_dir() or project.name.startswith("."):
            continue
        for required in ("index.md", "todo.md"):
            if not (project / required).is_file():
                findings.append(f"projects/{project.name}/ missing {required}")
    return findings


def report_section(title, findings, verbose):
    print(f"\n{title}: {len(findings)}")
    shown = findings if verbose else findings[:DEFAULT_SHOWN]
    for finding in shown:
        print(f"  - {finding}")
    if len(findings) > len(shown):
        print(f"  ... and {len(findings) - len(shown)} more (--verbose to list all)")


def main():
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--vault", default=".")
    parser.add_argument("--verbose", "-v", action="store_true")
    args = parser.parse_args()

    vault = Path(args.vault).expanduser().resolve()
    if not (vault / "areas").is_dir() or not (vault / "dailies").is_dir():
        sys.exit(
            f"error: {vault} does not look like an Obsidian work vault "
            "(missing areas/ or dailies/). Run this from the vault root."
        )

    notes = list(iter_notes(vault))
    indexes = sorted(note for note in notes if note.name == "index.md")
    targets = link_targets(vault)
    unresolved, archive_links = check_index_links(vault, indexes, targets)
    relative_folders = [
        f"{folder.relative_to(vault).as_posix()}"
        for folder in first_class_folders(vault)
        if not (folder / "index.md").is_file()
    ]

    print(f"Vault Doctor — {vault}")
    print(f"{len(notes)} notes, {len(indexes)} index.md files")

    report_section("Agent contract: nonexistent roots", check_agents_roots(vault), args.verbose)
    report_section("Indexes: unresolved wikilinks", unresolved, args.verbose)
    report_section(
        "Indexes: archive links from active notes", archive_links, args.verbose
    )
    report_section(
        "First-class folders missing index.md",
        [f"{folder}/" for folder in relative_folders],
        args.verbose,
    )
    report_section(
        "Indexes: missing frontmatter (type/status/summary)",
        check_frontmatter(vault, indexes),
        args.verbose,
    )
    report_section("Projects: missing required files", check_projects(vault), args.verbose)

    lens_findings, both_items = check_lens(vault)
    report_section("Lens: missing/illegal/disagreeing declarations", lens_findings, args.verbose)
    report_section("Taskmaster: dashboard drift", check_taskmaster(vault), args.verbose)
    report_section("Lens: both-lens items (informational, not drift)", both_items, args.verbose)


if __name__ == "__main__":
    main()
