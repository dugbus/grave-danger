extends "res://tests/test_case.gd"

const SUBJECT := preload("res://levels/graveyard/level.gd")
const SUBJECT_PATH := "res://levels/graveyard/level.gd"


func run(_tree: SceneTree) -> void:
	expect_script_contract(SUBJECT, SUBJECT_PATH)
	var level := SUBJECT.new() as GDLevel05
	expect(
		level.floor_size == Vector2(100.0, 100.0),
		"Graveyard dressing uses the same flat authored extent as its FloorSurface."
	)
	level.free()
