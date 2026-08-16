extends "res://tests/test_case.gd"

const LEVEL_MAPPING := preload("res://levels/level_mapping.tres")


func run(_tree: SceneTree) -> void:
	expect_equal(
		LEVEL_MAPPING.get_level_count(),
		23,
		"The level lookup exposes the debug level and twenty-two playable slots."
	)
	expect_equal(LEVEL_MAPPING.get_level_id(0), "tutorial_1", "Tutorial 1 appears first.")
	expect_equal(LEVEL_MAPPING.get_level_id(5), "debug_level", "The debug level has a stable ID.")
	expect_equal(LEVEL_MAPPING.get_level_id(6), "level_01", "Level 1 has a stable ID.")
	expect(
		LEVEL_MAPPING.find_level_index("Vampire Boss") == 14 \
			and LEVEL_MAPPING.find_level_index("vampire-maze") == 14,
		"Level lookup resolves CLI references by display name and folder."
	)
	expect(
		bool(LEVEL_MAPPING.get_level_data(14).get("run_playback_enabled", true)) \
			and not LEVEL_MAPPING.get_level_data(14).has(
				"run_playback_background_load_enabled"
			),
		"Vampire Boss recordings use the shared safe preview loader."
	)
	expect_equal(
		LEVEL_MAPPING.get_level_scene_path(14),
		"res://levels/vampire-maze/level.tscn",
		"The Vampire Boss resolves to its owned level scene."
	)
	expect_equal(
		LEVEL_MAPPING.get_level_scene_path(15),
		"res://levels/1/level.tscn",
		"Placeholder level slots may reuse an existing level scene."
	)
	var tutorials_are_registered := true
	for tutorial_number in range(1, 6):
		var tutorial_index := tutorial_number - 1
		var tutorial_data := LEVEL_MAPPING.get_level_data(tutorial_index)
		var tutorial_scene_path := (
			"res://levels/tutorial-%d/level.tscn" % tutorial_number
		)
		var tutorial_scene_text := FileAccess.get_file_as_string(
			tutorial_scene_path
		)
		var scene_matches_scaffold := tutorial_scene_text.contains(
			"res://levels/tutorial-%d/generated_maze_config.tres" \
				% tutorial_number
		) and tutorial_scene_text.contains(
			"maze_seed = %d" % tutorial_number
		)
		if tutorial_number == 1:
			# Tutorial 1 is the frozen, inspectable generated-layout example
			# created by the level duplication workflow.
			scene_matches_scaffold = tutorial_scene_text.contains(
				'[node name="Layout" parent="."'
			) and FileAccess.file_exists(
				"res://levels/tutorial-1/generated_maze_config.tres"
			)
		tutorials_are_registered = tutorials_are_registered \
			and tutorial_data.get("id") == "tutorial_%d" % tutorial_number \
			and tutorial_data.get("name") == "Tutorial %d" % tutorial_number \
			and tutorial_data.get("folder_name") == "tutorial-%d" % tutorial_number \
			and bool(tutorial_data.get("available", false)) \
			and bool(tutorial_data.get("tutorial", false)) \
			and FileAccess.file_exists(tutorial_scene_path) \
			and scene_matches_scaffold
	expect(
		tutorials_are_registered,
		"Tutorial 1 through 5 resolve to their distinct selectable scenes."
	)
