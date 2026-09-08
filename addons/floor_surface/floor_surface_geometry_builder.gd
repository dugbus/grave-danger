@tool
class_name FloorSurfaceGeometryBuilder
extends RefCounted

## Builds derived top and owned-ledge rendering and collision from authoritative floor data.

const MAP_SCRIPT := preload("res://addons/floor_surface/floor_map.gd")
const PROFILE_SCRIPT := preload("res://addons/floor_surface/floor_elevation_profile.gd")
const STYLE_SCRIPT := preload("res://addons/floor_surface/floor_style.gd")
const PIT_RESOLVER_SCRIPT := preload("res://addons/floor_surface/floor_surface_pit_resolver.gd")

enum EdgeDirection {
	North,
	East,
	South,
	West,
}

var _cell_size := 1.0
var _world_origin_xz := Vector2.ZERO
var _pit_bottom_heights: Dictionary[Vector2i, float] = {}


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
	_cell_size = maxf(cell_size, 0.01)
	_world_origin_xz = world_origin_xz
	var pit_result := PIT_RESOLVER_SCRIPT.new().resolve(floor_map, profile, styles)
	_pit_bottom_heights = pit_result["bottom_heights"] as Dictionary[Vector2i, float]
	var present_cells := floor_map.get_present_cells()
	var ledge_face_count := 0
	var pit_bottom_cell_count := 0
	for style_index in styles.size():
		var top_vertices: Array[Vector3] = []
		var top_normals: Array[Vector3] = []
		var top_uvs: Array[Vector2] = []
		var edge_vertices: Array[Vector3] = []
		var edge_normals: Array[Vector3] = []
		var edge_uvs: Array[Vector2] = []
		var pit_vertices: Array[Vector3] = []
		var pit_normals: Array[Vector3] = []
		var pit_uvs: Array[Vector2] = []
		var style := styles[style_index] as STYLE_SCRIPT
		var world_uv_metres := maxf(style.world_uv_metres, 0.01)
		for cell in present_cells:
			if _resolve_style_index(floor_map.get_cell_style(cell), styles.size()) != style_index:
				continue
			_append_flat_cell(
				top_vertices,
				top_normals,
				top_uvs,
				cell,
				profile.elevation_to_world(floor_map.get_cell_elevation(cell)),
				world_uv_metres
			)
			ledge_face_count += _append_owned_ledges(
				edge_vertices,
				edge_normals,
				edge_uvs,
				cell,
				floor_map,
				profile,
				maxf(style.pit_depth, 0.01),
				world_uv_metres
			)
		if style.pit_bottom_material != null:
			for z_coordinate in range(floor_map.minimum_cell.y, floor_map.minimum_cell.y + floor_map.dimensions.y):
				for x_coordinate in range(floor_map.minimum_cell.x, floor_map.minimum_cell.x + floor_map.dimensions.x):
					var hole_cell := Vector2i(x_coordinate, z_coordinate)
					if not _pit_bottom_heights.has(hole_cell) \
							or _resolve_style_index(floor_map.get_cell_style(hole_cell), styles.size()) \
							!= style_index:
						continue
					_append_flat_cell(
						pit_vertices,
						pit_normals,
						pit_uvs,
						hole_cell,
						_pit_bottom_heights[hole_cell],
						world_uv_metres
					)
					pit_bottom_cell_count += 1
		_append_mesh_surface(mesh, top_vertices, top_normals, top_uvs, style.top_material)
		_append_mesh_surface(mesh, edge_vertices, edge_normals, edge_uvs, style.edge_material)
		_append_mesh_surface(mesh, pit_vertices, pit_normals, pit_uvs, style.pit_bottom_material)

	for cell in present_cells:
		_append_flat_cell_collision(
			collision_vertices,
			cell,
			profile.elevation_to_world(floor_map.get_cell_elevation(cell))
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
			maxf(style.pit_depth, 0.01),
			maxf(style.world_uv_metres, 0.01)
		)
	var collision_shape := ConcavePolygonShape3D.new()
	collision_shape.backface_collision = true
	collision_shape.set_faces(PackedVector3Array(collision_vertices))
	return {
		"cell_count": present_cells.size(),
		"collision_shape": collision_shape,
		"ledge_face_count": ledge_face_count,
		"mesh": mesh,
		"pit_bottom_cell_count": pit_bottom_cell_count,
		"pit_region_count": pit_result["region_count"] as int,
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
	world_uv_metres: float
) -> void:
	var corners := _get_cell_corners(cell, height)
	var triangle_vertices: Array[Vector3] = [
		corners[0], corners[2], corners[1],
		corners[0], corners[3], corners[2],
	]
	var triangle_uvs: Array[Vector2] = [
		_top_uv(corners[0], world_uv_metres),
		_top_uv(corners[2], world_uv_metres),
		_top_uv(corners[1], world_uv_metres),
		_top_uv(corners[0], world_uv_metres),
		_top_uv(corners[3], world_uv_metres),
		_top_uv(corners[2], world_uv_metres),
	]
	vertices.append_array(triangle_vertices)
	uvs.append_array(triangle_uvs)
	for _vertex in triangle_vertices:
		normals.append(Vector3.UP)


func _append_flat_cell_collision(
	vertices: Array[Vector3],
	cell: Vector2i,
	height: float
) -> void:
	var corners := _get_cell_corners(cell, height)
	vertices.append_array([
		corners[0], corners[2], corners[1],
		corners[0], corners[3], corners[2],
	])


func _append_owned_ledges(
	vertices: Array[Vector3],
	normals: Array[Vector3],
	uvs: Array[Vector2],
	cell: Vector2i,
	floor_map: MAP_SCRIPT,
	profile: PROFILE_SCRIPT,
	exposed_depth: float,
	world_uv_metres: float
) -> int:
	var face_count := 0
	face_count += _append_owned_ledge(
		vertices, normals, uvs, cell, EdgeDirection.North, floor_map,
		profile, exposed_depth, world_uv_metres
	)
	face_count += _append_owned_ledge(
		vertices, normals, uvs, cell, EdgeDirection.East, floor_map,
		profile, exposed_depth, world_uv_metres
	)
	face_count += _append_owned_ledge(
		vertices, normals, uvs, cell, EdgeDirection.South, floor_map,
		profile, exposed_depth, world_uv_metres
	)
	face_count += _append_owned_ledge(
		vertices, normals, uvs, cell, EdgeDirection.West, floor_map,
		profile, exposed_depth, world_uv_metres
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
	exposed_depth: float,
	world_uv_metres: float
) -> int:
	var neighbour := cell + _edge_offset(direction)
	var top_height := profile.elevation_to_world(floor_map.get_cell_elevation(cell))
	var lower_height := top_height - exposed_depth
	if floor_map.has_floor(neighbour):
		lower_height = profile.elevation_to_world(floor_map.get_cell_elevation(neighbour))
	elif floor_map.is_in_bounds(neighbour) and _pit_bottom_heights.has(neighbour):
		lower_height = _pit_bottom_heights[neighbour]
	if lower_height >= top_height:
		return 0
	var corners := _get_cell_corners(cell, top_height)
	var edge_indices := _edge_corner_indices(direction)
	var top_a := corners[edge_indices.x]
	var top_b := corners[edge_indices.y]
	var bottom_a := Vector3(top_a.x, lower_height, top_a.z)
	var bottom_b := Vector3(top_b.x, lower_height, top_b.z)
	vertices.append_array([
		top_a, bottom_b, bottom_a,
		top_a, top_b, bottom_b,
	])
	var normal := _edge_normal(direction)
	for _vertex_index in 6:
		normals.append(normal)
	uvs.append_array([
		_edge_uv(top_a, direction, world_uv_metres),
		_edge_uv(bottom_b, direction, world_uv_metres),
		_edge_uv(bottom_a, direction, world_uv_metres),
		_edge_uv(top_a, direction, world_uv_metres),
		_edge_uv(top_b, direction, world_uv_metres),
		_edge_uv(bottom_b, direction, world_uv_metres),
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
	height: float
) -> Array[Vector3]:
	var minimum_x := _world_origin_xz.x + float(cell.x) * _cell_size
	var minimum_z := _world_origin_xz.y + float(cell.y) * _cell_size
	var maximum_x := minimum_x + _cell_size
	var maximum_z := minimum_z + _cell_size
	return [
		Vector3(minimum_x, height, minimum_z),
		Vector3(minimum_x, height, maximum_z),
		Vector3(maximum_x, height, maximum_z),
		Vector3(maximum_x, height, minimum_z),
	]


func _top_uv(vertex: Vector3, world_uv_metres: float) -> Vector2:
	return Vector2(vertex.x, vertex.z) / world_uv_metres


func _edge_uv(
	vertex: Vector3,
	direction: EdgeDirection,
	world_uv_metres: float
) -> Vector2:
	var horizontal := vertex.x \
		if direction == EdgeDirection.North or direction == EdgeDirection.South else vertex.z
	return Vector2(horizontal, -vertex.y) / world_uv_metres


func _resolve_style_index(authored_index: int, palette_size: int) -> int:
	if authored_index >= 0 and authored_index < palette_size:
		return authored_index
	return 0
