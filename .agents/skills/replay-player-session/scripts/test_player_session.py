#!/usr/bin/env python3
"""Regression tests for player_session.py."""

from __future__ import annotations

import importlib.util
import io
import json
import os
import sys
import tempfile
import unittest
from contextlib import redirect_stdout
from pathlib import Path
from types import ModuleType


SCRIPT_PATH = Path(__file__).with_name("player_session.py")


def _load_script() -> ModuleType:
    specification = importlib.util.spec_from_file_location("player_session", SCRIPT_PATH)
    if specification is None or specification.loader is None:
        raise RuntimeError("Could not load player_session.py")
    module = importlib.util.module_from_spec(specification)
    sys.modules[specification.name] = module
    specification.loader.exec_module(module)
    return module


player_session = _load_script()


class PlayerSessionTests(unittest.TestCase):
    def setUp(self) -> None:
        self.temporary_directory = tempfile.TemporaryDirectory()
        self.repository = Path(self.temporary_directory.name)
        for relative_path in (
            "project.godot",
            "game/graveyard.tscn",
            "tools/codex_replay_runner.gd",
        ):
            path = self.repository / relative_path
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text("", encoding="utf-8")
        changelog_script = (
            self.repository
            / ".agents/skills/write-changelog/scripts/add_changelog_entry.py"
        )
        changelog_script.parent.mkdir(parents=True, exist_ok=True)
        changelog_script.write_text(
            "from pathlib import Path\n"
            "import sys\n"
            "Path('CHANGELOG.md').write_text('\\n'.join(sys.argv[1:]), encoding='utf-8')\n",
            encoding="utf-8",
        )

    def tearDown(self) -> None:
        self.temporary_directory.cleanup()

    def test_directed_test_requires_explicit_user_confirmation(self) -> None:
        output = io.StringIO()
        with redirect_stdout(output):
            exit_code = player_session.main(
                [
                    "--repo",
                    str(self.repository),
                    "--godot",
                    sys.executable,
                    "request-test",
                    "--instruction",
                    "Walk through the gate.",
                ]
            )

        self.assertEqual(exit_code, 4)
        self.assertIn("user_confirmation_required", output.getvalue())
        self.assertIn("Are you ready", output.getvalue())

    def test_confirmed_test_command_preserves_instruction_and_level(self) -> None:
        command = player_session.build_request_test_command(
            "godot",
            self.repository,
            "Collect one coin.",
            "vampire_boss",
        )

        self.assertIn("--codex-test", command)
        self.assertIn("Collect one coin.", command)
        self.assertIn("--codex-report-button", command)
        self.assertIn("square", command)
        self.assertIn("--codex-text-button", command)
        self.assertIn("disabled", command)
        self.assertEqual(
            command[-3:],
            ["--codex-level", "vampire_boss", "--codex-confirmed"],
        )

    def test_replay_command_selects_logging_and_visual_mode(self) -> None:
        output_path = self.repository / "logs" / "replay.jsonl"
        command = player_session.build_replay_command(
            "godot",
            self.repository,
            level="latest",
            logs="summary,position",
            sample_seconds=0.25,
            speed=2.0,
            output=output_path,
            visual=True,
        )

        self.assertNotIn("--headless", command)
        self.assertIn("--codex-visual", command)
        self.assertIn("--codex-confirmed", command)
        self.assertIn("summary,position", command)
        self.assertIn(str(output_path.resolve()), command)

    def test_unknown_log_channel_is_rejected(self) -> None:
        with self.assertRaises(ValueError):
            player_session.validate_logs("summary,omniscience")

    def test_feedback_command_requests_only_a_small_marker_window(self) -> None:
        command = player_session.build_feedback_command(
            "godot",
            self.repository,
            logs="feedback,position,buttons",
            sample_seconds=0.25,
            before=1.5,
            after=2.5,
            speed=1.0,
            output=None,
            visual=False,
        )

        self.assertIn("--codex-new-feedback", command)
        self.assertIn("--codex-feedback-report", command)
        self.assertIn("feedback,position,buttons", command)
        self.assertIn("--codex-feedback-before", command)
        self.assertIn("1.5", command)
        self.assertIn("--codex-feedback-after", command)
        self.assertIn("2.5", command)

    def test_repository_reports_are_listed_newest_first(self) -> None:
        report_directory = self.repository / "feedback/reports"
        report_directory.mkdir(parents=True)
        for report_id, created in (("older", 10), ("newer", 20)):
            (report_directory / f"{report_id}.json").write_text(
                json.dumps(
                    {
                        "report_id": report_id,
                        "created_unix_time": created,
                        "status": "open",
                    }
                ),
                encoding="utf-8",
            )

        reports = player_session.list_repository_reports(self.repository)

        self.assertEqual(
            [report["report_id"] for report in reports],
            ["newer", "older"],
        )

    def test_resolved_feedback_moves_evidence_and_records_fix(self) -> None:
        report_id = "20260726T150000Z-vampire_boss"
        report_directory = self.repository / "feedback/reports"
        report_directory.mkdir(parents=True)
        (report_directory / f"{report_id}.json").write_text(
            json.dumps(
                {
                    "report_id": report_id,
                    "level_id": "vampire_boss",
                    "playback_file": f"{report_id}.gdr",
                    "marker": {"time": 12.5, "note": "Vampire stuck."},
                }
            ),
            encoding="utf-8",
        )
        (report_directory / f"{report_id}.gdr").write_bytes(b"recording")
        (report_directory / f"{report_id}.tscn").write_text(
            "[gd_scene format=3]\n",
            encoding="utf-8",
        )

        result = player_session.archive_feedback_report(
            self.repository,
            report_id,
            "The Vampire now rebuilds its route after colliding with the coffin.",
        )

        archived_report = self.repository / result["archive"]
        self.assertTrue(archived_report.is_file())
        self.assertFalse((report_directory / f"{report_id}.json").exists())
        self.assertTrue(
            (archived_report.parent / f"{report_id}.gdr").is_file()
        )
        self.assertTrue(
            (archived_report.parent / f"{report_id}.tscn").is_file()
        )
        archived_data = json.loads(archived_report.read_text(encoding="utf-8"))
        self.assertEqual(archived_data["status"], "resolved")
        self.assertIn("rebuilds its route", archived_data["fix"])
        self.assertIn(report_id, (self.repository / "CHANGELOG.md").read_text())

    def test_retention_prunes_oldest_resolved_report_first(self) -> None:
        archive_directory = self.repository / "feedback/archive/2026-07-26"
        archive_directory.mkdir(parents=True)
        for index in range(player_session.MAXIMUM_REPORT_COUNT + 1):
            report_id = f"report-{index:02d}"
            report_path = archive_directory / f"{report_id}.json"
            report_path.write_text(
                json.dumps(
                    {
                        "report_id": report_id,
                        "playback_file": f"{report_id}.gdr",
                        "level_scene_file": f"{report_id}.tscn",
                    }
                ),
                encoding="utf-8",
            )
            (archive_directory / f"{report_id}.gdr").write_bytes(b"playback")
            (archive_directory / f"{report_id}.tscn").write_text(
                "[gd_scene format=3]\n",
                encoding="utf-8",
            )
            os.utime(report_path, (index + 1, index + 1))

        pruned = player_session.enforce_report_retention(self.repository)

        self.assertEqual(pruned, ["report-00"])
        self.assertFalse((archive_directory / "report-00.json").exists())
        self.assertFalse((archive_directory / "report-00.tscn").exists())
        self.assertTrue((archive_directory / "report-20.json").exists())


if __name__ == "__main__":
    unittest.main()
