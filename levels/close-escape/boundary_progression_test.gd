extends "res://tests/test_case.gd"

const LEVEL := preload("res://levels/close-escape/level.tscn")
const PRESSURE := preload("res://levels/close-escape/boundary_progression.gd")


func run(_tree: SceneTree) -> void:
	var level := LEVEL.instantiate() as Node3D
	var pressure := level.get_node(^"BoundaryProgression") as PRESSURE
	var animator := GDKillBoundary2Animator.new()
	animator.configure(pressure.boundary.sequence, GDKillBoundary2Animator.PlaybackMode.SingleShot, 1.0)
	pressure.boundary.animator = animator
	pressure._ready()
	expect(pressure.passages.size() == 3 and pressure.checkpoints.size() == 3, "All three district doors have authored trailing-flame checkpoints.")
	pressure.passages[0].unlocked.emit()
	expect(is_equal_approx(pressure.target_time, pressure.checkpoints[0].time_seconds), "Actual door unlock signal requests its checkpoint.")
	pressure._physics_process(1.0)
	expect(is_zero_approx(animator.authored_position), "Progression cannot start the boundary before gameplay starts.")
	animator.restart()
	pressure._physics_process(1.0)
	expect(is_equal_approx(animator.authored_position, pressure.catch_up_rate), "Flame catches up smoothly instead of teleporting on unlock.")
	animator.set_paused(true)
	pressure._physics_process(10.0)
	expect(is_equal_approx(animator.authored_position, pressure.catch_up_rate), "Pause pickups also pause progression-driven pressure.")
	animator.set_paused(false)
	pressure._physics_process(100.0)
	expect(is_equal_approx(animator.authored_position, pressure.target_time), "Catch-up cannot overshoot the requested checkpoint.")
	pressure.passages[2].unlocked.emit()
	var latest_target := pressure.target_time
	pressure.passages[0].unlocked.emit()
	expect(is_equal_approx(pressure.target_time, latest_target), "Earlier doors cannot reset the deadline or rewind the flame.")
	pressure.boundary.boundary_removed_for_level = true
	var stopped_at := animator.authored_position
	pressure._physics_process(1.0)
	expect(is_equal_approx(animator.authored_position, stopped_at), "Removed boundaries do not keep catching up.")
	animator.free()
	level.free()
