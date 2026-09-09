extends "res://tests/test_case.gd"

const SUBJECT := preload("res://addons/floor_surface/editor/floor_surface_elevation_overlay.gd")
const FLOOR_MAP_SCRIPT := preload("res://addons/floor_surface/floor_map.gd")
const PROFILE_SCRIPT := preload("res://addons/floor_surface/floor_elevation_profile.gd")


func run(_tree: SceneTree) -> void:
	expect_script_contract(
		SUBJECT,
		"res://addons/floor_surface/editor/floor_surface_elevation_overlay.gd"
	)
	var floor_map := FLOOR_MAP_SCRIPT.new()
	floor_map.minimum_cell = Vector2i(-1, 0)
	floor_map.dimensions = Vector2i(2, 1)
	floor_map.default_present = true
	floor_map.set_cell_elevation(Vector2i(-1, 0), -2)
	floor_map.set_cell_elevation(Vector2i.ZERO, 24)
	var profile := PROFILE_SCRIPT.new()
	profile.elevation_unit = 0.25
	var mesh := SUBJECT.build_mesh(floor_map, profile, 1.0, Vector2.ZERO)
	expect_equal(mesh.get_surface_count(), 1, "The overlay batches every elevation into one surface.")
	var arrays := mesh.surface_get_arrays(0)
	var vertices := arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array
	var colours := arrays[Mesh.ARRAY_COLOR] as PackedColorArray
	var uvs := arrays[Mesh.ARRAY_TEX_UV] as PackedVector2Array
	expect_equal(vertices.size(), 12, "Two cells produce two coloured overlay quads.")
	expect_equal(uvs.size(), vertices.size(), "Every vertex carries a grid-guide coordinate.")
	expect(
		vertices.has(Vector3(0.0, 6.025, 0.0)),
		"Elevation 24 appears at six metres plus the preview offset."
	)
	expect(colours[0] != colours[6], "Negative and tall elevations remain visually distinguishable.")
	expect(
		colours[0].get_luminance() <= 0.38,
		"Elevation tint luminance remains muted for low-glare editing."
	)
	expect(
		absf(colours[0].a - 0.26) < 0.01,
		"The subtle overlay leaves the authored checker contrast visible."
	)
	var ramp_map := FLOOR_MAP_SCRIPT.new()
	ramp_map.dimensions = Vector2i(3, 3)
	ramp_map.default_present = true
	ramp_map.set_cell_elevation(Vector2i(2, 1), 1)
	ramp_map.set_cell_transition(
		Vector2i.ONE,
		FLOOR_MAP_SCRIPT.Transition.Ramp,
		FLOOR_MAP_SCRIPT.LowEdge.West,
		0
	)
	var ramp_mesh := SUBJECT.build_mesh(ramp_map, profile, 1.0, Vector2.ZERO)
	var ramp_arrays := ramp_mesh.surface_get_arrays(0)
	var ramp_vertices := ramp_arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array
	var ramp_normals := ramp_arrays[Mesh.ARRAY_NORMAL] as PackedVector3Array
	expect(
		ramp_vertices.has(Vector3(2.0, 0.275, 1.0)),
		"The elevation and optional grid overlays follow the generated ramp high edge."
	)
	expect(
		_has_sloped_normal(ramp_normals),
		"Overlay lighting data follows the ramp instead of presenting a flat guide."
	)
	var ramp_mask_mesh := SUBJECT.build_mesh(
		ramp_map,
		profile,
		1.0,
		Vector2.ZERO,
		SUBJECT.SURFACE_OFFSET,
		SUBJECT.ColourMode.RampMask
	)
	var ramp_mask_colours := (
		ramp_mask_mesh.surface_get_arrays(0)[Mesh.ARRAY_COLOR] as PackedColorArray
	)
	var marked_vertex_count := 0
	for colour in ramp_mask_colours:
		if colour.r > 0.5:
			marked_vertex_count += 1
	expect_equal(
		marked_vertex_count,
		6,
		"Ramp-mask mode marks exactly the authored ramp quad for the optional grid."
	)


func _has_sloped_normal(normals: PackedVector3Array) -> bool:
	for normal in normals:
		if normal.x < -0.2 and normal.y > 0.9:
			return true
	return false
