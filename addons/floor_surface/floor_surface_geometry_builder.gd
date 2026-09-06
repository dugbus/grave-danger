@tool
class_name FloorSurfaceGeometryBuilder
extends RefCounted

## Builds derived flat top rendering and collision from authoritative floor data.

const MAP_SCRIPT := preload("res://addons/floor_surface/floor_map.gd")
const PROFILE_SCRIPT := preload("res://addons/floor_surface/floor_elevation_profile.gd")
const STYLE_SCRIPT := preload("res://addons/floor_surface/floor_style.gd")


## Rebuilds one batched mesh surface per palette material and one shared static shape.
func build(
	floor_map: MAP_SCRIPT,
	profile: PROFILE_SCRIPT,
	styles: Array[STYLE_SCRIPT],
	cell_size: float,
	world_origin_xz: Vector2
) -> Dictionary:
	var mesh := ArrayMesh.new()
	var collision_vertices: Array[Vector3] = []
	var safe_cell_size := maxf(cell_size, 0.01)
	var present_cells := floor_map.get_present_cells()
	for style_index in styles.size():
		var vertices: Array[Vector3] = []
		var normals: Array[Vector3] = []
		var uvs: Array[Vector2] = []
		for cell in present_cells:
			if _resolve_style_index(floor_map.get_cell_style(cell), styles.size()) != style_index:
				continue
			_append_flat_cell(
				vertices,
				normals,
				uvs,
				cell,
				profile.elevation_to_world(floor_map.get_cell_elevation(cell)),
				safe_cell_size,
				world_origin_xz
			)
		if vertices.is_empty():
			continue
		var surface_arrays := []
		surface_arrays.resize(Mesh.ARRAY_MAX)
		surface_arrays[Mesh.ARRAY_VERTEX] = PackedVector3Array(vertices)
		surface_arrays[Mesh.ARRAY_NORMAL] = PackedVector3Array(normals)
		surface_arrays[Mesh.ARRAY_TEX_UV] = PackedVector2Array(uvs)
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, surface_arrays)
		var style := styles[style_index] as STYLE_SCRIPT
		mesh.surface_set_material(mesh.get_surface_count() - 1, style.top_material)

	for cell in present_cells:
		_append_flat_cell_collision(
			collision_vertices,
			cell,
			profile.elevation_to_world(floor_map.get_cell_elevation(cell)),
			safe_cell_size,
			world_origin_xz
		)
	var collision_shape := ConcavePolygonShape3D.new()
	collision_shape.backface_collision = true
	collision_shape.set_faces(PackedVector3Array(collision_vertices))
	return {
		"cell_count": present_cells.size(),
		"collision_shape": collision_shape,
		"mesh": mesh,
	}


func _append_flat_cell(
	vertices: Array[Vector3],
	normals: Array[Vector3],
	uvs: Array[Vector2],
	cell: Vector2i,
	height: float,
	cell_size: float,
	world_origin_xz: Vector2
) -> void:
	var corners := _get_cell_corners(cell, height, cell_size, world_origin_xz)
	var cell_uv := Vector2(cell.x, cell.y)
	var triangle_vertices: Array[Vector3] = [
		corners[0], corners[1], corners[2],
		corners[0], corners[2], corners[3],
	]
	var triangle_uvs: Array[Vector2] = [
		cell_uv,
		cell_uv + Vector2(0.0, 1.0),
		cell_uv + Vector2.ONE,
		cell_uv,
		cell_uv + Vector2.ONE,
		cell_uv + Vector2(1.0, 0.0),
	]
	vertices.append_array(triangle_vertices)
	uvs.append_array(triangle_uvs)
	for _vertex in triangle_vertices:
		normals.append(Vector3.UP)


func _append_flat_cell_collision(
	vertices: Array[Vector3],
	cell: Vector2i,
	height: float,
	cell_size: float,
	world_origin_xz: Vector2
) -> void:
	var corners := _get_cell_corners(cell, height, cell_size, world_origin_xz)
	vertices.append_array([
		corners[0], corners[1], corners[2],
		corners[0], corners[2], corners[3],
	])


func _get_cell_corners(
	cell: Vector2i,
	height: float,
	cell_size: float,
	world_origin_xz: Vector2
) -> Array[Vector3]:
	var minimum_x := world_origin_xz.x + float(cell.x) * cell_size
	var minimum_z := world_origin_xz.y + float(cell.y) * cell_size
	var maximum_x := minimum_x + cell_size
	var maximum_z := minimum_z + cell_size
	return [
		Vector3(minimum_x, height, minimum_z),
		Vector3(minimum_x, height, maximum_z),
		Vector3(maximum_x, height, maximum_z),
		Vector3(maximum_x, height, minimum_z),
	]


func _resolve_style_index(authored_index: int, palette_size: int) -> int:
	if authored_index >= 0 and authored_index < palette_size:
		return authored_index
	return 0
