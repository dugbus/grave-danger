@tool
extends RefCounted

## Plans height-only corrections for native GridMap brush strokes without changing floor data or meshes.

const ALIGNMENT := preload("res://addons/floor_surface/floor_surface_grid_alignment.gd")
const RAMP := preload("res://addons/floor_surface/floor_surface_ramp_resolver.gd")
const SET_CELL_ITEM := &"set_cell_item"
const NATIVE_PAINT_ACTION := &"GridMap Paint"
const MINIMUM_GRID_COORDINATE := -32768
const MAXIMUM_GRID_COORDINATE := 32767
# Absorb floating-point noise at exact grid steps without rounding visibly above support.
const GRID_STEP_EPSILON := 0.00001


## Captures item identity and orientation so replacing a grounded cell also has complete undo data.
static func snapshot(grid: GridMap) -> Dictionary[Vector3i, Vector2i]:
	var result: Dictionary[Vector3i, Vector2i] = {}
	for cell in grid.get_used_cells():
		result[cell] = Vector2i(grid.get_cell_item(cell), grid.get_cell_item_orientation(cell))
	return result


## Matches the native brush action in the editor's language, including erase strokes.
static func paint_action_name() -> String:
	return String(TranslationServer.get_or_add_domain(&"godot.editor").translate(NATIVE_PAINT_ACTION))


## Captures only geometry-affecting authoring state, so style edits never request scenery moves.
static func height_state(surface: FloorSurface) -> Dictionary:
	if surface == null or surface.floor_map == null or surface.elevation_profile == null:
		return {}
	return {
		"shape": surface.floor_map.get_shape_snapshot(),
		"transitions": surface.floor_map.get_transition_snapshot(),
		"default_elevation": surface.floor_map.default_elevation,
		"elevation_unit": surface.elevation_profile.elevation_unit,
		"origin": surface.world_origin_xz,
		"cell_size": surface.cell_size,
	}


## Creates an off-tree query snapshot; callers free it when the next floor edit is committed.
static func capture_surface(surface: FloorSurface) -> FloorSurface:
	if height_state(surface).is_empty():
		return null
	var previous := FloorSurface.new()
	previous.floor_map = surface.floor_map.create_unique_copy() as FloorMap
	previous.elevation_profile = surface.elevation_profile.duplicate(true) as FloorElevationProfile
	previous.world_origin_xz = surface.world_origin_xz
	previous.cell_size = surface.cell_size
	return previous


## Reseats pieces that matched the previous floor while preserving manually offset placements.
static func plan_floor_change(grid: GridMap, previous: FloorSurface, current: FloorSurface) -> Dictionary:
	var changes: Array[Dictionary] = []
	var errors := _configuration_errors(grid, current)
	if not errors.is_empty() or previous == null:
		return {"changes": changes, "errors": errors}
	if not _configuration_errors(grid, previous).is_empty():
		return {"changes": changes, "errors": ["Floor/grid alignment changed; existing scenery heights were kept."]}
	var cells := snapshot(grid)
	var target_counts: Dictionary[Vector3i, int] = {}
	for source in cells:
		var item := cells[source]
		if not _was_grounded(grid, previous, source, item):
			continue
		var centre := _world_transform(grid) * grid.map_to_local(source)
		if not current.sample_surface(centre).valid:
			errors.append("No floor remains below %s; the scenery was kept in place." % source)
			continue
		var anchor := _anchor(grid, current, source, item)
		if anchor.has("error"):
			errors.append(anchor["error"] as String)
			continue
		var target := Vector3i(source.x, anchor["y"] as int, source.z)
		if target == source:
			continue
		if cells.has(target):
			errors.append("Scenery at %s blocks the new floor height; both pieces were kept in place." % target)
			continue
		target_counts[target] = target_counts.get(target, 0) + 1
		(
			changes
			. append(
				{
					"source": source,
					"target": target,
					"painted": item,
					"source_before": item,
					"target_before": Vector2i(GridMap.INVALID_CELL_ITEM, 0),
					"previous": {} as Dictionary[Vector3i, Vector2i],
				}
			)
		)
	var safe_changes: Array[Dictionary] = []
	for change in changes:
		var target := change["target"] as Vector3i
		if target_counts[target] == 1:
			safe_changes.append(change)
		else:
			errors.append("Multiple scenery pieces would occupy %s; their heights were kept." % target)
	return {"changes": safe_changes, "errors": errors}


static func _was_grounded(grid: GridMap, surface: FloorSurface, source: Vector3i, item: Vector2i) -> bool:
	var centre := _world_transform(grid) * grid.map_to_local(source)
	var sample := surface.sample_surface(centre)
	if not sample.valid:
		return false
	var anchor := _anchor(grid, surface, source, item)
	if not anchor.has("error") and source.y == anchor["y"]:
		return true
	# Adopt placements from the earlier centre-height rule when their support is edited.
	var height := (_world_transform(grid).affine_inverse() * Vector3(centre.x, sample.world_height, centre.z)).y
	var offset := grid.cell_size.y * 0.5 if grid.cell_center_y else 0.0
	return source.y == roundi((height - offset) / grid.cell_size.y)


static func _configuration_errors(grid: GridMap, surface: FloorSurface) -> Array[String]:
	if surface == null or surface.floor_map == null or surface.elevation_profile == null:
		return ["Assign a Floor Surface with a map and elevation profile."]
	if not _world_transform(surface).is_equal_approx(Transform3D.IDENTITY):
		return ["FloorSurface requires an identity world transform."]
	var errors := ALIGNMENT.validate_grid_map(grid, surface)
	if errors.is_empty() and not ALIGNMENT.is_aligned(surface, grid):
		errors.append("The placement GridMap and FloorSurface cell origins must be aligned.")
	return errors


## Seats newly painted pieces at the lowest supporting height under their rotated mesh bounds.
## Other layers, existing placements, holes, and unsupported transforms remain authoritative.
static func plan(
	grid: GridMap,
	surface: FloorSurface,
	before: Dictionary[Vector3i, Vector2i],
	paint_layer: int,
	stroke_cells: Array[Vector3i] = []
) -> Dictionary:
	var changes: Array[Dictionary] = []
	var errors := _configuration_errors(grid, surface)
	if not errors.is_empty():
		return {"changes": changes, "errors": errors}
	var after := snapshot(grid)
	var candidates: Array[Vector3i] = []
	candidates.assign(after.keys())
	for cell in stroke_cells:
		if not candidates.has(cell):
			candidates.append(cell)
	for source in candidates:
		var painted := after.get(source, Vector2i(GridMap.INVALID_CELL_ITEM, 0)) as Vector2i
		if source.y != paint_layer or (not stroke_cells.has(source) and before.get(source) == painted):
			continue
		var result := _plan_cell(grid, surface, source, painted, before, after)
		if result.has("error"):
			errors.append(result["error"] as String)
		elif not result.is_empty():
			changes.append(result)
	return {"changes": changes, "errors": errors}


static func _plan_cell(
	grid: GridMap,
	surface: FloorSurface,
	source: Vector3i,
	painted: Vector2i,
	before: Dictionary[Vector3i, Vector2i],
	after: Dictionary[Vector3i, Vector2i]
) -> Dictionary:
	var centre := _world_transform(grid) * grid.map_to_local(source)
	var sample := surface.sample_surface(centre)
	if not sample.valid:
		return {"error": "No supporting floor below painted cell %s; its height was kept." % source}
	var centre_offset := grid.cell_size.y * 0.5 if grid.cell_center_y else 0.0
	var local_centre_height := (
		(_world_transform(grid).affine_inverse() * Vector3(centre.x, sample.world_height, centre.z)).y
	)
	var legacy_y := roundi((local_centre_height - centre_offset) / grid.cell_size.y)
	var previous := _grounded_column(grid, surface, source, before, legacy_y)
	var target: Vector3i
	if painted.x == GridMap.INVALID_CELL_ITEM:
		if previous.is_empty():
			return {}
		# Use the previous item's geometry and orientation, including older centre-anchored placements.
		target = previous.keys()[0] as Vector3i
	else:
		var anchor := _anchor(grid, surface, source, painted)
		if anchor.has("error"):
			return anchor
		target = Vector3i(source.x, anchor["y"] as int, source.z)
	previous.erase(source)
	previous.erase(target)
	if target == source and previous.is_empty():
		return {}
	if target != source and after.has(target) and before.get(target) != after[target]:
		return {"error": "Another newly painted cell occupies %s; its height was kept." % target}
	return {
		"source": source,
		"target": target,
		"painted": painted,
		"source_before": before.get(source, Vector2i(GridMap.INVALID_CELL_ITEM, 0)),
		"target_before": before.get(target, Vector2i(GridMap.INVALID_CELL_ITEM, 0)),
		"previous": previous,
	}


## Finds only recognizable automatic heights; arbitrary manually chosen layers remain untouched.
static func _grounded_column(
	grid: GridMap, surface: FloorSurface, source: Vector3i, before: Dictionary[Vector3i, Vector2i], legacy_y: int
) -> Dictionary[Vector3i, Vector2i]:
	var result: Dictionary[Vector3i, Vector2i] = {}
	for cell in before:
		if cell.x != source.x or cell.z != source.z:
			continue
		if cell.y == legacy_y:
			result[cell] = before[cell]
			continue
		var anchor := _anchor(grid, surface, source, before[cell])
		if not anchor.has("error") and cell.y == anchor["y"]:
			result[cell] = before[cell]
	return result


## The lower footprint corners of each intersected floor cell contain every possible planar minimum.
static func _anchor(grid: GridMap, surface: FloorSurface, source: Vector3i, item: Vector2i) -> Dictionary:
	var bounds := _item_bounds(grid, item)
	var grid_world := _world_transform(grid)
	var centre := grid_world * grid.map_to_local(source)
	var footprint := Rect2(
		Vector2(centre.x + bounds.position.x, centre.z + bounds.position.z), Vector2(bounds.size.x, bounds.size.z)
	)
	var minimum := surface.world_to_cell(Vector3(footprint.position.x, 0, footprint.position.y))
	var maximum := surface.world_to_cell(Vector3(footprint.end.x, 0, footprint.end.y))
	var lowest := INF
	var resolver := RAMP.new()
	for z in range(minimum.y, maximum.y + 1):
		for x in range(minimum.x, maximum.x + 1):
			var cell := Vector2i(x, z)
			if not surface.has_floor(cell):
				continue
			var cell_origin := surface.world_origin_xz + Vector2(cell) * surface.cell_size
			var overlap := footprint.intersection(Rect2(cell_origin, Vector2.ONE * surface.cell_size))
			if not overlap.has_area():
				continue
			var description := surface.get_cell_surface_description(cell)
			if not description.get("valid", false) as bool:
				continue
			for corner: Vector2 in [
				overlap.position,
				Vector2(overlap.end.x, overlap.position.y),
				overlap.end,
				Vector2(overlap.position.x, overlap.end.y)
			]:
				lowest = minf(lowest, resolver.sample_height(description, (corner - cell_origin) / surface.cell_size))
	if not is_finite(lowest):
		return {"error": "No supporting floor under the mesh at %s; its height was kept." % source}
	var local_height := (grid_world.affine_inverse() * Vector3(centre.x, lowest, centre.z)).y
	var centre_offset := grid.cell_size.y * 0.5 if grid.cell_center_y else 0.0
	var target_y := floori((local_height - bounds.position.y - centre_offset) / grid.cell_size.y + GRID_STEP_EPSILON)
	if target_y < MINIMUM_GRID_COORDINATE or target_y > MAXIMUM_GRID_COORDINATE:
		return {"error": "Floor height at %s exceeds the GridMap's vertical range; its height was kept." % source}
	return {"y": target_y}


## Applies the same item transform, orthogonal rotation and scale used by GridMap rendering.
static func _item_bounds(grid: GridMap, item: Vector2i) -> AABB:
	var library := grid.mesh_library
	if library != null and library.get_item_list().has(item.x):
		var mesh := library.get_item_mesh(item.x)
		if mesh != null:
			var rotation := grid.get_basis_with_orthogonal_index(item.y).scaled(Vector3.ONE * grid.cell_scale)
			var bounds := (
				(Transform3D(rotation, Vector3.ZERO) * library.get_item_mesh_transform(item.x)) * mesh.get_aabb()
			)
			if bounds.size.x > 0.0 and bounds.size.z > 0.0:
				return bounds
	# Missing mesh data still has the native cell footprint and an origin-level base.
	return AABB(
		Vector3(-grid.cell_size.x * 0.5, 0, -grid.cell_size.z * 0.5), Vector3(grid.cell_size.x, 0, grid.cell_size.z)
	)


## Appends corrections to the original native stroke, so one undo/redo restores the complete placement.
static func apply_with_history(
	grid: GridMap, changes: Array[Dictionary], manager: Object, action_name: String, context: Object = null
) -> void:
	if changes.is_empty():
		return
	manager.create_action(action_name, UndoRedo.MERGE_ALL, context if context != null else grid)
	for change in changes:
		var source := change["source"] as Vector3i
		var target := change["target"] as Vector3i
		var painted := change["painted"] as Vector2i
		var source_before := change["source_before"] as Vector2i
		var target_before := change["target_before"] as Vector2i
		var previous := change["previous"] as Dictionary[Vector3i, Vector2i]
		for old_cell in previous:
			var old_item := previous[old_cell]
			manager.add_do_method(grid, SET_CELL_ITEM, old_cell, GridMap.INVALID_CELL_ITEM)
			manager.add_undo_method(grid, SET_CELL_ITEM, old_cell, old_item.x, old_item.y)
			grid.set_cell_item(old_cell, GridMap.INVALID_CELL_ITEM)
		manager.add_do_method(grid, SET_CELL_ITEM, source, GridMap.INVALID_CELL_ITEM)
		manager.add_do_method(grid, SET_CELL_ITEM, target, painted.x, painted.y)
		# Restore pre-stroke source data, rather than the live native paint, regardless of undo ordering.
		manager.add_undo_method(grid, SET_CELL_ITEM, source, source_before.x, source_before.y)
		manager.add_undo_method(grid, SET_CELL_ITEM, target, target_before.x, target_before.y)
		grid.set_cell_item(source, GridMap.INVALID_CELL_ITEM)
		grid.set_cell_item(target, painted.x, painted.y)
	# Replaying a merged native action here would execute the original paint a second time.
	manager.commit_action(false)


static func _world_transform(node: Node3D) -> Transform3D:
	if node.is_inside_tree():
		return node.global_transform
	var result := node.transform
	var parent := node.get_parent()
	while parent != null:
		if parent is Node3D:
			result = (parent as Node3D).transform * result
		parent = parent.get_parent()
	return result
