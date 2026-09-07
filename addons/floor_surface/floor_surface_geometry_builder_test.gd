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
	_test_flat_top_batching()
	_test_owned_ledge_rendering_and_collision()


func _test_flat_top_batching() -> void:
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
	expect_equal(mesh.get_surface_count(), 2, "Shared-style tops and exposed sides each use one batch.")
	var arrays := mesh.surface_get_arrays(0)
	var rendered_vertices := arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array
	var edge_arrays := mesh.surface_get_arrays(1)
	var edge_vertices := edge_arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array
	expect_equal(rendered_vertices.size(), 12, "Two cells generate four matching top triangles.")
	expect_equal(edge_vertices.size(), 48, "Hole and outer boundaries generate eight side quads.")
	expect_equal(shape.get_faces().size(), 60, "Collision includes the top and every exposed side.")
	expect(
		rendered_vertices.has(Vector3(8.0, 0.0, -4.0)),
		"Negative cells, origin and cell size determine generated coordinates."
	)
	expect(
		edge_vertices.has(Vector3(10.0, -2.0, -4.0)),
		"A hole-facing side reaches the style's provisional exposed depth."
	)
	expect(
		edge_vertices.has(Vector3(8.0, -2.0, -4.0)),
		"The outer map boundary receives the same visible side treatment."
	)
	expect_equal(result["ledge_face_count"], 8, "Each exposed edge is owned exactly once.")


func _test_owned_ledge_rendering_and_collision() -> void:
	var floor_map := MAP_SCRIPT.new()
	floor_map.dimensions = Vector2i(3, 1)
	floor_map.default_present = true
	floor_map.set_cell_elevation(Vector2i(1, 0), 2)
	floor_map.set_cell_elevation(Vector2i(2, 0), 2)
	var profile := PROFILE_SCRIPT.new()
	profile.elevation_unit = 0.25
	var style := STYLE_SCRIPT.new()
	style.top_material = StandardMaterial3D.new()
	style.edge_material = StandardMaterial3D.new()
	var styles: Array[STYLE_SCRIPT] = [style]
	var result := SUBJECT.new().build(floor_map, profile, styles, 1.0, Vector2.ZERO)
	var mesh := result["mesh"] as ArrayMesh
	var shape := result["collision_shape"] as ConcavePolygonShape3D
	expect_equal(
		result["ledge_face_count"],
		9,
		"The higher cell owns one shared ledge in addition to the eight outer sides."
	)
	expect_equal(mesh.get_surface_count(), 2, "Top and edge materials use separate batched surfaces.")
	var edge_arrays := mesh.surface_get_arrays(1)
	var edge_vertices := edge_arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array
	expect_equal(edge_vertices.size(), 54, "Every owned elevation and outer boundary creates one quad.")
	expect(edge_vertices.has(Vector3(1.0, 0.5, 0.0)), "The ledge reaches the higher top.")
	expect(edge_vertices.has(Vector3(1.0, 0.0, 1.0)), "The ledge meets the lower neighbour.")
	expect_equal(shape.get_faces().size(), 72, "Collision contains three tops and all nine side quads.")
