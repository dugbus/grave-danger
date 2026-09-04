extends "res://tests/test_case.gd"

const SUBJECT := preload("res://addons/playthrough_position_markers/sample_collection.gd")
const SUBJECT_PATH := "res://addons/playthrough_position_markers/sample_collection.gd"


func run(_tree: SceneTree) -> void:
	expect_script_contract(SUBJECT, SUBJECT_PATH)
	var collection := SUBJECT.new() as RefCounted
	collection.add_sample(4, "res://levels/1/level.tscn", 0.0, Vector3(1.0, 0.0, 2.0))
	collection.add_sample(4, "res://levels/1/level.tscn", 2.0, Vector3(1.0, 0.0, 2.0))
	collection.add_sample(4, "res://levels/1/level.tscn", 4.0, Vector3(3.0, 0.0, 2.0))
	var levels := collection.take_session(4) as Dictionary
	var samples := levels.get("res://levels/1/level.tscn", []) as Array
	expect_equal(samples.size(), 2, "Consecutive identical positions collapse into one marker.")
	if samples.size() == 2:
		expect_equal(samples[0]["start_time"], 0.0, "A stationary range keeps its arrival time.")
		expect_equal(samples[0]["end_time"], 2.0, "A stationary range keeps its latest time.")
		expect_equal(samples[1]["start_time"], 4.0, "Movement creates a new timed marker.")
	expect(
		collection.take_session(4).is_empty(),
		"Taking a finished session clears it before the next playthrough."
	)
