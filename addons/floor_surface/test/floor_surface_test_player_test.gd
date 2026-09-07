extends "res://tests/test_case.gd"

const SUBJECT := preload("res://addons/floor_surface/test/floor_surface_test_player.gd")
const SETTINGS := preload("res://addons/floor_surface/test/floor_surface_test_player_settings.gd")


func run(_tree: SceneTree) -> void:
	expect_script_contract(
		SUBJECT,
		"res://addons/floor_surface/test/floor_surface_test_player.gd"
	)
	var player := SUBJECT.new()
	player.settings = SETTINGS.new()
	player.update_velocity(Vector3.RIGHT, false, true, 0.1)
	expect(
		is_equal_approx(player.velocity.x, player.settings.acceleration * 0.1),
		"Held movement input accelerates toward the configured speed."
	)
	player.update_velocity(Vector3.ZERO, false, true, 0.1)
	expect_equal(
		player.velocity,
		Vector3.ZERO,
		"Released movement input decelerates without retaining vertical motion on the floor."
	)
	player.update_velocity(Vector3.ZERO, true, true, 0.1)
	expect(
		is_equal_approx(player.velocity.y, player.settings.get_jump_velocity()),
		"A grounded jump uses the shared height-derived launch speed."
	)
	expect_equal(
		player.resolve_walkable_step_height(0.0, 0.25, 0.02, true),
		0.25,
		"A grounded player receives the configured one-unit step lift."
	)
	expect_equal(
		player.resolve_walkable_step_height(0.0, 0.5, 0.02, true),
		0.0,
		"A normal-jump ledge is never silently converted into a walkable step."
	)
	player.toggle_traversal_mode()
	expect_equal(player.get_traversal_mode_name(), "Unencumbered", "The reserved test mode is explicit.")
	player.velocity = Vector3(2.0, -4.0, 1.0)
	var reset_transform := Transform3D(Basis.IDENTITY, Vector3(3.0, 2.0, -1.0))
	player.reset_to_transform(reset_transform)
	expect_equal(player.transform, reset_transform, "Reset restores the requested pose off-tree.")
	expect_equal(player.velocity, Vector3.ZERO, "Reset clears all accumulated motion.")
	expect(player.should_reset(-3.1), "Positions below the configured fall boundary reset.")
	expect(not player.should_reset(-3.0), "The fall boundary itself remains inside the safe range.")
	player.free()
