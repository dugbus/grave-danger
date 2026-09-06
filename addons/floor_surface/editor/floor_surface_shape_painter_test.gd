extends "res://tests/test_case.gd"

const SUBJECT := preload("res://addons/floor_surface/editor/floor_surface_shape_painter.gd")
const FLOOR_MAP_SCRIPT := preload("res://addons/floor_surface/floor_map.gd")


func run(_tree: SceneTree) -> void:
	expect_script_contract(
		SUBJECT,
		"res://addons/floor_surface/editor/floor_surface_shape_painter.gd"
	)
	_test_bounded_footprints()
	_test_working_plane_fallback()
	_test_stroke_aggregation_cancel_and_round_trip()
	_test_erase_trims_bounds_automatically()


func _test_bounded_footprints() -> void:
	var floor_map := FLOOR_MAP_SCRIPT.new()
	floor_map.minimum_cell = Vector2i.ZERO
	floor_map.dimensions = Vector2i(4, 3)
	expect_equal(
		SUBJECT.brush_footprint(Vector2i(1, 1), 3, floor_map).size(),
		9,
		"A size-three brush produces a square nine-cell footprint."
	)
	expect_equal(
		SUBJECT.brush_footprint(Vector2i.ZERO, 3, floor_map).size(),
		4,
		"A brush footprint clips cleanly at map bounds."
	)
	expect_equal(
		SUBJECT.brush_footprint(Vector2i(-1, -1), 3, floor_map, false).size(),
		9,
		"A paint preview can extend beyond current storage bounds."
	)
	expect_equal(
		SUBJECT.rectangle_footprint(Vector2i(3, 2), Vector2i(1, 1), floor_map),
		[
			Vector2i(1, 1), Vector2i(2, 1), Vector2i(3, 1),
			Vector2i(1, 2), Vector2i(2, 2), Vector2i(3, 2),
		],
		"Rectangle fill is inclusive, ordered and independent of drag direction."
	)
	expect_equal(
		SUBJECT.stroke_centres(Vector2i.ZERO, Vector2i(4, 2)),
		[
			Vector2i(0, 0), Vector2i(1, 1), Vector2i(2, 1),
			Vector2i(3, 2), Vector2i(4, 2),
		],
		"Fast diagonal brush motion interpolates a continuous grid stroke."
	)


func _test_stroke_aggregation_cancel_and_round_trip() -> void:
	var floor_map := FLOOR_MAP_SCRIPT.new()
	floor_map.dimensions = Vector2i(5, 5)
	var painter := SUBJECT.new()
	expect(
		painter.begin(floor_map, SUBJECT.PaintMode.Paint),
		"A stroke begins against a valid map."
	)
	painter.apply_cells([Vector2i.ZERO, Vector2i(1, 0), Vector2i.ZERO])
	painter.apply_cells([Vector2i(1, 0), Vector2i(2, 0)])
	var edit := painter.finish()
	expect_equal(edit["touched_count"], 3, "A self-crossing stroke counts each cell once.")
	expect_equal(floor_map.get_present_cells().size(), 3, "The complete stroke paints three cells.")
	expect_equal(floor_map.dimensions, Vector2i(3, 1), "A completed stroke compacts unused storage.")
	var before := edit["before"] as Dictionary
	var after := edit["after"] as Dictionary
	var undo_redo := UndoRedo.new()
	undo_redo.create_action("Paint Floor Stroke")
	undo_redo.add_do_method(floor_map.apply_shape_snapshot.bind(after))
	undo_redo.add_undo_method(floor_map.apply_shape_snapshot.bind(before))
	undo_redo.commit_action(false)
	undo_redo.undo()
	expect_equal(floor_map.get_present_cells().size(), 0, "Undo restores the before snapshot.")
	undo_redo.redo()
	expect_equal(floor_map.get_present_cells().size(), 3, "Redo restores the after snapshot.")
	undo_redo.clear_history(false)
	undo_redo.free()
	painter.begin(floor_map, SUBJECT.PaintMode.Erase)
	painter.apply_cells([Vector2i.ZERO, Vector2i(1, 0)])
	expect(painter.cancel(), "An active edit can be cancelled.")
	expect_equal(
		floor_map.get_shape_snapshot(),
		after,
		"Cancellation restores the complete map state from before the gesture."
	)
	var expansion_before := floor_map.get_shape_snapshot()
	painter.begin(floor_map, SUBJECT.PaintMode.Paint)
	painter.apply_cells([Vector2i(-3, -2)])
	expect(floor_map.has_floor(Vector2i(-3, -2)), "Painting outside storage expands and paints it.")
	painter.cancel()
	expect_equal(
		floor_map.get_shape_snapshot(),
		expansion_before,
		"Cancelling an outside stroke also restores the original bounds."
	)


func _test_working_plane_fallback() -> void:
	var hit: Variant = SUBJECT.working_plane_intersection(
		Vector3(2.0, 8.0, -3.0),
		Vector3(0.0, -1.0, 0.0),
		1.5
	)
	expect_equal(hit, Vector3(2.0, 1.5, -3.0), "Empty space can be picked on the working plane.")
	expect_equal(
		SUBJECT.working_plane_intersection(Vector3.ZERO, Vector3.RIGHT, 0.0),
		null,
		"A ray parallel to the working plane has no ambiguous hit."
	)


func _test_erase_trims_bounds_automatically() -> void:
	var floor_map := FLOOR_MAP_SCRIPT.new()
	floor_map.dimensions = Vector2i(3, 1)
	floor_map.default_present = true
	var painter := SUBJECT.new()
	painter.begin(floor_map, SUBJECT.PaintMode.Erase)
	painter.apply_cells([Vector2i(2, 0)])
	var edit := painter.finish()
	expect_equal(
		floor_map.dimensions,
		Vector2i(2, 1),
		"Finishing an erase automatically trims an empty exterior edge."
	)
	expect_equal(floor_map.get_present_cells().size(), 2, "Trimming preserves remaining tiles.")
	floor_map.apply_shape_snapshot(edit["before"] as Dictionary)
	expect_equal(floor_map.dimensions, Vector2i(3, 1), "Undo data includes the previous extent.")
	floor_map.apply_shape_snapshot(edit["after"] as Dictionary)
	expect_equal(floor_map.dimensions, Vector2i(2, 1), "Redo data includes the compact extent.")
