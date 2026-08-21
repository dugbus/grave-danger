extends "res://tests/test_case.gd"

const SUBJECT := preload("res://enemies/zombie.gd")
const SUBJECT_PATH := "res://enemies/zombie.gd"
const ZOMBIE_SCENE := preload("res://enemies/zombie.tscn")


func run(tree: SceneTree) -> void:
	expect_script_contract(SUBJECT, SUBJECT_PATH)
	_test_authored_start_matches_first_path_point()
	_test_rotated_path_keeps_zombie_upright(tree)


func _test_authored_start_matches_first_path_point() -> void:
	var zombie := ZOMBIE_SCENE.instantiate() as Path3D
	var path_follow := zombie.get_node(^"PathFollow3D") as PathFollow3D
	var zombie_body := zombie.get_node(^"ZombieBody") as CharacterBody3D
	var editor_placement := zombie.get_node(^"GroundEditorPlacement") as GDGroundEnemyEditorPlacement
	var first_path_point := zombie.curve.get_point_position(0)
	expect(
		first_path_point.is_zero_approx()
			and path_follow.position.is_equal_approx(first_path_point),
		"The zombie editor origin, path follower, and first patrol point coincide."
	)
	expect(
		zombie_body.position.is_equal_approx(first_path_point),
		"The authored zombie body starts on the first patrol point for editor placement."
	)
	expect(
		is_zero_approx(zombie_body.position.y),
		"The authored zombie body origin rests at ground height."
	)
	expect_equal(
		editor_placement.floor_sample_path,
		NodePath("../ZombieBody"),
		"The zombie editor placement helper samples the authored body position."
	)
	zombie.free()


func _test_rotated_path_keeps_zombie_upright(tree: SceneTree) -> void:
	var zombie := ZOMBIE_SCENE.instantiate() as Node3D
	zombie.rotation = Vector3(-0.3, -1.15, 0.2)
	tree.root.add_child(zombie)
	var zombie_body := zombie.get_node(^"ZombieBody") as CharacterBody3D
	expect(
		zombie_body.global_basis.is_equal_approx(Basis.IDENTITY),
		"A rotated patrol path does not tilt or turn the zombie body."
	)
	zombie.free()
