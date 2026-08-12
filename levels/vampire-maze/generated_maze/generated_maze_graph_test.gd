extends "res://tests/test_case.gd"

const SUBJECT := preload("res://levels/vampire-maze/generated_maze/generated_maze_graph.gd")
const SUBJECT_PATH := "res://levels/vampire-maze/generated_maze/generated_maze_graph.gd"


func run(_tree: SceneTree) -> void:
	expect_script_contract(SUBJECT, SUBJECT_PATH)
