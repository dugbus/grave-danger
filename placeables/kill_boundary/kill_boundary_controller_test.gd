extends "res://tests/test_case.gd"

const SUBJECT := preload("res://placeables/kill_boundary/kill_boundary_controller.gd")
const SUBJECT_PATH := "res://placeables/kill_boundary/kill_boundary_controller.gd"
const TUTORIAL_THREE_LEVEL := preload("res://levels/tutorial-3/level.tscn")


func run(tree: SceneTree) -> void:
	expect_script_contract(SUBJECT, SUBJECT_PATH)

	var level := TUTORIAL_THREE_LEVEL.instantiate()
	tree.root.add_child(level)
	var boundary := level.get_node("GDKillBoundary3D") as GDKillBoundary3D
	var player := level.get_node("Player") as GDPlayer
	var death_controller := player.get_node("PlayerDeath") as GDPlayerDeath
	var center := boundary.get_node("BoundaryCenter") as PathFollow3D
	var player_collision := player.get_node("CollisionShape3D") as CollisionShape3D
	var player_shape := player_collision.shape as CapsuleShape3D
	var blocker_body := boundary.blocker_bodies[0] as StaticBody3D
	var blocker_shape := boundary.blocker_collisions[0].shape as BoxShape3D

	player.global_position = center.global_transform * Vector3(
		boundary.get_bounds_size().x * 0.5,
		0.0,
		0.0,
	)
	player.global_position.y = 0.0
	var energy_before := death_controller.flame_energy
	boundary._apply_flame_heat(1.0)
	var blocker_bottom := blocker_body.global_position.y - blocker_shape.size.y * 0.5
	var player_top := player_collision.global_position.y + player_shape.height * 0.5
	expect(
		death_controller.flame_energy < energy_before,
		"Tutorial 3's grounded flame boundary damages the player at its perimeter."
	)
	expect(
		blocker_bottom <= player_top,
		"Tutorial 3's boundary blockers overlap the player's collision height."
	)
	level.free()
