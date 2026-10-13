"""Behavior tests for the export documentation checker."""

import contextlib
import io
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

from check_export_docs import main, script_paths, undocumented_exports


class ExportDocumentationTests(unittest.TestCase):
    def test_export_variants_require_documentation(self):
        for annotation in (
            "@export", "@export_range(0, 1)", '@export_enum("A", "B")',
            '@export_file("*.png")', "@export_flags_3d_physics",
            '@export_group("Movement")', '@export_category("Settings")',
            '@export_subgroup("Speed")', "@export_custom(0, 0)",
        ):
            with self.subTest(annotation=annotation):
                self.assertEqual(len(undocumented_exports(annotation + " var value = 0")), 1)
                self.assertEqual(undocumented_exports("## Editor description.\n" + annotation), [])

    def test_missing_empty_and_separated_comments_fail(self):
        for prefix in ("", "# Ordinary comment.\n", "##   \n", "## Description.\n\n",
                       "## Description.\n# Intervening comment.\n"):
            with self.subTest(prefix=prefix):
                self.assertEqual(len(undocumented_exports(prefix + "@export var value = 0")), 1)

    def test_comments_and_strings_do_not_create_annotations_or_documentation(self):
        source = '''# @export var ignored = 0
var text = "@export_enum('A')"
var multiline = """
## Not documentation.
@export var ignored = 0
"""
@export var missing = 0
'''
        self.assertEqual(undocumented_exports(source), [(7, "@export")])
        self.assertEqual(undocumented_exports('var text = """\n## Fake docs.\n"""\n@export var v = 0'), [(4, "@export")])

    def test_indented_crlf_and_multiline_annotations(self):
        source = '\t## Choose a speed.\r\n\t@export_range(\r\n\t0, 1\r\n)\r\nvar speed = 0\r\n'
        self.assertEqual(undocumented_exports(source), [])

    def test_export_prefix_is_not_an_annotation(self):
        self.assertEqual(undocumented_exports("@exported var value = 0"), [])

    def test_scan_exclusions_and_exit_status(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            for name in ("player/value.gd", "addons/value.gd", "tests/value.gd", ".godot/value.gd"):
                path = root / name
                path.parent.mkdir(parents=True, exist_ok=True)
                path.write_text("@export var value = 0\n", encoding="utf-8")
            self.assertEqual(list(script_paths(root)), [root / "player/value.gd"])
            output = io.StringIO()
            with patch("sys.argv", ["check_export_docs.py", directory]), contextlib.redirect_stdout(output):
                self.assertEqual(main(), 1)
            self.assertIn("player/value.gd:1: @export requires", output.getvalue())
            (root / "player/value.gd").write_text("## Value description.\n@export var value = 0\n")
            with patch("sys.argv", ["check_export_docs.py", directory]), contextlib.redirect_stdout(io.StringIO()):
                self.assertEqual(main(), 0)


if __name__ == "__main__":
    unittest.main()
