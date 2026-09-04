extends "res://tests/test_case.gd"

const SUBJECT := preload("res://ui/screens/title_screen.gd")
const SUBJECT_PATH := "res://ui/screens/title_screen.gd"


func run(_tree: SceneTree) -> void:
	expect_script_contract(SUBJECT, SUBJECT_PATH)
	var source := (SUBJECT as Script).get_source_code()
	expect(
		source.contains("_precache_first_transition"),
		"The title screen begins preparing its immediate frontend destination."
	)
	expect(
		source.contains("scene_loader.request_scene(LEVEL_SELECT_SCENE)")
			and not source.contains("request_scene_directory")
			and not source.contains("GAME_SCENE"),
		"The title transition does not compete with gameplay and dynamic-catalog precaching."
	)
