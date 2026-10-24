extends "res://tests/test_case.gd"

const SKELETON := preload("res://enemies/skeleton.tscn")
const ZOMBIE := preload("res://enemies/zombie.tscn")
const BASELINE_PATH := "res://enemies/test_fixtures/patrol_timing.json"
const TICK_COUNT := 360
const TICK_DELTA := 1.0 / 60.0
const POSITION_TOLERANCE := 0.0001

enum PatrolCase { Immediate, Delayed, Looping }


# Flow: Shared presentation preserves patrol positions, turns, spawning, animations, and footstep cue times.
func run(tree: SceneTree) -> void:
	var baseline := JSON.parse_string(FileAccess.get_file_as_string(BASELINE_PATH)) as Dictionary
	for scene in [SKELETON, ZOMBIE]:
		for patrol_case in PatrolCase.values():
			var trace := await record_patrol(tree, scene, patrol_case as PatrolCase)
			var label := trace["label"] as String
			var expected := baseline[label] as Dictionary
			var samples := trace["samples"] as Array
			var expected_samples := expected["samples"] as Array
			expect_equal(samples.size(), expected_samples.size(), label + " retains every patrol checkpoint.")
			for index in mini(samples.size(), expected_samples.size()):
				_compare_sample(samples[index] as Dictionary, expected_samples[index] as Dictionary, label)
			expect_equal(trace["cues"], expected["cues"], label + " retains every audio cue's tick and sound.")


# Capture actual physics movement at a fixed tick rate; rendering cannot advance animations between samples.
func record_patrol(tree: SceneTree, scene: PackedScene, patrol_case: PatrolCase) -> Dictionary:
	var viewport := SubViewport.new()
	viewport.name = "PatrolTiming"
	viewport.own_world_3d = true
	var floor_body := StaticBody3D.new()
	floor_body.position.y = -0.25
	var shape := BoxShape3D.new()
	shape.size = Vector3(16.0, 0.5, 16.0)
	var collision := CollisionShape3D.new()
	collision.shape = shape
	floor_body.add_child(collision)
	viewport.add_child(floor_body)
	tree.root.add_child(viewport)
	await tree.physics_frame
	await tree.process_frame
	var enemy := scene.instantiate() as GDPathPlaceable
	enemy.name = "Actor"
	enemy.spawn_time = 0.4 if patrol_case == PatrolCase.Delayed else 0.0
	enemy.curve = Curve3D.new()
	for point in [Vector3.ZERO, Vector3(1.5, 0.0, 0.0), Vector3(1.5, 0.0, 1.5)]:
		enemy.curve.add_point(point)
	enemy.set_physics_process(false)
	if enemy is GDSkeletonPath:
		(enemy as GDSkeletonPath).loop_patrol = patrol_case == PatrolCase.Looping
	else:
		(enemy as GDZombiePath).loop_patrol = patrol_case == PatrolCase.Looping
	var cues: Array = []
	var clock: Array[int] = [0]
	var host := GDAudio.PLAYBACK_HOST
	var previous_executor := host.executor
	host.executor = func(player: Node) -> void:
		var audio := player as AudioStreamPlayer3D
		cues.append([float(clock[0]), audio.stream.resource_path])
	viewport.add_child(enemy)
	# Entering the tree enables declared physics callbacks; disable them after ready so each tick runs once.
	enemy.set_physics_process(false)
	var animation: AnimationPlayer
	if enemy is GDSkeletonPath:
		animation = (enemy as GDSkeletonPath).animation_player
	else:
		animation = (enemy as GDZombiePath).animation_player
	animation.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	var samples: Array = []
	var ticks: Array = []
	for tick in range(1, TICK_COUNT + 1):
		await tree.physics_frame
		clock[0] = tick
		if enemy is GDSkeletonPath:
			(enemy as GDSkeletonPath)._physics_process(TICK_DELTA)
		else:
			(enemy as GDZombiePath)._physics_process(TICK_DELTA)
		animation.advance(TICK_DELTA)
		var sample := _snapshot(enemy, animation, tick)
		ticks.append(sample)
		if tick == 1 or tick % 30 == 0:
			samples.append(sample)
		await tree.process_frame
	host.executor = previous_executor
	var label := scene.resource_path.get_file().get_basename() + "/" + String(PatrolCase.keys()[patrol_case])
	viewport.free()
	await tree.process_frame
	return {"label": label, "samples": samples, "cues": cues, "ticks": ticks}


func _snapshot(enemy: GDPathPlaceable, animation: AnimationPlayer, tick: int) -> Dictionary:
	var result := {"tick": tick, "animation": animation.current_animation, "animation_speed": animation.speed_scale}
	var feet: Node3D
	var drop: Node3D
	var pivot: Node3D
	if enemy is GDSkeletonPath:
		var skeleton := enemy as GDSkeletonPath
		feet = skeleton.path_follow
		drop = skeleton.drop_pivot
		pivot = skeleton.pivot
		result.merge(
			{
				"spawned": skeleton.has_dropped_in,
				"direction": skeleton.patrol_direction,
				"progress": skeleton.path_follow.progress,
				"elapsed": skeleton.elapsed_time,
				"drop_elapsed": skeleton.drop_elapsed,
				"rng": str(skeleton.footstep_rng.state)
			}
		)
	else:
		var zombie := enemy as GDZombiePath
		feet = zombie.zombie_body
		drop = zombie.drop_pivot
		pivot = zombie.pivot
		result.merge(
			{
				"spawned": zombie.has_dropped_in,
				"direction": zombie.patrol_direction,
				"patrol_index": zombie.patrol_index,
				"state": GDZombiePath.ZombieState.keys()[zombie.state],
				"elapsed": zombie.elapsed_time,
				"drop_elapsed": zombie.drop_elapsed,
				"rng": str(zombie.footstep_rng.state)
			}
		)
	result["position"] = [feet.global_position.x, feet.global_position.y, feet.global_position.z]
	result["drop_y"] = drop.position.y
	result["yaw"] = pivot.rotation.y
	return result


func _compare_sample(actual: Dictionary, expected: Dictionary, label: String) -> void:
	for key: String in expected:
		var description := "%s at tick %s preserves %s." % [label, expected["tick"], key]
		if key == "position":
			var actual_position := actual[key] as Array
			var expected_position := expected[key] as Array
			var matches := true
			for axis in 3:
				matches = (
					matches and absf(float(actual_position[axis]) - float(expected_position[axis])) < POSITION_TOLERANCE
				)
			expect(matches, description)
		elif expected[key] is float or expected[key] is int:
			expect(absf(float(actual[key]) - float(expected[key])) < POSITION_TOLERANCE, description)
		else:
			expect_equal(actual[key], expected[key], description)
