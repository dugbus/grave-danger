extends "res://tests/test_case.gd"

const SUBJECT := preload("res://enemies/enemy_death_presentation.gd")


func run(tree: SceneTree) -> void:
	expect_script_contract(SUBJECT, "res://enemies/enemy_death_presentation.gd")
	var owner := Node3D.new()
	var drop := Node3D.new()
	drop.position.y = 0.5
	var body := MeshInstance3D.new()
	body.transparency = 0.2
	var shadow := MeshInstance3D.new()
	shadow.transparency = 0.6
	owner.add_child(drop)
	drop.add_child(body)
	owner.add_child(shadow)
	tree.root.add_child(owner)
	# Flow: Sinking starts immediately; the body and shadow retain their opacity until the authored fade point.
	var tween := SUBJECT.create_disappear_tween(owner, drop, [body, shadow], 2.0, 3.0, 0.5)
	tween.pause()
	tween.custom_step(1.0)
	var halfway_sink := 0.5 - 3.0 * (1.0 - cos(PI * 0.25))
	expect(is_equal_approx(drop.position.y, halfway_sink), "The original sine ease controls sinking at half duration.")
	expect(
		is_equal_approx(body.transparency, 0.2) and is_equal_approx(shadow.transparency, 0.6),
		"Fading waits until the authored halfway point."
	)
	tween.custom_step(0.5)
	var halfway_fade := 1.0 - cos(PI * 0.25)
	expect(
		is_equal_approx(body.transparency, lerpf(0.2, 1.0, halfway_fade)), "The body keeps its original fade easing."
	)
	expect(
		is_equal_approx(shadow.transparency, lerpf(0.6, 1.0, halfway_fade)), "The shadow fades from its own opacity."
	)
	tween.custom_step(0.5)
	expect(is_equal_approx(drop.position.y, -2.5), "Sinking reaches the authored depth at the original duration.")
	expect(
		is_equal_approx(body.transparency, 1.0) and is_equal_approx(shadow.transparency, 1.0),
		"Both visual layers finish fading together."
	)
	owner.free()
