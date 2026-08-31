extends "res://tests/test_case.gd"

const SUBJECT := preload("res://ui/hud/minimap/minimap_view.gd")
const SUBJECT_PATH := "res://ui/hud/minimap/minimap_view.gd"


func run(_tree: SceneTree) -> void:
	expect_script_contract(SUBJECT, SUBJECT_PATH)
	var minimap := SUBJECT.new()
	var boundary := ExactBoundaryStub.new()
	minimap.kill_boundary = boundary
	var bounds := minimap._get_playable_bounds()
	expect_equal(
		bounds.position.x, -3.0, "Minimap exact bounds preserve the world perimeter minimum X."
	)
	expect_equal(
		bounds.size,
		Vector3(8.0, 2.0, 6.0),
		"Minimap derives its fallback AABB from exact world points."
	)
	minimap.free()
	boundary.free()


class ExactBoundaryStub:
	extends Node

	func get_boundary_world_points() -> PackedVector3Array:
		return PackedVector3Array(
			[
				Vector3(-3.0, 1.0, -2.0),
				Vector3(5.0, 1.0, -2.0),
				Vector3(5.0, 1.0, 4.0),
				Vector3(-3.0, 1.0, 4.0),
			]
		)

	func get_bounds_size() -> Vector2:
		return Vector2(8.0, 6.0)

	func get_bounds_center() -> Vector3:
		return Vector3(1.0, 1.0, 1.0)

	func get_bounds_height() -> float:
		return 2.0
