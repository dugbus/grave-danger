extends "res://tests/test_case.gd"

const SUBJECT := preload("res://addons/floor_surface/floor_map.gd")
const ROUND_TRIP_PATH := "res://.godot/floor_surface_map_round_trip_test.tres"


func run(_tree: SceneTree) -> void:
	expect_script_contract(SUBJECT, "res://addons/floor_surface/floor_map.gd")
	_test_bounds_occupancy_and_negative_cells()
	_test_presence_snapshots_and_unique_copy()
	_test_bounds_expand_without_implicit_floor()
	_test_elevation_snapshots()
	_test_style_snapshots()
	_test_transition_snapshots()
	_test_sparse_authored_values_and_palette_validation()
	_test_text_resource_round_trip()


func _test_bounds_occupancy_and_negative_cells() -> void:
	var floor_map := SUBJECT.new()
	floor_map.minimum_cell = Vector2i(-2, -1)
	floor_map.dimensions = Vector2i(4, 3)
	floor_map.default_present = true
	floor_map.presence_exceptions = [Vector2i(-1, 0)]
	expect(floor_map.has_floor(Vector2i(-2, -1)), "Negative in-bounds cells can own floor.")
	expect(not floor_map.has_floor(Vector2i(-1, 0)), "An occupancy exception creates a hole.")
	expect(not floor_map.has_floor(Vector2i(2, 0)), "The exclusive maximum bound is absent.")
	expect_equal(floor_map.get_present_cells().size(), 11, "The finite map lists every top except its hole.")
	expect(floor_map.set_floor_present(Vector2i(-1, 0), true), "A hole can be restored.")
	expect(not floor_map.set_floor_present(Vector2i(8, 8), true), "Outside occupancy cannot be authored.")


func _test_sparse_authored_values_and_palette_validation() -> void:
	var floor_map := SUBJECT.new()
	floor_map.minimum_cell = Vector2i(-1, -1)
	floor_map.dimensions = Vector2i(2, 2)
	floor_map.default_present = true
	expect(floor_map.set_cell_elevation(Vector2i(-1, -1), -4), "Negative absolute elevation is stored.")
	expect_equal(floor_map.get_cell_elevation(Vector2i(-1, -1)), -4, "Elevation remains an integer.")
	floor_map.set_floor_present(Vector2i(0, 0), false)
	floor_map.set_cell_style(Vector2i(0, 0), 2)
	expect_equal(floor_map.get_cell_style(Vector2i(0, 0)), 2, "Absent cells retain style intent.")
	expect_equal(
		floor_map.get_cell_elevation(Vector2i(0, 0)),
		SUBJECT.INVALID_ELEVATION,
		"A hole never exposes an implicit world height."
	)
	expect_equal(floor_map.validate_palette_size(3), [], "Valid absent-cell styles pass validation.")
	expect_equal(floor_map.validate_palette_size(2).size(), 1, "Out-of-range style intent is reported.")


func _test_elevation_snapshots() -> void:
	var floor_map := SUBJECT.new()
	floor_map.dimensions = Vector2i(3, 1)
	floor_map.default_present = true
	floor_map.set_cell_elevation(Vector2i(2, 0), 24)
	var elevated := floor_map.get_elevation_snapshot()
	floor_map.set_cell_elevation(Vector2i(1, 0), -2)
	expect(floor_map.apply_elevation_snapshot(elevated), "A saved elevation state can be restored.")
	expect_equal(floor_map.get_cell_elevation(Vector2i(2, 0)), 24, "Tall absolute elevation survives undo.")
	expect_equal(floor_map.get_cell_elevation(Vector2i(1, 0)), 0, "Restoring removes later overrides.")
	elevated[Vector2i(9, 9)] = 3
	floor_map.apply_elevation_snapshot(elevated)
	expect(
		not floor_map.elevation_overrides.has(Vector2i(9, 9)),
		"Elevation snapshots cannot add data outside tile storage."
	)
	floor_map.set_floor_present(Vector2i(2, 0), false)
	floor_map.compact_storage()
	expect_equal(floor_map.dimensions, Vector2i(2, 1), "Removing an edge tile trims its storage.")
	expect(
		not floor_map.elevation_overrides.has(Vector2i(2, 0)),
		"Trimming a removed edge tile also discards its unreachable authored data."
	)


func _test_style_snapshots() -> void:
	var floor_map := SUBJECT.new()
	floor_map.dimensions = Vector2i(3, 1)
	floor_map.default_present = true
	floor_map.set_floor_present(Vector2i(1, 0), false)
	floor_map.set_cell_style(Vector2i.ZERO, 1)
	floor_map.set_cell_style(Vector2i(1, 0), 2)
	var styled := floor_map.get_style_snapshot()
	floor_map.set_cell_style(Vector2i(2, 0), 3)
	expect(floor_map.apply_style_snapshot(styled), "A saved style state can be restored.")
	expect_equal(floor_map.get_cell_style(Vector2i.ZERO), 1, "Present-cell style survives undo.")
	expect_equal(floor_map.get_cell_style(Vector2i(1, 0)), 2, "Hole style intent survives undo.")
	expect_equal(floor_map.get_cell_style(Vector2i(2, 0)), 0, "Restoring removes later style overrides.")
	styled[Vector2i(9, 9)] = 1
	floor_map.apply_style_snapshot(styled)
	expect(
		not floor_map.style_overrides.has(Vector2i(9, 9)),
		"Style snapshots cannot add data outside tile storage."
	)


func _test_transition_snapshots() -> void:
	var floor_map := SUBJECT.new()
	floor_map.dimensions = Vector2i(3, 1)
	floor_map.default_present = true
	var before := floor_map.get_transition_snapshot()
	expect(
		floor_map.set_cell_transition(
			Vector2i(1, 0),
			SUBJECT.Transition.Ramp,
			SUBJECT.LowEdge.West,
			2
		),
		"A ramp stores its named transition, low edge and low anchor elevation together."
	)
	expect_equal(
		floor_map.get_cell_transition(Vector2i(1, 0)),
		SUBJECT.Transition.Ramp,
		"The authored ramp transition is queryable."
	)
	expect_equal(floor_map.get_cell_low_edge(Vector2i(1, 0)), SUBJECT.LowEdge.West, "Low edge is named.")
	expect_equal(floor_map.get_cell_elevation(Vector2i(1, 0)), 2, "Ramp anchor uses the inferred low band.")
	expect(floor_map.apply_transition_snapshot(before), "Undo restores all ramp fields together.")
	expect_equal(floor_map.get_cell_transition(Vector2i(1, 0)), SUBJECT.Transition.Flat, "Undo removes the ramp.")
	expect_equal(floor_map.get_cell_elevation(Vector2i(1, 0)), 0, "Undo restores the prior elevation.")


func _test_presence_snapshots_and_unique_copy() -> void:
	var floor_map := SUBJECT.new()
	floor_map.minimum_cell = Vector2i(-1, -1)
	floor_map.dimensions = Vector2i(3, 3)
	floor_map.default_present = false
	expect(
		floor_map.apply_presence_snapshot([
			Vector2i(1, 1),
			Vector2i(-1, -1),
			Vector2i(1, 1),
			Vector2i(9, 9),
		]),
		"An occupancy snapshot can be applied."
	)
	expect_equal(
		floor_map.get_presence_snapshot(),
		[Vector2i(-1, -1), Vector2i(1, 1)],
		"Snapshots are bounded, deduplicated and stored in stable order."
	)
	var snapshot := floor_map.get_presence_snapshot()
	snapshot.clear()
	expect(floor_map.has_floor(Vector2i(-1, -1)), "Returned snapshots do not alias map storage.")
	var unique_map := floor_map.create_unique_copy() as SUBJECT
	expect(unique_map != floor_map, "Make Unique returns a different resource instance.")
	expect(unique_map.resource_local_to_scene, "A unique copy is marked scene-local.")
	unique_map.set_floor_present(Vector2i.ZERO, true)
	expect(
		not floor_map.has_floor(Vector2i.ZERO),
		"Editing the unique copy cannot change its source map."
	)


func _test_bounds_expand_without_implicit_floor() -> void:
	var floor_map := SUBJECT.new()
	floor_map.minimum_cell = Vector2i.ZERO
	floor_map.dimensions = Vector2i(2, 2)
	floor_map.default_present = true
	var before := floor_map.get_shape_snapshot()
	expect(
		floor_map.expand_bounds_to_include([Vector2i(-2, 0), Vector2i(3, 2)]),
		"Painting can grow storage beyond every original edge."
	)
	expect_equal(floor_map.minimum_cell, Vector2i(-2, 0), "Expansion moves the minimum bound.")
	expect_equal(floor_map.dimensions, Vector2i(6, 3), "Expansion contains the complete request.")
	expect(floor_map.has_floor(Vector2i.ZERO), "Existing default-present floor is preserved.")
	expect(
		not floor_map.has_floor(Vector2i(-1, 0)),
		"Newly enclosed cells do not appear until the painter explicitly paints them."
	)
	expect(floor_map.apply_shape_snapshot(before), "Undo can restore bounds and occupancy together.")
	expect_equal(floor_map.minimum_cell, Vector2i.ZERO, "Undo restores the original minimum bound.")
	expect_equal(floor_map.dimensions, Vector2i(2, 2), "Undo restores the original dimensions.")
	expect(floor_map.default_present, "Undo restores the original occupancy representation.")

	floor_map.minimum_cell = Vector2i(-14, -60)
	floor_map.dimensions = Vector2i(25, 67)
	floor_map.default_present = true
	floor_map.presence_exceptions.clear()
	for z_coordinate in range(-60, 7):
		for x_coordinate in range(-14, 11):
			var cell := Vector2i(x_coordinate, z_coordinate)
			if not _is_in_compact_fixture(cell):
				floor_map.presence_exceptions.append(cell)
	expect(floor_map.compact_storage(), "Unused exterior storage can be compacted.")
	expect_equal(floor_map.minimum_cell, Vector2i(-6, -5), "Compaction finds the occupied minimum.")
	expect_equal(floor_map.dimensions, Vector2i(12, 10), "Compaction trims empty exterior rows and columns.")
	expect(floor_map.default_present, "Compaction chooses the smaller dense representation.")
	expect_equal(floor_map.presence_exceptions.size(), 4, "Only the central hole needs serialization.")
	expect_equal(floor_map.get_present_cells().size(), 116, "Compaction preserves the exact floor shape.")


func _test_text_resource_round_trip() -> void:
	var floor_map := SUBJECT.new()
	floor_map.minimum_cell = Vector2i(-3, 2)
	floor_map.dimensions = Vector2i(5, 4)
	floor_map.default_present = true
	floor_map.set_floor_present(Vector2i(-1, 3), false)
	floor_map.set_cell_elevation(Vector2i(-2, 2), 7)
	floor_map.set_cell_style(Vector2i(-1, 3), 1)
	var save_error := ResourceSaver.save(floor_map, ROUND_TRIP_PATH)
	expect_equal(save_error, OK, "FloorMap saves as a text resource.")
	var restored := ResourceLoader.load(
		ROUND_TRIP_PATH,
		"",
		ResourceLoader.CACHE_MODE_IGNORE
	)
	expect(restored != null, "A saved FloorMap reloads.")
	if restored != null:
		expect_equal(restored.minimum_cell, floor_map.minimum_cell, "Minimum cell survives reload.")
		expect_equal(restored.dimensions, floor_map.dimensions, "Dimensions survive reload.")
		expect(not restored.has_floor(Vector2i(-1, 3)), "A saved hole survives reload.")
		expect_equal(restored.get_cell_elevation(Vector2i(-2, 2)), 7, "Elevation survives reload.")
		expect_equal(restored.get_cell_style(Vector2i(-1, 3)), 1, "Absent style survives reload.")
		var unique_map := restored.create_unique_copy() as SUBJECT
		expect(
			unique_map.resource_path.is_empty(),
			"A unique copy no longer points at the shared resource file."
		)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(ROUND_TRIP_PATH))


func _is_in_compact_fixture(cell: Vector2i) -> bool:
	return cell.x >= -6 and cell.x <= 5 \
		and cell.y >= -5 and cell.y <= 4 \
		and cell not in [Vector2i(-1, -1), Vector2i.ZERO, Vector2i(-1, 0), Vector2i(0, -1)]
