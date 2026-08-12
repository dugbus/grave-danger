extends "res://tests/test_case.gd"

const SUBJECT := preload("res://placeables/spike_trap/spike_trap.gd")
const SUBJECT_PATH := "res://placeables/spike_trap/spike_trap.gd"


func run(_tree: SceneTree) -> void:
	expect_script_contract(SUBJECT, SUBJECT_PATH)
