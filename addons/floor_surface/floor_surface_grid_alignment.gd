@tool
class_name FloorSurfaceGridAlignment
extends RefCounted

## Defines the shared horizontal cell convention between FloorSurface and sparse GridMap data.
## GridMaps have no finite bounds: aligned coordinates remain addressable after a floor expands.


## Makes FloorSurface cell centres coincide with equal-X/Z cells in the placement GridMap.
static func align_surface_to_grid_map(
	floor_surface: FloorSurface,
	grid_map: GridMap
) -> Array[String]:
	var errors := validate_grid_map(grid_map, floor_surface)
	if not errors.is_empty():
		return errors
	var grid_to_surface := _transform_relative_to(grid_map, floor_surface)
	var zero_cell_centre := grid_to_surface * grid_map.map_to_local(Vector3i.ZERO)
	floor_surface.cell_size = grid_map.cell_size.x
	floor_surface.world_origin_xz = Vector2(zero_cell_centre.x, zero_cell_centre.z) \
		- Vector2.ONE * floor_surface.cell_size * 0.5
	return []


## Reports transforms or cell settings that cannot share FloorSurface's square horizontal grid.
static func validate_grid_map(grid_map: GridMap, floor_surface: FloorSurface) -> Array[String]:
	var errors: Array[String] = []
	if grid_map == null:
		return ["FloorSurface placement GridMap path does not resolve to a GridMap."]
	if floor_surface == null:
		return ["Grid alignment requires a FloorSurface."]
	var grid_to_surface := _transform_relative_to(grid_map, floor_surface)
	if not grid_to_surface.basis.is_equal_approx(Basis.IDENTITY):
		errors.append(
			"The placement GridMap is rotated or scaled relative to FloorSurface; identity alignment is required."
		)
	if not is_zero_approx(grid_to_surface.origin.y):
		errors.append(
			"The placement GridMap is vertically offset relative to FloorSurface; a shared base height is required."
		)
	if not is_equal_approx(grid_map.cell_size.x, grid_map.cell_size.z):
		errors.append("The placement GridMap must use equal X and Z sizes for square floor cells.")
	if not grid_map.cell_center_x or not grid_map.cell_center_z:
		errors.append("The placement GridMap must centre items along X and Z.")
	return errors


## Reports whether current origin and size settings map equal horizontal cells to equal centres.
static func is_aligned(floor_surface: FloorSurface, grid_map: GridMap) -> bool:
	if not validate_grid_map(grid_map, floor_surface).is_empty():
		return false
	if not is_equal_approx(floor_surface.cell_size, grid_map.cell_size.x):
		return false
	var expected_origin := _expected_floor_origin(floor_surface, grid_map)
	return floor_surface.world_origin_xz.is_equal_approx(expected_origin)


## Resolves any floor cell into the sparse GridMap coordinate available for object placement.
static func floor_cell_to_grid_cell(
	floor_surface: FloorSurface,
	grid_map: GridMap,
	floor_cell: Vector2i
) -> Vector2i:
	var floor_centre := floor_surface.cell_to_local(floor_cell)
	var floor_to_grid := _transform_relative_to(floor_surface, grid_map)
	var grid_cell := grid_map.local_to_map(floor_to_grid * floor_centre)
	return Vector2i(grid_cell.x, grid_cell.z)


static func _expected_floor_origin(floor_surface: FloorSurface, grid_map: GridMap) -> Vector2:
	var grid_to_surface := _transform_relative_to(grid_map, floor_surface)
	var zero_cell_centre := grid_to_surface * grid_map.map_to_local(Vector3i.ZERO)
	return Vector2(zero_cell_centre.x, zero_cell_centre.z) \
		- Vector2.ONE * grid_map.cell_size.x * 0.5


## Computes a Node3D transform in another Node3D's local coordinate space, on-tree or off-tree.
static func _transform_relative_to(node: Node3D, target: Node3D) -> Transform3D:
	var node_to_root := _transform_to_tree_root(node)
	var target_to_root := _transform_to_tree_root(target)
	return target_to_root.affine_inverse() * node_to_root


static func _transform_to_tree_root(node: Node3D) -> Transform3D:
	var result := node.transform
	var ancestor := node.get_parent()
	while ancestor != null:
		if ancestor is Node3D:
			result = (ancestor as Node3D).transform * result
		ancestor = ancestor.get_parent()
	return result
