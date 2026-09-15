extends "res://tests/test_case.gd"

const SUBJECT := preload("res://addons/playthrough_position_markers/plugin.gd")
const SUBJECT_PATH := "res://addons/playthrough_position_markers/plugin.gd"
const SAMPLE_SCENE := preload("res://addons/floor_surface/floor_surface.tscn")


func run(_tree: SceneTree) -> void:
	expect_script_contract(SUBJECT, SUBJECT_PATH)
	var scene_source_hash := SUBJECT.SceneSourceHasher.calculate("res://ui/screens") as int
	expect(
		scene_source_hash != 0,
		"Export customization hashes source scenes so inherited layout changes invalidate caches."
	)
	expect(
		(SUBJECT as Script).get_source_code().contains("SceneSourceHasher.calculate()"),
		"The export customization cache key includes the complete scene-source hash."
	)
	var edited_scene := SAMPLE_SCENE.instantiate()
	expect(
		SUBJECT.edited_scene_matches_level(edited_scene, edited_scene.scene_file_path) \
			and not SUBJECT.edited_scene_matches_level(edited_scene, "res://other_level.tscn") \
			and not SUBJECT.edited_scene_matches_level(null, edited_scene.scene_file_path),
		"Marker application reuses only the matching already-loaded editor scene."
	)
	edited_scene.free()
