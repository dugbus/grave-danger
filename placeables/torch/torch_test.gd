extends "res://tests/test_case.gd"

const SUBJECT := preload("res://placeables/torch/torch.gd")
const SUBJECT_PATH := "res://placeables/torch/torch.gd"


func run(_tree: SceneTree) -> void:
	expect_script_contract(SUBJECT, SUBJECT_PATH)
