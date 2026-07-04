import tempfile
import unittest
from pathlib import Path

from vault_doctor import (
    check_agents_roots,
    check_frontmatter,
    check_index_links,
    check_projects,
    first_class_folders,
    frontmatter_keys,
    iter_notes,
    link_targets,
    normalize,
    wikilinks,
)

INDEX_WITH_FRONTMATTER = """---
type: area
status: active
summary: Test area.
---

# Test
"""


class VaultFixture(unittest.TestCase):
    def setUp(self):
        self._tmp = tempfile.TemporaryDirectory()
        self.vault = Path(self._tmp.name)
        self.addCleanup(self._tmp.cleanup)

    def note(self, rel_path, text=""):
        path = self.vault / rel_path
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(text, encoding="utf-8")
        return path


class TestWikilinks(VaultFixture):
    def test_extracts_targets_from_links_embeds_aliases_and_anchors(self):
        text = "[[plain]] ![[embedded]] [[with|alias]] [[note#heading]] [[note^block]]"
        self.assertEqual(wikilinks(text), ["plain", "embedded", "with", "note", "note"])

    def test_normalize_strips_md_extension_and_case(self):
        self.assertEqual(normalize("Areas/Thing.md"), "areas/thing")

    def test_resolves_by_relative_path_and_by_basename(self):
        self.note("areas/team/index.md")
        self.note("areas/team/roadmap.md")
        targets = link_targets(self.vault)
        self.assertIn("areas/team/roadmap", targets)
        self.assertIn("roadmap", targets)

    def test_skipped_analysis_dirs_still_resolve_as_targets(self):
        self.note("templates/feedback.md")
        self.assertIn("templates/feedback", link_targets(self.vault))

    def test_non_markdown_files_resolve_with_extension(self):
        self.note("resources/views/active_projects.base")
        self.note("matrix.canvas")
        targets = link_targets(self.vault)
        self.assertIn("resources/views/active_projects.base", targets)
        self.assertIn("active_projects.base", targets)
        self.assertIn("matrix.canvas", targets)

    def test_unresolved_and_archive_links_reported(self):
        self.note("archive/old_thing/summary.md")
        index = "[[archive/old_thing/summary]] [[does_not_exist]]"
        self.note("areas/team/index.md", index)
        notes = list(iter_notes(self.vault))
        indexes = [note for note in notes if note.name == "index.md"]
        unresolved, archive_links = check_index_links(self.vault, indexes, link_targets(self.vault))
        self.assertEqual(unresolved, ["areas/team/index.md: [[does_not_exist]]"])
        self.assertEqual(archive_links, ["areas/team/index.md: [[archive/old_thing/summary]]"])


class TestFrontmatter(VaultFixture):
    def test_missing_and_complete_frontmatter(self):
        self.assertIsNone(frontmatter_keys("# no frontmatter"))
        self.assertEqual(
            frontmatter_keys(INDEX_WITH_FRONTMATTER), {"type", "status", "summary"}
        )

    def test_check_reports_missing_keys(self):
        good = self.note("areas/good/index.md", INDEX_WITH_FRONTMATTER)
        bad = self.note("areas/bad/index.md", "---\ntype: area\n---\n")
        none = self.note("areas/none/index.md", "# bare")
        findings = check_frontmatter(self.vault, [good, bad, none])
        self.assertEqual(
            findings,
            [
                "areas/bad/index.md: missing status, summary",
                "areas/none/index.md: no frontmatter",
            ],
        )


class TestStructure(VaultFixture):
    def test_first_class_folders_skip_minutes_and_dated_folders(self):
        self.note("areas/team/index.md")
        self.note("areas/team/minutes/2026-01-01_0900_sync/summary.md")
        folders = first_class_folders(self.vault)
        names = [folder.relative_to(self.vault).as_posix() for folder in folders]
        self.assertEqual(names, ["areas", "areas/team"])

    def test_projects_require_index_and_todo(self):
        self.note("projects/complete/index.md")
        self.note("projects/complete/todo.md")
        self.note("projects/bare/summary.md")
        self.assertEqual(
            check_projects(self.vault),
            ["projects/bare/ missing index.md", "projects/bare/ missing todo.md"],
        )

    def test_agents_contract_roots(self):
        self.note("dailies/index.md")
        self.note("areas/team/minutes/keep.md")
        contract = "Notes live in `dailies/` and `daily_work/meetings/`, under `minutes/`."
        self.note("AGENTS.md", contract)
        self.assertEqual(
            check_agents_roots(self.vault),
            ["AGENTS.md: references `daily_work/` which does not exist"],
        )


if __name__ == "__main__":
    unittest.main()
