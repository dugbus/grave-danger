extends "res://tests/test_case.gd"

const SUBJECT := preload("res://enemies/zombie.gd")
const SUBJECT_PATH := "res://enemies/zombie.gd"
const ZOMBIE_SCENE := preload("res://enemies/zombie.tscn")


class DeathCollisionSubject extends GDZombiePath:
	func _play_death_scream() -> void:
		pass

	func _play_death_animation() -> void:
		pass

	func _disappear_after_death() -> void:
		pass


func run(tree: SceneTree) -> void:
	expect_script_contract(SUBJECT, SUBJECT_PATH)
	_test_authored_start_matches_first_path_point()
	_test_rotated_path_keeps_zombie_upright(tree)
	_test_death_releases_collision()


func _test_death_releases_collision() -> void:
	for spike_death in [true, false]:
		var zombie := DeathCollisionSubject.new()
		var body := CharacterBody3D.new()
		body.collision_layer = GDZombiePath.ZOMBIE_COLLISION_LAYER
		body.collision_mask = GDZombiePath.ZOMBIE_COLLISION_LAYER
		zombie.add_child(body)
		zombie.zombie_body = body
		if spike_death:
			zombie.die_from_spike_trap()
		else:
			zombie._die_from_rolling_ball()
		expect(zombie.is_dead and zombie.state == GDZombiePath.ZombieState.Die, "Spike and crush deaths retain the explicit dead state.")
		expect(body.collision_layer == 0 and body.collision_mask == 0, "Both death causes immediately remove the upright corpse's physical blocking.")
		zombie.free()


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
