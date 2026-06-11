@tool
class_name PNGToGridMapImageGrid
extends RefCounted


## Converts a Godot colour to the uppercase key used by mapping profiles.
static func colour_key(colour: Color) -> String:
	return colour.to_html(true).to_upper()


## Scans an image and returns colour counts sorted by most common first.
static func scan_image_colours(image: Image, ignore_fully_transparent: bool) -> Dictionary:
	var detected_colours := {}
	var colour_order: Array[String] = []
	if image == null or image.is_empty():
		return {"data": detected_colours, "order": colour_order}
	for y in image.get_height():
		for x in image.get_width():
			var colour := image.get_pixel(x, y)
			if ignore_fully_transparent and is_zero_approx(colour.a):
				continue
			var key := colour_key(colour)
			if not detected_colours.has(key):
				detected_colours[key] = {"colour": colour, "count": 0}
			detected_colours[key]["count"] = int(detected_colours[key]["count"]) + 1
	colour_order.assign(detected_colours.keys())
	colour_order.sort_custom(func(a: String, b: String) -> bool:
		var count_a := int(detected_colours[a]["count"])
		var count_b := int(detected_colours[b]["count"])
		return a < b if count_a == count_b else count_a > count_b
	)
	return {"data": detected_colours, "order": colour_order}


## Builds a 2D colour-key grid from a source image.
static func grid_from_image(image: Image, ignore_fully_transparent: bool, empty_key: String) -> Array:
	var grid := []
	if image == null:
		return grid
	for y in image.get_height():
		var row: Array[String] = []
		for x in image.get_width():
			var colour := image.get_pixel(x, y)
			if ignore_fully_transparent and is_zero_approx(colour.a):
				row.append("")
			else:
				var key := colour_key(colour)
				row.append("" if key == empty_key else key)
		grid.append(row)
	return grid


## Builds a 2D colour-key grid from populated GridMap cells.
static func grid_from_cells(
	cell_to_key: Dictionary,
	origin: Vector2i,
	size: Vector2i,
	flip_y_to_world_negative_z: bool
) -> Array:
	var grid := []
	for y in size.y:
		var row: Array[String] = []
		for x in size.x:
			row.append("")
		grid.append(row)
	for cell in cell_to_key.keys():
		var pixel := cell_to_pixel(cell, origin, size, flip_y_to_world_negative_z)
		grid[pixel.y][pixel.x] = cell_to_key[cell]
	return grid


## Lists every autotile variant that appears for a colour in the current grid.
static func required_variants_for_colour(colour_grid: Array, key: String) -> Array[String]:
	var variants: Array[String] = []
	for y in colour_grid.size():
		var row: Array = colour_grid[y]
		for x in row.size():
			if row[x] != key:
				continue
			var variant := PNGToGridMapAutotile.variant_for_mask(get_same_colour_mask(colour_grid, x, y, key))
			if not variants.has(variant):
				variants.append(variant)
	return variants


## Builds a cardinal neighbour bitmask for same-colour adjacent pixels.
static func get_same_colour_mask(colour_grid: Array, x: int, y: int, key: String) -> int:
	var mask := 0
	if grid_has_key(colour_grid, x, y - 1, key):
		mask |= PNGToGridMapAutotile.NORTH
	if grid_has_key(colour_grid, x + 1, y, key):
		mask |= PNGToGridMapAutotile.EAST
	if grid_has_key(colour_grid, x, y + 1, key):
		mask |= PNGToGridMapAutotile.SOUTH
	if grid_has_key(colour_grid, x - 1, y, key):
		mask |= PNGToGridMapAutotile.WEST
	return mask


## Checks whether a colour-key grid contains a specific key at a coordinate.
static func grid_has_key(colour_grid: Array, x: int, y: int, key: String) -> bool:
	if y < 0 or y >= colour_grid.size():
		return false
	var row: Array = colour_grid[y]
	if x < 0 or x >= row.size():
		return false
	return row[x] == key


## Chooses the GridMap cell origin for a fresh import or exported round-trip.
static func get_import_origin(
	width: int,
	height: int,
	export_origin: Vector2i,
	export_size: Vector2i,
	center_cells: bool,
	flip_y_to_world_negative_z: bool
) -> Vector2i:
	if export_size.x > 0 and export_size.y > 0:
		return export_origin
	if center_cells:
		return Vector2i(-int(floor(width * 0.5)), -int(floor(height * 0.5)))
	if flip_y_to_world_negative_z:
		return Vector2i(0, -(height - 1))
	return Vector2i.ZERO


## Offsets a newly created GridMap so zero-based imported cells are centred at world origin.
static func offset_created_gridmap_for_rect(grid_map: GridMap, size: Vector2i) -> void:
	grid_map.position.x = -float(size.x - 1) * grid_map.cell_size.x * 0.5
	grid_map.position.y = 0.0
	grid_map.position.z = -float(size.y - 1) * grid_map.cell_size.z * 0.5


## Clears the target rectangle before writing imported cells.
static func clear_gridmap_rect(grid_map: GridMap, origin: Vector2i, size: Vector2i) -> void:
	for z_offset in size.y:
		for x_offset in size.x:
			grid_map.set_cell_item(Vector3i(origin.x + x_offset, 0, origin.y + z_offset), GridMap.INVALID_CELL_ITEM)


## Converts a PNG pixel coordinate into a GridMap cell coordinate.
static func pixel_to_cell(
	pixel: Vector2i,
	origin: Vector2i,
	size: Vector2i,
	flip_y_to_world_negative_z: bool
) -> Vector3i:
	var z_offset := size.y - 1 - pixel.y if flip_y_to_world_negative_z else pixel.y
	return Vector3i(origin.x + pixel.x, 0, origin.y + z_offset)


## Converts a GridMap cell coordinate into a PNG pixel coordinate.
static func cell_to_pixel(
	cell: Vector3i,
	origin: Vector2i,
	size: Vector2i,
	flip_y_to_world_negative_z: bool
) -> Vector2i:
	var x := cell.x - origin.x
	var z_offset := cell.z - origin.y
	var y := size.y - 1 - z_offset if flip_y_to_world_negative_z else z_offset
	return Vector2i(x, y)
