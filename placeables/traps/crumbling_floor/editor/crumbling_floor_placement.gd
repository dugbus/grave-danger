@tool
extends RefCounted

## Handles editor placement without a plugin or changes to floor occupancy or materials.

var pending := false
var undo_transform := Transform3D.IDENTITY
var _observed_position := Vector3.ZERO
var _observed_transform := Transform3D.IDENTITY
var _settle_frames := 0


## Existing children enter before their scene root is ready; only newly added instances auto-place on entry.
func begin(target: Node3D, scene_root: Node) -> void:
	reset(target)
	pending = (
		scene_root != null and scene_root != target and scene_root.is_ancestor_of(target) and scene_root.is_node_ready()
	)
	_settle_frames = 2


## Undo/redo and vertical adjustments establish a baseline rather than starting another placement.
func reset(target: Node3D) -> void:
	_observed_position = _world_transform(target).origin
	_observed_transform = target.transform
	undo_transform = target.transform
	pending = false


## Wait for the drag to end and transforms to settle; only horizontal movement requests another snap.
func should_place(target: Node3D, enabled: bool, dragging: bool) -> bool:
	var current := _world_transform(target).origin
	if not is_equal_approx(current.x, _observed_position.x) or not is_equal_approx(current.z, _observed_position.z):
		if not pending:
			undo_transform = _observed_transform
		pending = true
		_settle_frames = 2
	_observed_position = current
	_observed_transform = target.transform
	if not enabled:
		pending = false
	if not pending or dragging:
		if not pending:
			undo_transform = target.transform
		return false
	if _settle_frames > 0:
		_settle_frames -= 1
		return false
	pending = false
	return true


## Resolves a unique floor under the tile; overlapping floors require an explicit Inspector assignment.
static func find_surface(target: Node3D, scene_root: Node) -> FloorSurface:
	if scene_root == null or scene_root == target:
		return null
	var candidates: Array[FloorSurface] = []
	_collect_surfaces(scene_root, _world_transform(target).origin, candidates)
	return candidates[0] if candidates.size() == 1 else null


static func _collect_surfaces(node: Node, position: Vector3, candidates: Array[FloorSurface]) -> void:
	if node is FloorSurface:
		var surface := node as FloorSurface
		if (
			surface.floor_map != null
			and (
				surface.floor_map.get_authored_cell_elevation(surface.world_to_cell(position))
				!= FloorMap.INVALID_ELEVATION
			)
		):
			candidates.append(surface)
	for child in node.get_children():
		_collect_surfaces(child, position, candidates)


## Snaps the containing cell's centre and chooses its lowest adjacent flat floor, falling back to retained height.
static func calculate_auto_transform(target: Node3D, surface: FloorSurface) -> Dictionary:
	var result := calculate_height_transform(target, surface)
	if not result["valid"] as bool:
		return result
	var world := _world_transform(target)
	var cell := surface.world_to_cell(world.origin)
	var elevation := FloorMap.INVALID_ELEVATION
	for dz in range(-1, 2):
		for dx in range(-1, 2):
			if dx == 0 and dz == 0:
				continue
			var neighbor := cell + Vector2i(dx, dz)
			if (
				not surface.floor_map.has_floor(neighbor)
				or (
					surface.floor_map.transition_overrides.get(neighbor, FloorMap.Transition.Flat)
					!= FloorMap.Transition.Flat
				)
			):
				continue
			var neighbor_elevation := surface.floor_map.get_cell_elevation(neighbor)
			if elevation == FloorMap.INVALID_ELEVATION or neighbor_elevation < elevation:
				elevation = neighbor_elevation
	if elevation == FloorMap.INVALID_ELEVATION:
		elevation = surface.floor_map.get_authored_cell_elevation(cell)
	world.origin.x = surface.world_origin_xz.x + (float(cell.x) + 0.5) * surface.cell_size
	world.origin.z = surface.world_origin_xz.y + (float(cell.y) + 0.5) * surface.cell_size
	world.origin.y = surface.elevation_profile.elevation_to_world(elevation)
	result["transform"] = _to_local_transform(target, world)
	return result


## Editor services may be unavailable while tool scripts or their scene are being reloaded.
static func get_editor_history() -> Object:
	if not Engine.is_editor_hint() or not Engine.has_singleton(&"EditorInterface"):
		return null
	var editor := Engine.get_singleton(&"EditorInterface")
	return editor.get_editor_undo_redo() as Object if is_instance_valid(editor) else null


## Append the correction to the editor's placement/move action, preserving one-step undo and redo.
static func apply_auto_in_editor(
	target: Node3D, surface: FloorSurface, after: Transform3D, before: Transform3D
) -> void:
	var manager := get_editor_history()
	if not is_instance_valid(manager):
		return
	var history := manager.get_history_undo_redo(manager.get_object_history_id(target)) as UndoRedo
	apply_auto_with_history(target, surface, after, before, manager, history)


## Records through the editor manager; the supplied history is read only to identify the native move action.
static func apply_auto_with_history(
	target: Node3D, surface: FloorSurface, after: Transform3D, before: Transform3D, manager: Object, history: UndoRedo
) -> void:
	if target.transform.is_equal_approx(after) and target.get(&"floor_surface") == surface:
		return
	var action_name := history.get_current_action_name() if is_instance_valid(history) else ""
	var merge := not action_name.is_empty() and not history.has_redo()
	if not merge:
		action_name = "Place crumbling floor"
	manager.create_action(action_name, UndoRedo.MERGE_ALL if merge else UndoRedo.MERGE_DISABLE, target)
	manager.add_do_property(target, &"transform", after)
	# Also record the settled baseline when the original action was a setting change rather than a move.
	manager.add_undo_property(target, &"transform", before)
	if target.get(&"floor_surface") != surface:
		manager.add_do_property(target, &"floor_surface", surface)
		manager.add_undo_property(target, &"floor_surface", target.get(&"floor_surface"))
	# The original editor operation already ran; replaying a merged creation action would add the node twice.
	target.transform = after
	target.set(&"floor_surface", surface)
	manager.commit_action(false)


## Plans a height-only adjustment, including the retained elevation of an already empty floor cell.
static func calculate_height_transform(target: Node3D, surface: FloorSurface) -> Dictionary:
	if target == null or surface == null or surface.floor_map == null or surface.elevation_profile == null:
		return {"valid": false, "error": "Assign a Floor Surface with floor data and an elevation profile first."}
	if not _world_transform(surface).is_equal_approx(Transform3D.IDENTITY):
		return {
			"valid": false, "error": "Floor Surface needs an identity root transform, as required by the floor module."
		}
	var world := _world_transform(target)
	var cell := surface.world_to_cell(world.origin)
	var elevation := surface.floor_map.get_authored_cell_elevation(cell)
	if elevation == FloorMap.INVALID_ELEVATION:
		return {"valid": false, "error": "The tile is outside the Floor Surface's authored cells."}
	var transition := surface.floor_map.transition_overrides.get(cell, FloorMap.Transition.Flat) as int
	if transition != FloorMap.Transition.Flat:
		return {
			"valid": false, "error": "Crumbling floors currently replace flat cells; choose a flat cell's elevation."
		}
	world.origin.y = surface.elevation_profile.elevation_to_world(elevation)
	return {"valid": true, "transform": _to_local_transform(target, world)}


## Inspector buttons use Godot's own editor undo history; this helper has no editor-plugin dependency.
static func match_height_in_editor(target: Node3D, surface: FloorSurface) -> void:
	var history := get_editor_history()
	if not is_instance_valid(history):
		return
	var result := calculate_height_transform(target, surface)
	if not result["valid"] as bool:
		push_warning(result["error"] as String)
		return
	history.create_action("Match crumbling floor height", UndoRedo.MERGE_DISABLE, target)
	history.add_do_property(target, &"transform", result["transform"] as Transform3D)
	history.add_undo_property(target, &"transform", target.transform)
	history.commit_action()


static func _world_transform(node: Node3D) -> Transform3D:
	if node.is_inside_tree():
		return node.global_transform
	var result := node.transform
	var ancestor := node.get_parent()
	while ancestor != null:
		if ancestor is Node3D:
			result = (ancestor as Node3D).transform * result
		ancestor = ancestor.get_parent()
	return result


static func _to_local_transform(target: Node3D, world: Transform3D) -> Transform3D:
	var parent := target.get_parent_node_3d()
	return _world_transform(parent).affine_inverse() * world if parent != null else world
