extends "res://tests/test_case.gd"

const SUBJECT := preload("res://player/player_death.gd")
const SUBJECT_PATH := "res://player/player_death.gd"


func run(_tree: SceneTree) -> void:
	expect_script_contract(SUBJECT, SUBJECT_PATH)
	expect(
		(SUBJECT as Script).get_source_code().contains("scene_loader.request_scene(lose_scene)"),
		"The lose screen is prepared before a player death transition needs it."
	)
