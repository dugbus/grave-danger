extends "res://tests/test_case.gd"

const SUBJECT := preload("res://addons/floor_surface/floor_surface_geometry_builder.gd")
const MAP_SCRIPT := preload("res://addons/floor_surface/floor_map.gd")
const PROFILE_SCRIPT := preload("res://addons/floor_surface/floor_elevation_profile.gd")
const STYLE_SCRIPT := preload("res://addons/floor_surface/floor_style.gd")


func run(_tree: SceneTree) -> void:
	expect_script_contract(
		SUBJECT,
		"res://addons/floor_surface/floor_surface_geometry_builder.gd"
	)
	var floor_map := MAP_SCRIPT.new()
	floor_map.minimum_cell = Vector2i(-1, 0)
	floor_map.dimensions = Vector2i(3, 1)
	floor_map.default_present = true
	floor_map.presence_exceptions = [Vector2i.ZERO]
	var profile := PROFILE_SCRIPT.new()
	profile.elevation_unit = 0.25
	var style := STYLE_SCRIPT.new()
	style.top_material = StandardMaterial3D.new()
	var styles: Array[STYLE_SCRIPT] = [style]
	var result := SUBJECT.new().build(floor_map, profile, styles, 2.0, Vector2(10.0, -4.0))
	var mesh := result["mesh"] as ArrayMesh
	var shape := result["collision_shape"] as ConcavePolygonShape3D
	expect_equal(result["cell_count"], 2, "Only present cells generate flat tops.")
	expect_equal(mesh.get_surface_count(), 1, "Cells sharing a style use one batched mesh surface.")
	var arrays := mesh.surface_get_arrays(0)
	var rendered_vertices := arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array
	expect_equal(rendered_vertices.size(), 12, "Two cells generate four matching top triangles.")
	expect_equal(shape.get_faces().size(), 12, "Collision uses the same four top triangles.")
	expect(
		rendered_vertices.has(Vector3(8.0, 0.0, -4.0)),
		"Negative cells, origin and cell size determine generated coordinates."
	)
