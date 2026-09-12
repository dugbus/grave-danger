extends "res://tests/test_case.gd"

const SUBJECT := preload("res://addons/floor_surface/floor_surface_grounding.gd")
const SURFACE_SCRIPT := preload("res://addons/floor_surface/floor_surface.gd")
const MAP_SCRIPT := preload("res://addons/floor_surface/floor_map.gd")
const PROFILE_SCRIPT := preload("res://addons/floor_surface/floor_elevation_profile.gd")


func run(tree: SceneTree) -> void:
	expect_script_contract(SUBJECT, "res://addons/floor_surface/floor_surface_grounding.gd")
	await _test_flat_modes_offsets_and_stability(tree)
	await _test_ramp_alignment_and_missing_support(tree)


func _test_flat_modes_offsets_and_stability(tree: SceneTree) -> void:
	var fixture := _make_fixture()
	tree.root.add_child(fixture)
	var surface := fixture.get_node("Surface") as SURFACE_SCRIPT
	var target := fixture.get_node("Target") as Node3D
	var grounding := target.get_node("Grounding") as SUBJECT
	target.global_position = Vector3(0.5, 9.0, 0.5)
	target.scale = Vector3(2.0, 3.0, 4.0)
	grounding.height_offset = 0.35
	grounding.heading_radians = deg_to_rad(32.0)
	expect(grounding.conform(), "An upright object conforms to a present flat cell.")
	expect(
		is_equal_approx(target.global_position.y, 1.35),
		"Grounding retains its explicit world-up offset above the flat floor."
	)
	expect(target.global_basis.y.normalized().dot(Vector3.UP) > 0.999, "Upright mode remains vertical.")
	expect(target.global_basis.get_scale().is_equal_approx(Vector3(2.0, 3.0, 4.0)), "Conform preserves scale.")
	var first_transform := target.global_transform
	expect(grounding.conform(), "Repeated conform remains valid.")
	expect(
		target.global_transform.is_equal_approx(first_transform),
		"Repeated conform preserves heading, offset and transform exactly."
	)
	surface.surface_rebuilt.emit(1)
	expect(grounding.grounding_stale, "A floor rebuild marks a conformed object stale without moving it.")
	grounding.grounding_mode = SUBJECT.GroundingMode.Absolute
	target.global_position.y = 7.0
	expect(grounding.conform(), "Absolute mode is a valid no-op.")
	expect(is_equal_approx(target.global_position.y, 7.0), "Absolute mode preserves authored height.")
	surface.surface_rebuilt.emit(1)
	expect(not grounding.grounding_stale, "Absolute objects are not made stale by a floor rebuild.")
	fixture.queue_free()
	await tree.process_frame


func _test_ramp_alignment_and_missing_support(tree: SceneTree) -> void:
	var fixture := _make_fixture(true)
	tree.root.add_child(fixture)
	var surface := fixture.get_node("Surface") as SURFACE_SCRIPT
	var target := fixture.get_node("Target") as Node3D
	var grounding := target.get_node("Grounding") as SUBJECT
	target.global_position = Vector3(1.5, 8.0, 1.5)
	grounding.grounding_mode = SUBJECT.GroundingMode.AlignNormal
	grounding.height_offset = 0.1
	expect(grounding.conform(), "Align Normal conforms over a valid ramp.")
	var sample := surface.sample_surface(target.global_position)
	expect(
		target.global_basis.y.normalized().dot(sample.surface_normal) > 0.999,
		"Align Normal uses the authoritative ramp normal."
	)
	expect(is_equal_approx(target.global_position.y, sample.world_height + 0.1), "Ramp offset uses world-up space.")
	surface.floor_map.set_floor_present(Vector2i.ONE, false)
	var unchanged := target.global_transform
	expect(not grounding.conform(), "A missing supporting tile rejects conform.")
	expect(target.global_transform.is_equal_approx(unchanged), "Invalid support never moves an object to Y=0.")
	expect(not grounding.validate_grounding().is_empty(), "Missing support produces an editor warning.")
	fixture.queue_free()
	await tree.process_frame


func _make_fixture(with_ramp: bool = false) -> Node3D:
	var root := Node3D.new()
	var surface := SURFACE_SCRIPT.new()
	surface.name = "Surface"
	var floor_map := MAP_SCRIPT.new()
	floor_map.dimensions = Vector2i(3, 3)
	floor_map.default_present = true
	floor_map.default_elevation = 4
	if with_ramp:
		floor_map.default_elevation = 0
		floor_map.set_cell_elevation(Vector2i(2, 1), 4)
		floor_map.set_cell_transition(
			Vector2i.ONE,
			MAP_SCRIPT.Transition.Ramp,
			MAP_SCRIPT.LowEdge.West,
			0
		)
	surface.floor_map = floor_map
	surface.elevation_profile = PROFILE_SCRIPT.new()
	root.add_child(surface)
	var target := Node3D.new()
	target.name = "Target"
	root.add_child(target)
	var grounding := SUBJECT.new()
	grounding.name = "Grounding"
	target.add_child(grounding)
	grounding.surface_path = NodePath("../../Surface")
	return root
