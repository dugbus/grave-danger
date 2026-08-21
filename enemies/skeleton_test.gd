extends "res://tests/test_case.gd"

const SUBJECT := preload("res://enemies/skeleton.gd")
const SUBJECT_PATH := "res://enemies/skeleton.gd"
const SKELETON_SCENE := preload("res://enemies/skeleton.tscn")


func run(tree: SceneTree) -> void:
	expect_script_contract(SUBJECT, SUBJECT_PATH)
	_test_authored_start_matches_first_path_point()
	_test_rotated_path_keeps_skeleton_upright(tree)


func _test_authored_start_matches_first_path_point() -> void:
	var skeleton := SKELETON_SCENE.instantiate() as Path3D
	var path_follow := skeleton.get_node(^"PathFollow3D") as PathFollow3D
	var drop_pivot := skeleton.get_node(^"PathFollow3D/DropPivot") as Node3D
	var skeleton_body := skeleton.get_node(^"PathFollow3D/DropPivot/SkeletonBody") as AnimatableBody3D
	var editor_placement := skeleton.get_node(^"GroundEditorPlacement") as GDGroundEnemyEditorPlacement
	var first_path_point := skeleton.curve.get_point_position(0)
	expect(
		first_path_point.is_zero_approx()
			and path_follow.position.is_equal_approx(first_path_point),
		"The skeleton editor origin, character carrier, and first patrol point coincide."
	)
	expect(
		is_zero_approx(path_follow.position.y)
			and is_zero_approx(drop_pivot.position.y)
			and is_zero_approx(skeleton_body.position.y),
		"The authored skeleton body origin rests at ground height."
	)
	expect_equal(
		editor_placement.floor_sample_path,
		NodePath("../PathFollow3D"),
		"The skeleton editor placement helper samples its path follower position."
	)
	skeleton.free()


func _test_rotated_path_keeps_skeleton_upright(tree: SceneTree) -> void:
	var skeleton := SKELETON_SCENE.instantiate() as Node3D
	skeleton.rotation = Vector3(0.35, 1.2, -0.25)
	tree.root.add_child(skeleton)
	var drop_pivot := skeleton.get_node(^"PathFollow3D/DropPivot") as Node3D
	expect(
		drop_pivot.global_basis.is_equal_approx(Basis.IDENTITY),
		"A rotated patrol path does not tilt or turn the skeleton carrier."
	)
	skeleton.free()
