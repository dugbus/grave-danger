@tool
class_name FloorSurfaceGeometryBuilder
extends RefCounted

## Builds derived top and owned-ledge rendering and collision from authoritative floor data.

const MAP_SCRIPT := preload("res://addons/floor_surface/floor_map.gd")
const PROFILE_SCRIPT := preload("res://addons/floor_surface/floor_elevation_profile.gd")
const STYLE_SCRIPT := preload("res://addons/floor_surface/floor_style.gd")
const PIT_RESOLVER_SCRIPT := preload("res://addons/floor_surface/floor_surface_pit_resolver.gd")
const RAMP_RESOLVER_SCRIPT := preload("res://addons/floor_surface/floor_surface_ramp_resolver.gd")

enum EdgeDirection {
	North,
	East,
	South,
	West,
}

var _cell_size := 1.0
var _world_origin_xz := Vector2.ZERO
var _surface_uv_origin := Vector2.ZERO
var _surface_uv_size := Vector2.ONE
var _pit_bottom_heights: Dictionary[Vector2i, float] = {}
var _surface_descriptions: Dictionary[Vector2i, Dictionary] = {}


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
	_surface_uv_origin = world_origin_xz + Vector2(floor_map.minimum_cell) * _cell_size
	_surface_uv_size = Vector2(floor_map.dimensions) * _cell_size
	var pit_result := PIT_RESOLVER_SCRIPT.new().resolve(floor_map, profile, styles)
	_pit_bottom_heights = pit_result["bottom_heights"] as Dictionary[Vector2i, float]
	var present_cells := floor_map.get_present_cells()
	_surface_descriptions.clear()
	var ramp_resolver := RAMP_RESOLVER_SCRIPT.new()
	var ramp_cell_count := 0
	var invalid_ramp_count := 0
	for cell in present_cells:
		var description := ramp_resolver.resolve_cell(
			floor_map,
			profile,
			cell,
			_cell_size
		)
		_surface_descriptions[cell] = description
		if floor_map.get_cell_transition(cell) == MAP_SCRIPT.Transition.Ramp:
			if description.get("valid", false) as bool:
				ramp_cell_count += 1
			else:
				invalid_ramp_count += 1
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
		var top_uv_metres := maxf(style.world_uv_metres, 0.01)
		var top_uv_mapping := style.top_uv_mapping as STYLE_SCRIPT.TopUvMapping
		var wall_uv_metres := maxf(style.wall_uv_metres, 0.01)
		for cell in present_cells:
			if _resolve_style_index(floor_map.get_cell_style(cell), styles.size()) != style_index:
				continue
			_append_cell_top(
				top_vertices,
				top_normals,
				top_uvs,
				cell,
				_surface_descriptions[cell],
				top_uv_metres,
				top_uv_mapping
			)
			ledge_face_count += _append_owned_ledges(
				edge_vertices,
				edge_normals,
				edge_uvs,
				cell,
				floor_map,
				maxf(style.pit_depth, 0.01),
				wall_uv_metres
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
						top_uv_metres,
						top_uv_mapping
					)
					pit_bottom_cell_count += 1
		_append_mesh_surface(mesh, top_vertices, top_normals, top_uvs, style.top_material)
		_append_mesh_surface(mesh, edge_vertices, edge_normals, edge_uvs, style.get_wall_material())
		_append_mesh_surface(mesh, pit_vertices, pit_normals, pit_uvs, style.pit_bottom_material)

	for cell in present_cells:
		_append_cell_top_collision(
			collision_vertices,
			cell,
			_surface_descriptions[cell]
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
			maxf(style.pit_depth, 0.01),
			maxf(style.wall_uv_metres, 0.01)
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
		"ramp_cell_count": ramp_cell_count,
		"invalid_ramp_count": invalid_ramp_count,
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
	world_uv_metres: float,
	top_uv_mapping: STYLE_SCRIPT.TopUvMapping
) -> void:
	var description := {
		"corner_heights": [height, height, height, height] as Array[float],
		"normal": Vector3.UP,
	}
	_append_cell_top(
		vertices,
		normals,
		uvs,
		cell,
		description,
		world_uv_metres,
		top_uv_mapping
	)


func _append_cell_top(
	vertices: Array[Vector3],
	normals: Array[Vector3],
	uvs: Array[Vector2],
	cell: Vector2i,
	description: Dictionary,
	world_uv_metres: float,
	top_uv_mapping: STYLE_SCRIPT.TopUvMapping
) -> void:
	var corners := _get_cell_corners_from_description(cell, description)
	var triangle_vertices: Array[Vector3] = [
		corners[0], corners[2], corners[1],
		corners[0], corners[3], corners[2],
	]
	var triangle_uvs: Array[Vector2] = [
		_top_uv(corners[0], world_uv_metres, top_uv_mapping),
		_top_uv(corners[2], world_uv_metres, top_uv_mapping),
		_top_uv(corners[1], world_uv_metres, top_uv_mapping),
		_top_uv(corners[0], world_uv_metres, top_uv_mapping),
		_top_uv(corners[3], world_uv_metres, top_uv_mapping),
		_top_uv(corners[2], world_uv_metres, top_uv_mapping),
	]
	vertices.append_array(triangle_vertices)
	uvs.append_array(triangle_uvs)
	var surface_normal := description.get("normal", Vector3.UP) as Vector3
	for _vertex in triangle_vertices:
		normals.append(surface_normal)


func _append_cell_top_collision(
	vertices: Array[Vector3],
	cell: Vector2i,
	description: Dictionary
) -> void:
	var corners := _get_cell_corners_from_description(cell, description)
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
	exposed_depth: float,
	world_uv_metres: float
) -> int:
	var face_count := 0
	face_count += _append_owned_ledge(
		vertices, normals, uvs, cell, EdgeDirection.North, floor_map,
		exposed_depth, world_uv_metres
	)
	face_count += _append_owned_ledge(
		vertices, normals, uvs, cell, EdgeDirection.East, floor_map,
		exposed_depth, world_uv_metres
	)
	face_count += _append_owned_ledge(
		vertices, normals, uvs, cell, EdgeDirection.South, floor_map,
		exposed_depth, world_uv_metres
	)
	face_count += _append_owned_ledge(
		vertices, normals, uvs, cell, EdgeDirection.West, floor_map,
		exposed_depth, world_uv_metres
	)
	return face_count


func _append_owned_ledge(
	vertices: Array[Vector3],
	normals: Array[Vector3],
	uvs: Array[Vector2],
	cell: Vector2i,
	direction: EdgeDirection,
	floor_map: MAP_SCRIPT,
	exposed_depth: float,
	world_uv_metres: float
) -> int:
	var neighbour := cell + _edge_offset(direction)
	var description := _surface_descriptions[cell] as Dictionary
	var corners := _get_cell_corners_from_description(cell, description)
	var edge_indices := _edge_corner_indices(direction)
	var top_a := corners[edge_indices.x]
	var top_b := corners[edge_indices.y]
	var lower_a := top_a.y - exposed_depth
	var lower_b := top_b.y - exposed_depth
	if floor_map.has_floor(neighbour):
		lower_a = _get_neighbour_height_at_corner(neighbour, top_a)
		lower_b = _get_neighbour_height_at_corner(neighbour, top_b)
	elif floor_map.is_in_bounds(neighbour) and _pit_bottom_heights.has(neighbour):
		lower_a = _pit_bottom_heights[neighbour]
		lower_b = lower_a
	var gap_a := top_a.y - lower_a
	var gap_b := top_b.y - lower_b
	if gap_a <= 0.001 and gap_b <= 0.001:
		return 0
	lower_a = minf(lower_a, top_a.y)
	lower_b = minf(lower_b, top_b.y)
	var bottom_a := Vector3(top_a.x, lower_a, top_a.z)
	var bottom_b := Vector3(top_b.x, lower_b, top_b.z)
	var normal := _edge_normal(direction)
	if gap_a > 0.001 and gap_b > 0.001:
		_append_edge_triangle(vertices, normals, uvs, [top_a, bottom_b, bottom_a], normal, direction, world_uv_metres)
		_append_edge_triangle(vertices, normals, uvs, [top_a, top_b, bottom_b], normal, direction, world_uv_metres)
	elif gap_a > 0.001:
		_append_edge_triangle(vertices, normals, uvs, [top_a, top_b, bottom_a], normal, direction, world_uv_metres)
	else:
		_append_edge_triangle(vertices, normals, uvs, [top_a, top_b, bottom_b], normal, direction, world_uv_metres)
	return 1


func _append_edge_triangle(
	vertices: Array[Vector3],
	normals: Array[Vector3],
	uvs: Array[Vector2],
	triangle: Array[Vector3],
	normal: Vector3,
	direction: EdgeDirection,
	world_uv_metres: float
) -> void:
	vertices.append_array(triangle)
	for vertex in triangle:
		normals.append(normal)
		uvs.append(_edge_uv(vertex, direction, world_uv_metres))


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


func _get_cell_corners_from_description(
	cell: Vector2i,
	description: Dictionary
) -> Array[Vector3]:
	var heights := description.get("corner_heights", []) as Array[float]
	if heights.size() != 4:
		return _get_cell_corners(cell, 0.0)
	var minimum_x := _world_origin_xz.x + float(cell.x) * _cell_size
	var minimum_z := _world_origin_xz.y + float(cell.y) * _cell_size
	var maximum_x := minimum_x + _cell_size
	var maximum_z := minimum_z + _cell_size
	return [
		Vector3(minimum_x, heights[0], minimum_z),
		Vector3(minimum_x, heights[1], maximum_z),
		Vector3(maximum_x, heights[2], maximum_z),
		Vector3(maximum_x, heights[3], minimum_z),
	]


func _get_neighbour_height_at_corner(neighbour: Vector2i, corner: Vector3) -> float:
	var neighbour_description := _surface_descriptions.get(neighbour, {}) as Dictionary
	for neighbour_corner in _get_cell_corners_from_description(neighbour, neighbour_description):
		if is_equal_approx(neighbour_corner.x, corner.x) \
				and is_equal_approx(neighbour_corner.z, corner.z):
			return neighbour_corner.y
	return corner.y


func _top_uv(
	vertex: Vector3,
	world_uv_metres: float,
	top_uv_mapping: STYLE_SCRIPT.TopUvMapping
) -> Vector2:
	if top_uv_mapping == STYLE_SCRIPT.TopUvMapping.SurfaceNormalized:
		return (Vector2(vertex.x, vertex.z) - _surface_uv_origin) / _surface_uv_size
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
