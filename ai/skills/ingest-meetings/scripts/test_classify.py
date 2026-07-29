import json
import tempfile
import unittest
from pathlib import Path

from meeting_frontmatter import render_frontmatter
from classify import (
    apply,
    classify_meeting,
    discover_candidates,
    plan,
    resolve_destination,
)


class VaultFixture(unittest.TestCase):
    def setUp(self):
        self._tmp = tempfile.TemporaryDirectory()
        self.root = Path(self._tmp.name)
        self.addCleanup(self._tmp.cleanup)

    def mkdirs(self, *rel_paths):
        for rel in rel_paths:
            (self.root / rel).mkdir(parents=True, exist_ok=True)

    def write_meeting(self, staging_dir, folder_name, title, attendees, muesli_id, date="2026-07-24", meeting_time="14:07"):
        folder = self.root / staging_dir / folder_name
        folder.mkdir(parents=True)
        frontmatter = render_frontmatter(
            date=date, meeting_time=meeting_time, attendees=attendees, muesli_id=muesli_id, tags=["meeting"]
        )
        text = f"{frontmatter}\n\n# {title}\n\nbody\n"
        (folder / "notes.md").write_text(text, encoding="utf-8")
        (folder / "transcript.md").write_text(text.replace(title, f"{title} — Transcript"), encoding="utf-8")
        return folder


class TestDiscoverCandidates(VaultFixture):
    def test_finds_folders_across_all_buckets(self):
        self.mkdirs(
            "areas/colleagues/glenn",
            "areas/colleagues/stefan",
            "areas/people_management/direct_reports/gabriel",
            "areas/people_management/domain_staff/hasan",
            "projects/mongo_cold_storage",
            "areas/chatlayer_product_area",
        )
        candidates = discover_candidates(self.root)
        self.assertIn("glenn", candidates["colleagues"])
        self.assertIn("stefan", candidates["colleagues"])
        self.assertIn("gabriel", candidates["direct_reports"])
        self.assertIn("hasan", candidates["domain_staff"])
        self.assertIn("mongo_cold_storage", candidates["projects"])
        self.assertIn("chatlayer_product_area", candidates["areas"])
        self.assertNotIn("colleagues", candidates["areas"])
        self.assertNotIn("people_management", candidates["areas"])


class TestClassifyMeeting(VaultFixture):
    def setUp(self):
        super().setUp()
        self.mkdirs(
            "areas/colleagues/glenn",
            "areas/colleagues/stefan",
            "areas/colleagues/jean_p",
            "areas/people_management/direct_reports/gabriel",
            "areas/people_management/domain_staff/hasan",
            "projects/mongo_cold_storage",
            "areas/chatlayer_product_area",
        )
        self.candidates = discover_candidates(self.root)

    def test_peer_match(self):
        result = classify_meeting("Glenn x Josh", ["Glenn"], self.candidates)
        self.assertEqual(result["type"], "peer")
        self.assertEqual(result["person"], "glenn")
        self.assertEqual(result["confidence"], "high")

    def test_boss_match(self):
        result = classify_meeting("Stefan 1:1", ["Stefan"], self.candidates)
        self.assertEqual(result["type"], "boss")

    def test_partial_slug_match(self):
        result = classify_meeting("Jean 1:1", ["Jean"], self.candidates)
        self.assertEqual(result["type"], "peer")
        self.assertEqual(result["person"], "jean_p")

    def test_direct_report_match(self):
        result = classify_meeting("Gabriel x Joshua Collaborama", ["Gabriel"], self.candidates)
        self.assertEqual(result["type"], "direct_report")
        self.assertEqual(result["person"], "gabriel")

    def test_domain_staff_match(self):
        result = classify_meeting("Hasan Sync", ["Hasan"], self.candidates)
        self.assertEqual(result["type"], "domain_staff")

    def test_project_title_match(self):
        result = classify_meeting("Mongo Cold Storage Review", [], self.candidates)
        self.assertEqual(result["type"], "project")
        self.assertEqual(result["person"], "mongo_cold_storage")
        self.assertEqual(result["confidence"], "medium")

    def test_area_title_match(self):
        result = classify_meeting("Chatlayer Product Area Sync", [], self.candidates)
        self.assertEqual(result["type"], "area")
        self.assertEqual(result["person"], "chatlayer_product_area")

    def test_unclassified_when_no_match(self):
        result = classify_meeting("Orchestral Conversations", [], self.candidates)
        self.assertEqual(result["type"], "unclassified")
        self.assertEqual(result["confidence"], "low")

    def test_vault_owner_first_name_does_not_prefix_match_colleague(self):
        self.mkdirs("areas/colleagues/josh_barwise")
        candidates = discover_candidates(self.root)
        result = classify_meeting("US-Only MVP Deployment Strategy", ["Diego", "Josh"], candidates)
        self.assertNotEqual(result["person"], "josh_barwise")

    def test_stopword_does_not_cause_false_project_match(self):
        self.mkdirs("projects/migrate_addresses_to_remailer")
        candidates = discover_candidates(self.root)
        result = classify_meeting("Orchestrator Team Getting to Know You", [], candidates)
        self.assertNotEqual(result["person"], "migrate_addresses_to_remailer")


class TestResolveDestination(VaultFixture):
    def test_person_destination_gets_minutes_suffix(self):
        self.mkdirs("areas/colleagues/glenn")
        classification = {
            "type": "peer",
            "person": "glenn",
            "destination_path": self.root / "areas/colleagues/glenn",
        }
        self.assertEqual(
            resolve_destination(self.root, classification),
            self.root / "areas/colleagues/glenn/minutes",
        )

    def test_unclassified_destination_is_dailies_meetings(self):
        classification = {"type": "unclassified", "person": None, "destination_path": None}
        self.assertEqual(resolve_destination(self.root, classification), self.root / "dailies/meetings")


class TestPlan(VaultFixture):
    def test_produces_one_item_per_staged_meeting(self):
        self.mkdirs("areas/colleagues/glenn")
        self.write_meeting("inbox/meetings_outgest", "2026-07-24-14-07_minutes", "Glenn x Josh", ["Glenn"], muesli_id=6)
        items = plan(self.root, self.root / "inbox/meetings_outgest")
        self.assertEqual(len(items), 1)
        item = items[0]
        self.assertEqual(item["title"], "Glenn x Josh")
        self.assertEqual(item["type"], "peer")
        self.assertEqual(item["muesli_id"], 6)
        self.assertTrue(item["destination_dir"].endswith("areas/colleagues/glenn/minutes"))


class TestApply(VaultFixture):
    def test_moves_renames_and_tags(self):
        self.mkdirs("areas/colleagues/glenn")
        folder = self.write_meeting("inbox/meetings_outgest", "2026-07-24-14-07_minutes", "Glenn x Josh", ["Glenn"], muesli_id=6)
        items = plan(self.root, self.root / "inbox/meetings_outgest")
        results = apply(self.root, items)

        self.assertFalse(folder.exists())
        target = self.root / "areas/colleagues/glenn/minutes/2026-07-24_1407_Glenn_x_Josh"
        self.assertTrue((target / "notes.md").exists())
        self.assertTrue((target / "transcript.md").exists())
        notes_text = (target / "notes.md").read_text(encoding="utf-8")
        self.assertIn("  - peer", notes_text)
        self.assertIn("  - glenn", notes_text)
        self.assertEqual(results[0]["destination"], str(target))

    def test_collision_appends_muesli_id(self):
        self.mkdirs("dailies/meetings")
        (self.root / "dailies/meetings/2026-07-24_1407_Orchestral_Conversations").mkdir(parents=True)
        self.write_meeting(
            "inbox/meetings_outgest", "2026-07-24-14-07_minutes", "Orchestral Conversations", [], muesli_id=13
        )
        items = plan(self.root, self.root / "inbox/meetings_outgest")
        results = apply(self.root, items)
        self.assertTrue(results[0]["destination"].endswith("-13"))


if __name__ == "__main__":
    unittest.main()
