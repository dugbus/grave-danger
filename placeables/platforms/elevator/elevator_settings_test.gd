extends "res://tests/test_case.gd"

const SUBJECT := preload("res://placeables/platforms/elevator/elevator_settings.gd")
const DEFAULTS := preload("res://placeables/platforms/elevator/elevator_settings.tres")


func run(_tree: SceneTree) -> void:
	expect_script_contract(SUBJECT, "res://placeables/platforms/elevator/elevator_settings.gd")
	expect_equal(DEFAULTS.speed, 0.75, "The shared default travels at a boardable speed.")
	expect_equal(DEFAULTS.landing_pause, 1.0, "Default landings pause for boarding.")
	expect_equal(DEFAULTS.thickness, 0.25, "The slab matches crumbling-floor thickness.")
	expect(
		DEFAULTS.collision_margin < DEFAULTS.support_margin,
		"Safety sweeps retain a smaller clearance than support checks."
	)
