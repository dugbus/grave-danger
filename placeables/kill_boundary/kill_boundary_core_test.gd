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
	var loop_boundary := GDKillBoundary3D.new()
	loop_boundary.curve = Curve3D.new()
	loop_boundary.curve.add_point(Vector3.ZERO)
	loop_boundary.curve.add_point(Vector3.RIGHT)
	loop_boundary.curve.add_point(Vector3.RIGHT + Vector3.FORWARD)
	loop_boundary._ensure_boundary_nodes()
	var path_follow := loop_boundary.get_node("BoundaryCenter") as PathFollow3D
	expect(
		loop_boundary.curve.closed and path_follow.loop,
		"Looping closes the boundary curve so it travels from the final point back to the start."
	)

	loop_boundary.loop_boundary_path = false
	expect(
		not loop_boundary.curve.closed and not path_follow.loop,
		"Disabling looping keeps the boundary path open and stops at its final point."
	)
	loop_boundary.free()

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
