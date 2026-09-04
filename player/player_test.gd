extends "res://tests/test_case.gd"

const SUBJECT := preload("res://player/player.gd")
const SUBJECT_PATH := "res://player/player.gd"
const PLAYER_SCENE := preload("res://player/player.tscn")


func run(_tree: SceneTree) -> void:
	expect_script_contract(SUBJECT, SUBJECT_PATH)
	var player := PLAYER_SCENE.instantiate() as CharacterBody3D
	expect(
		player.get_node_or_null("PlaythroughPositionCapture") == null,
		"Reusable player instances cannot capture frontend playback as a live playthrough."
	)
	player.free()
