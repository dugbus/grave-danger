extends "res://tests/test_case.gd"

const SUBJECT := preload("res://addons/floor_surface/floor_surface_ramp_resolver.gd")
const MAP_SCRIPT := preload("res://addons/floor_surface/floor_map.gd")
const PROFILE_SCRIPT := preload("res://addons/floor_surface/floor_elevation_profile.gd")


func run(_tree: SceneTree) -> void:
	expect_script_contract(SUBJECT, "res://addons/floor_surface/floor_surface_ramp_resolver.gd")
	_test_all_orientations_and_sampling()
	_test_inference_and_invalid_topology()
	_test_variable_length_unrestricted_rise()


func _test_all_orientations_and_sampling() -> void:
	var resolver := SUBJECT.new()
	var profile := PROFILE_SCRIPT.new()
	for low_edge in [
		MAP_SCRIPT.LowEdge.North,
		MAP_SCRIPT.LowEdge.East,
		MAP_SCRIPT.LowEdge.South,
		MAP_SCRIPT.LowEdge.West,
	]:
		var floor_map := _make_map()
		var low_cell := Vector2i.ONE + resolver.edge_offset(low_edge)
		var high_cell := Vector2i.ONE - resolver.edge_offset(low_edge)
		floor_map.set_cell_elevation(low_cell, 4)
		floor_map.set_cell_elevation(high_cell, 5)
		floor_map.set_cell_transition(Vector2i.ONE, MAP_SCRIPT.Transition.Ramp, low_edge, 4)
		var result := resolver.resolve_cell(floor_map, profile, Vector2i.ONE, 1.0)
		expect(result["valid"] as bool, "%s ramp resolves." % floor_map.get_low_edge_name(low_edge))
		expect(is_equal_approx(resolver.sample_height(result, Vector2(0.5, 0.5)), 1.125), "Ramp midpoint is interpolated.")
		var normal := result["normal"] as Vector3
		expect(normal.y > 0.9 and not normal.is_equal_approx(Vector3.UP), "Ramp exposes an upward slope normal.")
		var edge_offset := resolver.edge_offset(low_edge)
		var low_sample_xz := Vector2(
			0.5 + float(edge_offset.x) * 0.5,
			0.5 + float(edge_offset.y) * 0.5
		)
		var high_sample_xz := Vector2.ONE - low_sample_xz
		expect(
			is_equal_approx(resolver.sample_height(result, low_sample_xz), 1.0),
			"%s endpoint meets the low landing." % floor_map.get_low_edge_name(low_edge)
		)
		expect(
			is_equal_approx(resolver.sample_height(result, high_sample_xz), 1.25),
			"%s endpoint meets the high landing." % floor_map.get_low_edge_name(low_edge)
		)
		var expected_downhill := Vector3(float(edge_offset.x), 0.0, float(edge_offset.y))
		expect(
			normal.dot(expected_downhill) > 0.2,
			"%s normal tilts toward the authored low edge." % floor_map.get_low_edge_name(low_edge)
		)


func _test_inference_and_invalid_topology() -> void:
	var resolver := SUBJECT.new()
	var profile := PROFILE_SCRIPT.new()
	var floor_map := _make_map()
	floor_map.set_cell_elevation(Vector2i(0, 1), 2)
	floor_map.set_cell_elevation(Vector2i(2, 1), 3)
	expect_equal(
		resolver.infer_low_edge(floor_map, Vector2i.ONE, Vector2i(2, 1)),
		MAP_SCRIPT.LowEdge.West,
		"Dragging toward either landing infers the lower opposite edge."
	)
	expect_equal(
		resolver.infer_low_edge(floor_map, Vector2i.ONE, Vector2i(0, 1)),
		MAP_SCRIPT.LowEdge.West,
		"Dragging toward the low landing infers the same orientation."
	)
	floor_map.set_cell_transition(Vector2i.ONE, MAP_SCRIPT.Transition.Ramp, MAP_SCRIPT.LowEdge.West)
	expect_equal(resolver.validate_map(floor_map, profile, 1.0), [], "A ramp between different heights is valid.")
	floor_map.set_cell_elevation(Vector2i(2, 1), 14)
	expect(
		resolver.validate_map(floor_map, profile, 1.0).is_empty(),
		"A steep twelve-unit rise is not restricted by an arbitrary slope limit."
	)
	floor_map.set_floor_present(Vector2i(0, 1), false)
	expect(
		resolver.validate_map(floor_map, profile, 1.0)[0].contains("landing"),
		"A ramp beside a hole is rejected instead of guessing an endpoint."
	)


func _test_variable_length_unrestricted_rise() -> void:
	var resolver := SUBJECT.new()
	var profile := PROFILE_SCRIPT.new()
	for run_length in range(1, 6):
		var floor_map := MAP_SCRIPT.new()
		floor_map.dimensions = Vector2i(run_length + 2, 1)
		floor_map.default_present = true
		floor_map.set_cell_elevation(Vector2i(run_length + 1, 0), 12)
		for x_coordinate in range(1, run_length + 1):
			floor_map.set_cell_transition(
				Vector2i(x_coordinate, 0),
				MAP_SCRIPT.Transition.Ramp,
				MAP_SCRIPT.LowEdge.West
			)
		var first_result := resolver.resolve_cell(floor_map, profile, Vector2i(1, 0), 1.0)
		var last_result := resolver.resolve_cell(
			floor_map, profile, Vector2i(run_length, 0), 1.0
		)
		expect(first_result["valid"] as bool, "%d-tile ramp accepts a three-metre rise." % run_length)
		expect_equal(first_result["run_length"], run_length, "Every ramp cell resolves the shared run length.")
		expect(
			is_equal_approx(resolver.sample_height(first_result, Vector2(0.0, 0.5)), 0.0),
			"The run begins exactly at its zero-metre landing."
		)
		expect(
			is_equal_approx(resolver.sample_height(last_result, Vector2(1.0, 0.5)), 3.0),
			"The run ends exactly at its three-metre landing."
		)
		var midpoint_cell := Vector2i(ceili(float(run_length) * 0.5), 0)
		var midpoint_result := resolver.resolve_cell(floor_map, profile, midpoint_cell, 1.0)
		var run_midpoint_x := 0.5 if run_length % 2 == 1 else 1.0
		expect(
			is_equal_approx(resolver.sample_height(midpoint_result, Vector2(run_midpoint_x, 0.5)), 1.5),
			"The complete run interpolates its physical midpoint."
		)


func _make_map() -> MAP_SCRIPT:
	var floor_map := MAP_SCRIPT.new()
	floor_map.dimensions = Vector2i(3, 3)
	floor_map.default_present = true
	return floor_map
