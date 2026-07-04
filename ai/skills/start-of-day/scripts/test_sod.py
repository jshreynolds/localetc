"""Tests for sod.py — the logic that keeps record/status aligned with STEPS.

Run: python3 -m unittest discover -s scripts   (from the skill root)
     python3 scripts/test_sod.py
"""

import os
import shutil
import tempfile
import unittest

import sod


class SodTestCase(unittest.TestCase):
    """Each test runs in its own temp dir so log_path()'s `dailies/...` is isolated."""

    def setUp(self):
        self._old_cwd = os.getcwd()
        self._tmp = tempfile.mkdtemp()
        os.chdir(self._tmp)

    def tearDown(self):
        os.chdir(self._old_cwd)
        shutil.rmtree(self._tmp, ignore_errors=True)


class SkeletonInvariant(SodTestCase):
    def test_one_findings_slot_per_step(self):
        lines = sod.render_skeleton()
        self.assertEqual(len(sod.findings_slots(lines)), len(sod.STEPS))

    def test_slots_are_in_step_order(self):
        # Each _Findings:_ line should sit right under its step's title.
        lines = sod.render_skeleton()
        for step, slot in zip(sod.STEPS, sod.findings_slots(lines)):
            self.assertEqual(lines[slot - 1], f"### {step.title}")


class Record(SodTestCase):
    def test_creates_log_on_first_record(self):
        self.assertFalse(os.path.exists(sod.log_path()))
        sod.cmd_record(1, "first finding")
        self.assertTrue(os.path.exists(sod.log_path()))

    def test_fills_only_the_targeted_slot(self):
        sod.cmd_record(3, "operational looks fine")
        lines = sod.load_log()
        slots = sod.findings_slots(lines)
        self.assertEqual(lines[slots[2]], "_Findings:_ operational looks fine")
        # every other slot stays empty
        for i, slot in enumerate(slots):
            if i != 2:
                self.assertEqual(lines[slot].strip(), sod.FINDINGS_MARKER)

    def test_out_of_range_is_rejected_and_writes_nothing(self):
        msg = sod.cmd_record(99, "nope")
        self.assertIn("No step 99", msg)
        self.assertFalse(os.path.exists(sod.log_path()))


class Status(SodTestCase):
    def test_fresh_log_awaits_step_one(self):
        self.assertIn("step 1 of", sod.cmd_status())

    def test_reports_first_empty_step(self):
        sod.cmd_record(1, "done")
        sod.cmd_record(2, "done")
        self.assertIn("step 3 of", sod.cmd_status())

    def test_all_recorded(self):
        for n in range(1, len(sod.STEPS) + 1):
            sod.cmd_record(n, f"finding {n}")
        self.assertIn("All", sod.cmd_status())


if __name__ == "__main__":
    unittest.main()
