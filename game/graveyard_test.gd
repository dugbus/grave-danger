extends "res://tests/test_case.gd"

const SUBJECT := preload("res://game/graveyard.gd")
const SUBJECT_PATH := "res://game/graveyard.gd"
const GAME_SCENE := preload("res://game/graveyard.tscn")


func run(_tree: SceneTree) -> void:
	expect_script_contract(SUBJECT, SUBJECT_PATH)
	var game_scene := GAME_SCENE.instantiate() as Node3D
	expect_equal(
		game_scene.default_level_scene_path,
		"res://levels/1/level.tscn",
		"The lightweight gameplay shell does not synchronously embed its fallback level."
	)
	var music_player := game_scene.get_node("GameRuntime/MusicPlayer") as AudioStreamPlayer
	expect(
		not music_player.autoplay,
		"Gameplay music waits until level and navigation initialization have completed."
	)
	expect(
		game_scene.get_node_or_null("PlaythroughPositionCapture/Sampler") != null,
		"Only the live gameplay host composes playthrough position capture."
	)
	game_scene.free()
	var game := SUBJECT.new()
	var level := Node3D.new()
	var old_provider := Node3D.new()
	old_provider.add_to_group(&"kill_boundary")
	level.add_child(old_provider)
	game.current_level = level
	expect_equal(
		game._get_kill_boundary(),
		old_provider,
		"Boundary discovery accepts a grouped legacy provider without exact script coupling."
	)
	old_provider.remove_from_group(&"kill_boundary")
	var new_provider := GDKillBoundary2.new()
	new_provider.add_to_group(&"kill_boundary")
	level.add_child(new_provider)
	expect_equal(
		game._get_kill_boundary(),
		new_provider,
		"Boundary discovery accepts a grouped Kill Boundary 2 provider."
	)
	expect(
		(SUBJECT as Script).get_source_code().contains("exactly one is supported"),
		"Duplicate-boundary discovery declares a clear configuration error."
	)
	level.free()
	game.free()
