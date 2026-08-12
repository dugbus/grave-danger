extends "res://tests/test_case.gd"

const SUBJECT := preload("res://placeables/treasure_deposit/treasure_deposit_coffin.gd")
const SUBJECT_PATH := "res://placeables/treasure_deposit/treasure_deposit_coffin.gd"


func run(_tree: SceneTree) -> void:
	expect_script_contract(SUBJECT, SUBJECT_PATH)
