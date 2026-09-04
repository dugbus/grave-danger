extends "res://tests/test_case.gd"

const SUBJECT := preload("res://addons/playthrough_position_markers/debugger_reporter.gd")
const SUBJECT_PATH := "res://addons/playthrough_position_markers/debugger_reporter.gd"


func run(_tree: SceneTree) -> void:
	expect_script_contract(SUBJECT, SUBJECT_PATH)
	expect_equal(
		SUBJECT.MESSAGE_NAME,
		&"playthrough_position_markers:sample",
		"The runtime reporter uses the editor plugin's namespaced debugger message."
	)
	var reporter := SUBJECT.new() as Node
	expect(
		not reporter.capture_playthrough_positions(null, null),
		"Position capture stays inactive without an editor debug session and live gameplay targets."
	)
	var playback_root := Node.new()
	playback_root.add_to_group(&"run_playback_session")
	var playback_player := Node3D.new()
	playback_root.add_child(playback_player)
	expect(
		reporter.is_frontend_playback(playback_player),
		"Frontend playback players are explicitly excluded from position capture."
	)
	playback_root.free()
	reporter.free()
