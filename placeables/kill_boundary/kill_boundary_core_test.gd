extends "res://tests/test_case.gd"

const SUBJECT := preload("res://placeables/kill_boundary/kill_boundary_core.gd")
const SUBJECT_PATH := "res://placeables/kill_boundary/kill_boundary_core.gd"


class TestBoundary:
	extends GDKillBoundary3D

	var animation_seconds: Array[float] = []
	var restored_active_seconds := 0.0
	var restored_contraction_seconds := 0.0


	func _runtime_effects_enabled() -> bool:
		return true


	func _animate_runtime_bounds_multiplier(
		_target_multiplier: float,
		seconds: float
	) -> void:
		animation_seconds.append(seconds)


	func _restore_runtime_bounds_after(
		_multiplier: float,
		active_seconds: float,
		contraction_transition_seconds: float
	) -> void:
		restored_active_seconds = active_seconds
		restored_contraction_seconds = contraction_transition_seconds


func run(_tree: SceneTree) -> void:
	expect_script_contract(SUBJECT, SUBJECT_PATH)
	var boundary := TestBoundary.new()
	var applied := boundary.expand_runtime_bounds_percent_for(
		25.0,
		8.0,
		1.0,
		4.0
	)
	expect(
		applied \
			and boundary.animation_seconds == ([1.0] as Array[float]) \
			and is_equal_approx(boundary.restored_active_seconds, 8.0) \
			and is_equal_approx(boundary.restored_contraction_seconds, 4.0),
		"Temporary boundary expansion passes distinct expansion and contraction timings."
	)
	boundary.free()
