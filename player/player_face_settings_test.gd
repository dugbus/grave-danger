extends "res://tests/test_case.gd"

const SUBJECT := preload("res://player/player_face_settings.gd")
const ANDY := preload("res://player/andy_face_settings.tres")
const FALLBACK := preload("res://player/player_face_settings.tres")


func run(_tree: SceneTree) -> void:
	expect_script_contract(SUBJECT, "res://player/player_face_settings.gd")
	expect(
		ANDY.splatter_offset.y < ANDY.nose_offset.y,
		"The rigged cheek mark sits below the nose rather than in the hair."
	)
	expect(
		ANDY.mouth_offset.y < ANDY.nose_offset.y and ANDY.nose_offset.y < ANDY.left_eye_offset.y,
		"The model's mouth, nose and eye sources follow facial feature order."
	)
	expect(FALLBACK.splatter_offset.y > 0.0, "The legacy standing face retains its original positive-height offsets.")
