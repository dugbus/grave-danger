extends "res://tests/test_case.gd"

const SUBJECT := preload("res://game/follow_camera.gd")
const SUBJECT_PATH := "res://game/follow_camera.gd"


func run(_tree: SceneTree) -> void:
	expect_script_contract(SUBJECT, SUBJECT_PATH)
	var camera := SUBJECT.new()
	var boundary := ExactBoundaryStub.new()
	camera.kill_boundary = boundary
	var points := camera._get_boundary_fit_points(Vector2(20.0, 20.0))
	expect_equal(
		points.size(), 8, "Camera fitting uses exact perimeter points at the base and top."
	)
	expect(points[0].x < -1.0, "Camera padding expands exact points around the boundary centre.")
	camera.free()
	boundary.free()


class ExactBoundaryStub:
	extends Node3D

	func get_camera_fit_world_points() -> PackedVector3Array:
		return PackedVector3Array(
			[
				Vector3(-1.0, 0.0, -2.0),
				Vector3(1.0, 0.0, -2.0),
				Vector3(1.0, 0.0, 2.0),
				Vector3(-1.0, 0.0, 2.0),
			]
		)

	func get_bounds_center() -> Vector3:
		return Vector3.ZERO

	func get_bounds_height() -> float:
		return 2.0
