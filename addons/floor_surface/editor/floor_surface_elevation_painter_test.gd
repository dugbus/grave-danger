extends "res://tests/test_case.gd"

const SUBJECT := preload("res://addons/floor_surface/editor/floor_surface_elevation_painter.gd")
const FLOOR_MAP_SCRIPT := preload("res://addons/floor_surface/floor_map.gd")


func run(_tree: SceneTree) -> void:
	expect_script_contract(
		SUBJECT,
		"res://addons/floor_surface/editor/floor_surface_elevation_painter.gd"
	)
	_test_absolute_raise_lower_and_absent_cells()
	_test_cancel_and_undo_round_trip()


func _test_absolute_raise_lower_and_absent_cells() -> void:
	var floor_map := FLOOR_MAP_SCRIPT.new()
	floor_map.dimensions = Vector2i(4, 1)
	floor_map.default_present = true
	floor_map.set_floor_present(Vector2i(3, 0), false)
	var painter := SUBJECT.new()
	painter.begin(floor_map, SUBJECT.Operation.SetAbsolute, 24)
	expect_equal(
		painter.apply_cells([Vector2i.ZERO, Vector2i(1, 0), Vector2i(3, 0)]),
		2,
		"Absolute painting changes present cells and ignores holes."
	)
	painter.finish()
	expect_equal(floor_map.get_cell_elevation(Vector2i.ZERO), 24, "A platform can be set directly to 24 units.")
	painter.begin(floor_map, SUBJECT.Operation.RaiseOne, 0)
	painter.apply_cells([Vector2i.ZERO])
	painter.finish()
	expect_equal(floor_map.get_cell_elevation(Vector2i.ZERO), 25, "Raise adds exactly one integer unit.")
	painter.begin(floor_map, SUBJECT.Operation.LowerOne, 0)
	painter.apply_cells([Vector2i.ZERO])
	painter.finish()
	expect_equal(floor_map.get_cell_elevation(Vector2i.ZERO), 24, "Lower removes exactly one integer unit.")


func _test_cancel_and_undo_round_trip() -> void:
	var floor_map := FLOOR_MAP_SCRIPT.new()
	floor_map.dimensions = Vector2i(3, 1)
	floor_map.default_present = true
	var painter := SUBJECT.new()
	painter.begin(floor_map, SUBJECT.Operation.SetAbsolute, -4)
	painter.apply_cells([Vector2i.ZERO, Vector2i(1, 0), Vector2i.ZERO])
	expect(painter.cancel(), "Escape can cancel a complete elevation gesture.")
	expect_equal(floor_map.get_elevation_snapshot(), {}, "Cancellation restores every elevation override.")
	painter.begin(floor_map, SUBJECT.Operation.SetAbsolute, 24)
	painter.apply_cells([Vector2i.ZERO, Vector2i(1, 0)])
	var edit := painter.finish()
	var before := edit["before"] as Dictionary[Vector2i, int]
	var after := edit["after"] as Dictionary[Vector2i, int]
	var undo_redo := UndoRedo.new()
	undo_redo.create_action("Set Floor Elevation")
	undo_redo.add_do_method(floor_map.apply_elevation_snapshot.bind(after))
	undo_redo.add_undo_method(floor_map.apply_elevation_snapshot.bind(before))
	undo_redo.commit_action(false)
	undo_redo.undo()
	expect_equal(floor_map.get_cell_elevation(Vector2i.ZERO), 0, "Undo restores the earlier absolute height.")
	undo_redo.redo()
	expect_equal(floor_map.get_cell_elevation(Vector2i.ZERO), 24, "Redo restores the tall platform.")
	undo_redo.clear_history(false)
	undo_redo.free()
