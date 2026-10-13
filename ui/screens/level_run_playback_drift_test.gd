extends "res://tests/test_case.gd"

const SUBJECT := preload("res://ui/screens/level_run_playback_drift.gd")
const SUBJECT_PATH := "res://ui/screens/level_run_playback_drift.gd"


func run(tree: SceneTree) -> void:
	expect_script_contract(SUBJECT, SUBJECT_PATH)
	var level := Node3D.new()
	var actor := Node3D.new()
	actor.name = "Actor"
	level.add_child(actor)
	tree.root.add_child(level)
	var checkpoints: Array[Dictionary] = [
		{"time": 1.0, "states": [{"path": "Actor", "position": [0.0, 0.0, 0.0]}]},
		{
			"time": 2.0,
			"states":
			[
				{"path": "Actor", "position": [2.0, 0.0, 0.0]},
				{"path": "Missing", "position": [0.0, 0.0, 0.0]},
			]
		},
		{"time": 3.0, "states": [{"path": "AlsoMissing", "position": [0.0, 0.0, 0.0]}]},
	]
	var recording := {"run_metadata": {"level_id": "drift-test", "drift_checkpoints": checkpoints}}
	var warned := {}
	expect_equal(SUBJECT.report_due(recording, level, 0.5, 0, warned), 0, "Future checkpoints are not checked early.")
	expect_equal(
		SUBJECT.report_due(recording, level, 1.5, 0, warned), 1, "Matching checkpoints advance without a warning."
	)
	expect(warned.is_empty(), "A matching playback remains eligible for presentation.")
	actor.position.x = SUBJECT.POSITION_TOLERANCE * 0.5
	expect_equal(
		SUBJECT.report_due(recording, level, 1.5, 0, warned), 1, "Small position errors remain within tolerance."
	)
	var next_index := SUBJECT.report_due(recording, level, 4.0, 1, warned)
	expect_equal(next_index, 2, "Checks stop immediately after the first drifted checkpoint.")
	expect_equal(warned.size(), 1, "Only one node is reported even when multiple nodes and checkpoints drift.")
	expect(warned.has("Actor"), "The warning identifies the first positional mismatch.")
	expect_equal(SUBJECT.report_due(recording, level, 4.0, next_index, warned), next_index, "Later checks stay silent.")
	expect_equal(
		SUBJECT.report_due(recording, level, 4.0, 0, warned), 0, "Restarting the loop cannot repeat a warning."
	)
	var missing_warned := {}
	SUBJECT._report_checkpoint(level, checkpoints[2], "missing-node-test", missing_warned)
	expect(missing_warned.has("AlsoMissing"), "A removed tracked node also invalidates the recording.")
	SUBJECT._report_checkpoint(level, checkpoints[1], "missing-node-test", missing_warned)
	expect_equal(missing_warned.size(), 1, "Subsequent missing nodes or positions do not add warnings.")
	level.free()
