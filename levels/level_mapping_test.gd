extends "res://tests/test_case.gd"

const LEVEL_MAPPING := preload("res://levels/level_mapping.tres")


func run(_tree: SceneTree) -> void:
	expect_equal(
		LEVEL_MAPPING.get_level_count(),
		18,
		"The level lookup exposes the debug level and seventeen playable slots."
	)
	expect_equal(LEVEL_MAPPING.get_level_id(0), "debug_level", "The debug level has a stable ID.")
	expect_equal(LEVEL_MAPPING.get_level_id(1), "level_01", "Level 1 has a stable ID.")
	expect(
		LEVEL_MAPPING.find_level_index("Vampire Boss") == 9 \
			and LEVEL_MAPPING.find_level_index("vampire-maze") == 9,
		"Level lookup resolves CLI references by display name and folder."
	)
	expect(
		bool(LEVEL_MAPPING.get_level_data(9).get("run_playback_enabled", true)) \
			and not LEVEL_MAPPING.get_level_data(9).has(
				"run_playback_background_load_enabled"
			),
		"Vampire Boss recordings use the shared safe preview loader."
	)
	expect_equal(
		LEVEL_MAPPING.get_level_scene_path(9),
		"res://levels/vampire-maze/level.tscn",
		"The Vampire Boss resolves to its owned level scene."
	)
	expect_equal(
		LEVEL_MAPPING.get_level_scene_path(10),
		"res://levels/1/level.tscn",
		"Placeholder level slots may reuse an existing level scene."
	)
