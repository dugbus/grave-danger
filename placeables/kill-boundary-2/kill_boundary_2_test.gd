extends "res://tests/test_case.gd"

const SUBJECT := preload("res://placeables/kill-boundary-2/kill_boundary_2.gd")
const SUBJECT_PATH := "res://placeables/kill-boundary-2/kill_boundary_2.gd"
const SCENE := preload("res://placeables/kill-boundary-2/kill_boundary_2.tscn")


func run(_tree: SceneTree) -> void:
	expect_script_contract(SUBJECT, SUBJECT_PATH)
	var boundary := SCENE.instantiate() as GDKillBoundary2
	expect(
		boundary.is_in_group(&"kill_boundary"),
		"Kill Boundary 2 joins the existing discovery group."
	)
	expect(
		boundary.get_class() == "Node",
		"The boundary root has no spatial transform or transform gizmo."
	)
	expect(
		boundary.sequence.get_pose(0) is GDKillBoundary2Pose,
		"Authored poses are selectable Node3D children in the scene tree."
	)
	expect(
		boundary.get_node_or_null(^"Poses") == boundary.sequence,
		"Programmatic and newly placed boundaries create their visible authored Poses container."
	)
	expect(
		(
			boundary.get_node_or_null(^"Animator") is GDKillBoundary2Animator
			and boundary.get_node_or_null(^"Geometry") is GDKillBoundary2Geometry
			and boundary.get_node_or_null(^"BoundarySpace/StateRoot") is Node3D
		),
		"The scene authors its animator and geometry as composed child components."
	)
	expect(
		(
			boundary.find_children("*", "Path3D", true, false).is_empty()
			and boundary.find_children("*", "AnimationPlayer", true, false).is_empty()
		),
		"Kill Boundary 2 has no path or animation-track source."
	)
	var source := (SUBJECT as Script).get_source_code()
	expect(
		source.contains("Turn this off when another level event")
		and source.contains("Single Shot stays at the final pose")
		and source.contains("None is useful for an invisible hazard")
		and source.contains("Lower values keep the")
		and source.contains("camera closer; raise it"),
		"Boundary-wide Inspector settings explain when to change them and the resulting effect."
	)
	for compatibility_method in [
		"play_runtime_animation",
		"begin_runtime_animation",
		"get_elapsed_time",
		"get_boundary_animation_position",
		"get_boundary_animation_duration",
		"get_bounds_center",
		"get_bounds_transform",
		"get_bounds_size",
		"get_bounds_height",
		"pause_runtime_for",
		"expand_runtime_bounds_percent",
		"expand_runtime_bounds_percent_for",
		"remove_for_level",
		"get_boundary_world_points",
	]:
		expect(
			source.contains("func %s" % compatibility_method),
			"The root exposes compatibility method %s." % compatibility_method
		)
	boundary.free()
