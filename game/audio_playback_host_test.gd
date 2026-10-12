extends "res://tests/test_case.gd"

const SUBJECT := preload("res://game/audio_playback_host.gd")


func run(_tree: SceneTree) -> void:
	expect_script_contract(SUBJECT, "res://game/audio_playback_host.gd")
	var host := SUBJECT.new()
	var player := Node.new()
	expect(not host.execute(player), "An unconfigured host leaves native playback to the caller.")
	var requests: Array[Node] = []
	host.executor = func(request: Node) -> void: requests.append(request)
	expect(host.execute(player), "A configured host handles the cue.")
	expect(requests.size() == 1 and requests[0] == player, "The executor receives the exact cue node.")
	host.executor = Callable()
	expect(not host.execute(player), "Clearing the executor restores normal playback ownership.")
	player.free()
