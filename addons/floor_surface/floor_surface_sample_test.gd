extends "res://tests/test_case.gd"

const SUBJECT := preload("res://addons/floor_surface/floor_surface_sample.gd")
const MAP_SCRIPT := preload("res://addons/floor_surface/floor_map.gd")


func run(_tree: SceneTree) -> void:
	expect_script_contract(SUBJECT, "res://addons/floor_surface/floor_surface_sample.gd")
	var sample := SUBJECT.new()
	sample.set_flat(Vector2i(-2, 4), 1.5, 3, MAP_SCRIPT.Transition.Flat)
	expect(sample.valid, "A flat result is explicitly valid.")
	expect_equal(sample.cell, Vector2i(-2, 4), "A result identifies its authoritative cell.")
	expect(is_equal_approx(sample.world_height, 1.5), "A result exposes world height.")
	expect_equal(sample.surface_normal, Vector3.UP, "A flat result exposes an upward normal.")
	sample.set_surface(Vector2i.ONE, 0.25, Vector3(-0.2, 0.98, 0.0), 2, MAP_SCRIPT.Transition.Ramp)
	expect_equal(sample.transition, MAP_SCRIPT.Transition.Ramp, "A sloped result preserves its transition type.")
	expect(sample.surface_normal.x < 0.0, "A sloped result exposes its generated surface normal.")
	sample.set_invalid(Vector2i(8, 9))
	expect(not sample.valid and is_inf(sample.world_height), "An invalid result never implies Y=0.")
