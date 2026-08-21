extends "res://tests/test_case.gd"

const SUBJECT := preload("res://game/audio.gd")
const SUBJECT_PATH := "res://game/audio.gd"


func run(_tree: SceneTree) -> void:
	expect_script_contract(SUBJECT, SUBJECT_PATH)
	_test_dungeon_reverb_only_changes_sfx_bus()


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
	var reverb := AudioServer.get_bus_effect(sfx_bus_index, effect_index) as AudioEffectReverb \
		if effect_index >= 0 else null
	expect_equal(
		AudioServer.get_bus_effect_count(sfx_bus_index),
		initial_sfx_effect_count + 1,
		"Dungeon gameplay adds one acoustic effect to the SFX bus."
	)
	expect(reverb != null, "The dungeon SFX effect is reverb.")
	if reverb != null:
		expect(
			is_equal_approx(reverb.room_size, SUBJECT.DUNGEON_REVERB_ROOM_SIZE) \
				and is_equal_approx(reverb.damping, SUBJECT.DUNGEON_REVERB_DAMPING) \
				and is_equal_approx(reverb.predelay_msec, SUBJECT.DUNGEON_REVERB_PREDELAY_MSEC) \
				and is_equal_approx(reverb.hipass, SUBJECT.DUNGEON_REVERB_HIPASS) \
				and is_equal_approx(reverb.wet, SUBJECT.DUNGEON_REVERB_WET),
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
