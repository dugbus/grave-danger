extends "res://tests/test_case.gd"

const SUBJECT := preload("res://placeables/kill-boundary-2/kill_boundary_2_state.gd")
const SUBJECT_PATH := "res://placeables/kill-boundary-2/kill_boundary_2_state.gd"


func run(_tree: SceneTree) -> void:
	expect_script_contract(SUBJECT, SUBJECT_PATH)
	var state := GDKillBoundary2State.new()
	state.set_values(Vector3.RIGHT, 1.0, Vector2(2.0, 3.0), 0.5)
	expect(
		state.position == Vector3.RIGHT and state.size == Vector2(2.0, 3.0),
		"State updates all evaluated values together."
	)
