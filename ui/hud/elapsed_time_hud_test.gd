extends "res://tests/test_case.gd"

const SUBJECT := preload("res://ui/hud/elapsed_time_hud.gd")
const SUBJECT_PATH := "res://ui/hud/elapsed_time_hud.gd"


func run(_tree: SceneTree) -> void:
	expect_script_contract(SUBJECT, SUBJECT_PATH)
	var hud := GDElapsedTimeHud.new()
	expect_equal(
		hud._format_elapsed_seconds(65.25),
		"65.2s",
		"Onscreen timers remain in seconds after passing one minute."
	)
	expect_equal(
		hud._format_elapsed_seconds(-1.0),
		"0.0s",
		"Onscreen timer formatting still clamps negative values to zero."
	)
	hud.free()
