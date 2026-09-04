extends "res://tests/test_case.gd"

const SUBJECT := preload("res://levels/graveyard/level_tree_surround.gd")
const SUBJECT_PATH := "res://levels/graveyard/level_tree_surround.gd"


func run(_tree: SceneTree) -> void:
	expect_script_contract(SUBJECT, SUBJECT_PATH)
	var surround := SUBJECT.new() as GDLevel05TreeSurround
	expect_equal(
		surround.tree_scenes.size(),
		3,
		"Tree surround models are retained as threaded scene dependencies."
	)
	surround.free()
