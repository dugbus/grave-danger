extends "res://tests/test_case.gd"

const SUBJECT := preload("res://enemies/zombie/zombie_navigation.gd")
const SUBJECT_PATH := "res://enemies/zombie/zombie_navigation.gd"


func run(_tree: SceneTree) -> void:
	expect_script_contract(SUBJECT, SUBJECT_PATH)
