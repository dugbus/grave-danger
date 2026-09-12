extends "res://tests/test_case.gd"

const SUBJECT := preload("res://addons/floor_surface/editor/floor_surface_validation.gd")
const SURFACE_SCRIPT := preload("res://addons/floor_surface/floor_surface.gd")
const MAP_SCRIPT := preload("res://addons/floor_surface/floor_map.gd")
const PROFILE_SCRIPT := preload("res://addons/floor_surface/floor_elevation_profile.gd")
const STYLE_SCRIPT := preload("res://addons/floor_surface/floor_style.gd")


func run(_tree: SceneTree) -> void:
	expect_script_contract(
		SUBJECT,
		"res://addons/floor_surface/editor/floor_surface_validation.gd"
	)
	_test_invalid_ramp_repair_round_trip()


func _test_invalid_ramp_repair_round_trip() -> void:
	var surface := SURFACE_SCRIPT.new()
	var floor_map := MAP_SCRIPT.new()
	floor_map.dimensions = Vector2i(2, 1)
	floor_map.default_present = true
	floor_map.set_cell_transition(
		Vector2i.ZERO,
		MAP_SCRIPT.Transition.Ramp,
		MAP_SCRIPT.LowEdge.West,
		0
	)
	surface.floor_map = floor_map
	surface.elevation_profile = PROFILE_SCRIPT.new()
	var style := STYLE_SCRIPT.new()
	style.top_material = StandardMaterial3D.new()
	var styles: Array[STYLE_SCRIPT] = [style]
	surface.styles = styles
	var diagnostics := SUBJECT.collect(null, surface)
	expect(not diagnostics.is_empty(), "Validation exposes an invalid unsupported ramp.")
	var repair := SUBJECT.plan_safe_ramp_repair(surface)
	var repaired_cells := repair["repaired_cells"] as Array[Vector2i]
	expect_equal(
		repaired_cells,
		[Vector2i.ZERO] as Array[Vector2i],
		"Repair identifies the invalid ramp cell."
	)
	floor_map.apply_transition_snapshot(repair["after"] as Dictionary)
	expect_equal(
		floor_map.get_cell_transition(Vector2i.ZERO),
		MAP_SCRIPT.Transition.Flat,
		"Safe repair makes only the invalid ramp flat."
	)
	floor_map.apply_transition_snapshot(repair["before"] as Dictionary)
	expect_equal(
		floor_map.get_cell_transition(Vector2i.ZERO),
		MAP_SCRIPT.Transition.Ramp,
		"Undo restores complete ramp intent."
	)
	surface.free()
