extends "res://tests/test_case.gd"

const SUBJECT := preload("res://addons/floor_surface/floor_surface_placement_gridmap.gd")
const PAINT := preload("res://addons/floor_surface/editor/floor_surface_gridmap_paint.gd")

enum Item { Fence, Wall }
enum HistoryScope { Global, Scene }


## Models the manager's commit/undo signals while using Godot's real action merging and replay.
class HistoryManager:
	extends RefCounted
	signal history_changed
	signal version_changed
	var history := UndoRedo.new()
	var resource_history := UndoRedo.new()
	var _pending: UndoRedo
	var contexts: Array[Object] = []

	func get_object_history_id(object: Object) -> int:
		return HistoryScope.Global if object is Resource else HistoryScope.Scene

	func get_history_undo_redo(id: int) -> UndoRedo:
		return resource_history if id == HistoryScope.Global else history

	func create_action(name: String, merge: UndoRedo.MergeMode, context: Object) -> void:
		contexts.append(context)
		_pending = get_history_undo_redo(get_object_history_id(context))
		_pending.create_action(name, merge)

	func add_do_method(target: GridMap, _method: StringName, cell: Vector3i, item: int, orientation := 0) -> void:
		_pending.add_do_method(target.set_cell_item.bind(cell, item, orientation))

	func add_undo_method(target: GridMap, _method: StringName, cell: Vector3i, item: int, orientation := 0) -> void:
		_pending.add_undo_method(target.set_cell_item.bind(cell, item, orientation))

	func commit_action(execute: bool) -> void:
		_pending.commit_action(execute)
		history_changed.emit()

	func simulate_undo(context: Object = null) -> void:
		get_history_undo_redo(get_object_history_id(context)).undo()
		version_changed.emit()

	func simulate_redo(context: Object = null) -> void:
		get_history_undo_redo(get_object_history_id(context)).redo()
		version_changed.emit()

	func _notification(what: int) -> void:
		if what == NOTIFICATION_PREDELETE:
			if is_instance_valid(history):
				history.free()
			if is_instance_valid(resource_history):
				resource_history.free()


func run(tree: SceneTree) -> void:
	expect_script_contract(SUBJECT, "res://addons/floor_surface/floor_surface_placement_gridmap.gd")
	_test_editor_manager_api_boundary()
	_test_native_stroke_replacement_and_undo()
	_test_manual_layers_opt_out_and_reload()
	_test_unrelated_editor_commit_during_paint()
	_test_lowering_an_old_centre_anchored_fence()
	_test_floor_edits_share_undo(HistoryScope.Global)
	_test_floor_edits_share_undo(HistoryScope.Scene)
	_test_style_edits_and_manual_heights()
	_test_inspector_elevation_unit_change()
	_test_disabled_floor_following()
	await _test_native_eraser_observation(tree)


func _test_editor_manager_api_boundary() -> void:
	var manager := HistoryManager.new()
	# Test-only event controls are named simulate_*. Every modeled public manager
	# operation must actually be callable from GDScript in the running Godot build.
	for method in (manager.get_script() as Script).get_script_method_list():
		var method_name := method["name"] as StringName
		if String(method_name).begins_with("_") or String(method_name).begins_with("simulate_"):
			continue
		expect(
			ClassDB.class_has_method(&"EditorUndoRedoManager", method_name),
			"The history test substitute only models exposed editor API: %s." % method_name
		)
	manager.history.free()


func _fixture() -> Node3D:
	var root := Node3D.new()
	var surface := FloorSurface.new()
	surface.name = "Floor"
	surface.floor_map = FloorMap.new()
	surface.floor_map.dimensions = Vector2i(3, 1)
	surface.floor_map.default_present = true
	surface.floor_map.default_elevation = 4
	surface.floor_map.set_cell_elevation(Vector2i(2, 0), 8)
	surface.floor_map.set_cell_transition(Vector2i(1, 0), FloorMap.Transition.Ramp, FloorMap.LowEdge.West)
	surface.elevation_profile = FloorElevationProfile.new()
	root.add_child(surface)
	var grid := SUBJECT.new()
	grid.name = "Grid"
	grid.cell_size = Vector3(1, 0.01, 1)
	grid.cell_center_y = false
	grid.floor_surface_path = ^"../Floor"
	root.add_child(grid)
	return root


func _native_stroke(grid: GridMap, manager: HistoryManager, cells: Array[Vector3i], item: Item) -> void:
	manager.create_action(PAINT.paint_action_name(), UndoRedo.MERGE_DISABLE, grid)
	for cell in cells:
		manager.add_undo_method(
			grid, &"set_cell_item", cell, grid.get_cell_item(cell), grid.get_cell_item_orientation(cell)
		)
		manager.add_do_method(grid, &"set_cell_item", cell, item)
		# Godot paints live before committing the native stroke on mouse release.
		grid.set_cell_item(cell, item)
	manager.commit_action(true)


func _test_native_stroke_replacement_and_undo() -> void:
	var root := _fixture()
	var grid := root.get_node(^"Grid") as SUBJECT
	var manager := HistoryManager.new()
	grid.bind_editor_history(manager)
	var source := Vector3i(1, 0, 0)
	var target := Vector3i(1, 100, 0)
	_native_stroke(grid, manager, [source, Vector3i(2, 0, 0)], Item.Fence)
	expect_equal(
		grid.get_cell_item(target),
		Item.Fence,
		"A native brush commit places its fence at the ramp's lowest supporting edge."
	)
	expect_equal(grid.get_cell_item(Vector3i(2, 200, 0)), Item.Fence, "One stroke follows different floor heights.")
	expect_equal(grid.get_cell_item(source), GridMap.INVALID_CELL_ITEM, "No duplicate fence remains on the base layer.")
	expect_equal(manager.history.get_history_count(), 1, "Grounding remains part of the original native brush action.")
	expect(
		manager.contexts.all(func(context: Object) -> bool: return context == grid),
		"Every correction uses the grid's scene history."
	)
	manager.simulate_undo()
	expect(grid.get_used_cells().is_empty(), "One undo removes the complete grounded stroke.")
	manager.simulate_redo()
	expect_equal(grid.get_cell_item(target), Item.Fence, "One redo restores the grounded stroke without re-snapping.")
	_native_stroke(grid, manager, [source], Item.Wall)
	expect_equal(grid.get_cell_item(target), Item.Wall, "A new brush stroke replaces an existing grounded item.")
	manager.simulate_undo()
	expect_equal(grid.get_cell_item(target), Item.Fence, "Undoing a replacement restores the previous raised fence.")
	expect_equal(
		grid.get_cell_item(source), GridMap.INVALID_CELL_ITEM, "Replacement undo never recreates a raw base-layer item."
	)
	manager.simulate_redo()
	expect_equal(grid.get_cell_item(target), Item.Wall, "Redo restores the replacement at its sampled height.")
	grid.bind_editor_history(manager)
	expect_equal(
		manager.history_changed.get_connections().size(), 1, "Repeated history binding does not duplicate handlers."
	)
	grid._disconnect_history()
	expect(manager.history_changed.get_connections().is_empty(), "Disconnecting releases the editor history handlers.")
	manager.history.clear_history()
	manager.history.free()
	root.free()


func _test_manual_layers_opt_out_and_reload() -> void:
	var root := _fixture()
	var grid := root.get_node(^"Grid") as SUBJECT
	var saved := Vector3i(2, 0, 0)
	grid.set_cell_item(saved, Item.Wall)
	var manager := HistoryManager.new()
	grid.bind_editor_history(manager)
	expect_equal(grid.get_cell_item(saved), Item.Wall, "Binding or reopening a scene does not move saved placements.")
	_native_stroke(grid, manager, [Vector3i(1, 12, 0)], Item.Fence)
	expect_equal(
		grid.get_cell_item(Vector3i(1, 12, 0)),
		Item.Fence,
		"Painting another layer preserves intentional manual height."
	)
	grid.follow_floor = false
	_native_stroke(grid, manager, [Vector3i(1, 0, 0)], Item.Fence)
	expect_equal(grid.get_cell_item(Vector3i(1, 0, 0)), Item.Fence, "Follow Floor can be explicitly disabled.")
	grid.follow_floor = true
	# A tool reload may retain the live manager while resetting newly added script state.
	grid._history_versions.clear()
	grid.bind_editor_history(manager)
	manager.history_changed.emit()
	expect_equal(
		grid.get_cell_item(Vector3i(1, 0, 0)),
		Item.Fence,
		"Recovering editor history does not retroactively move old cells."
	)
	grid._disconnect_history()
	manager.history.clear_history()
	manager.history.free()
	root.free()


func _test_unrelated_editor_commit_during_paint() -> void:
	var root := _fixture()
	var grid := root.get_node(^"Grid") as SUBJECT
	var manager := HistoryManager.new()
	grid.bind_editor_history(manager)
	# Another scene's history notification must not capture a still-live native
	# brush stroke as our new baseline before its own commit reaches the manager.
	grid.set_cell_item(Vector3i(1, 0, 0), Item.Fence)
	var unrelated := Resource.new()
	manager.create_action("Unrelated resource edit", UndoRedo.MERGE_DISABLE, unrelated)
	manager.resource_history.add_do_property(unrelated, &"resource_name", "Changed")
	manager.resource_history.add_undo_property(unrelated, &"resource_name", "")
	manager.commit_action(true)
	_native_stroke(grid, manager, [Vector3i(1, 0, 0)], Item.Fence)
	expect_equal(
		grid.get_cell_item(Vector3i(1, 100, 0)),
		Item.Fence,
		"An unrelated editor commit does not prevent the native brush from grounding."
	)
	grid._disconnect_history()
	manager.history.clear_history()
	manager.history.free()
	root.free()


func _test_lowering_an_old_centre_anchored_fence() -> void:
	var root := _fixture()
	var grid := root.get_node(^"Grid") as SUBJECT
	var old_target := Vector3i(1, 150, 0)
	var new_target := Vector3i(1, 100, 0)
	grid.set_cell_item(old_target, Item.Fence)
	var manager := HistoryManager.new()
	grid.bind_editor_history(manager)
	_native_stroke(grid, manager, [Vector3i(1, 0, 0)], Item.Fence)
	expect_equal(
		grid.get_cell_item(new_target),
		Item.Fence,
		"Repainting lowers a centre-anchored fence to the slope's bottom edge."
	)
	expect_equal(
		grid.get_cell_item(old_target), GridMap.INVALID_CELL_ITEM, "Repainting removes the previous floating copy."
	)
	expect_equal(grid.get_used_cells().size(), 1, "Correcting an old placement keeps exactly one fence.")
	manager.simulate_undo()
	expect_equal(grid.get_cell_item(old_target), Item.Fence, "One undo restores the original authored placement.")
	expect_equal(grid.get_cell_item(new_target), GridMap.INVALID_CELL_ITEM, "Undo also removes the lowered copy.")
	manager.simulate_redo()
	expect_equal(grid.get_cell_item(new_target), Item.Fence, "Redo restores the base-anchored placement.")
	expect_equal(grid.get_cell_item(old_target), GridMap.INVALID_CELL_ITEM, "Redo keeps the old floating copy removed.")
	grid._disconnect_history()
	manager.history.clear_history()
	manager.history.free()
	root.free()


func _test_native_eraser_observation(tree: SceneTree) -> void:
	var root := _fixture()
	var grid := root.get_node(^"Grid") as SUBJECT
	var target := Vector3i(1, 100, 0)
	grid.set_cell_item(target, Item.Fence)
	tree.root.add_child(root)
	await tree.process_frame

	var camera := Camera3D.new()
	root.add_child(camera)
	camera.position = Vector3(1.5, 10, 0.5)
	camera.rotation_degrees.x = -90
	var manager := HistoryManager.new()
	grid.bind_editor_history(manager)
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	click.position = tree.root.get_visible_rect().size * 0.5
	grid.observe_pointer(camera, click)
	click.pressed = false
	grid.observe_pointer(camera, click)
	# The native eraser commits even though its fixed-height source cell is empty.
	manager.create_action(PAINT.paint_action_name(), UndoRedo.MERGE_DISABLE, grid)
	manager.add_do_method(grid, &"set_cell_item", Vector3i(1, 0, 0), GridMap.INVALID_CELL_ITEM)
	manager.add_undo_method(grid, &"set_cell_item", Vector3i(1, 0, 0), GridMap.INVALID_CELL_ITEM)
	manager.commit_action(true)
	expect_equal(
		grid.get_cell_item(target), GridMap.INVALID_CELL_ITEM, "The normal native eraser removes a raised fence."
	)
	expect_equal(manager.history.get_history_count(), 1, "Erasing and grounding share one action.")
	manager.simulate_undo()
	expect_equal(grid.get_cell_item(target), Item.Fence, "One undo restores the erased fence at its real height.")
	manager.simulate_redo()
	expect_equal(
		grid.get_cell_item(target),
		GridMap.INVALID_CELL_ITEM,
		"Redo erases the fence without triggering placement again."
	)
	grid._disconnect_history()
	manager.history.clear_history()
	manager.history.free()
	root.free()
	await tree.process_frame


func _raise_floor(grid: SUBJECT, manager: HistoryManager, scope: HistoryScope) -> void:
	var surface := grid.get_node(grid.floor_surface_path) as FloorSurface
	var floor_map := surface.floor_map
	var before := floor_map.get_elevation_snapshot()
	var after := before.duplicate()
	after[Vector2i.ZERO] = 8
	after[Vector2i(2, 0)] = 12
	floor_map.apply_elevation_snapshot(after)
	# Live floor previews do not repeatedly move scenery during the gesture.
	expect_equal(
		grid.get_cell_item(Vector3i(1, 100, 0)), Item.Fence, "Scenery stays settled until the floor stroke commits."
	)
	var context: Object = grid if scope == HistoryScope.Scene else floor_map
	manager.create_action("Raise floor", UndoRedo.MERGE_DISABLE, context)
	var history := manager.get_history_undo_redo(manager.get_object_history_id(context))
	history.add_do_method(floor_map.apply_elevation_snapshot.bind(after))
	history.add_undo_method(floor_map.apply_elevation_snapshot.bind(before))
	manager.commit_action(false)


func _test_floor_edits_share_undo(scope: HistoryScope) -> void:
	var root := _fixture()
	var grid := root.get_node(^"Grid") as SUBJECT
	var surface := root.get_node(^"Floor") as FloorSurface
	var original_elevations := surface.floor_map.get_elevation_snapshot()
	grid.set_cell_item(Vector3i(1, 100, 0), Item.Fence)
	grid.set_cell_item(Vector3i(1, 125, 0), Item.Wall)
	var manager := HistoryManager.new()
	grid.bind_editor_history(manager)
	_raise_floor(grid, manager, scope)
	expect_equal(
		grid.get_cell_item(Vector3i(1, 200, 0)), Item.Fence, "A completed floor edit raises its grounded fence."
	)
	expect_equal(
		grid.get_cell_item(Vector3i(1, 100, 0)),
		GridMap.INVALID_CELL_ITEM,
		"Floor edits do not leave an old fence behind."
	)
	expect_equal(
		grid.get_cell_item(Vector3i(1, 125, 0)), Item.Wall, "A manually offset item keeps its authored height."
	)
	var context: Object = grid if scope == HistoryScope.Scene else surface.floor_map
	var history := manager.get_history_undo_redo(manager.get_object_history_id(context))
	expect_equal(
		history.get_history_count(), 1, "The floor and scenery changes share one undo action in their source history."
	)
	manager.simulate_undo(context)
	expect_equal(surface.floor_map.get_cell_elevation(Vector2i.ZERO), 4, "One undo restores the previous floor height.")
	expect_equal(
		grid.get_cell_item(Vector3i(1, 100, 0)), Item.Fence, "The same undo restores the previous fence height."
	)
	manager.simulate_redo(context)
	expect_equal(
		grid.get_cell_item(Vector3i(1, 200, 0)),
		Item.Fence,
		"Redo restores the floor-following placement without another action."
	)
	manager.simulate_undo(context)
	_raise_floor(grid, manager, scope)
	expect_equal(
		grid.get_cell_item(Vector3i(1, 200, 0)),
		Item.Fence,
		"A new floor edit after undo uses the restored floor baseline."
	)
	var raised := surface.floor_map.get_elevation_snapshot()
	manager.create_action("Lower floor", UndoRedo.MERGE_DISABLE, context)
	history.add_do_method(surface.floor_map.apply_elevation_snapshot.bind(original_elevations))
	history.add_undo_method(surface.floor_map.apply_elevation_snapshot.bind(raised))
	manager.commit_action(true)
	expect_equal(grid.get_cell_item(Vector3i(1, 100, 0)), Item.Fence, "A later lowering edit also moves scenery down.")
	expect_equal(history.get_history_count(), 2, "Separate floor edits remain separate undo steps.")
	manager.simulate_undo(context)
	expect_equal(
		grid.get_cell_item(Vector3i(1, 200, 0)),
		Item.Fence,
		"Undoing the lowering edit raises floor and scenery together."
	)
	grid._disconnect_history()
	root.free()


func _test_style_edits_and_manual_heights() -> void:
	var root := _fixture()
	var grid := root.get_node(^"Grid") as SUBJECT
	var surface := root.get_node(^"Floor") as FloorSurface
	# Style changes must not adopt or move an older centre-height fence.
	grid.set_cell_item(Vector3i(1, 150, 0), Item.Fence)
	var manager := HistoryManager.new()
	grid.bind_editor_history(manager)
	var styles := surface.floor_map.get_style_snapshot()
	var painted_styles := styles.duplicate()
	painted_styles[Vector2i(1, 0)] = 1
	manager.create_action("Paint Style", UndoRedo.MERGE_DISABLE, surface.floor_map)
	manager.resource_history.add_do_method(surface.floor_map.apply_style_snapshot.bind(painted_styles))
	manager.resource_history.add_undo_method(surface.floor_map.apply_style_snapshot.bind(styles))
	manager.commit_action(true)
	expect_equal(surface.floor_map.get_cell_style(Vector2i(1, 0)), 1, "The style-only resource edit was applied.")
	expect_equal(
		grid.get_cell_item(Vector3i(1, 150, 0)), Item.Fence, "Changing floor appearance does not reseat scenery."
	)
	grid._disconnect_history()
	root.free()


func _test_inspector_elevation_unit_change() -> void:
	var root := _fixture()
	var grid := root.get_node(^"Grid") as SUBJECT
	var surface := root.get_node(^"Floor") as FloorSurface
	grid.set_cell_item(Vector3i(1, 100, 0), Item.Fence)
	var manager := HistoryManager.new()
	grid.bind_editor_history(manager)
	var profile := surface.elevation_profile
	manager.create_action("Set elevation unit", UndoRedo.MERGE_DISABLE, profile)
	manager.resource_history.add_do_property(profile, &"elevation_unit", 0.5)
	manager.resource_history.add_undo_property(profile, &"elevation_unit", 0.25)
	manager.commit_action(true)
	expect_equal(
		grid.get_cell_item(Vector3i(1, 200, 0)), Item.Fence, "Inspector unit changes also reseat grounded scenery."
	)
	expect_equal(
		manager.resource_history.get_history_count(), 1, "Inspector and scenery edits share the same resource action."
	)
	manager.simulate_undo(profile)
	expect_equal(grid.get_cell_item(Vector3i(1, 100, 0)), Item.Fence, "Undo restores the profile and scenery together.")
	expect(is_equal_approx(profile.elevation_unit, 0.25), "The original elevation unit is restored.")
	grid._disconnect_history()
	root.free()


func _test_disabled_floor_following() -> void:
	var root := _fixture()
	var grid := root.get_node(^"Grid") as SUBJECT
	grid.set_cell_item(Vector3i(1, 100, 0), Item.Fence)
	grid.follow_floor = false
	var manager := HistoryManager.new()
	grid.bind_editor_history(manager)
	_raise_floor(grid, manager, HistoryScope.Global)
	expect_equal(
		grid.get_cell_item(Vector3i(1, 100, 0)),
		Item.Fence,
		"Disabling Follow Floor keeps scenery fixed during floor edits."
	)
	expect_equal(
		grid.get_cell_item(Vector3i(1, 200, 0)),
		GridMap.INVALID_CELL_ITEM,
		"Disabled floor following creates no moved copy."
	)
	grid._disconnect_history()
	root.free()
