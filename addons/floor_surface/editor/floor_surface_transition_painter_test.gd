extends "res://tests/test_case.gd"

const SUBJECT := preload("res://addons/floor_surface/editor/floor_surface_transition_painter.gd")
const MAP_SCRIPT := preload("res://addons/floor_surface/floor_map.gd")
const PROFILE_SCRIPT := preload("res://addons/floor_surface/floor_elevation_profile.gd")


func run(_tree: SceneTree) -> void:
	expect_script_contract(
		SUBJECT,
		"res://addons/floor_surface/editor/floor_surface_transition_painter.gd"
	)
	_test_single_ramp_between_flat_landings()
	_test_unrestricted_variable_length_runs()
	_test_erase_rotate_cancel_and_invalid_run()


func _test_single_ramp_between_flat_landings() -> void:
	var floor_map := _make_run_map(1, 12)
	var painter := SUBJECT.new()
	var before := floor_map.get_transition_snapshot()
	expect(
		painter.begin(floor_map, PROFILE_SCRIPT.new(), 1.0, SUBJECT.Operation.PaintRamp, Vector2i(2, 0)),
		"A ramp drag begins on the three-metre flat landing."
	)
	expect_equal(
		painter.get_preview_cells(Vector2i.ZERO),
		[Vector2i(2, 0), Vector2i(1, 0), Vector2i.ZERO] as Array[Vector2i],
		"The preview includes both flat landings and the ramp tile between them."
	)
	expect_equal(
		painter.get_preview_ramp_cells(Vector2i.ZERO),
		[Vector2i(1, 0)] as Array[Vector2i],
		"Only the tile between the endpoints is marked as a ramp."
	)
	expect_equal(
		painter.get_preview_low_edge(Vector2i.ZERO),
		MAP_SCRIPT.LowEdge.West,
		"Endpoint heights infer the west-facing low edge."
	)
	var edit := painter.finish(Vector2i.ZERO)
	expect_equal(edit["error"], "", "A three-metre rise over one tile has no slope restriction.")
	expect_equal(edit["touched_count"], 1, "One ramp tile is one undoable change.")
	expect_equal(
		floor_map.get_cell_transition(Vector2i(1, 0)),
		MAP_SCRIPT.Transition.Ramp,
		"The tile between the two landings becomes the ramp."
	)
	expect_equal(
		floor_map.get_cell_elevation(Vector2i(1, 0)),
		0,
		"Painting a ramp preserves the tile's original flat elevation for Make Flat."
	)
	var preview_descriptions := painter.get_preview_surface_descriptions(Vector2i.ZERO)
	expect_equal(
		preview_descriptions,
		{},
		"Completing the gesture clears its transient surface preview."
	)
	expect(floor_map.apply_transition_snapshot(before), "The complete ramp gesture supports one-step undo.")
	painter.begin(floor_map, PROFILE_SCRIPT.new(), 1.0, SUBJECT.Operation.PaintRamp, Vector2i.ZERO)
	var reverse_edit := painter.finish(Vector2i(2, 0))
	expect_equal(reverse_edit["error"], "", "Dragging from low to high infers the same unrestricted run.")
	expect_equal(
		floor_map.get_cell_low_edge(Vector2i(1, 0)),
		MAP_SCRIPT.LowEdge.West,
		"Reversing drag direction does not reverse the physical slope."
	)
	var extension_painter := SUBJECT.new()
	expect(
		extension_painter.begin(
			floor_map,
			PROFILE_SCRIPT.new(),
			1.0,
			SUBJECT.Operation.PaintRamp,
			Vector2i(1, 0)
		),
		"Painting can begin on an existing valid slope."
	)
	expect_equal(
		extension_painter.get_start_cell(),
		Vector2i(2, 0),
		"Clicking an existing slope snaps the drag to its flat high landing."
	)
	extension_painter.cancel()


func _test_unrestricted_variable_length_runs() -> void:
	for run_length in range(1, 6):
		var floor_map := _make_run_map(run_length, 12)
		var painter := SUBJECT.new()
		var high_landing := Vector2i(run_length + 1, 0)
		painter.begin(
			floor_map,
			PROFILE_SCRIPT.new(),
			1.0,
			SUBJECT.Operation.PaintRamp,
			high_landing
		)
		expect_equal(
			painter.get_preview_cells(Vector2i.ZERO).size(),
			run_length + 2,
			"The drag preview spans the complete run and both flat landings."
		)
		var preview_descriptions := painter.get_preview_surface_descriptions(Vector2i.ZERO)
		expect_equal(
			preview_descriptions.size(),
			run_length + 2,
			"The preview follows every intended slope and landing top."
		)
		var first_ramp_description := preview_descriptions[Vector2i(1, 0)] as Dictionary
		var first_heights := first_ramp_description["corner_heights"] as Array[float]
		expect(
			is_equal_approx(first_heights[0], 0.0),
			"The preview begins on the low landing instead of floating at the high endpoint."
		)
		var edit := painter.finish(Vector2i.ZERO)
		expect_equal(edit["error"], "", "%d ramp tiles accept an unrestricted three-metre rise." % run_length)
		expect_equal(edit["touched_count"], run_length, "Every generated ramp tile is counted once.")
		for x_coordinate in range(1, run_length + 1):
			expect_equal(
				floor_map.get_cell_low_edge(Vector2i(x_coordinate, 0)),
				MAP_SCRIPT.LowEdge.West,
				"Every tile in the run shares the inferred low edge."
			)


func _test_erase_rotate_cancel_and_invalid_run() -> void:
	var floor_map := _make_run_map(3, 12)
	var painter := SUBJECT.new()
	painter.begin(floor_map, PROFILE_SCRIPT.new(), 1.0, SUBJECT.Operation.PaintRamp, Vector2i(4, 0))
	painter.finish(Vector2i.ZERO)
	var ramp_snapshot := floor_map.get_transition_snapshot()
	painter.begin(floor_map, PROFILE_SCRIPT.new(), 1.0, SUBJECT.Operation.RotateRamp, Vector2i(1, 0))
	var rotate_edit := painter.finish(Vector2i(3, 0))
	expect_equal(rotate_edit["touched_count"], 3, "A correction can rotate the complete selected run.")
	expect(floor_map.apply_transition_snapshot(rotate_edit["before"]), "Rotate has a complete undo snapshot.")
	expect_equal(floor_map.get_transition_snapshot(), ramp_snapshot, "Undo restores the run orientation.")
	painter.begin(floor_map, PROFILE_SCRIPT.new(), 1.0, SUBJECT.Operation.EraseRamp, Vector2i(1, 0))
	var erase_edit := painter.finish(Vector2i(3, 0))
	expect_equal(erase_edit["touched_count"], 3, "Make Flat removes a complete selected ramp run.")
	for x_coordinate in range(1, 4):
		expect_equal(
			floor_map.get_cell_transition(Vector2i(x_coordinate, 0)),
			MAP_SCRIPT.Transition.Flat,
			"Make Flat restores each tile's original authored elevation."
		)
	expect(floor_map.apply_transition_snapshot(ramp_snapshot), "The authored ramp can be restored for cancellation.")
	painter.begin(floor_map, PROFILE_SCRIPT.new(), 1.0, SUBJECT.Operation.EraseRamp, Vector2i(1, 0))
	expect(painter.cancel(), "Escape cancels a pending transition gesture.")
	expect_equal(floor_map.get_transition_snapshot(), ramp_snapshot, "Cancellation leaves the ramp run unchanged.")
	floor_map.set_floor_present(Vector2i(2, 0), false)
	var before_invalid := floor_map.get_transition_snapshot()
	painter.begin(floor_map, PROFILE_SCRIPT.new(), 1.0, SUBJECT.Operation.PaintRamp, Vector2i(4, 0))
	var invalid_edit := painter.finish(Vector2i.ZERO)
	expect((invalid_edit["error"] as String).contains("missing floor"), "A missing ramp tile is rejected visibly.")
	expect_equal(
		floor_map.get_transition_snapshot(),
		before_invalid,
		"A rejected run leaves every authored tile unchanged."
	)


func _make_run_map(run_length: int, high_elevation: int) -> MAP_SCRIPT:
	var floor_map := MAP_SCRIPT.new()
	floor_map.dimensions = Vector2i(run_length + 2, 1)
	floor_map.default_present = true
	floor_map.set_cell_elevation(Vector2i(run_length + 1, 0), high_elevation)
	return floor_map
