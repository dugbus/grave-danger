extends "res://tests/test_case.gd"

const SUBJECT := preload("res://addons/floor_surface/editor/floor_surface_style_painter.gd")
const FLOOR_MAP_SCRIPT := preload("res://addons/floor_surface/floor_map.gd")


func run(_tree: SceneTree) -> void:
	expect_script_contract(
		SUBJECT,
		"res://addons/floor_surface/editor/floor_surface_style_painter.gd"
	)
	_test_present_and_hole_painting()
	_test_cancel_and_undo_round_trip()


func _test_present_and_hole_painting() -> void:
	var floor_map := FLOOR_MAP_SCRIPT.new()
	floor_map.dimensions = Vector2i(3, 1)
	floor_map.default_present = true
	floor_map.set_floor_present(Vector2i(1, 0), false)
	var painter := SUBJECT.new()
	expect(painter.begin(floor_map, 1), "A valid palette index begins a style gesture.")
	expect_equal(
		painter.apply_cells([Vector2i.ZERO, Vector2i(1, 0), Vector2i(8, 0)]),
		2,
		"Style painting affects present tiles and bounded pit intent, but not outside storage."
	)
	painter.finish()
	expect_equal(floor_map.get_cell_style(Vector2i.ZERO), 1, "A walkable top receives the style.")
	expect_equal(floor_map.get_cell_style(Vector2i(1, 0)), 1, "A hole receives pit-bottom style intent.")


func _test_cancel_and_undo_round_trip() -> void:
	var floor_map := FLOOR_MAP_SCRIPT.new()
	floor_map.dimensions = Vector2i(2, 1)
	floor_map.default_present = true
	var painter := SUBJECT.new()
	painter.begin(floor_map, 1)
	painter.apply_cells([Vector2i.ZERO, Vector2i(1, 0)])
	expect(painter.cancel(), "Escape can cancel a complete style gesture.")
	expect_equal(floor_map.get_style_snapshot(), {}, "Cancellation restores every style override.")
	painter.begin(floor_map, 1)
	painter.apply_cells([Vector2i.ZERO, Vector2i(1, 0)])
	var edit := painter.finish()
	var before := edit["before"] as Dictionary[Vector2i, int]
	var after := edit["after"] as Dictionary[Vector2i, int]
	var undo_redo := UndoRedo.new()
	undo_redo.create_action("Paint Floor Style")
	undo_redo.add_do_method(floor_map.apply_style_snapshot.bind(after))
	undo_redo.add_undo_method(floor_map.apply_style_snapshot.bind(before))
	undo_redo.commit_action(false)
	undo_redo.undo()
	expect_equal(floor_map.get_cell_style(Vector2i.ZERO), 0, "Undo restores the earlier style.")
	undo_redo.redo()
	expect_equal(floor_map.get_cell_style(Vector2i.ZERO), 1, "Redo restores the painted style.")
	undo_redo.clear_history(false)
	undo_redo.free()
