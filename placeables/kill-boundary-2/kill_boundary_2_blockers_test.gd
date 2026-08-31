extends "res://tests/test_case.gd"

const SUBJECT := preload("res://placeables/kill-boundary-2/kill_boundary_2_blockers.gd")
const SUBJECT_PATH := "res://placeables/kill-boundary-2/kill_boundary_2_blockers.gd"


func run(_tree: SceneTree) -> void:
	expect_script_contract(SUBJECT, SUBJECT_PATH)
	var blockers := GDKillBoundary2Blockers.new()
	var settings := GDKillBoundary2Settings.new()
	blockers.configure(settings)
	blockers.apply_geometry(
		GDKillBoundary2Geometry.build_points(Vector2(8.0, 8.0), 1.0, settings.boundary_segments)
	)
	expect(
		blockers.blockers.size() == settings.boundary_segments,
		"Blockers use every canonical segment."
	)
	var first_shape := blockers.blockers[0].get_node(^"CollisionShape3D") as CollisionShape3D
	var second_shape := blockers.blockers[1].get_node(^"CollisionShape3D") as CollisionShape3D
	expect(
		first_shape.shape != second_shape.shape,
		"Each blocker owns its independently resizable collision shape."
	)
	blockers.free()
