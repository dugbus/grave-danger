class_name FloorSurfaceVisibilityData
extends RefCounted

## Encodes authored occupancy and planar top heights into a world-aligned GPU texture.

const SURFACE_SCRIPT := preload("res://addons/floor_surface/floor_surface.gd")

var elevation_texture: ImageTexture
var preview_texture: ImageTexture
var minimum_cell := Vector2i.ZERO
var dimensions := Vector2i.ZERO
var world_origin_xz := Vector2.ZERO
var cell_size := 1.0
var rebuild_count := 0


## Replaces both GPU data and the readable debug preview from one surface snapshot.
func rebuild(surface: SURFACE_SCRIPT) -> bool:
	if surface == null or surface.floor_map == null or surface.elevation_profile == null:
		clear()
		return false
	minimum_cell = surface.floor_map.minimum_cell
	dimensions = surface.floor_map.dimensions
	world_origin_xz = surface.world_origin_xz
	cell_size = surface.cell_size
	if dimensions.x <= 0 or dimensions.y <= 0:
		clear()
		return false

	var data_image := Image.create_empty(
		dimensions.x,
		dimensions.y,
		false,
		Image.FORMAT_RGBAF
	)
	var minimum_height := INF
	var maximum_height := -INF
	for local_z in dimensions.y:
		for local_x in dimensions.x:
			var cell := minimum_cell + Vector2i(local_x, local_z)
			var encoded := _encode_cell(surface, cell)
			data_image.set_pixel(local_x, local_z, encoded)
			if encoded.r > 0.5:
				minimum_height = minf(minimum_height, encoded.g)
				maximum_height = maxf(maximum_height, encoded.g)

	elevation_texture = ImageTexture.create_from_image(data_image)
	preview_texture = ImageTexture.create_from_image(
		_build_preview_image(data_image, minimum_height, maximum_height)
	)
	rebuild_count += 1
	return true


## Drops derived textures while retaining a deterministic empty state.
func clear() -> void:
	elevation_texture = null
	preview_texture = null
	minimum_cell = Vector2i.ZERO
	dimensions = Vector2i.ZERO
	world_origin_xz = Vector2.ZERO
	cell_size = 1.0


## Returns one encoded texel: occupancy, centre height, X slope and Z slope.
func get_encoded_cell(cell: Vector2i) -> Color:
	if elevation_texture == null:
		return Color(0.0, 0.0, 0.0, 0.0)
	var local_cell := cell - minimum_cell
	if local_cell.x < 0 or local_cell.y < 0 \
			or local_cell.x >= dimensions.x or local_cell.y >= dimensions.y:
		return Color(0.0, 0.0, 0.0, 0.0)
	return elevation_texture.get_image().get_pixel(local_cell.x, local_cell.y)


func _encode_cell(surface: SURFACE_SCRIPT, cell: Vector2i) -> Color:
	if not surface.has_floor(cell):
		return Color(0.0, 0.0, 0.0, 0.0)
	var description := surface.get_cell_surface_description(cell)
	var corner_heights := description.get("corner_heights", []) as Array[float]
	if not description.get("valid", false) as bool or corner_heights.size() != 4:
		var fallback_height := surface.get_world_height_at_cell(cell)
		return Color(1.0, fallback_height, 0.0, 0.0)
	var centre_height := (
		corner_heights[0] + corner_heights[1]
		+ corner_heights[2] + corner_heights[3]
	) * 0.25
	var x_slope := (
		corner_heights[2] + corner_heights[3]
		- corner_heights[0] - corner_heights[1]
	) * 0.5
	var z_slope := (
		corner_heights[1] + corner_heights[2]
		- corner_heights[0] - corner_heights[3]
	) * 0.5
	return Color(1.0, centre_height, x_slope, z_slope)


func _build_preview_image(data_image: Image, minimum_height: float, maximum_height: float) -> Image:
	var preview := Image.create_empty(dimensions.x, dimensions.y, false, Image.FORMAT_RGBA8)
	var safe_minimum := minimum_height if is_finite(minimum_height) else 0.0
	var height_range := maxf(maximum_height - safe_minimum, 0.001) \
		if is_finite(maximum_height) else 1.0
	for local_z in dimensions.y:
		for local_x in dimensions.x:
			var encoded := data_image.get_pixel(local_x, local_z)
			if encoded.r < 0.5:
				preview.set_pixel(local_x, local_z, Color(0.025, 0.035, 0.05, 1.0))
				continue
			var height_t := clampf((encoded.g - safe_minimum) / height_range, 0.0, 1.0)
			var colour := Color(0.12, 0.28, 0.4, 1.0).lerp(
				Color(0.82, 0.64, 0.28, 1.0),
				height_t
			)
			if absf(encoded.b) + absf(encoded.a) > 0.001:
				colour = colour.lerp(Color(0.22, 0.78, 0.72, 1.0), 0.55)
			preview.set_pixel(local_x, local_z, colour)
	return preview
