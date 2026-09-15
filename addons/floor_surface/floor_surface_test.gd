extends "res://tests/test_case.gd"

const SUBJECT := preload("res://addons/floor_surface/floor_surface.gd")
const SURFACE_SCENE := preload("res://addons/floor_surface/floor_surface.tscn")
const MAP_SCRIPT := preload("res://addons/floor_surface/floor_map.gd")
const PROFILE_SCRIPT := preload("res://addons/floor_surface/floor_elevation_profile.gd")
const STYLE_SCRIPT := preload("res://addons/floor_surface/floor_style.gd")


func run(tree: SceneTree) -> void:
	expect_script_contract(SUBJECT, "res://addons/floor_surface/floor_surface.gd")
	_test_queries_boundaries_and_origin()
	_test_cell_to_world_uses_surface_height()
	_test_ramp_queries_and_validation()
	_test_contiguous_ramp_edges_are_traversal_flat()
	await _test_incomplete_palette_is_safe(tree)
	await _test_rebuild_and_collision_agreement(tree)
	await _test_ramp_collision_agreement(tree)
	await _test_multiple_surface_instances_are_isolated(tree)


func _test_incomplete_palette_is_safe(tree: SceneTree) -> void:
	var surface := SURFACE_SCENE.instantiate() as FloorSurface
	var floor_map := MAP_SCRIPT.new()
	floor_map.default_present = true
	surface.floor_map = floor_map
	surface.elevation_profile = PROFILE_SCRIPT.new()
	surface.styles.clear()
	tree.root.add_child(surface)
	expect_equal(surface.get_generated_cell_count(), 0, "An incomplete palette builds no geometry.")
	expect(
		surface.top_mesh.mesh == null and surface.collision_shape.shape == null,
		"An incomplete palette safely clears its derived mesh and collision."
	)
	surface.queue_free()
	await tree.process_frame


func _test_queries_boundaries_and_origin() -> void:
	var surface := SUBJECT.new()
	var floor_map := MAP_SCRIPT.new()
	floor_map.minimum_cell = Vector2i(-2, -2)
	floor_map.dimensions = Vector2i(4, 4)
	floor_map.default_present = true
	floor_map.presence_exceptions = [Vector2i.ZERO]
	floor_map.set_cell_elevation(Vector2i(-1, 0), 3)
	var profile := PROFILE_SCRIPT.new()
	profile.elevation_unit = 0.5
	surface.floor_map = floor_map
	surface.elevation_profile = profile
	surface.cell_size = 2.0
	surface.world_origin_xz = Vector2(10.0, -6.0)
	expect_equal(
		surface.world_to_cell(Vector3(10.0, 0.0, -6.0)),
		Vector2i.ZERO,
		"An exact boundary belongs to the positive cell."
	)
	expect_equal(
		surface.world_to_cell(Vector3(9.999, 0.0, -6.001)),
		Vector2i(-1, -1),
		"Negative offsets use floor-based boundary ownership."
	)
	expect(
		not surface.sample_surface(Vector3(10.5, 8.0, -5.5)).valid,
		"A hole returns an invalid sample at every query Y."
	)
	var sample := surface.sample_surface(Vector3(8.5, -20.0, -5.5))
	expect(sample.valid, "A present negative cell returns a valid sample.")
	expect_equal(sample.cell, Vector2i(-1, 0), "Sampling reports the authoritative cell.")
	expect(is_equal_approx(sample.world_height, 1.5), "Sampling converts integer elevation through the shared unit.")
	expect_equal(sample.surface_normal, Vector3.UP, "Flat sampling reports an upward normal.")
	expect(is_nan(surface.get_world_height_at_cell(Vector2i(9, 9))), "Outside bounds has no implicit height.")
	floor_map.set_cell_elevation(Vector2i(-2, 0), 1)
	expect_equal(
		surface.classify_edge(Vector2i(-2, 0), Vector2i(-1, 0)),
		PROFILE_SCRIPT.TraversalClass.NormalJump,
		"Surface traversal uses the signed local elevation difference."
	)
	expect_equal(
		surface.get_elevation_delta(Vector2i(-2, 0), Vector2i(-1, 0)),
		2,
		"The surface exposes the exact directed integer delta."
	)
	surface.transform.origin.y = 1.0
	expect_equal(
		surface.validate_configuration().size(),
		2,
		"Missing palette and unsupported root height are both reported."
	)
	surface.free()


func _test_cell_to_world_uses_surface_height() -> void:
	var surface := SUBJECT.new()
	var floor_map := MAP_SCRIPT.new()
	floor_map.dimensions = Vector2i.ONE
	floor_map.default_present = true
	floor_map.set_cell_elevation(Vector2i.ZERO, 4)
	var profile := PROFILE_SCRIPT.new()
	profile.elevation_unit = 0.25
	surface.floor_map = floor_map
	surface.elevation_profile = profile
	surface.world_origin_xz = Vector2(-2.0, 3.0)
	surface.cell_size = 2.0
	expect_equal(
		surface.cell_to_world(Vector2i.ZERO),
		Vector3(-1.0, 1.0, 4.0),
		"Cell centres include the authored elevation and world origin."
	)
	surface.free()


func _test_ramp_queries_and_validation() -> void:
	var surface := SUBJECT.new()
	var floor_map := MAP_SCRIPT.new()
	floor_map.dimensions = Vector2i(3, 3)
	floor_map.default_present = true
	floor_map.set_cell_elevation(Vector2i(2, 1), 1)
	floor_map.set_cell_transition(
		Vector2i.ONE,
		MAP_SCRIPT.Transition.Ramp,
		MAP_SCRIPT.LowEdge.West,
		0
	)
	surface.floor_map = floor_map
	surface.elevation_profile = PROFILE_SCRIPT.new()
	var low_sample := surface.sample_surface(Vector3(1.0, 8.0, 1.5))
	var middle_sample := surface.sample_surface(Vector3(1.5, -8.0, 1.5))
	var high_sample := surface.sample_surface(Vector3(1.999, 0.0, 1.5))
	expect(is_equal_approx(low_sample.world_height, 0.0), "Ramp sampling meets its low edge.")
	expect(is_equal_approx(middle_sample.world_height, 0.125), "Ramp sampling interpolates its midpoint.")
	expect(is_equal_approx(high_sample.world_height, 0.24975), "Ramp sampling approaches its high edge.")
	expect(middle_sample.surface_normal.x < -0.2, "Ramp sampling reports the shared slope normal.")
	expect_equal(middle_sample.transition, MAP_SCRIPT.Transition.Ramp, "Ramp sampling identifies the transition.")
	expect(surface.get_transition_error(Vector2i.ONE).is_empty(), "A valid ramp has no editor error.")
	expect_equal(
		surface.classify_edge(Vector2i(0, 1), Vector2i.ONE),
		PROFILE_SCRIPT.TraversalClass.Flat,
		"A valid ramp endpoint is continuous regardless of its authored flat-cell delta."
	)
	floor_map.set_floor_present(Vector2i(2, 1), false)
	expect(
		not surface.get_transition_error(Vector2i.ONE).is_empty(),
		"Removing a required landing produces an actionable error."
	)
	expect(surface.validate_configuration().size() >= 2, "Surface warnings include invalid ramp and empty palette.")
	surface.free()


func _test_contiguous_ramp_edges_are_traversal_flat() -> void:
	var surface := SUBJECT.new()
	var floor_map := MAP_SCRIPT.new()
	floor_map.dimensions = Vector2i(7, 1)
	floor_map.default_present = true
	floor_map.set_cell_elevation(Vector2i(6, 0), 12)
	for x_coordinate in range(1, 6):
		floor_map.set_cell_transition(
			Vector2i(x_coordinate, 0),
			MAP_SCRIPT.Transition.Ramp,
			MAP_SCRIPT.LowEdge.West
		)
	surface.floor_map = floor_map
	surface.elevation_profile = PROFILE_SCRIPT.new()
	for x_coordinate in range(6):
		expect_equal(
			surface.classify_edge(
				Vector2i(x_coordinate, 0),
				Vector2i(x_coordinate + 1, 0)
			),
			PROFILE_SCRIPT.TraversalClass.Flat,
			"The traversal gate treats each continuous slope seam as floor."
		)
	surface.free()


func _test_rebuild_and_collision_agreement(tree: SceneTree) -> void:
	var surface := SURFACE_SCENE.instantiate() as SUBJECT
	var floor_map := MAP_SCRIPT.new()
	floor_map.minimum_cell = Vector2i(-1, 0)
	floor_map.dimensions = Vector2i(2, 1)
	floor_map.default_present = true
	floor_map.presence_exceptions = [Vector2i(0, 0)]
	var profile := PROFILE_SCRIPT.new()
	var style := STYLE_SCRIPT.new()
	style.top_material = StandardMaterial3D.new()
	var styles: Array[STYLE_SCRIPT] = [style]
	surface.floor_map = floor_map
	surface.elevation_profile = profile
	surface.styles = styles
	tree.root.add_child(surface)
	await tree.physics_frame
	await tree.physics_frame
	expect_equal(surface.get_generated_cell_count(), 1, "The rebuild excludes the authored hole.")
	var automatic_rebuild_count := surface.get_rebuild_count()
	floor_map.set_floor_present(Vector2i.ZERO, true)
	expect_equal(surface.get_generated_cell_count(), 2, "Map changes rebuild derived output immediately.")
	floor_map.set_floor_present(Vector2i.ZERO, false)
	expect_equal(surface.get_generated_cell_count(), 1, "Restoring a hole removes its derived top again.")
	expect_equal(
		surface.get_rebuild_count(),
		automatic_rebuild_count + 2,
		"Each authoritative occupancy change emits one complete rebuild."
	)
	var derived := surface.get_node("Derived") as Node3D
	var child_count_before := derived.get_child_count()
	var rebuild_count_before := surface.get_rebuild_count()
	surface.rebuild()
	surface.rebuild()
	expect_equal(derived.get_child_count(), child_count_before, "Repeated rebuilds do not duplicate derived nodes.")
	expect_equal(surface.get_rebuild_count(), rebuild_count_before + 2, "Each explicit rebuild completes once.")
	expect(
		surface.get_last_rebuild_microseconds() >= 0,
		"A complete rebuild records an editor-visible duration."
	)
	var space_state := surface.get_world_3d().direct_space_state
	var floor_query := PhysicsRayQueryParameters3D.create(
		Vector3(-0.5, 2.0, 0.5),
		Vector3(-0.5, -2.0, 0.5)
	)
	var hole_query := PhysicsRayQueryParameters3D.create(
		Vector3(0.5, 2.0, 0.5),
		Vector3(0.5, -2.0, 0.5)
	)
	expect(not space_state.intersect_ray(floor_query).is_empty(), "Visible floor has matching static collision.")
	expect(space_state.intersect_ray(hole_query).is_empty(), "The visible hole has no invisible collision bridge.")
	surface.queue_free()
	await tree.process_frame


func _test_ramp_collision_agreement(tree: SceneTree) -> void:
	var surface := SURFACE_SCENE.instantiate() as SUBJECT
	var floor_map := MAP_SCRIPT.new()
	floor_map.dimensions = Vector2i(3, 3)
	floor_map.default_present = true
	floor_map.set_cell_elevation(Vector2i(2, 1), 12)
	floor_map.set_cell_transition(
		Vector2i.ONE,
		MAP_SCRIPT.Transition.Ramp,
		MAP_SCRIPT.LowEdge.West,
		0
	)
	var style := STYLE_SCRIPT.new()
	style.top_material = StandardMaterial3D.new()
	style.wall_material = StandardMaterial3D.new()
	var styles: Array[STYLE_SCRIPT] = [style]
	surface.floor_map = floor_map
	surface.elevation_profile = PROFILE_SCRIPT.new()
	surface.styles = styles
	tree.root.add_child(surface)
	await tree.physics_frame
	await tree.physics_frame
	var query_position := Vector3(1.5, 0.0, 1.5)
	var sample := surface.sample_surface(query_position)
	expect(is_equal_approx(sample.world_height, 1.5), "A one-tile ramp may interpolate a three-metre rise.")
	var ray_query := PhysicsRayQueryParameters3D.create(
		query_position + Vector3.UP * 2.0,
		query_position + Vector3.DOWN * 2.0
	)
	var collision_hit := surface.get_world_3d().direct_space_state.intersect_ray(ray_query)
	expect(not collision_hit.is_empty(), "The generated ramp has static collision.")
	if not collision_hit.is_empty():
		var collision_position := collision_hit["position"] as Vector3
		var collision_normal := collision_hit["normal"] as Vector3
		expect(
			is_equal_approx(collision_position.y, sample.world_height),
			"Ramp collision and authoritative sampling agree at the midpoint."
		)
		expect(
			collision_normal.dot(sample.surface_normal) > 0.999,
			"Ramp collision and authoritative sampling expose the same normal."
		)
	surface.queue_free()
	await tree.process_frame


func _test_multiple_surface_instances_are_isolated(tree: SceneTree) -> void:
	var first_surface := SURFACE_SCENE.instantiate() as SUBJECT
	var second_surface := SURFACE_SCENE.instantiate() as SUBJECT
	var first_map := MAP_SCRIPT.new()
	first_map.dimensions = Vector2i(2, 1)
	first_map.default_present = true
	var second_map := first_map.create_unique_copy() as MAP_SCRIPT
	var style := STYLE_SCRIPT.new()
	style.top_material = StandardMaterial3D.new()
	var styles: Array[STYLE_SCRIPT] = [style]
	expect(first_map != second_map, "The independent workflow creates a separate FloorMap resource.")
	tree.root.add_child(first_surface)
	tree.root.add_child(second_surface)
	for surface in [first_surface, second_surface] as Array[SUBJECT]:
		surface.elevation_profile = PROFILE_SCRIPT.new()
		surface.styles = styles
	first_surface.floor_map = first_map
	second_surface.floor_map = second_map
	expect(first_surface.floor_map == first_map, "The first surface retains its assigned map.")
	expect(second_surface.floor_map == second_map, "The second surface retains its assigned map.")
	await tree.physics_frame
	expect_equal(first_surface.get_generated_cell_count(), 2, "The first surface builds its own map.")
	expect_equal(second_surface.get_generated_cell_count(), 2, "The second surface builds independently.")
	var edited_cell := Vector2i(1, 0)
	first_map.set_floor_present(edited_cell, false)
	expect_equal(first_surface.get_generated_cell_count(), 1, "Editing one map rebuilds only its owning surface data.")
	expect_equal(second_surface.get_generated_cell_count(), 2, "A separate surface keeps its map and derived output.")
	expect(second_surface.has_floor(edited_cell), "Multiple instances never share mutable FloorMap state accidentally.")
	first_surface.queue_free()
	second_surface.queue_free()
	await tree.process_frame
