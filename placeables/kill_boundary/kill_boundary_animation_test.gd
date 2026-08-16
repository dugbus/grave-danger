extends "res://tests/test_case.gd"

const SUBJECT := preload("res://placeables/kill_boundary/kill_boundary_animation.gd")
const SUBJECT_PATH := "res://placeables/kill_boundary/kill_boundary_animation.gd"


func run(_tree: SceneTree) -> void:
	expect_script_contract(SUBJECT, SUBJECT_PATH)
	var boundary := GDKillBoundary3D.new()
	boundary.curve = Curve3D.new()
	boundary.curve.add_point(Vector3.ZERO)
	expect(
		not boundary._has_previewable_editor_path(),
		"A one-point path does not drive the editor boundary preview."
	)

	boundary.curve.add_point(Vector3.ZERO)
	expect(
		not boundary._has_previewable_editor_path(),
		"A zero-length path does not drive the editor boundary preview."
	)

	boundary.curve.set_point_position(1, Vector3.RIGHT)
	expect(
		boundary._has_previewable_editor_path(),
		"A path with two distinct points can drive the editor boundary preview."
	)
	boundary.free()
