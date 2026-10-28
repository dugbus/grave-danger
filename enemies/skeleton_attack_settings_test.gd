extends "res://tests/test_case.gd"

const SUBJECT := preload("res://enemies/skeleton_attack_settings.gd")


func run(_tree: SceneTree) -> void:
	expect_script_contract(SUBJECT, "res://enemies/skeleton_attack_settings.gd")
