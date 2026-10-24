extends "res://tests/test_case.gd"

const SUBJECT := preload("res://enemies/enemy_footsteps.gd")


func run(tree: SceneTree) -> void:
	expect_script_contract(SUBJECT, "res://enemies/enemy_footsteps.gd")
	var player := AnimationPlayer.new()
	player.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	var animation := Animation.new()
	animation.length = 1.0
	animation.loop_mode = Animation.LOOP_LINEAR
	var library := AnimationLibrary.new()
	library.add_animation("Walk", animation)
	player.add_animation_library("Rig", library)
	tree.root.add_child(player)
	player.play("Rig/Walk")
	var footsteps := SUBJECT.new()
	# Flow: Authored quarter-cycle contacts fire once, survive wrapping, and reset when walking ends.
	var phases: Array[float] = [0.1, 0.3, 0.3, 0.7, 0.8, 0.95, 0.3]
	var expected: Array[bool] = [false, true, false, false, true, false, true]
	for index in phases.size():
		player.seek(phases[index], true)
		expect_equal(
			footsteps.did_cross_animation_phase(player, "Rig/Walk", "Rig/Walk"),
			expected[index],
			"Footstep contact preserves phase %.2f." % phases[index]
		)
	expect(not footsteps.did_cross_animation_phase(player, "idle", "Rig/Walk"), "Idle suppresses walk contacts.")
	expect_equal(footsteps.previous_phase, -1.0, "Leaving walk resets its contact history.")
	expect(
		not footsteps.did_cross_animation_phase(player, "Rig/Walk", "Rig/Walk"), "Resuming walk seeds a fresh phase."
	)
	footsteps.reset()
	expect_equal(footsteps.previous_phase, -1.0, "Stopping movement explicitly resets contacts.")
	expect(
		not footsteps.did_cross_animation_phase(null, "Rig/Walk", "Rig/Walk"), "Missing animation players stay silent."
	)
	player.free()
