extends "res://tests/test_case.gd"

const SUBJECT := preload("res://game/run_recording.gd")
const SUBJECT_PATH := "res://game/run_recording.gd"


func run(_tree: SceneTree) -> void:
	expect_script_contract(SUBJECT, SUBJECT_PATH)
	var directory := "res://tests/run_recording_remove_test_%d" % Time.get_ticks_usec()
	var created := DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(directory))
	if not expect_equal(created, OK, "An isolated recording storage directory can be created."):
		return
	for level_id in ["drifted", "healthy"]:
		# Text placeholders exercise deletion without generating compressed binary recordings.
		var file := FileAccess.open(SUBJECT.get_path_for_level(level_id, directory), FileAccess.WRITE)
		if expect(file != null, "A disposable playback placeholder can be created."):
			file.store_string("disposable recording placeholder")
			file.close()
	SUBJECT.remove_for_level("drifted", directory)
	expect(
		not FileAccess.file_exists(SUBJECT.get_path_for_level("drifted", directory)),
		"Drifted playback is removed from storage."
	)
	expect(
		FileAccess.file_exists(SUBJECT.get_path_for_level("healthy", directory)),
		"Other level playbacks remain available."
	)
	SUBJECT.remove_for_level("drifted", directory)
	expect(
		not FileAccess.file_exists(SUBJECT.get_path_for_level("drifted", directory)), "Repeated deletion is harmless."
	)
	SUBJECT.remove_for_level("healthy", directory)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(directory))
