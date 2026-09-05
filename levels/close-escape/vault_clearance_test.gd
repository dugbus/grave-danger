extends "res://tests/test_case.gd"

const LEVEL := preload("res://levels/close-escape/level.tscn")
const PLAYER := preload("res://player/player.tscn")
const ZOMBIE := preload("res://enemies/zombie.tscn")
# Replay at 1:49: the zombie dies in the only return opening from the spike pocket.
const RECORDED_ZOMBIE_POSITION := Vector3(7.98464, 0.000007, 9.95662)


func run(tree: SceneTree) -> void:
	var level := LEVEL.instantiate() as Node3D
	var player := PLAYER.instantiate() as CharacterBody3D
	var harness := Node3D.new()
	harness.add_child(level.get_node(^"AuthoredLayout").duplicate())
	harness.add_child(level.get_node(^"FloorGridMap").duplicate())
	tree.root.add_child(harness)
	await tree.physics_frame
	await tree.physics_frame
	var collision := player.get_node(^"CollisionShape3D") as CollisionShape3D
	expect(_escape_fraction(harness, player, collision) >= 0.99, "The real player capsule clears the spike pocket's return opening without a zombie.")
	var zombie := ZOMBIE.instantiate() as GDZombiePath
	zombie.ai_enabled_on_ready = false
	zombie.death_disappear_delay = 0.0
	zombie.death_disappear_duration = 0.01
	harness.add_child(zombie)
	zombie.set_physics_process(false)
	zombie.zombie_body.global_position = RECORDED_ZOMBIE_POSITION
	await tree.physics_frame
	await tree.physics_frame
	expect(_escape_fraction(harness, player, collision) < 0.99, "The recorded zombie body blocks the return opening while alive.")
	zombie.die_from_spike_trap()
	await tree.physics_frame
	await tree.physics_frame
	expect(zombie.is_dead, "The spike death uses the actual zombie death path.")
	expect(_escape_fraction(harness, player, collision) >= 0.99, "A spike-killed zombie immediately releases the recorded escape route.")
	await tree.create_timer(0.25).timeout
	expect(not zombie.drop_pivot.visible, "The corpse completes its visual disappearance.")
	expect(_escape_fraction(harness, player, collision) >= 0.99, "The vanished corpse cannot leave an invisible barrier in the vault.")
	harness.free()
	player.free()
	level.free()
	# Let completed death timers release their suspended call state before runner teardown.
	await tree.physics_frame
	await tree.process_frame


func _escape_fraction(harness: Node3D, player: CharacterBody3D, collision: CollisionShape3D) -> float:
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = collision.shape
	query.collision_mask = player.collision_mask
	query.transform.origin = Vector3(8, 0.001, 10.7) + collision.position
	query.motion = Vector3(0, 0, -2)
	return harness.get_world_3d().direct_space_state.cast_motion(query)[0]
