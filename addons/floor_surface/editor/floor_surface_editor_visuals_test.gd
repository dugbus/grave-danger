extends "res://tests/test_case.gd"

const SUBJECT := preload("res://addons/floor_surface/editor/floor_surface_editor_visuals.gd")
const FLOOR_MAP_SCRIPT := preload("res://addons/floor_surface/floor_map.gd")
const PROFILE_SCRIPT := preload("res://addons/floor_surface/floor_elevation_profile.gd")


func run(_tree: SceneTree) -> void:
	expect_script_contract(
		SUBJECT,
		"res://addons/floor_surface/editor/floor_surface_editor_visuals.gd"
	)
	var target := Node3D.new()
	var visuals := SUBJECT.new()
	visuals.attach(target)
	expect_equal(target.get_child_count(), 3, "Editor feedback uses three transient child meshes.")
	visuals.update_footprint(
		[Vector2i(-1, 2), Vector2i.ZERO],
		2.0,
		Vector2(4.0, -3.0),
		6.0,
		Color.YELLOW,
		true
	)
	var footprint := target.get_node("_FloorSurfacePaintPreview") as MeshInstance3D
	expect(footprint.visible, "A non-empty active footprint is visible.")
	expect(is_equal_approx(footprint.position.y, 6.04), "The footprint follows a tall authored height.")
	var footprint_material := footprint.mesh.surface_get_material(0) as StandardMaterial3D
	expect(
		not footprint_material.no_depth_test,
		"The highlight respects scene depth instead of appearing to float through floors."
	)
	var slope_descriptions: Dictionary = {
		Vector2i.ZERO: {
			# Dictionaries loaded from editor preview state may expose an untyped Array.
			"corner_heights": [0.0, 0.0, 1.0, 1.0],
		},
	}
	visuals.update_surface_footprint(
		[Vector2i.ZERO],
		1.0,
		Vector2.ZERO,
		slope_descriptions,
		Color.SKY_BLUE,
		true
	)
	var slope_vertices := (
		footprint.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX] as PackedVector3Array
	)
	expect(
		slope_vertices.has(Vector3(0.0, 0.04, 0.0)) \
			and slope_vertices.has(Vector3(1.0, 1.04, 1.0)),
		"A transition highlight follows the intended slope instead of one floating plane."
	)
	var floor_map := FLOOR_MAP_SCRIPT.new()
	floor_map.default_present = true
	var profile := PROFILE_SCRIPT.new()
	visuals.update_elevation_overlay(floor_map, profile, 1.0, Vector2.ZERO, true)
	var overlay := target.get_node("_FloorSurfaceElevationOverlay") as MeshInstance3D
	expect(overlay.visible and overlay.mesh.get_surface_count() == 1, "The elevation overlay is populated.")
	var grid := target.get_node("_FloorSurfaceGridOverlay") as MeshInstance3D
	expect(not grid.visible, "The texture-obscuring grid guide starts hidden.")
	floor_map.dimensions = Vector2i(3, 1)
	floor_map.set_cell_elevation(Vector2i(2, 0), 4)
	floor_map.set_cell_transition(
		Vector2i(1, 0),
		FLOOR_MAP_SCRIPT.Transition.Ramp,
		FLOOR_MAP_SCRIPT.LowEdge.West
	)
	visuals.update_grid_overlay(floor_map, profile, 1.0, Vector2.ZERO, true, true)
	expect(grid.visible and grid.mesh.get_surface_count() == 1, "The optional grid guide can be shown.")
	var grid_material := grid.mesh.surface_get_material(0) as ShaderMaterial
	expect(
		grid_material.get_shader_parameter(&"highlight_ramps") as bool,
		"Ramp mode enables the grid's authored-transition tint."
	)
	expect(is_equal_approx(
		grid_material.get_shader_parameter(&"grid_width") as float,
		SUBJECT.GRID_WIDTH
	), "The enabled guide uses a clearly readable line width.")
	var grid_colour := grid_material.get_shader_parameter(&"grid_colour") as Color
	expect(
		grid_colour.a >= 0.5 and grid_colour.get_luminance() < 0.55,
		"Grid lines are obvious when requested without becoming a high-glare overlay."
	)
	var ramp_colour := grid_material.get_shader_parameter(&"ramp_tile_colour") as Color
	expect(
		ramp_colour.a < 0.35 and ramp_colour.get_luminance() < 0.45,
		"The ramp tint remains muted enough for low-glare editing."
	)
	var grid_colours := (
		grid.mesh.surface_get_arrays(0)[Mesh.ARRAY_COLOR] as PackedColorArray
	)
	var ramp_vertex_count := 0
	for colour in grid_colours:
		if colour.r > 0.5:
			ramp_vertex_count += 1
	expect_equal(ramp_vertex_count, 6, "Only one authored ramp tile receives the tint mask.")
	visuals.update_grid_overlay(floor_map, profile, 1.0, Vector2.ZERO, true, false)
	expect(
		not grid_material.get_shader_parameter(&"highlight_ramps") as bool,
		"Leaving Ramp mode disables the tint while retaining the ordinary grid."
	)
	visuals.update_grid_overlay(floor_map, profile, 1.0, Vector2.ZERO, false)
	expect(not grid.visible, "The grid guide can be hidden to inspect the floor texture.")
	visuals.detach()
	expect_equal(target.get_child_count(), 0, "Detaching removes only the transient feedback meshes.")
	target.free()
