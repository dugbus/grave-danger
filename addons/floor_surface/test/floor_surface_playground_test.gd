extends "res://tests/test_case.gd"

const SUBJECT := preload("res://addons/floor_surface/test/floor_surface_playground.gd")
const PLAYGROUND := preload("res://addons/floor_surface/test/floor_surface_playground.tscn")
const PLAYER_SCRIPT := preload("res://addons/floor_surface/test/floor_surface_test_player.gd")
const SURFACE_SCRIPT := preload("res://addons/floor_surface/floor_surface.gd")


func run(tree: SceneTree) -> void:
	expect_script_contract(
		SUBJECT,
		"res://addons/floor_surface/test/floor_surface_playground.gd"
	)
	var playground := PLAYGROUND.instantiate() as SUBJECT
	expect(playground != null, "The standalone playground scene instantiates safely.")
	if playground == null:
		return

	tree.root.add_child(playground)
	await tree.process_frame
	var player := playground.get_node_or_null("Player") as PLAYER_SCRIPT
	var camera := playground.get_node_or_null("Camera3D") as Camera3D
	var status := playground.get_node_or_null("HUD/Panel/Margin/Rows/Status") as Label
	var surface := playground.get_node_or_null("FloorSurface") as SURFACE_SCRIPT
	expect(player != null, "The playground owns its independent test player.")
	expect(camera != null and camera.current, "The playground owns an active fixed camera.")
	expect(surface != null, "The M2 fixture replaces its temporary pad with FloorSurface.")
	expect(
		surface.floor_map.resource_local_to_scene,
		"The M3 authoring trial persists an independent map with the playground scene."
	)
	expect_equal(
		surface.get_generated_cell_count(),
		164,
		"The M6 fixture retains every accepted top while adding transitions to existing cells."
	)
	expect_equal(surface.validate_configuration(), [], "The saved floor surface has no configuration warnings.")
	expect_equal(surface.styles.size(), 2, "The playground exposes two reusable text-material styles.")
	expect_equal(surface.styles[1].display_name, "Flagstones", "The second style is named for painting.")
	expect_equal(
		surface.elevation_profile.validate_controller_limits(
			player.settings.maximum_step_height,
			player.settings.normal_jump_height,
			player.settings.unencumbered_jump_height
		),
		[],
		"The M4 traversal profile and physical controller thresholds agree."
	)
	expect(not surface.sample_surface(Vector3.ZERO).valid, "The central 2x2 hole has no sampled floor.")
	expect_equal(surface.floor_map.get_cell_style(Vector2i.ZERO), 1, "The absent pit cell owns stone-bottom style intent.")
	expect_equal(surface.get_cell_elevation(Vector2i(-1, -2)), 1, "The north pit rim uses a one-unit height.")
	expect_equal(surface.get_cell_elevation(Vector2i(1, -1)), 2, "The stone east rim uses a two-unit height.")
	var pit_query := PhysicsRayQueryParameters3D.create(
		Vector3(0.5, 2.0, 0.5),
		Vector3(0.5, -4.0, 0.5)
	)
	expect(
		surface.get_world_3d().direct_space_state.intersect_ray(pit_query).is_empty(),
		"The visible M5 pit bottom remains non-collidable so the player falls through."
	)
	expect(
		status != null and status.text.contains("Floor surface: valid"),
		"The debug panel shows the player's live M2 floor sample."
	)
	expect_equal(surface.get_cell_elevation(Vector2i(-6, 10)), 24, "The high lane starts at 24 units / 6m.")
	expect_equal(
		surface.floor_map.get_cell_transition(Vector2i(-4, 3)),
		surface.floor_map.Transition.Ramp,
		"The first route transition is stored as explicit ramp intent."
	)
	expect_equal(
		surface.floor_map.get_cell_low_edge(Vector2i(-4, 3)),
		surface.floor_map.LowEdge.West,
		"The route's low edge faces its lower west landing."
	)
	var ramp_sample := surface.sample_surface(Vector3(-3.5, 0.0, 3.5))
	expect(
		is_equal_approx(ramp_sample.world_height, 0.3),
		"The first tile reaches one tenth of the route's three-metre rise at its centre."
	)
	expect(ramp_sample.surface_normal.x < -0.2, "The route reports a usable east-rising slope normal.")
	var middle_ramp_sample := surface.sample_surface(Vector3(-1.5, 0.0, 3.5))
	expect(
		is_equal_approx(middle_ramp_sample.world_height, 1.5),
		"The middle of five ramp tiles reaches half of the arbitrary endpoint rise."
	)
	for x_coordinate in range(-5, 1):
		expect_equal(
			surface.classify_edge(
				Vector2i(x_coordinate, 3),
				Vector2i(x_coordinate + 1, 3)
			),
			surface.elevation_profile.TraversalClass.Flat,
			"Every landing and internal seam in the continuous run is traversal-flat."
		)
	expect_equal(
		surface.classify_edge(Vector2i(-4, 6), Vector2i(-3, 6)),
		surface.elevation_profile.TraversalClass.Flat,
		"A comparison plateau remains flat."
	)
	expect_equal(
		surface.classify_edge(Vector2i(-5, 6), Vector2i(-4, 6)),
		surface.elevation_profile.TraversalClass.WalkableStep,
		"The low lane begins with a walkable one-unit step."
	)
	expect_equal(
		surface.classify_edge(Vector2i(-5, 10), Vector2i(-4, 10)),
		surface.elevation_profile.TraversalClass.WalkableStep,
		"The high lane has the same local classification at a different absolute elevation."
	)
	var first_trial_name := playground.get_trial_name()
	playground.cycle_trial()
	expect(playground.get_trial_name() != first_trial_name, "A human can cycle to a comparison lane.")
	expect_equal(player.reset_marker, playground.get_node("LowLaneStart"), "Trial cycling updates repeatable reset.")
	await _test_physical_traversal_lanes(tree, playground, player)
	playground.cycle_trial()
	expect_equal(
		playground.get_trial_name(),
		"Variable five-tile ramp run",
		"A human can reset directly to the M6 ramp route."
	)
	expect_equal(player.reset_marker, playground.get_node("RampRouteStart"), "The ramp trial has a repeatable start.")
	await _settle_player(tree, player, 15)
	await _move_player_east(tree, player, 65)
	expect(
		player.global_position.x > -1.0 and player.global_position.y > 1.3,
		"The physical controller walks up the continuous three-metre ramp without jumping."
	)
	var first_view_name := playground.get_camera_view_name()
	playground.cycle_camera_view()
	expect(
		playground.get_camera_view_name() != first_view_name,
		"A human can cycle to a named alternate camera arrangement."
	)
	playground.queue_free()
	await tree.process_frame
	expect(not is_instance_valid(playground), "The standalone scene tears down without retained nodes.")


func _test_physical_traversal_lanes(
	tree: SceneTree,
	playground: SUBJECT,
	player: PLAYER_SCRIPT
) -> void:
	player.set_physics_process(false)
	await _settle_player(tree, player, 15)
	await _move_player_east(tree, player, 55)
	expect(
		player.global_position.x > -2.5 and player.global_position.x < -2.1,
		"Walking climbs the one-unit step and stops physically at the normal-jump ledge."
	)
	await _move_player_east(tree, player, 45, 2)
	expect(player.global_position.x > -0.5, "The normal jump crosses the two-unit ledge.")
	await _move_player_east(tree, player, 40, 2)
	expect(player.global_position.x < -0.2, "Normal mode cannot cross the reserved three-unit ledge.")
	player.toggle_traversal_mode()
	await _move_player_east(tree, player, 45, 2)
	expect(player.global_position.x > 1.4, "Unencumbered mode crosses the three-unit ledge.")
	await _move_player_east(tree, player, 40, 2)
	expect(player.global_position.x < 1.9, "The four-unit ledge remains blocked in both modes.")
	playground.cycle_trial()
	await _settle_player(tree, player, 15)
	await _move_player_east(tree, player, 55)
	expect(
		player.global_position.y > 6.8 and player.global_position.x > -2.5,
		"The high lane enforces the same physical walkable step at a 24-unit base."
	)


func _settle_player(tree: SceneTree, player: PLAYER_SCRIPT, frames: int) -> void:
	for _frame in frames:
		player.update_velocity(Vector3.ZERO, false, player.is_on_floor(), 1.0 / 60.0)
		player.move_and_slide()
		await tree.physics_frame


func _move_player_east(
	tree: SceneTree,
	player: PLAYER_SCRIPT,
	frames: int,
	jump_frame := -1
) -> void:
	for frame in frames:
		var grounded := player.is_on_floor()
		player.update_velocity(Vector3.RIGHT, frame == jump_frame, grounded, 1.0 / 60.0)
		player._apply_walkable_step(Vector3.RIGHT, grounded)
		player._apply_traversal_gate(Vector3.RIGHT)
		player.move_and_slide()
		await tree.physics_frame
