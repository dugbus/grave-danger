extends "res://tests/test_case.gd"

const SUBJECT := preload("res://placeables/traps/crumbling_floor/editor/crumbling_floor_placement.gd")
const TILE := preload("res://placeables/traps/crumbling_floor/crumbling_floor.gd")
const SCENE := preload("res://placeables/traps/crumbling_floor/crumbling_floor.tscn")


class PlacementProbe:
	extends Node3D
	var placement := SUBJECT.new()
	var scene_root: Node

	func _ready() -> void:
		placement.begin(self, scene_root)


## Provides the editor manager's context argument while exercising Godot's actual undo merge behavior.
class HistoryManager:
	extends RefCounted
	var history := UndoRedo.new()

	func create_action(name: String, merge: UndoRedo.MergeMode, _context: Object) -> void:
		history.create_action(name, merge)

	func add_do_property(target: Object, property: StringName, value: Variant) -> void:
		history.add_do_property(target, property, value)

	func add_undo_property(target: Object, property: StringName, value: Variant) -> void:
		history.add_undo_property(target, property, value)

	func commit_action(execute: bool) -> void:
		history.commit_action(execute)


func run(tree: SceneTree) -> void:
	expect_script_contract(SUBJECT, "res://placeables/traps/crumbling_floor/editor/crumbling_floor_placement.gd")
	_test_elevated_hole_and_undo()
	_test_missing_or_invalid_floor()
	_test_auto_cell_centres_and_neighbors()
	_test_surface_discovery()
	await _test_placement_lifecycle(tree)
	_test_auto_undo_redo()
	_test_grouped_placement_history()
	_test_creation_history()
	_test_missing_native_history()
	await _test_floor_module_dimensions(tree)


func _make_surface() -> FloorSurface:
	var surface := FloorSurface.new()
	surface.world_origin_xz = Vector2(-4.0, -6.0)
	surface.floor_map = FloorMap.new()
	surface.floor_map.dimensions = Vector2i(3, 3)
	surface.floor_map.default_present = true
	surface.floor_map.default_elevation = 8
	surface.elevation_profile = FloorElevationProfile.new()
	return surface


func _test_elevated_hole_and_undo() -> void:
	var root := Node3D.new()
	var surface := _make_surface()
	root.add_child(surface)
	var hole := Vector2i.ONE
	surface.floor_map.set_cell_elevation(hole, 20)
	surface.floor_map.set_floor_present(hole, false)
	var before_presence := surface.floor_map.get_presence_snapshot()
	var before_elevations := surface.floor_map.get_elevation_snapshot()
	var parent := Node3D.new()
	parent.transform = Transform3D(Basis(Vector3.UP, 0.7), Vector3(4.0, 3.0, -2.0))
	root.add_child(parent)
	var tile := SCENE.instantiate() as TILE
	tile.floor_surface = surface
	parent.add_child(tile)
	var world_before := Transform3D(Basis(Vector3.UP, 0.3), Vector3(-2.5, 19.0, -4.5))
	tile.transform = parent.transform.affine_inverse() * world_before
	var before := tile.transform
	var result := SUBJECT.calculate_height_transform(tile, surface)
	expect(result["valid"] as bool, "An existing elevated hole has a valid placement height.")
	expect_equal(tile.transform, before, "Planning never moves the tile automatically.")
	var expected := world_before
	expected.origin.y = 5.0
	var after := result["transform"] as Transform3D
	expect(
		(parent.transform * after).is_equal_approx(expected),
		"Height matching uses authored elevation while preserving world X/Z and orientation under a rotated parent."
	)
	var history := UndoRedo.new()
	history.create_action("Match floor height")
	history.add_do_property(tile, &"transform", after)
	history.add_undo_property(tile, &"transform", before)
	history.commit_action()
	expect(tile.transform.is_equal_approx(after), "Applying the planned height conforms to the elevated floor.")
	history.undo()
	expect(tile.transform.is_equal_approx(before), "Undo restores the tile's original authored height.")
	history.redo()
	expect(tile.transform.is_equal_approx(after), "Redo reapplies the matching elevation.")
	expect_equal(surface.floor_map.get_presence_snapshot(), before_presence, "Height matching never edits occupancy.")
	expect_equal(
		surface.floor_map.get_elevation_snapshot(), before_elevations, "Height matching never changes elevations."
	)
	expect(not surface.floor_map.has_floor(hole), "The supporting hole remains empty for the tile to collapse into.")
	history.clear_history()
	history.free()
	root.free()


func _test_missing_or_invalid_floor() -> void:
	var tile := SCENE.instantiate() as TILE
	var original := tile.transform
	expect(
		not SUBJECT.calculate_height_transform(tile, null)["valid"] as bool,
		"Missing floor data cannot silently snap the tile to zero."
	)
	var surface := _make_surface()
	tile.position = Vector3(-3.5, -15.0, -5.5)
	var flat := SUBJECT.calculate_height_transform(tile, surface)
	expect(flat["valid"] as bool, "Present flat cells can also supply an elevated baseline.")
	expect(
		is_equal_approx((flat["transform"] as Transform3D).origin.y, 2.0),
		"The floor module's elevation-unit conversion supplies the height."
	)
	expect(surface.floor_map.has_floor(Vector2i.ZERO), "Planning over present floor does not remove its cell.")
	surface.floor_map.set_cell_elevation(Vector2i.ZERO, -6)
	var lowered := SUBJECT.calculate_height_transform(tile, surface)
	expect(
		is_equal_approx((lowered["transform"] as Transform3D).origin.y, -1.5),
		"Below-zero floors use their authored elevation too."
	)
	tile.position.x = 100.0
	expect(
		not SUBJECT.calculate_height_transform(tile, surface)["valid"] as bool,
		"Outside cells leave author placement unchanged."
	)
	tile.position = Vector3(-3.5, 9.0, -5.5)
	surface.floor_map.transition_overrides[Vector2i.ZERO] = FloorMap.Transition.Ramp
	expect(
		not SUBJECT.calculate_height_transform(tile, surface)["valid"] as bool,
		"A flat crumbling tile does not silently misalign with a ramp."
	)
	tile.transform = original
	tile.match_floor_height.call()
	expect_equal(tile.transform, original, "Editor placement actions have no effect during gameplay.")
	tile.free()
	surface.free()


func _test_floor_module_dimensions(tree: SceneTree) -> void:
	var surface := _make_surface()
	surface.cell_size = 2.0
	var tile := SCENE.instantiate() as TILE
	tile.floor_surface = surface
	tile.position = Vector3(-1.8, 11.0, -3.2)
	tree.root.add_child(tile)
	expect_equal(
		tile.tile_size,
		Vector3(2.0, 0.25, 2.0),
		"The floor module sizes a tile without requiring a placement GridMap or plugin."
	)
	expect_equal(tile.position, Vector3(-1.8, 11.0, -3.2), "Gameplay never snaps authored transforms.")
	expect(tile._editor_placement == null, "Runtime tiles do not allocate editor placement state.")
	tile.free()
	surface.free()
	await tree.process_frame


func _test_auto_cell_centres_and_neighbors() -> void:
	var surface := _make_surface()
	surface.cell_size = 2.0
	var root := Node3D.new()
	var parent := Node3D.new()
	parent.transform = Transform3D(Basis(Vector3.UP, 0.6), Vector3(4.0, 3.0, -2.0))
	root.add_child(parent)
	var tile := SCENE.instantiate() as TILE
	parent.add_child(tile)
	var before := Transform3D(Basis(Vector3.UP, 0.2), Vector3(-1.8, 99.0, -3.2))
	tile.transform = parent.transform.affine_inverse() * before
	var hole := Vector2i.ONE
	surface.floor_map.set_cell_elevation(hole, 20)
	surface.floor_map.set_floor_present(hole, false)
	surface.floor_map.set_cell_elevation(Vector2i(2, 1), -4)
	# A deeper neighboring hole and a ramp must not drag the tile down toward the pit or slope.
	surface.floor_map.set_cell_elevation(Vector2i(0, 1), -40)
	surface.floor_map.set_floor_present(Vector2i(0, 1), false)
	surface.floor_map.set_cell_elevation(Vector2i(1, 0), -80)
	surface.floor_map.transition_overrides[Vector2i(1, 0)] = FloorMap.Transition.Ramp
	var occupancy := surface.floor_map.get_presence_snapshot()
	var elevations := surface.floor_map.get_elevation_snapshot()
	var result := SUBJECT.calculate_auto_transform(tile, surface)
	expect(result["valid"] as bool, "A hole with surrounding flat floor can auto-place.")
	var after := parent.transform * (result["transform"] as Transform3D)
	expect(
		after.origin.is_equal_approx(Vector3(-1.0, -1.0, -3.0)),
		"Auto placement respects nonzero origin, two-metre cells, parent transforms and lowest neighboring floor."
	)
	expect(after.basis.is_equal_approx(before.basis), "Automatic placement preserves the authored orientation.")
	expect((parent.transform * tile.transform).is_equal_approx(before), "Planning does not mutate the tile.")
	expect_equal(surface.floor_map.get_presence_snapshot(), occupancy, "Auto placement never erases ordinary floor.")
	expect_equal(surface.floor_map.get_elevation_snapshot(), elevations, "Auto placement never changes floor heights.")
	surface.floor_map.default_present = false
	surface.floor_map.presence_exceptions.clear()
	result = SUBJECT.calculate_auto_transform(tile, surface)
	after = parent.transform * (result["transform"] as Transform3D)
	expect(
		is_equal_approx(after.origin.y, 5.0), "Interior cells of a large hole retain authored height without neighbors."
	)
	surface.floor_map.transition_overrides[hole] = FloorMap.Transition.Ramp
	expect(not SUBJECT.calculate_auto_transform(tile, surface)["valid"] as bool, "Ramp targets are rejected.")
	tile.position.x = 100.0
	expect(not SUBJECT.calculate_auto_transform(tile, surface)["valid"] as bool, "Outside cells are rejected.")
	root.free()
	surface.free()


func _test_surface_discovery() -> void:
	var root := Node3D.new()
	var nested := Node3D.new()
	root.add_child(nested)
	var surface := _make_surface()
	nested.add_child(surface)
	var tile := Node3D.new()
	tile.position = Vector3(-2.2, 13.0, -4.2)
	root.add_child(tile)
	expect_equal(SUBJECT.find_surface(tile, root), surface, "New tiles discover a nested floor beneath their cell.")
	expect(SUBJECT.find_surface(tile, tile) == null, "Editing the standalone trap scene cannot discover a level floor.")
	var other := _make_surface()
	other.world_origin_xz = Vector2(100.0, 100.0)
	root.add_child(other)
	expect_equal(SUBJECT.find_surface(tile, root), surface, "A disjoint floor does not make discovery ambiguous.")
	other.world_origin_xz = surface.world_origin_xz
	expect(SUBJECT.find_surface(tile, root) == null, "Overlapping surfaces require an explicit assignment.")
	root.free()


func _test_placement_lifecycle(tree: SceneTree) -> void:
	var root := Node3D.new()
	var saved_tile := PlacementProbe.new()
	saved_tile.scene_root = root
	saved_tile.position = Vector3(0.2, 7.0, 0.3)
	root.add_child(saved_tile)
	tree.root.add_child(root)
	for frame in 4:
		expect(
			not saved_tile.placement.should_place(saved_tile, true, false),
			"Opening a saved scene preserves its authored placement and manual height."
		)
	var tile := PlacementProbe.new()
	tile.scene_root = root
	root.add_child(tile)
	expect(tile.placement.pending, "Adding a new tile to a ready level requests placement.")
	tile.position = Vector3(2.2, 10.0, 3.4)
	for frame in 4:
		expect(not tile.placement.should_place(tile, true, true), "A held drag never fights the editor gizmo.")
	expect(not tile.placement.should_place(tile, true, false), "Placement waits for transforms to settle.")
	expect(not tile.placement.should_place(tile, true, false), "Settling also covers deferred editor operations.")
	expect(tile.placement.should_place(tile, true, false), "Dropping the tile requests one automatic correction.")
	expect(not tile.placement.should_place(tile, true, false), "An unchanged tile does not repeatedly snap.")
	tile.position.y += 2.0
	expect(not tile.placement.should_place(tile, true, false), "Vertical-only manual adjustments remain untouched.")
	var manually_raised := tile.transform
	tile.position.x += 2.0
	for frame in 2:
		tile.placement.should_place(tile, true, false)
	expect(tile.placement.should_place(tile, true, false), "A duplicated or horizontally moved tile snaps again.")
	expect_equal(tile.placement.undo_transform, manually_raised, "The next move retains manual height for undo.")
	tile.position.z += 1.0
	tile.placement.should_place(tile, false, false)
	expect(not tile.placement.pending, "Disabling automatic placement allows freely authored positions.")
	tile.position.x -= 2.0
	tile.placement.reset(tile)
	expect(not tile.placement.should_place(tile, true, false), "Undo/redo resets the baseline without resnapping.")
	root.free()
	await tree.process_frame


func _test_auto_undo_redo() -> void:
	var surface := _make_surface()
	var tile := SCENE.instantiate() as TILE
	var manager := HistoryManager.new()
	var history := manager.history
	var placement := SUBJECT.new()
	history.version_changed.connect(func() -> void: placement.reset(tile))
	var before := Transform3D(Basis.IDENTITY, Vector3(-3.5, 7.0, -5.5))
	var moved := Transform3D(Basis.IDENTITY, Vector3(-2.2, 7.0, -4.2))
	tile.transform = before
	history.create_action("Move node")
	history.add_do_property(tile, &"transform", moved)
	history.add_undo_property(tile, &"transform", before)
	history.commit_action()
	var result := SUBJECT.calculate_auto_transform(tile, surface)
	var after := result["transform"] as Transform3D
	SUBJECT.apply_auto_with_history(tile, surface, after, before, manager, history)
	expect_equal(tile.transform, after, "Placement applies the corrected transform.")
	expect_equal(tile.floor_surface, surface, "Placement assigns the discovered floor for dimensions.")
	expect_equal(history.get_history_count(), 1, "Automatic correction merges into the original editor move.")
	history.undo()
	expect_equal(tile.transform, before, "One undo restores the original position and manual height.")
	expect(tile.floor_surface == null, "Undo restores the previous floor reference.")
	expect(not placement.should_place(tile, true, false), "Undo does not trigger another automatic correction.")
	history.redo()
	expect_equal(tile.transform, after, "One redo restores the snapped placement rather than the raw drop point.")
	expect_equal(tile.floor_surface, surface, "Redo also restores the discovered floor reference.")
	history.clear_history()
	history.free()
	tile.free()
	surface.free()


func _test_grouped_placement_history() -> void:
	var surface := _make_surface()
	var first := SCENE.instantiate() as TILE
	var second := SCENE.instantiate() as TILE
	var manager := HistoryManager.new()
	var history := manager.history
	var first_before := Transform3D(Basis.IDENTITY, Vector3(-3.5, 7.0, -5.5))
	var second_before := Transform3D(Basis.IDENTITY, Vector3(-2.5, 9.0, -5.5))
	first.transform = first_before
	second.transform = second_before
	history.create_action("Move corridor row")
	history.add_do_property(first, &"position", Vector3(-3.2, 7.0, -4.2))
	history.add_do_property(second, &"position", Vector3(-2.2, 9.0, -4.2))
	history.add_undo_property(first, &"transform", first_before)
	history.add_undo_property(second, &"transform", second_before)
	history.commit_action()
	var first_after := SUBJECT.calculate_auto_transform(first, surface)["transform"] as Transform3D
	var second_after := SUBJECT.calculate_auto_transform(second, surface)["transform"] as Transform3D
	SUBJECT.apply_auto_with_history(first, surface, first_after, first_before, manager, history)
	SUBJECT.apply_auto_with_history(second, surface, second_after, second_before, manager, history)
	expect_equal(first.transform, first_after, "Snapping the second tile does not replay and displace the first.")
	expect_equal(second.transform, second_after, "Both columns of a corridor row snap independently.")
	expect_equal(history.get_history_count(), 1, "A row's corrections share its original group move action.")
	history.undo()
	expect_equal(first.transform, first_before, "One group undo restores the first column's manual height.")
	expect_equal(second.transform, second_before, "One group undo restores the second column's manual height.")
	history.redo()
	expect_equal(first.transform, first_after, "Group redo restores the first snapped column.")
	expect_equal(second.transform, second_after, "Group redo restores the second snapped column.")
	history.clear_history()
	history.free()
	first.free()
	second.free()
	surface.free()


func _test_creation_history() -> void:
	var root := Node3D.new()
	var surface := _make_surface()
	var tile := SCENE.instantiate() as TILE
	tile.position = Vector3(-2.2, 99.0, -4.2)
	var before := tile.transform
	var manager := HistoryManager.new()
	var history := manager.history
	history.create_action("Instance scene")
	history.add_do_method(root.add_child.bind(tile))
	history.add_undo_method(root.remove_child.bind(tile))
	history.add_do_reference(tile)
	history.commit_action()
	var after := SUBJECT.calculate_auto_transform(tile, surface)["transform"] as Transform3D
	SUBJECT.apply_auto_with_history(tile, surface, after, before, manager, history)
	expect_equal(root.get_child_count(), 1, "Snapping a new instance does not run its add-child operation twice.")
	expect_equal(history.get_history_count(), 1, "A new instance and its automatic correction share one action.")
	history.undo()
	expect(tile.get_parent() == null, "One undo removes the newly placed tile.")
	history.redo()
	expect_equal(tile.get_parent(), root, "Redo restores the scene instance.")
	expect_equal(tile.transform, after, "Redo restores the snapped transform after adding the instance.")
	history.clear_history()
	history.free()
	root.free()
	surface.free()


func _test_missing_native_history() -> void:
	var surface := _make_surface()
	var tile := SCENE.instantiate() as TILE
	tile.position = Vector3(-2.2, 17.0, -4.2)
	var before := tile.transform
	var manager := HistoryManager.new()
	var after := SUBJECT.calculate_auto_transform(tile, surface)["transform"] as Transform3D
	SUBJECT.apply_auto_with_history(tile, surface, after, before, manager, null)
	expect_equal(
		tile.transform, after, "A first placement can create its own action without an existing native history."
	)
	manager.history.undo()
	expect_equal(tile.transform, before, "A new history still preserves the authored position for undo.")
	manager.history.clear_history()
	manager.history.free()
	tile.free()
	surface.free()
