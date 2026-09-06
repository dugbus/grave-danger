extends "res://tests/test_case.gd"

const SUBJECT := preload("res://addons/floor_surface/floor_surface.gd")
const SURFACE_SCENE := preload("res://addons/floor_surface/floor_surface.tscn")
const MAP_SCRIPT := preload("res://addons/floor_surface/floor_map.gd")
const PROFILE_SCRIPT := preload("res://addons/floor_surface/floor_elevation_profile.gd")
const STYLE_SCRIPT := preload("res://addons/floor_surface/floor_style.gd")


func run(tree: SceneTree) -> void:
	expect_script_contract(SUBJECT, "res://addons/floor_surface/floor_surface.gd")
	_test_queries_boundaries_and_origin()
	await _test_rebuild_and_collision_agreement(tree)


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
	surface.transform.origin.y = 1.0
	expect_equal(
		surface.validate_configuration().size(),
		2,
		"Missing palette and unsupported root height are both reported."
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
