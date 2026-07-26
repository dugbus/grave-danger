#!/usr/bin/env python3
"""Regression tests for the timestamped changelog writer."""

from datetime import datetime, timezone
import unittest

from add_changelog_entry import format_changelog


class ChangelogFormattingTests(unittest.TestCase):
    def test_preserves_legacy_entries_under_undated_heading(self) -> None:
        updated, added = format_changelog(
            "- Existing historical entry.\n",
            "A new player-facing improvement.",
            "Improve the player experience.",
            datetime(2026, 7, 26, 11, 15, tzinfo=timezone.utc),
        )

        self.assertTrue(added)
        self.assertIn("# Changelog\n", updated)
        self.assertIn("## 2026-07-26\n\n### 1100\n\n- A new", updated)
        self.assertIn("  - Prompt: Improve the player experience.", updated)
        self.assertIn("## Undated entries\n\n- Existing historical entry.", updated)
        self.assertNotIn("\n\n\n## Undated entries", updated)

    def test_reuses_hour_and_updates_prompt_without_duplicate_entry(self) -> None:
        first, first_added = format_changelog(
            "",
            "The Vampire returns to its regenerated gate.",
            "Resize the Vampire Maze.",
            datetime(2026, 7, 26, 11, 5, tzinfo=timezone.utc),
        )
        second, second_added = format_changelog(
            first,
            "Treasure remains visible in dark rooms.",
            "Make treasure easier to see.",
            datetime(2026, 7, 26, 11, 45, tzinfo=timezone.utc),
        )
        updated, updated_existing = format_changelog(
            second,
            "The Vampire returns to its regenerated gate.",
            "Keep the Vampire at the gate after resizing.",
            datetime(2026, 7, 26, 11, 59, tzinfo=timezone.utc),
        )
        duplicate, duplicate_added = format_changelog(
            updated,
            "The Vampire returns to its regenerated gate.",
            "Keep the Vampire at the gate after resizing.",
            datetime(2026, 7, 26, 11, 59, tzinfo=timezone.utc),
        )

        self.assertTrue(first_added)
        self.assertTrue(second_added)
        self.assertTrue(updated_existing)
        self.assertFalse(duplicate_added)
        self.assertEqual(duplicate.count("### 1100"), 1)
        self.assertEqual(
            duplicate.count("- The Vampire returns to its regenerated gate."),
            1,
        )
        self.assertIn(
            "  - Prompt: Keep the Vampire at the gate after resizing.",
            duplicate,
        )
        self.assertNotIn("  - Prompt: Resize the Vampire Maze.", duplicate)

    def test_adds_prompt_to_an_existing_unannotated_entry(self) -> None:
        updated, added = format_changelog(
            "# Changelog\n\n## 2026-07-26\n\n### 1100\n\n"
            "- Existing outcome.\n",
            "Existing outcome.",
            "Record the request behind each changelog entry.",
            datetime(2026, 7, 26, 11, 30, tzinfo=timezone.utc),
        )

        self.assertTrue(added)
        self.assertEqual(updated.count("- Existing outcome."), 1)
        self.assertIn(
            "  - Prompt: Record the request behind each changelog entry.",
            updated,
        )

    def test_keeps_newest_dates_and_hours_first(self) -> None:
        changelog, _added = format_changelog(
            "",
            "Morning entry.",
            "Add a morning change.",
            datetime(2026, 7, 25, 9, 0, tzinfo=timezone.utc),
        )
        changelog, _added = format_changelog(
            changelog,
            "Afternoon entry.",
            "Add an afternoon change.",
            datetime(2026, 7, 25, 14, 0, tzinfo=timezone.utc),
        )
        changelog, _added = format_changelog(
            changelog,
            "Next day entry.",
            "Add a change on the next day.",
            datetime(2026, 7, 26, 8, 0, tzinfo=timezone.utc),
        )

        self.assertLess(
            changelog.index("## 2026-07-26"),
            changelog.index("## 2026-07-25"),
        )
        self.assertLess(changelog.index("### 1400"), changelog.index("### 0900"))


if __name__ == "__main__":
    unittest.main()
