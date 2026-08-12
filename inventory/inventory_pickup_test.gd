extends "res://tests/test_case.gd"

const SUBJECT := preload("res://inventory/inventory_pickup.gd")
const SUBJECT_PATH := "res://inventory/inventory_pickup.gd"


func run(_tree: SceneTree) -> void:
	expect_script_contract(SUBJECT, SUBJECT_PATH)
