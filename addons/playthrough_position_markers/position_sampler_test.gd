extends "res://tests/test_case.gd"

const SUBJECT := preload("res://addons/playthrough_position_markers/position_sampler.gd")
const SUBJECT_PATH := "res://addons/playthrough_position_markers/position_sampler.gd"
const SETTINGS := preload(
	"res://addons/playthrough_position_markers/playthrough_position_sampling_settings.gd"
)


func run(tree: SceneTree) -> void:
	expect_script_contract(SUBJECT, SUBJECT_PATH)
	var level := Node3D.new()
	level.scene_file_path = "res://levels/test/level.tscn"
	tree.root.add_child(level)
	var player := Node3D.new()
	level.add_child(player)
	player.position = Vector3(3.0, 0.5, -4.0)
	var sampler := SUBJECT.new() as Node
	player.add_child(sampler)
	var settings := SETTINGS.new() as Resource
	settings.set("sample_interval_seconds", 2.0)
	sampler.set("settings", settings)
	var samples: Array[Dictionary] = []
	sampler.position_sampled.connect(func(
		level_path: String,
		time: float,
		position: Vector3
	) -> void:
		samples.append({"level_path": level_path, "time": time, "position": position})
	)

	expect(
		sampler.start(player, level),
		"A sampler starts when given a player and an authored level scene."
	)
	sampler.advance(1.0)
	sampler.advance(1.0)
	expect_equal(samples.size(), 2, "Sampling captures the start and the configured interval.")
	if samples.size() == 2:
		expect_equal(samples[1]["time"], 2.0, "The interval sample retains playthrough time.")
		expect_equal(
			samples[1]["position"],
			Vector3(3.0, 0.5, -4.0),
			"Samples use coordinates local to the authored level root."
		)
	var sample_count_before_physics := samples.size()
	settings.set("sample_interval_seconds", 0.1)
	for _frame_index in 8:
		await tree.physics_frame
	expect(
		samples.size() > sample_count_before_physics,
		"The configured live sampler continues emitting from physics processing after startup."
	)
	level.queue_free()
