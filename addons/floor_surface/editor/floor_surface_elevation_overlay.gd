@tool
class_name FloorSurfaceElevationOverlay
extends RefCounted

## Builds a temporary vertex-coloured height overlay for the editor viewport.

const FLOOR_MAP_SCRIPT := preload("res://addons/floor_surface/floor_map.gd")
const PROFILE_SCRIPT := preload("res://addons/floor_surface/floor_elevation_profile.gd")
const RAMP_RESOLVER_SCRIPT := preload("res://addons/floor_surface/floor_surface_ramp_resolver.gd")
const SURFACE_OFFSET := 0.025
const OVERLAY_ALPHA := 0.26
const OVERLAY_SATURATION := 0.52
const OVERLAY_VALUE := 0.38

enum ColourMode {
	Elevation,
	RampMask,
}


## Builds one coloured quad per present cell at its actual absolute elevation.
static func build_mesh(
	floor_map: FLOOR_MAP_SCRIPT,
	profile: PROFILE_SCRIPT,
	cell_size: float,
	world_origin_xz: Vector2,
	surface_offset := SURFACE_OFFSET,
	colour_mode: ColourMode = ColourMode.Elevation
) -> ArrayMesh:
	var mesh := ArrayMesh.new()
	if floor_map == null or profile == null:
		return mesh
	var vertices: Array[Vector3] = []
	var normals: Array[Vector3] = []
	var colours: Array[Color] = []
	var uvs: Array[Vector2] = []
	var safe_cell_size := maxf(cell_size, 0.01)
	var ramp_resolver := RAMP_RESOLVER_SCRIPT.new()
	for cell in floor_map.get_present_cells():
		var elevation := floor_map.get_cell_elevation(cell)
		var description := ramp_resolver.resolve_cell(floor_map, profile, cell, safe_cell_size)
		var heights := description.get("corner_heights", []) as Array[float]
		if heights.size() != 4:
			continue
		var minimum_x := world_origin_xz.x + float(cell.x) * safe_cell_size
		var minimum_z := world_origin_xz.y + float(cell.y) * safe_cell_size
		var maximum_x := minimum_x + safe_cell_size
		var maximum_z := minimum_z + safe_cell_size
		var corners: Array[Vector3] = [
			Vector3(minimum_x, heights[0] + surface_offset, minimum_z),
			Vector3(minimum_x, heights[1] + surface_offset, maximum_z),
			Vector3(maximum_x, heights[2] + surface_offset, maximum_z),
			Vector3(maximum_x, heights[3] + surface_offset, minimum_z),
		]
		var triangle_vertices: Array[Vector3] = [
			corners[0], corners[1], corners[2],
			corners[0], corners[2], corners[3],
		]
		var minimum_uv := Vector2(minimum_x, minimum_z) / safe_cell_size
		var maximum_uv := Vector2(maximum_x, maximum_z) / safe_cell_size
		var triangle_uvs: Array[Vector2] = [
			minimum_uv,
			Vector2(minimum_uv.x, maximum_uv.y),
			maximum_uv,
			minimum_uv,
			maximum_uv,
			Vector2(maximum_uv.x, minimum_uv.y),
		]
		vertices.append_array(triangle_vertices)
		uvs.append_array(triangle_uvs)
		var colour := _cell_colour(floor_map, cell, elevation, colour_mode)
		var surface_normal := description.get("normal", Vector3.UP) as Vector3
		for _vertex in triangle_vertices:
			normals.append(surface_normal)
			colours.append(colour)
	if vertices.is_empty():
		return mesh
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = PackedVector3Array(vertices)
	arrays[Mesh.ARRAY_NORMAL] = PackedVector3Array(normals)
	arrays[Mesh.ARRAY_COLOR] = PackedColorArray(colours)
	arrays[Mesh.ARRAY_TEX_UV] = PackedVector2Array(uvs)
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


static func _cell_colour(
	floor_map: FLOOR_MAP_SCRIPT,
	cell: Vector2i,
	elevation: int,
	colour_mode: ColourMode
) -> Color:
	if colour_mode == ColourMode.RampMask:
		return Color.RED \
			if floor_map.get_cell_transition(cell) == FLOOR_MAP_SCRIPT.Transition.Ramp \
			else Color.BLACK
	return elevation_colour(elevation)


## Maps every integer elevation to a repeatable muted tint that preserves floor detail.
static func elevation_colour(elevation: int) -> Color:
	var hue := fposmod(0.52 - float(elevation) * 0.061, 1.0)
	var colour := Color.from_hsv(hue, OVERLAY_SATURATION, OVERLAY_VALUE, OVERLAY_ALPHA)
	return colour
