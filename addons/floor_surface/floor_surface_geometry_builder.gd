@tool
class_name FloorSurfaceGeometryBuilder
extends RefCounted

## Builds derived top and owned-ledge rendering and collision from authoritative floor data.

const MAP_SCRIPT := preload("res://addons/floor_surface/floor_map.gd")
const PROFILE_SCRIPT := preload("res://addons/floor_surface/floor_elevation_profile.gd")
const STYLE_SCRIPT := preload("res://addons/floor_surface/floor_style.gd")

enum EdgeDirection {
	North,
	East,
	South,
	West,
}


## Rebuilds batched top/edge surfaces per style and one shared static collision shape.
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
	var ledge_face_count := 0
	for style_index in styles.size():
		var top_vertices: Array[Vector3] = []
		var top_normals: Array[Vector3] = []
		var top_uvs: Array[Vector2] = []
		var edge_vertices: Array[Vector3] = []
		var edge_normals: Array[Vector3] = []
		var edge_uvs: Array[Vector2] = []
		var style := styles[style_index] as STYLE_SCRIPT
		for cell in present_cells:
			if _resolve_style_index(floor_map.get_cell_style(cell), styles.size()) != style_index:
				continue
			_append_flat_cell(
				top_vertices,
				top_normals,
				top_uvs,
				cell,
				profile.elevation_to_world(floor_map.get_cell_elevation(cell)),
				safe_cell_size,
				world_origin_xz
			)
			ledge_face_count += _append_owned_ledges(
				edge_vertices,
				edge_normals,
				edge_uvs,
				cell,
				floor_map,
				profile,
				safe_cell_size,
				world_origin_xz,
				maxf(style.pit_depth, 0.01)
			)
		_append_mesh_surface(mesh, top_vertices, top_normals, top_uvs, style.top_material)
		var edge_material := style.edge_material \
			if style.edge_material != null else style.top_material
		_append_mesh_surface(mesh, edge_vertices, edge_normals, edge_uvs, edge_material)

	for cell in present_cells:
		_append_flat_cell_collision(
			collision_vertices,
			cell,
			profile.elevation_to_world(floor_map.get_cell_elevation(cell)),
			safe_cell_size,
			world_origin_xz
		)
		var unused_normals: Array[Vector3] = []
		var unused_uvs: Array[Vector2] = []
		var style_index := _resolve_style_index(floor_map.get_cell_style(cell), styles.size())
		var style := styles[style_index] as STYLE_SCRIPT
		_append_owned_ledges(
			collision_vertices,
			unused_normals,
			unused_uvs,
			cell,
			floor_map,
			profile,
			safe_cell_size,
			world_origin_xz,
			maxf(style.pit_depth, 0.01)
		)
	var collision_shape := ConcavePolygonShape3D.new()
	collision_shape.backface_collision = true
	collision_shape.set_faces(PackedVector3Array(collision_vertices))
	return {
		"cell_count": present_cells.size(),
		"collision_shape": collision_shape,
		"ledge_face_count": ledge_face_count,
		"mesh": mesh,
	}


func _append_mesh_surface(
	mesh: ArrayMesh,
	vertices: Array[Vector3],
	normals: Array[Vector3],
	uvs: Array[Vector2],
	material: Material
) -> void:
	if vertices.is_empty():
		return
	var surface_arrays := []
	surface_arrays.resize(Mesh.ARRAY_MAX)
	surface_arrays[Mesh.ARRAY_VERTEX] = PackedVector3Array(vertices)
	surface_arrays[Mesh.ARRAY_NORMAL] = PackedVector3Array(normals)
	surface_arrays[Mesh.ARRAY_TEX_UV] = PackedVector2Array(uvs)
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, surface_arrays)
	mesh.surface_set_material(mesh.get_surface_count() - 1, material)


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


func _append_owned_ledges(
	vertices: Array[Vector3],
	normals: Array[Vector3],
	uvs: Array[Vector2],
	cell: Vector2i,
	floor_map: MAP_SCRIPT,
	profile: PROFILE_SCRIPT,
	cell_size: float,
	world_origin_xz: Vector2,
	exposed_depth: float
) -> int:
	var face_count := 0
	face_count += _append_owned_ledge(
		vertices, normals, uvs, cell, EdgeDirection.North, floor_map,
		profile, cell_size, world_origin_xz, exposed_depth
	)
	face_count += _append_owned_ledge(
		vertices, normals, uvs, cell, EdgeDirection.East, floor_map,
		profile, cell_size, world_origin_xz, exposed_depth
	)
	face_count += _append_owned_ledge(
		vertices, normals, uvs, cell, EdgeDirection.South, floor_map,
		profile, cell_size, world_origin_xz, exposed_depth
	)
	face_count += _append_owned_ledge(
		vertices, normals, uvs, cell, EdgeDirection.West, floor_map,
		profile, cell_size, world_origin_xz, exposed_depth
	)
	return face_count


func _append_owned_ledge(
	vertices: Array[Vector3],
	normals: Array[Vector3],
	uvs: Array[Vector2],
	cell: Vector2i,
	direction: EdgeDirection,
	floor_map: MAP_SCRIPT,
	profile: PROFILE_SCRIPT,
	cell_size: float,
	world_origin_xz: Vector2,
	exposed_depth: float
) -> int:
	var neighbour := cell + _edge_offset(direction)
	var top_height := profile.elevation_to_world(floor_map.get_cell_elevation(cell))
	var lower_height := top_height - exposed_depth
	if floor_map.has_floor(neighbour):
		lower_height = profile.elevation_to_world(floor_map.get_cell_elevation(neighbour))
	if lower_height >= top_height:
		return 0
	var corners := _get_cell_corners(cell, top_height, cell_size, world_origin_xz)
	var edge_indices := _edge_corner_indices(direction)
	var top_a := corners[edge_indices.x]
	var top_b := corners[edge_indices.y]
	var bottom_a := Vector3(top_a.x, lower_height, top_a.z)
	var bottom_b := Vector3(top_b.x, lower_height, top_b.z)
	vertices.append_array([
		top_a, bottom_a, bottom_b,
		top_a, bottom_b, top_b,
	])
	var normal := _edge_normal(direction)
	for _vertex_index in 6:
		normals.append(normal)
	uvs.append_array([
		Vector2(0.0, top_height), Vector2(0.0, lower_height), Vector2(1.0, lower_height),
		Vector2(0.0, top_height), Vector2(1.0, lower_height), Vector2(1.0, top_height),
	])
	return 1


func _edge_offset(direction: EdgeDirection) -> Vector2i:
	match direction:
		EdgeDirection.North:
			return Vector2i.UP
		EdgeDirection.East:
			return Vector2i.RIGHT
		EdgeDirection.South:
			return Vector2i.DOWN
		_:
			return Vector2i.LEFT


func _edge_corner_indices(direction: EdgeDirection) -> Vector2i:
	match direction:
		EdgeDirection.North:
			return Vector2i(3, 0)
		EdgeDirection.East:
			return Vector2i(2, 3)
		EdgeDirection.South:
			return Vector2i(1, 2)
		_:
			return Vector2i(0, 1)


func _edge_normal(direction: EdgeDirection) -> Vector3:
	match direction:
		EdgeDirection.North:
			return Vector3.FORWARD
		EdgeDirection.East:
			return Vector3.RIGHT
		EdgeDirection.South:
			return Vector3.BACK
		_:
			return Vector3.LEFT


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
