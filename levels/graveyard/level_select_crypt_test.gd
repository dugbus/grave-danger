extends "res://tests/test_case.gd"

const SUBJECT := preload("res://levels/graveyard/level_select_crypt.gd")
const SUBJECT_PATH := "res://levels/graveyard/level_select_crypt.gd"


func run(_tree: SceneTree) -> void:
	expect_script_contract(SUBJECT, SUBJECT_PATH)
	expect(
		(SUBJECT as Script).get_source_code().contains("scene_loader.request_scene(GAME_SCENE)"),
		"Crypt transitions prepare the target game and level during their fade."
	)
