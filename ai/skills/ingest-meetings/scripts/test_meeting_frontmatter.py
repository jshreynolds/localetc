import unittest
from datetime import timezone, timedelta

from meeting_frontmatter import (
    append_tags,
    duration_str,
    extract_int_field,
    extract_title,
    infer_attendees,
    normalize_checkboxes,
    read_list_field,
    render_frontmatter,
    render_list_field,
    replace_list_field,
    slugify,
    to_local,
    folder_stamp,
)


class TestTimeHelpers(unittest.TestCase):
    def test_to_local_converts_utc_to_given_timezone(self):
        tz = timezone(timedelta(hours=2))
        result = to_local("2026-07-21T13:23:38Z", tz=tz)
        self.assertEqual(result.strftime("%Y-%m-%d %H:%M:%S"), "2026-07-21 15:23:38")

    def test_folder_stamp_formats_local_datetime(self):
        tz = timezone(timedelta(hours=2))
        dt = to_local("2026-07-21T13:23:38Z", tz=tz)
        self.assertEqual(folder_stamp(dt), "2026-07-21_1523")

    def test_duration_str_with_hours(self):
        self.assertEqual(duration_str(3700), "1h 1m")

    def test_duration_str_under_an_hour(self):
        self.assertEqual(duration_str(300), "5m")


class TestChecklistNormalization(unittest.TestCase):
    def test_normalizes_unchecked_and_checked_boxes(self):
        text = "- [ ] Do thing\n- [x] Done thing\n- Not a checkbox\n"
        self.assertEqual(
            normalize_checkboxes(text),
            "- Do thing\n- Done thing\n- Not a checkbox\n",
        )


class TestAttendeeInference(unittest.TestCase):
    def test_infers_and_drops_owner_name(self):
        self.assertEqual(infer_attendees("Gabriel x Joshua Collaborama"), ["Gabriel"])

    def test_infers_two_names_short_title(self):
        self.assertEqual(infer_attendees("Glenn x Josh"), ["Glenn"])

    def test_infers_two_non_owner_names(self):
        self.assertEqual(infer_attendees("Gabriel x Pedro Sync"), ["Gabriel", "Pedro"])

    def test_no_separator_returns_empty(self):
        self.assertEqual(infer_attendees("Orchestral Conversations"), [])

    def test_slash_separator(self):
        self.assertEqual(infer_attendees("Camila / Josh"), ["Camila"])


class TestSlugify(unittest.TestCase):
    def test_replaces_spaces_with_underscores(self):
        self.assertEqual(slugify("the old men"), "the_old_men")

    def test_strips_special_characters(self):
        self.assertEqual(slugify("Sync: Q3 Planning!"), "Sync_Q3_Planning")

    def test_truncates_to_max_length(self):
        long_title = "a" * 100
        self.assertEqual(len(slugify(long_title)), 60)


class TestListFieldRoundTrip(unittest.TestCase):
    def test_render_empty_list_inline(self):
        self.assertEqual(render_list_field("attendees", []), "attendees: []")

    def test_render_populated_list_block(self):
        self.assertEqual(
            render_list_field("tags", ["meeting", "peer"]),
            "tags:\n  - meeting\n  - peer",
        )

    def test_read_list_field_inline_empty(self):
        text = "attendees: []\nsource: muesli\n"
        self.assertEqual(read_list_field(text, "attendees"), [])

    def test_read_list_field_block(self):
        text = "tags:\n  - meeting\n  - peer\nsource: muesli\n"
        self.assertEqual(read_list_field(text, "tags"), ["meeting", "peer"])

    def test_replace_list_field_inline_to_block(self):
        text = "attendees: []\nsource: muesli\n"
        result = replace_list_field(text, "attendees", ["Glenn"])
        self.assertEqual(result, "attendees:\n  - Glenn\nsource: muesli\n")

    def test_replace_list_field_block_to_block(self):
        text = "tags:\n  - meeting\nsource: muesli\n"
        result = replace_list_field(text, "tags", ["meeting", "peer", "glenn"])
        self.assertEqual(result, "tags:\n  - meeting\n  - peer\n  - glenn\nsource: muesli\n")

    def test_append_tags_dedupes(self):
        text = "tags:\n  - meeting\nsource: muesli\n"
        result = append_tags(text, ["meeting", "peer", "glenn"])
        self.assertEqual(result, "tags:\n  - meeting\n  - peer\n  - glenn\nsource: muesli\n")


class TestFieldExtraction(unittest.TestCase):
    def test_extract_int_field(self):
        text = "muesli_id: 8\ntags:\n  - meeting\n"
        self.assertEqual(extract_int_field(text, "muesli_id"), 8)

    def test_extract_int_field_missing_returns_none(self):
        self.assertIsNone(extract_int_field("tags:\n  - meeting\n", "muesli_id"))

    def test_extract_title(self):
        text = "---\ntype: meeting\n---\n\n# Glenn x Josh\n\n## Summary\n"
        self.assertEqual(extract_title(text), "Glenn x Josh")


class TestRenderFrontmatter(unittest.TestCase):
    def test_full_block(self):
        result = render_frontmatter(
            date="2026-07-21",
            meeting_time="15:23",
            attendees=["Glenn"],
            muesli_id=8,
            tags=["meeting"],
        )
        expected = (
            "---\n"
            "type: meeting\n"
            "date: 2026-07-21\n"
            'meeting_time: "15:23"\n'
            "attendees:\n"
            "  - Glenn\n"
            "source: muesli\n"
            "muesli_id: 8\n"
            "tags:\n"
            "  - meeting\n"
            "---"
        )
        self.assertEqual(result, expected)


if __name__ == "__main__":
    unittest.main()
