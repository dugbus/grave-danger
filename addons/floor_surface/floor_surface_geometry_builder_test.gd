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
	_test_pit_bottom_materials_projection_and_collision()
	_test_material_only_style_change_preserves_collision()


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
	expect_equal(result["pit_region_count"], 1, "The bounded hole still resolves a wall datum.")
	expect_equal(result["pit_bottom_cell_count"], 0, "A missing optional pit material omits its bottom.")
	expect(
		_all_rendered_faces_use_clockwise_winding(mesh),
		"Top and exposed-side faces use Godot's visible clockwise winding."
	)


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


func _test_pit_bottom_materials_projection_and_collision() -> void:
	var floor_map := MAP_SCRIPT.new()
	floor_map.dimensions = Vector2i(3, 2)
	floor_map.default_present = true
	floor_map.set_floor_present(Vector2i(1, 0), false)
	floor_map.set_cell_style(Vector2i(1, 0), 1)
	floor_map.set_cell_style(Vector2i(2, 0), 1)
	floor_map.set_cell_style(Vector2i(2, 1), 1)
	floor_map.set_cell_elevation(Vector2i(2, 0), 2)
	floor_map.set_cell_elevation(Vector2i(2, 1), 2)
	var profile := PROFILE_SCRIPT.new()
	profile.elevation_unit = 0.25
	var teal_style := STYLE_SCRIPT.new()
	teal_style.top_material = StandardMaterial3D.new()
	teal_style.edge_material = StandardMaterial3D.new()
	teal_style.pit_depth = 1.0
	var stone_style := STYLE_SCRIPT.new()
	stone_style.world_uv_metres = 0.5
	stone_style.top_material = StandardMaterial3D.new()
	stone_style.edge_material = StandardMaterial3D.new()
	stone_style.pit_bottom_material = StandardMaterial3D.new()
	stone_style.pit_depth = 3.0
	var styles: Array[STYLE_SCRIPT] = [teal_style, stone_style]
	var result := SUBJECT.new().build(floor_map, profile, styles, 2.0, Vector2(10.0, -4.0))
	var mesh := result["mesh"] as ArrayMesh
	var shape := result["collision_shape"] as ConcavePolygonShape3D
	expect_equal(result["pit_region_count"], 1, "The bounded hole becomes one connected pit region.")
	expect_equal(result["pit_bottom_cell_count"], 1, "Only the styled absent cell gets a visual bottom.")
	expect_equal(mesh.get_surface_count(), 5, "Top and edge batches stay separate by style and pit material.")
	var top_surface := _find_material_surface(mesh, stone_style.top_material)
	var edge_surface := _find_material_surface(mesh, stone_style.edge_material)
	var pit_surface := _find_material_surface(mesh, stone_style.pit_bottom_material)
	expect(top_surface >= 0 and edge_surface >= 0 and pit_surface >= 0, "Every independent style material is used.")
	var top_arrays := mesh.surface_get_arrays(top_surface)
	var top_vertices := top_arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array
	var top_uvs := top_arrays[Mesh.ARRAY_TEX_UV] as PackedVector2Array
	expect(
		top_uvs.has(Vector2(28.0, -8.0)),
		"Top UVs use continuous world X/Z coordinates divided by the style scale."
	)
	expect_equal(
		_count_vertex_uv(top_vertices, top_uvs, Vector3(14.0, 0.5, -2.0), Vector2(28.0, -4.0)),
		3,
		"Adjacent cells use the same world UV at their shared top vertex."
	)
	var edge_arrays := mesh.surface_get_arrays(edge_surface)
	var edge_vertices := edge_arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array
	var edge_uvs := edge_arrays[Mesh.ARRAY_TEX_UV] as PackedVector2Array
	expect(
		edge_uvs.has(Vector2(28.0, 5.0)),
		"Axis-aligned side UVs use world horizontal/Y projection at the same scale."
	)
	expect(
		edge_vertices.has(Vector3(14.0, -2.5, -4.0)),
		"The stone hole wall reaches the shared mixed-rim bottom without a crack."
	)
	var pit_arrays := mesh.surface_get_arrays(pit_surface)
	var pit_vertices := pit_arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array
	var pit_uvs := pit_arrays[Mesh.ARRAY_TEX_UV] as PackedVector2Array
	expect(pit_vertices.has(Vector3(12.0, -2.5, -4.0)), "The visual bottom meets the mixed rim datum.")
	expect(pit_uvs.has(Vector2(24.0, -8.0)), "Pit bottoms share continuous world X/Z projection.")
	expect(
		not _has_horizontal_triangle_at_height(shape.get_faces(), -2.5),
		"Visual pit bottoms never add walkable collision."
	)


func _test_material_only_style_change_preserves_collision() -> void:
	var floor_map := MAP_SCRIPT.new()
	floor_map.dimensions = Vector2i(2, 1)
	floor_map.default_present = true
	var profile := PROFILE_SCRIPT.new()
	var first_style := STYLE_SCRIPT.new()
	first_style.top_material = StandardMaterial3D.new()
	first_style.edge_material = StandardMaterial3D.new()
	var second_style := STYLE_SCRIPT.new()
	second_style.top_material = StandardMaterial3D.new()
	second_style.edge_material = StandardMaterial3D.new()
	var styles: Array[STYLE_SCRIPT] = [first_style, second_style]
	var before := SUBJECT.new().build(floor_map, profile, styles, 1.0, Vector2.ZERO)
	floor_map.set_cell_style(Vector2i(1, 0), 1)
	var after := SUBJECT.new().build(floor_map, profile, styles, 1.0, Vector2.ZERO)
	var before_shape := before["collision_shape"] as ConcavePolygonShape3D
	var after_shape := after["collision_shape"] as ConcavePolygonShape3D
	expect_equal(after["cell_count"], before["cell_count"], "Style painting never changes floor topology.")
	expect_equal(
		after_shape.get_faces(),
		before_shape.get_faces(),
		"Styles with the same depth change appearance without changing collision."
	)


func _find_material_surface(mesh: ArrayMesh, material: Material) -> int:
	for surface_index in mesh.get_surface_count():
		if mesh.surface_get_material(surface_index) == material:
			return surface_index
	return -1


func _has_horizontal_triangle_at_height(faces: PackedVector3Array, height: float) -> bool:
	for index in range(0, faces.size(), 3):
		if is_equal_approx(faces[index].y, height) \
				and is_equal_approx(faces[index + 1].y, height) \
				and is_equal_approx(faces[index + 2].y, height):
			return true
	return false


func _count_vertex_uv(
	vertices: PackedVector3Array,
	uvs: PackedVector2Array,
	vertex: Vector3,
	uv: Vector2
) -> int:
	var count := 0
	for index in vertices.size():
		if vertices[index].is_equal_approx(vertex) and uvs[index].is_equal_approx(uv):
			count += 1
	return count


func _all_rendered_faces_use_clockwise_winding(mesh: ArrayMesh) -> bool:
	for surface_index in mesh.get_surface_count():
		var arrays := mesh.surface_get_arrays(surface_index)
		var vertices := arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array
		var normals := arrays[Mesh.ARRAY_NORMAL] as PackedVector3Array
		if vertices.size() != normals.size() or vertices.size() % 3 != 0:
			return false
		for triangle_start in range(0, vertices.size(), 3):
			var conventional_normal := (
				vertices[triangle_start + 1] - vertices[triangle_start]
			).cross(vertices[triangle_start + 2] - vertices[triangle_start])
			if conventional_normal.dot(normals[triangle_start]) >= 0.0:
				return false
	return true
