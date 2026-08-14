extends "res://tests/test_case.gd"

const SUBJECT := preload("res://placeables/collectibles/flask_breathing_space.gd")
const SUBJECT_PATH := "res://placeables/collectibles/flask_breathing_space.gd"


class TestBoundary:
	extends Node

	var expansion_percent := 0.0
	var active_seconds := 0.0
	var expansion_transition_seconds := 0.0
	var contraction_transition_seconds := 0.0


	func expand_runtime_bounds_percent_for(
		percent: float,
		duration: float,
		expansion_seconds: float,
		contraction_seconds: float
	) -> bool:
		expansion_percent = percent
		active_seconds = duration
		expansion_transition_seconds = expansion_seconds
		contraction_transition_seconds = contraction_seconds
		return true


class TestFlask:
	extends GDFlaskBreathingSpace

	var boundary: Node


	func _get_kill_boundary() -> Node:
		return boundary


func run(_tree: SceneTree) -> void:
	expect_script_contract(SUBJECT, SUBJECT_PATH)
	var boundary := TestBoundary.new()
	var flask := TestFlask.new()
	flask.boundary = boundary
	var applied := flask.call(&"_apply_effect", null) as bool
	expect(
		applied \
			and is_equal_approx(boundary.expansion_percent, 25.0) \
			and is_equal_approx(boundary.active_seconds, 8.0) \
			and is_equal_approx(boundary.expansion_transition_seconds, 1.0) \
			and is_equal_approx(boundary.contraction_transition_seconds, 4.0),
		"Breathing-space flasks pass separate one-second expansion and four-second contraction timings."
	)
	flask.free()
	boundary.free()
