extends "res://tests/test_case.gd"

const SUBJECT := preload("res://addons/playthrough_position_markers/plugin.gd")
const SUBJECT_PATH := "res://addons/playthrough_position_markers/plugin.gd"


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
