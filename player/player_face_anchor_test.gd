extends "res://tests/test_case.gd"

const SUBJECT := preload("res://player/player_face_anchor.gd")


func run(_tree: SceneTree) -> void:
	expect_script_contract(SUBJECT, "res://player/player_face_anchor.gd")
