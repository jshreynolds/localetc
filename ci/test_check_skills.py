"""Tests for the skill-metadata check.

Discovered automatically: run-checks.sh derives its test suites from any
`test_*.py` in the repo, so this file needs no registration anywhere.
"""

import io
import unittest
from contextlib import redirect_stderr, redirect_stdout
from pathlib import Path
from tempfile import TemporaryDirectory

import check_skills

VALID = "---\nname: thing\ndescription: does a thing\n---\n\nbody\n"


class FrontmatterProblems(unittest.TestCase):
    def test_valid_frontmatter_is_accepted(self):
        self.assertEqual(check_skills.frontmatter_problems(VALID, "s"), [])

    def test_missing_frontmatter_is_reported(self):
        self.assertEqual(
            check_skills.frontmatter_problems("# no frontmatter\n", "s"),
            ["s: missing frontmatter"],
        )

    def test_unclosed_frontmatter_is_reported(self):
        self.assertEqual(
            check_skills.frontmatter_problems("---\nname: x\n", "s"),
            ["s: unclosed frontmatter"],
        )

    def test_each_missing_key_is_reported(self):
        self.assertEqual(
            check_skills.frontmatter_problems("---\nother: x\n---\n", "s"),
            ["s: missing name:", "s: missing description:"],
        )

    def test_keys_outside_the_frontmatter_do_not_count(self):
        text = "---\nname: x\n---\n\ndescription: in the body\n"
        self.assertEqual(
            check_skills.frontmatter_problems(text, "s"), ["s: missing description:"]
        )


class Check(unittest.TestCase):
    def _skill(self, root, name, text):
        (root / name).mkdir(parents=True)
        (root / name / "SKILL.md").write_text(text, encoding="utf-8")

    def test_counts_skills_and_collects_problems(self):
        with TemporaryDirectory() as tmp:
            root = Path(tmp)
            self._skill(root, "good", VALID)
            self._skill(root, "bad", "no frontmatter\n")
            found, problems = check_skills.check(root)
            self.assertEqual(found, 2)
            self.assertEqual(len(problems), 1)
            self.assertIn("bad/SKILL.md", problems[0])

    def test_empty_root_finds_nothing(self):
        with TemporaryDirectory() as tmp:
            self.assertEqual(check_skills.check(Path(tmp)), (0, []))


class Main(unittest.TestCase):
    """The vacuous-pass floor is the whole reason this check has a guard."""

    def _main(self, root):
        """Run main, capturing its streams so tests don't pollute check output."""
        out, err = io.StringIO(), io.StringIO()
        with redirect_stdout(out), redirect_stderr(err):
            code = check_skills.main(["check_skills.py", str(root)])
        return code, out.getvalue(), err.getvalue()

    def test_empty_root_is_a_failure_not_a_pass(self):
        with TemporaryDirectory() as tmp:
            code, _, err = self._main(tmp)
            self.assertEqual(code, 1)
            self.assertIn("no SKILL.md files found", err)

    def test_valid_tree_passes(self):
        with TemporaryDirectory() as tmp:
            root = Path(tmp)
            (root / "good").mkdir()
            (root / "good" / "SKILL.md").write_text(VALID, encoding="utf-8")
            code, out, _ = self._main(tmp)
            self.assertEqual(code, 0)
            self.assertIn("1 SKILL.md files", out)

    def test_bad_frontmatter_fails_and_names_the_file(self):
        with TemporaryDirectory() as tmp:
            root = Path(tmp)
            (root / "bad").mkdir()
            (root / "bad" / "SKILL.md").write_text("nope\n", encoding="utf-8")
            code, _, err = self._main(tmp)
            self.assertEqual(code, 1)
            self.assertIn("bad/SKILL.md: missing frontmatter", err)


if __name__ == "__main__":
    unittest.main()
