import tempfile
import unittest
from datetime import timezone, timedelta
from pathlib import Path

from ingest import (
    existing_muesli_ids,
    ingest_meeting,
    render_notes,
    render_transcript,
    run,
    set_attendees,
    set_title,
    unique_folder,
)

TZ = timezone(timedelta(hours=2))

MEETING = {
    "id": 8,
    "status": "completed",
    "title": "Gabriel x Joshua Collaborama",
    "startTime": "2026-07-21T13:23:38Z",
    "durationSeconds": 3393,
    "formattedNotes": "## Meeting Summary\nWe talked.\n\n## Action Items\n- [ ] Send notes\n",
    "rawTranscript": "[15:23:38] You: Hello.\n",
    "manualNotes": "",
}


class VaultFixture(unittest.TestCase):
    def setUp(self):
        self._tmp = tempfile.TemporaryDirectory()
        self.root = Path(self._tmp.name)
        self.addCleanup(self._tmp.cleanup)
        self.staging = self.root / "inbox" / "meetings_outgest"
        self.staging.mkdir(parents=True)

    def write(self, rel_path, text):
        path = self.root / rel_path
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(text, encoding="utf-8")
        return path


class TestExistingMuesliIds(VaultFixture):
    def test_collects_ids_from_frontmatter(self):
        self.write("dailies/meetings/a/notes.md", "muesli_id: 5\n")
        self.write("areas/colleagues/glenn/minutes/b/notes.md", "muesli_id: 9\n")
        self.write("dailies/meetings/c/notes.md", "no id here\n")
        self.assertEqual(existing_muesli_ids(self.root), {5, 9})

    def test_ignores_dot_dirs(self):
        self.write(".obsidian/cache.md", "muesli_id: 99\n")
        self.assertEqual(existing_muesli_ids(self.root), set())


class TestUniqueFolder(VaultFixture):
    def test_no_collision_uses_stamp_and_slug(self):
        folder = unique_folder(self.staging, "2026-07-21_1523", "Gabriel_x_Joshua_Collaborama", meeting_id=8)
        self.assertEqual(folder.name, "2026-07-21_1523_Gabriel_x_Joshua_Collaborama")

    def test_collision_appends_meeting_id(self):
        (self.staging / "2026-07-21_1523_Gabriel_x_Joshua_Collaborama").mkdir()
        folder = unique_folder(self.staging, "2026-07-21_1523", "Gabriel_x_Joshua_Collaborama", meeting_id=8)
        self.assertEqual(folder.name, "2026-07-21_1523_Gabriel_x_Joshua_Collaborama-8")


class TestRenderNotesAndTranscript(unittest.TestCase):
    def test_render_notes_body(self):
        text = render_notes(MEETING, attendees=["Gabriel"], local_dt_str="2026-07-21 15:23")
        self.assertIn("muesli_id: 8", text)
        self.assertIn("attendees:\n  - Gabriel", text)
        self.assertIn("# Gabriel x Joshua Collaborama", text)
        self.assertIn("- Send notes", text)
        self.assertNotIn("[ ]", text)
        self.assertNotIn("## Private Notes", text)

    def test_render_notes_includes_private_notes_when_present(self):
        meeting = dict(MEETING, manualNotes="Remember to follow up.")
        text = render_notes(meeting, attendees=[], local_dt_str="2026-07-21 15:23")
        self.assertIn("## Private Notes", text)
        self.assertIn("Remember to follow up.", text)

    def test_render_transcript_body(self):
        text = render_transcript(MEETING, attendees=["Gabriel"], local_dt_str="2026-07-21 15:23")
        self.assertIn("muesli_id: 8", text)
        self.assertIn("# Gabriel x Joshua Collaborama — Transcript", text)
        self.assertIn("[15:23:38] You: Hello.", text)


class TestIngestMeeting(VaultFixture):
    def test_writes_both_files_into_staging(self):
        result = ingest_meeting(MEETING, self.staging, tz=TZ)
        notes = result["folder"] / "notes.md"
        transcript = result["folder"] / "transcript.md"
        self.assertTrue(notes.exists())
        self.assertTrue(transcript.exists())
        self.assertEqual(result["attendees"], ["Gabriel"])
        self.assertFalse(result["needs_attendees"])
        self.assertEqual(result["folder"].name, "2026-07-21_1523_Gabriel_x_Joshua_Collaborama")

    def test_flags_meetings_with_no_inferred_attendees(self):
        meeting = dict(MEETING, title="Orchestral Conversations")
        result = ingest_meeting(meeting, self.staging, tz=TZ)
        self.assertEqual(result["attendees"], [])
        self.assertTrue(result["needs_attendees"])


class TestRun(VaultFixture):
    def test_creates_new_and_skips_known_and_incomplete(self):
        self.write(
            "dailies/meetings/existing/notes.md",
            "muesli_id: 6\n",
        )
        meetings = [
            {"id": 6, "status": "completed", "title": "Already Here"},
            {"id": 8, "status": "completed", "title": "Gabriel x Joshua Collaborama"},
            {"id": 9, "status": "in_progress", "title": "Still Recording"},
        ]

        def list_fn():
            return meetings

        def get_fn(meeting_id):
            return next(m for m in [MEETING] if m["id"] == meeting_id)

        report = run(list_fn, get_fn, vault_root=self.root, staging_dir=self.staging, tz=TZ)
        self.assertEqual([c["muesli_id"] for c in report["created"]], [8])
        self.assertEqual(report["skipped_existing"], [6])
        self.assertEqual(report["skipped_incomplete"], [9])


class TestRunDateFiltering(VaultFixture):
    def test_only_processes_meetings_matching_target_date(self):
        meetings = [
            {"id": 20, "status": "completed", "title": "Yesterday Sync", "startTime": "2026-07-23T09:00:00Z"},
            {"id": 21, "status": "completed", "title": "Today Sync", "startTime": "2026-07-24T09:00:00Z"},
        ]

        def list_fn():
            return meetings

        def get_fn(meeting_id):
            summary = next(m for m in meetings if m["id"] == meeting_id)
            return dict(MEETING, id=meeting_id, title=summary["title"], startTime=summary["startTime"])

        report = run(
            list_fn, get_fn, vault_root=self.root, staging_dir=self.staging, tz=TZ, target_date="2026-07-24"
        )
        self.assertEqual([c["muesli_id"] for c in report["created"]], [21])

    def test_none_processes_all_days(self):
        meetings = [
            {"id": 20, "status": "completed", "title": "Yesterday Sync", "startTime": "2026-07-23T09:00:00Z"},
            {"id": 21, "status": "completed", "title": "Today Sync", "startTime": "2026-07-24T09:00:00Z"},
        ]

        def list_fn():
            return meetings

        def get_fn(meeting_id):
            summary = next(m for m in meetings if m["id"] == meeting_id)
            return dict(MEETING, id=meeting_id, title=summary["title"], startTime=summary["startTime"])

        report = run(list_fn, get_fn, vault_root=self.root, staging_dir=self.staging, tz=TZ, target_date=None)
        self.assertEqual(sorted(c["muesli_id"] for c in report["created"]), [20, 21])


class TestSetAttendees(VaultFixture):
    def test_patches_both_files(self):
        result = ingest_meeting(dict(MEETING, title="Orchestral Conversations"), self.staging, tz=TZ)
        set_attendees(result["folder"], ["Gabriel", "Pedro"])
        notes_text = (result["folder"] / "notes.md").read_text(encoding="utf-8")
        transcript_text = (result["folder"] / "transcript.md").read_text(encoding="utf-8")
        self.assertIn("attendees:\n  - Gabriel\n  - Pedro", notes_text)
        self.assertIn("attendees:\n  - Gabriel\n  - Pedro", transcript_text)


class TestSetTitle(VaultFixture):
    def test_renames_heading_in_both_files_and_moves_folder(self):
        result = ingest_meeting(dict(MEETING, title="Orchestrator Technical Debt Review"), self.staging, tz=TZ)
        old_folder = result["folder"]

        new_folder = set_title(old_folder, "Chatlayer Steering Weekly")

        self.assertFalse(old_folder.exists())
        self.assertEqual(new_folder.name, "2026-07-21_1523_Chatlayer_Steering_Weekly")
        notes_text = (new_folder / "notes.md").read_text(encoding="utf-8")
        transcript_text = (new_folder / "transcript.md").read_text(encoding="utf-8")
        self.assertIn("# Chatlayer Steering Weekly", notes_text)
        self.assertNotIn("Orchestrator Technical Debt Review", notes_text)
        self.assertIn("# Chatlayer Steering Weekly — Transcript", transcript_text)
        self.assertNotIn("Orchestrator Technical Debt Review", transcript_text)

    def test_no_rename_when_target_unchanged(self):
        result = ingest_meeting(MEETING, self.staging, tz=TZ)
        new_folder = set_title(result["folder"], MEETING["title"])
        self.assertEqual(new_folder, result["folder"])
        self.assertTrue(new_folder.exists())


if __name__ == "__main__":
    unittest.main()
