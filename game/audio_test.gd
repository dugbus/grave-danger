extends "res://tests/test_case.gd"

const SUBJECT := preload("res://game/audio.gd")
const SUBJECT_PATH := "res://game/audio.gd"


func run(tree: SceneTree) -> void:
	expect_script_contract(SUBJECT, SUBJECT_PATH)
	_test_dungeon_reverb_only_changes_sfx_bus()
	_test_one_shot_requests_reach_playback_executor(tree)


func _test_dungeon_reverb_only_changes_sfx_bus() -> void:
	var sfx_bus_index := AudioServer.get_bus_index(SUBJECT.SFX_BUS)
	var music_bus_index := AudioServer.get_bus_index(&"Music")
	expect(sfx_bus_index >= 0, "The dungeon effect can find the SFX bus.")
	expect(music_bus_index >= 0, "The dungeon effect leaves a dedicated Music bus available.")
	if sfx_bus_index < 0 or music_bus_index < 0:
		return

	SUBJECT.clear_dungeon_sfx_environment()
	var initial_sfx_effect_count := AudioServer.get_bus_effect_count(sfx_bus_index)
	var initial_music_effect_count := AudioServer.get_bus_effect_count(music_bus_index)
	SUBJECT.setup_dungeon_sfx_environment()

	var effect_index := SUBJECT._find_dungeon_reverb_effect_index(sfx_bus_index)
	var reverb := (
		AudioServer.get_bus_effect(sfx_bus_index, effect_index) as AudioEffectReverb if effect_index >= 0 else null
	)
	expect_equal(
		AudioServer.get_bus_effect_count(sfx_bus_index),
		initial_sfx_effect_count + 1,
		"Dungeon gameplay adds one acoustic effect to the SFX bus."
	)
	expect(reverb != null, "The dungeon SFX effect is reverb.")
	if reverb != null:
		expect(
			(
				is_equal_approx(reverb.room_size, SUBJECT.DUNGEON_REVERB_ROOM_SIZE)
				and is_equal_approx(reverb.damping, SUBJECT.DUNGEON_REVERB_DAMPING)
				and is_equal_approx(reverb.predelay_msec, SUBJECT.DUNGEON_REVERB_PREDELAY_MSEC)
				and is_equal_approx(reverb.hipass, SUBJECT.DUNGEON_REVERB_HIPASS)
				and is_equal_approx(reverb.wet, SUBJECT.DUNGEON_REVERB_WET)
			),
			"The dungeon reverb uses the shared room, brightness, reflection, and wet-mix tuning."
		)
	expect_equal(
		AudioServer.get_bus_effect_count(music_bus_index),
		initial_music_effect_count,
		"Dungeon acoustics do not add an effect to the Music bus."
	)

	SUBJECT.setup_dungeon_sfx_environment()
	expect_equal(
		AudioServer.get_bus_effect_count(sfx_bus_index),
		initial_sfx_effect_count + 1,
		"Repeated dungeon setup does not duplicate the SFX reverb."
	)

	SUBJECT.clear_dungeon_sfx_environment()
	expect_equal(
		AudioServer.get_bus_effect_count(sfx_bus_index),
		initial_sfx_effect_count,
		"Leaving dungeon gameplay removes only its SFX reverb."
	)


# Flow: Hosts receive complete audio cue requests without replacing their authored stream or routing.
func _test_one_shot_requests_reach_playback_executor(tree: SceneTree) -> void:
	var playback_host := SUBJECT.PLAYBACK_HOST as Resource
	var prior_executor := playback_host.executor as Callable
	var requests: Array[Node] = []
	playback_host.executor = func(player: Node) -> void: requests.append(player)
	var holder := Node3D.new()
	tree.root.add_child(holder)
	var stream := AudioStreamWAV.new()
	var flat := SUBJECT.play_one_shot(holder, stream, "MenuCue", -4.0, 1.2)
	var spatial := SUBJECT.play_one_shot_3d(holder, stream, "LandingCue", 4.0, 0.9, 48.0, 16.0)
	expect(
		requests.size() == 2 and requests[0] == flat and requests[1] == spatial,
		"The playback host receives both nonspatial and spatial cues exactly once."
	)
	expect(
		(
			flat.stream == stream
			and flat.bus == SUBJECT.SFX_BUS
			and is_equal_approx(flat.volume_db, -4.0)
			and is_equal_approx(flat.pitch_scale, 1.2)
		),
		"Nonspatial cues retain the source, bus, volume and pitch at the playback boundary."
	)
	expect(
		(
			spatial.stream == stream
			and spatial.bus == SUBJECT.SFX_BUS
			and is_equal_approx(spatial.volume_db, 4.0)
			and is_equal_approx(spatial.pitch_scale, 0.9)
			and is_equal_approx(spatial.max_distance, 48.0)
			and is_equal_approx(spatial.unit_size, 16.0)
		),
		"Spatial cues retain their source and authored audibility settings."
	)
	expect(
		not flat.playing and not spatial.playing,
		"An inspecting host can validate requests without starting native decoding."
	)
	playback_host.executor = prior_executor
	holder.free()
