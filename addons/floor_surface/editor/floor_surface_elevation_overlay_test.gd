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
