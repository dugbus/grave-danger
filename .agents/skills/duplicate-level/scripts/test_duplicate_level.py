#!/usr/bin/env python3
"""Regression tests for duplicate_level.py."""

from __future__ import annotations

import importlib.util
import io
import json
import struct
import sys
import tempfile
import unittest
from contextlib import redirect_stdout
from pathlib import Path
from types import ModuleType


SCRIPT_PATH = Path(__file__).with_name("duplicate_level.py")


def _load_script() -> ModuleType:
    specification = importlib.util.spec_from_file_location("duplicate_level", SCRIPT_PATH)
    if specification is None or specification.loader is None:
        raise RuntimeError("Could not load duplicate_level.py")
    module = importlib.util.module_from_spec(specification)
    sys.modules[specification.name] = module
    specification.loader.exec_module(module)
    return module


duplicate_level = _load_script()


MAPPING_TEMPLATE = """[gd_resource type="Resource" format=3]

[resource]
level_entries = Array[Dictionary]([{
"available": true,
"folder_name": "1",
"id": "level_01",
"legacy_result_key": "01",
"name": "Level 1",
"tutorial": false
}, {
"available": true,
"folder_name": "1",
"id": "level_10",
"legacy_result_key": "10",
"name": "Level 10",
"tutorial": false
}])
"""


TYPED_MAPPING_TEMPLATE = """[gd_resource type="Resource" script_class="GDLevelMapping" format=3]

[ext_resource type="Script" path="res://levels/level_mapping.gd" id="1_mapping"]
[ext_resource type="Script" path="res://levels/level_definition.gd" id="2_definition"]

[sub_resource type="Resource" id="Level_01"]
script = ExtResource("2_definition")
id = "level_01"
display_name = "Level 1"
folder_name = "1"
legacy_result_key = "01"
available = true

[resource]
script = ExtResource("1_mapping")
level_entries = Array[ExtResource("2_definition")]([SubResource("Level_01")])
"""


class DuplicateLevelTests(unittest.TestCase):
    def setUp(self) -> None:
        self.temporary_directory = tempfile.TemporaryDirectory()
        self.repository = Path(self.temporary_directory.name)
        (self.repository / "project.godot").write_text("[application]\n", encoding="utf-8")
        source = self.repository / "levels" / "1"
        source.mkdir(parents=True)
        (self.repository / "levels" / "level_mapping.tres").write_text(
            MAPPING_TEMPLATE,
            encoding="utf-8",
        )
        (source / "level.tscn").write_text(
            """[gd_scene format=3 uid="uid://source"]

[ext_resource type="Script" uid="uid://script" path="res://levels/1/level.gd" id="1"]
[node name="Level1" type="Node3D"]
script = ExtResource("1")
""",
            encoding="utf-8",
        )
        (source / "level.gd").write_text(
            (
                "class_name GDSourceLevel\n"
                "extends Node3D\n"
                'const LOCAL := preload("res://levels/1/settings.tres")\n'
                "var sibling: GDSourceLevel\n"
            ),
            encoding="utf-8",
        )
        (source / "settings.tres").write_text(
            '[gd_resource format=3 uid="uid://settings"]\n',
            encoding="utf-8",
        )
        (source / "level.gd.uid").write_text("uid://script\n", encoding="utf-8")
        (source / "level.png.import").write_text("[remap]\n", encoding="utf-8")
        duplicate_level.write_transparent_png(source / "level.png", 8, 6)

    def tearDown(self) -> None:
        self.temporary_directory.cleanup()

    def test_list_groups_aliases_that_share_a_scene(self) -> None:
        options = duplicate_level.discover_level_options(self.repository)

        self.assertEqual(options[0].key, "level_01")
        self.assertEqual(options[0].folder, "1")
        self.assertEqual(options[0].aliases, ("Level 10 (level_10)",))
        self.assertEqual(options[-1].key, "generated-template")

    def test_duplicate_rewrites_local_paths_and_mapping(self) -> None:
        result = duplicate_level.duplicate_level(
            self.repository,
            "Level 1",
            "Level 2",
        )

        target = self.repository / "levels" / "2"
        scene = (target / "level.tscn").read_text(encoding="utf-8")
        script = (target / "level.gd").read_text(encoding="utf-8")
        mapping = (self.repository / "levels" / "level_mapping.tres").read_text(
            encoding="utf-8"
        )
        self.assertTrue(result["created"])
        self.assertIn('[node name="Level2" type="Node3D"]', scene)
        self.assertNotIn('uid="uid://', scene)
        self.assertIn("res://levels/2/settings.tres", script)
        self.assertIn("class_name GDSourceLevelLevel2", script)
        self.assertIn("var sibling: GDSourceLevelLevel2", script)
        self.assertNotIn("var sibling: GDSourceLevel\n", script)
        self.assertFalse((target / "level.gd.uid").exists())
        self.assertFalse((target / "level.png.import").exists())
        self.assertEqual(_png_dimensions(target / "level.png"), (8, 6))
        self.assertIn('"folder_name": "2"', mapping)
        self.assertIn('"id": "level_02"', mapping)
        self.assertIn('"legacy_result_key": "02"', mapping)

    def test_generated_template_aligns_png_config_and_seed(self) -> None:
        result = duplicate_level.duplicate_level(
            self.repository,
            "generated-template",
            "Moonlit Crypt",
            png_size=(64, 48),
            seed=23,
        )

        target = self.repository / "levels" / "moonlit-crypt"
        scene = (target / "level.tscn").read_text(encoding="utf-8")
        config = (target / "generated_maze_config.tres").read_text(encoding="utf-8")
        settings = (target / "png_to_gridmap_settings.tres").read_text(encoding="utf-8")
        self.assertEqual(result["png_size"], [64, 48])
        self.assertEqual(_png_dimensions(target / "level.png"), (64, 48))
        self.assertIn("res://levels/moonlit-crypt/generated_maze_config.tres", scene)
        self.assertIn("maze_seed = 23", scene)
        self.assertIn("width = 64", config)
        self.assertIn("height = 48", config)
        self.assertIn("export_size = Vector2i(64, 48)", settings)
        self.assertIn("res://levels/moonlit-crypt/level.png", settings)

    def test_typed_mapping_is_parsed_and_extended(self) -> None:
        mapping_path = self.repository / "levels" / "level_mapping.tres"
        mapping_path.write_text(TYPED_MAPPING_TEMPLATE, encoding="utf-8")

        result = duplicate_level.duplicate_level(
            self.repository,
            "Level 1",
            "Practice Yard",
        )

        mapping = mapping_path.read_text(encoding="utf-8")
        options = duplicate_level.discover_level_options(self.repository)
        self.assertTrue(result["created"])
        self.assertIn('[sub_resource type="Resource" id="Level_practice_yard"]', mapping)
        self.assertIn('id = "practice_yard"', mapping)
        self.assertIn('display_name = "Practice Yard"', mapping)
        self.assertIn('folder_name = "practice-yard"', mapping)
        self.assertIn('SubResource("Level_practice_yard")', mapping)
        self.assertEqual(options[0].key, "level_01")
        self.assertEqual(options[1].key, "practice_yard")

    def test_dry_run_does_not_write(self) -> None:
        before_mapping = (self.repository / "levels" / "level_mapping.tres").read_text(
            encoding="utf-8"
        )
        result = duplicate_level.duplicate_level(
            self.repository,
            "level_01",
            "Practice Yard",
            dry_run=True,
        )

        self.assertTrue(result["dry_run"])
        self.assertFalse((self.repository / "levels" / "practice-yard").exists())
        self.assertEqual(
            (self.repository / "levels" / "level_mapping.tres").read_text(
                encoding="utf-8"
            ),
            before_mapping,
        )

    def test_json_list_cli_is_machine_readable(self) -> None:
        output = io.StringIO()
        with redirect_stdout(output):
            exit_code = duplicate_level.main(
                ["--repo", str(self.repository), "--list", "--json"]
            )
        self.assertEqual(exit_code, 0)
        payload = json.loads(output.getvalue())
        self.assertIn(
            "generated-template",
            [option["key"] for option in payload["bases"]],
        )


def _png_dimensions(path: Path) -> tuple[int, int]:
    data = path.read_bytes()
    if data[:8] != b"\x89PNG\r\n\x1a\n":
        raise AssertionError("Not a PNG")
    return struct.unpack(">II", data[16:24])


if __name__ == "__main__":
    unittest.main()
