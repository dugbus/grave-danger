extends "res://tests/test_case.gd"

## Match the real player's grounded gravity, capsule and normal walking speed.
const TILE := preload("res://placeables/traps/crumbling_floor/crumbling_floor.gd")
const SCENE := preload("res://placeables/traps/crumbling_floor/crumbling_floor.tscn")


class GroundedWalker:
	extends CharacterBody3D
	var walking := false

	func _ready() -> void:
		add_to_group(&"player")

	func _physics_process(delta: float) -> void:
		if not is_on_floor():
			velocity += get_gravity() * delta
		velocity.x = GDPlayerMovement.SPEED if walking else 0.0
		move_and_slide()


func run(tree: SceneTree) -> void:
	await _test_crossing(tree, false)
	await _test_crossing(tree, true)
	await _test_disabled_tile(tree)
	await _test_close_escapes(tree)
	_test_debug_level_settings()


func _test_crossing(tree: SceneTree, jump: bool) -> void:
	var fixture := _make_crossing(tree, 0, Vector3.ZERO)
	var root := fixture["root"] as Node3D
	var tile := fixture["tile"] as TILE
	var walker := fixture["walker"] as GroundedWalker
	for frame in 8:
		await tree.physics_frame
		await tree.process_frame
	expect(walker.is_on_floor(), "The real-sized capsule starts grounded on neighboring floor.")
	if jump:
		walker.velocity.y = GDPlayerMovement.JUMP_SETTINGS.get_jump_velocity(walker.get_gravity().length())
	walker.walking = true
	for frame in 30:
		await tree.physics_frame
		await tree.process_frame
	walker.walking = false
	if jump:
		expect_equal(tile.state, TILE.State.Intact, "Jumping over the floor without landing leaves it intact.")
		expect_equal(_audio_count(tile), 0, "Jumping over the tile does not play its crack sound.")
	else:
		expect(tile.state != TILE.State.Intact, "Walking across at normal speed always starts the floor breaking.")
	for frame in 100:
		await tree.physics_frame
		await tree.process_frame
	expect_equal(
		tile.state,
		TILE.State.Intact if jump else TILE.State.Collapsed,
		"An airborne crossing stays intact; a grounded crossing always finishes collapsing."
	)
	if jump:
		walker.position = Vector3(0.0, 0.6, 0.0)
		walker.velocity = Vector3.ZERO
		for frame in 90:
			await tree.physics_frame
			await tree.process_frame
		expect_equal(tile.state, TILE.State.Collapsed, "Landing on the tile after a jump still starts its collapse.")
	root.free()
	await tree.process_frame


func _test_disabled_tile(tree: SceneTree) -> void:
	var fixture := _make_crossing(tree, 0, Vector3.ZERO)
	var root := fixture["root"] as Node3D
	var tile := fixture["tile"] as TILE
	var walker := fixture["walker"] as GroundedWalker
	tile.process_mode = Node.PROCESS_MODE_DISABLED
	walker.position = Vector3(0.0, 0.01, 0.0)
	for frame in 8:
		await tree.physics_frame
		await tree.process_frame
	expect(not walker.is_on_floor(), "A disabled tile removes its native support from the physics world.")
	expect_equal(tile.state, TILE.State.Intact, "The shared monitor respects disabled tile previews.")
	tile.process_mode = Node.PROCESS_MODE_INHERIT
	walker.position = Vector3(0.0, 0.01, 0.0)
	walker.velocity = Vector3.ZERO
	for frame in 8:
		await tree.physics_frame
		await tree.process_frame
	expect(tile.state != TILE.State.Intact, "Re-enabling a supported tile restores contact activation.")
	root.free()
	await tree.process_frame


func _make_crossing(tree: SceneTree, seed_value: int, at: Vector3) -> Dictionary:
	var root := Node3D.new()
	root.position = at
	tree.root.add_child(root)
	var tile := SCENE.instantiate() as TILE
	tile.fracture_seed = seed_value
	root.add_child(tile)
	for x in [-1.0, 1.0]:
		var floor := StaticBody3D.new()
		var collision := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = Vector3(1.0, 0.25, 1.0)
		collision.shape = box
		floor.position = Vector3(x, -0.125, 0.0)
		floor.add_child(collision)
		root.add_child(floor)
	var walker := GroundedWalker.new()
	walker.position = Vector3(-1.0, 0.01, 0.0)
	walker.collision_layer = 2
	walker.collision_mask = 9
	var collision := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.height = 0.8
	capsule.radius = 0.28
	collision.shape = capsule
	collision.position.y = 0.4
	walker.add_child(collision)
	root.add_child(walker)
	return {"root": root, "tile": tile, "walker": walker, "escaped": false}


func _test_close_escapes(tree: SceneTree) -> void:
	var fixtures: Array[Dictionary] = []
	for seed_value in range(1, 25):
		fixtures.append(_make_crossing(tree, seed_value, Vector3(0.0, 0.0, seed_value * 3.0)))
	for frame in 8:
		await tree.physics_frame
		await tree.process_frame
	for fixture in fixtures:
		(fixture["walker"] as GroundedWalker).walking = true
	for frame in 30:
		await tree.physics_frame
		await tree.process_frame
		for fixture in fixtures:
			var walker := fixture["walker"] as GroundedWalker
			var tile := fixture["tile"] as TILE
			if not fixture["escaped"] and walker.position.x >= 0.75:
				fixture["escaped"] = true
				expect(
					walker.is_on_floor(), "A full-speed crossing reaches solid floor for seed %d." % tile.fracture_seed
				)
				expect(
					tile._released_count >= 14 and tile._released_count < tile._blocks.size(),
					(
						"Nearly all blocks have fallen at escape, with the last blocks still falling for seed %d."
						% tile.fracture_seed
					)
				)
	for fixture in fixtures:
		expect(fixture["escaped"] as bool, "The player can escape each shuffled pattern at normal movement speed.")
		(fixture["root"] as Node3D).free()
	await tree.process_frame


func _test_debug_level_settings() -> void:
	var packed := load("res://levels/debug-level/level.tscn") as PackedScene
	var level := packed.instantiate() as Node3D
	var prototype := SCENE.instantiate() as TILE
	var tiles := level.get_node("Objects/CrumblingFloors") as Node3D
	for child in tiles.get_children():
		var tile := child as TILE
		expect_equal(
			tile.collapse_delay,
			prototype.collapse_delay,
			"The debug-level tile inherits the tuned warning instead of a stale saved delay."
		)
		expect_equal(
			tile.block_release_interval,
			prototype.block_release_interval,
			"The debug-level tile inherits the tuned progressive release interval."
		)
	prototype.free()
	level.free()


func _audio_count(tile: TILE) -> int:
	var count := 0
	for child in tile.get_children():
		if child is AudioStreamPlayer3D:
			count += 1
	return count
