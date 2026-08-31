extends "res://tests/test_case.gd"

const SUBJECT := preload("res://placeables/kill-boundary-2/kill_boundary_2_pose.gd")
const SUBJECT_PATH := "res://placeables/kill-boundary-2/kill_boundary_2_pose.gd"


func run(_tree: SceneTree) -> void:
	expect_script_contract(SUBJECT, SUBJECT_PATH)
	var pose := GDKillBoundary2Pose.new()
	pose.size = Vector2.ZERO
	pose.rounding = 2.0
	pose.time_seconds = -1.0
	pose.position = Vector3(2.0, 1.0, -3.0)
	pose.rotation = Vector3(0.4, 0.7, -0.2)
	pose.scale = Vector3(2.0, 3.0, 4.0)
	pose._sanitize_transform()
	expect_equal(pose.size, Vector2(0.1, 0.1), "Pose size is kept usable.")
	expect(is_equal_approx(pose.rounding, 1.0), "Rounding is clamped to ellipse.")
	expect(is_zero_approx(pose.time_seconds), "Pose time cannot become negative.")
	expect(
		pose.scale.is_equal_approx(Vector3.ONE)
		and is_zero_approx(pose.rotation.x)
		and is_zero_approx(pose.rotation.z),
		"Pose transforms retain position and yaw while discarding pitch, roll, and scale."
	)
	var copy := GDKillBoundary2Pose.new()
	copy.copy_values_from(pose)
	copy.position = Vector3.RIGHT
	expect(pose.position != copy.position, "Pose copies are independently editable nodes.")
	var has_boundary_proxy := false
	for property in pose.get_property_list():
		if String(property.get("name", "")).begins_with("boundary_"):
			has_boundary_proxy = true
			break
	expect(
		not has_boundary_proxy,
		"Pose Inspectors expose only pose-owned authoring values, not boundary-wide settings."
	)
	expect(
		(SUBJECT as Script).get_source_code().contains("0 is a sharp rectangle")
		and (SUBJECT as Script).get_source_code().contains("Constant moves evenly"),
		"Pose-owned settings retain plain-language Inspector hover help."
	)
	copy.free()
	pose.free()
