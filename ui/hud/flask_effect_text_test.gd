extends "res://tests/test_case.gd"

const SUBJECT := preload("res://ui/hud/flask_effect_text.gd")
const ORDER := preload("res://ui/hud/overlay_render_order.gd")
const SUBJECT_PATH := "res://ui/hud/flask_effect_text.gd"


func run(_tree: SceneTree) -> void:
	expect_script_contract(SUBJECT, SUBJECT_PATH)

	var text := SUBJECT.new()
	expect_equal(
		text.text_material.render_priority,
		ORDER.DrawPass.ScreenText,
		"A flask message reserves the screen-text pass even when configured off-tree."
	)
	text.free()
