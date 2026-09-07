@tool
class_name FloorSurfaceElevationOverlay
extends RefCounted

## Builds a temporary vertex-coloured height overlay for the editor viewport.

const FLOOR_MAP_SCRIPT := preload("res://addons/floor_surface/floor_map.gd")
const PROFILE_SCRIPT := preload("res://addons/floor_surface/floor_elevation_profile.gd")
const SURFACE_OFFSET := 0.025
const OVERLAY_ALPHA := 0.26
const OVERLAY_SATURATION := 0.52
const OVERLAY_VALUE := 0.38


## Builds one coloured quad per present cell at its actual absolute elevation.
static func build_mesh(
	floor_map: FLOOR_MAP_SCRIPT,
	profile: PROFILE_SCRIPT,
	cell_size: float,
	world_origin_xz: Vector2
) -> ArrayMesh:
	var mesh := ArrayMesh.new()
	if floor_map == null or profile == null:
		return mesh
	var vertices: Array[Vector3] = []
	var normals: Array[Vector3] = []
	var colours: Array[Color] = []
	var safe_cell_size := maxf(cell_size, 0.01)
	for cell in floor_map.get_present_cells():
		var elevation := floor_map.get_cell_elevation(cell)
		var height := profile.elevation_to_world(elevation) + SURFACE_OFFSET
		var minimum_x := world_origin_xz.x + float(cell.x) * safe_cell_size
		var minimum_z := world_origin_xz.y + float(cell.y) * safe_cell_size
		var maximum_x := minimum_x + safe_cell_size
		var maximum_z := minimum_z + safe_cell_size
		var corners: Array[Vector3] = [
			Vector3(minimum_x, height, minimum_z),
			Vector3(minimum_x, height, maximum_z),
			Vector3(maximum_x, height, maximum_z),
			Vector3(maximum_x, height, minimum_z),
		]
		var triangle_vertices: Array[Vector3] = [
			corners[0], corners[1], corners[2],
			corners[0], corners[2], corners[3],
		]
		vertices.append_array(triangle_vertices)
		var colour := elevation_colour(elevation)
		for _vertex in triangle_vertices:
			normals.append(Vector3.UP)
			colours.append(colour)
	if vertices.is_empty():
		return mesh
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = PackedVector3Array(vertices)
	arrays[Mesh.ARRAY_NORMAL] = PackedVector3Array(normals)
	arrays[Mesh.ARRAY_COLOR] = PackedColorArray(colours)
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


## Maps every integer elevation to a repeatable muted tint that preserves floor detail.
static func elevation_colour(elevation: int) -> Color:
	var hue := fposmod(0.52 - float(elevation) * 0.061, 1.0)
	var colour := Color.from_hsv(hue, OVERLAY_SATURATION, OVERLAY_VALUE, OVERLAY_ALPHA)
	return colour
