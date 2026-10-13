"""Behavior checks for scoped formatting; run with python3 -B to avoid bytecode files."""

import importlib.util
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch


spec = importlib.util.spec_from_file_location(
    "format_gdscript", Path(__file__).with_name("format_gdscript.py")
)
subject = importlib.util.module_from_spec(spec)
spec.loader.exec_module(subject)

SOURCE = '''extends RefCounted

# Keep meaningful comments and spaces inside strings.
func sample() -> String:
    var text := "spaces inside text    stay"
    return text
'''


class FormatterTests(unittest.TestCase):
    def setUp(self):
        self.workspace = tempfile.TemporaryDirectory()
        self.root = Path(self.workspace.name).resolve()
        self.root_patch = patch.object(subject, "REPOSITORY_ROOT", self.root)
        self.root_patch.start()
        self.script = self.root / "sample.gd"
        self.script.write_text(SOURCE)

    def tearDown(self):
        self.root_patch.stop()
        self.workspace.cleanup()

    def run_formatter(self, *args):
        with patch.object(sys, "argv", ["format_gdscript.py", *args]):
            return subject.main()

    def test_check_and_diff_do_not_write_then_format_is_stable(self):
        self.assertNotEqual(self.run_formatter("--check", "sample.gd"), 0)
        self.assertEqual(self.script.read_text(), SOURCE)
        self.assertNotEqual(self.run_formatter("--diff", "sample.gd"), 0)
        self.assertEqual(self.script.read_text(), SOURCE)
        self.assertEqual(self.run_formatter("sample.gd"), 0)
        formatted = self.script.read_text()
        self.assertIn('\tvar text := "spaces inside text    stay"', formatted)
        self.assertIn("# Keep meaningful comments and spaces inside strings.", formatted)
        self.assertEqual(self.run_formatter("--check", "sample.gd"), 0)
        self.assertEqual(self.run_formatter("sample.gd"), 0)
        self.assertEqual(self.script.read_text(), formatted)

    def test_invalid_selection_is_rejected_before_any_writes(self):
        resource = self.root / "settings.tres"
        resource.write_text("Read-only scene data")
        with self.assertRaises(SystemExit):
            self.run_formatter("sample.gd", "settings.tres")
        self.assertEqual(self.script.read_text(), SOURCE)
        self.assertEqual(resource.read_text(), "Read-only scene data")

    def test_directories_external_paths_and_addons_are_rejected(self):
        addon = self.root / "addons" / "third_party.gd"
        addon.parent.mkdir()
        addon.write_text(SOURCE)
        for value in [".", "addons/third_party.gd", "../external.gd"]:
            with self.subTest(value=value), self.assertRaises(SystemExit):
                self.run_formatter(value)
        self.assertEqual(addon.read_text(), SOURCE)

    def test_no_arguments_do_not_trigger_repository_wide_changes(self):
        with self.assertRaises(SystemExit):
            self.run_formatter()
        self.assertEqual(self.script.read_text(), SOURCE)

    def test_explicit_first_party_addon_selection_is_supported(self):
        addon = self.root / "addons" / "floor_surface" / "sample.gd"
        addon.parent.mkdir(parents=True)
        addon.write_text(SOURCE)
        self.assertEqual(self.run_formatter("addons/floor_surface/sample.gd"), 0)
        self.assertIn("\tvar text", addon.read_text())

    def test_all_formats_sources_but_preserves_generated_and_addon_scripts(self):
        ignored_paths = ["addons/vendor.gd", ".godot/generated.gd"]
        for value in ignored_paths:
            path = self.root / value
            path.parent.mkdir()
            path.write_text(SOURCE)
        original_run = subprocess.run

        def run(command, **kwargs):
            if command[0] == "git":
                paths = ["sample.gd", "sample.gd", "deleted.gd", *ignored_paths]
                return subprocess.CompletedProcess(command, 0, "\0".join(paths).encode())
            return original_run(command, **kwargs)

        with patch.object(subject.subprocess, "run", run):
            self.assertEqual(self.run_formatter("--all"), 0)
        self.assertIn("\tvar text", self.script.read_text())
        for value in ignored_paths:
            self.assertEqual((self.root / value).read_text(), SOURCE)


if __name__ == "__main__":
    unittest.main()
