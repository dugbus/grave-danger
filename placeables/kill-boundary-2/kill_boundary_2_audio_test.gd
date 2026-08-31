extends "res://tests/test_case.gd"

const SUBJECT := preload("res://placeables/kill-boundary-2/kill_boundary_2_audio.gd")
const SUBJECT_PATH := "res://placeables/kill-boundary-2/kill_boundary_2_audio.gd"


func run(_tree: SceneTree) -> void:
	expect_script_contract(SUBJECT, SUBJECT_PATH)
	var audio := GDKillBoundary2Audio.new()
	audio.render_effect = GDKillBoundary2Settings.RenderEffect.Ghost
	expect(
		is_equal_approx(audio._adjusted_volume(-20.0), -12.0),
		"Ghost proximity audio retains its volume boost."
	)
	audio.free()
