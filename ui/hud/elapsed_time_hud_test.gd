extends "res://tests/test_case.gd"

const SUBJECT := preload("res://ui/hud/elapsed_time_hud.gd")
const SUBJECT_PATH := "res://ui/hud/elapsed_time_hud.gd"


func run(tree: SceneTree) -> void:
	expect_script_contract(SUBJECT, SUBJECT_PATH)
	var hud := GDElapsedTimeHud.new()
	expect_equal(
		hud._format_elapsed_seconds(65.25), "65.2s", "Onscreen timers remain in seconds after passing one minute."
	)
	expect_equal(
		hud._format_elapsed_seconds(-1.0), "0.0s", "Onscreen timer formatting still clamps negative values to zero."
	)
	hud.free()
	await _test_fps_with_elapsed_time(tree)


# Flow: Ordinary levels display live FPS alongside elapsed time, with boundary timing when active.
func _test_fps_with_elapsed_time(tree: SceneTree) -> void:
	var hud := GDElapsedTimeHud.new()
	tree.root.add_child(hud)
	hud.set_process(false)
	expect(hud.elapsed_label.visible, "The shared elapsed HUD displays FPS without a minimap or Vampire.")
	expect_equal(
		hud.elapsed_label.text,
		"Elapsed 0.0s  •  FPS %d" % Engine.get_frames_per_second(),
		"FPS is shown on initial load."
	)
	hud._process(0.1)
	expect_equal(
		hud.elapsed_label.text,
		"Elapsed 0.1s  •  FPS %d" % Engine.get_frames_per_second(),
		"Updating the HUD advances elapsed time and refreshes FPS together."
	)
	var boundary := BoundaryClock.new()
	hud.add_child(boundary)
	hud.set_runtime_references(boundary)
	expect_equal(
		hud.elapsed_label.text,
		"Elapsed 0.1s  •  FPS %d\nBoundary 1.0s / 3.0s" % Engine.get_frames_per_second(),
		"Active boundary timing remains visible below elapsed time and FPS."
	)
	hud.free()
	await tree.process_frame


class BoundaryClock:
	extends Node3D

	func get_boundary_animation_position() -> float:
		return 1.0

	func get_boundary_animation_duration() -> float:
		return 3.0
