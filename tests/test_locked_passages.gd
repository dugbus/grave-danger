extends Node


const PLAYER_SCENE := preload("res://player/player.tscn")
const GOLD_KEY_SCENE := preload("res://collectibles/key.tscn")
const SILVER_KEY_SCENE := preload("res://collectibles/silver_key.tscn")
const LOCKED_DOOR_SCENE := preload("res://levels/common/locked_door.tscn")
const LOCKED_GATE_SCENE := preload("res://levels/common/locked_gate.tscn")

const GOLD_KEY_ITEM_TYPE := &"key"
const SILVER_KEY_ITEM_TYPE := &"silver_key"

var failure_count := 0


func run() -> int:
	var tests: Array[Dictionary] = [
		{"name": "silver key pickup adds silver_key inventory", "callable": _test_silver_key_pickup},
		{"name": "door stays locked without silver key", "callable": _test_door_requires_silver_key},
		{"name": "door scene includes frame mesh", "callable": _test_door_scene_includes_frame_mesh},
		{"name": "door consumes exactly one silver key", "callable": _test_door_consumes_one_silver_key},
		{"name": "multiple doors consume one silver key each", "callable": _test_multiple_doors_consume_separate_keys},
		{"name": "gate does not unlock with a silver key", "callable": _test_gate_rejects_silver_key},
		{"name": "gate consumes one gold key", "callable": _test_gate_consumes_gold_key},
		{"name": "gate completes only from past-gate trigger", "callable": _test_gate_completion_trigger},
	]

	for test: Dictionary in tests:
		await _clear_children()
		var failures_before := failure_count
		var test_name := String(test["name"])
		var test_callable := test["callable"] as Callable
		await test_callable.call()
		if failure_count == failures_before:
			print("PASS: %s" % test_name)
		else:
			print("FAIL: %s" % test_name)

	await _clear_children()
	return failure_count


func _test_silver_key_pickup() -> void:
	var player := await _create_player()
	var collected := await _collect_item(player, SILVER_KEY_SCENE)
	_assert_true(collected, "Player should collect the silver key pickup.")
	_assert_equal(_get_item_count(player, SILVER_KEY_ITEM_TYPE), 1, "Player should carry one silver key.")


func _test_door_requires_silver_key() -> void:
	var player := await _create_player()
	var door := await _create_passage(LOCKED_DOOR_SCENE)
	_assert_false(door.try_unlock_with(player), "Door should not unlock without a silver key.")
	_assert_true(door.is_locked(), "Door should remain locked without a silver key.")


func _test_door_scene_includes_frame_mesh() -> void:
	var door := await _create_passage(LOCKED_DOOR_SCENE)
	var frame := door.get_node_or_null("FrameBody/Frame") as MeshInstance3D
	var door_mesh := door.get_node_or_null("Leaves/DoorLeaf/Door") as MeshInstance3D
	_assert_true(frame != null, "Door scene should include a frame mesh node.")
	if frame != null:
		_assert_true(frame.mesh != null, "Door frame mesh node should have a mesh resource.")
	_assert_true(door_mesh != null, "Door scene should include a door mesh node.")
	if frame != null and frame.mesh != null and door_mesh != null and door_mesh.mesh != null:
		var frame_aabb := _get_global_mesh_aabb(frame)
		var door_aabb := _get_global_mesh_aabb(door_mesh)
		_assert_true(
			door_aabb.size.y >= 1.19,
			"Door mesh should be scaled up by 20 percent."
		)
		_assert_true(
			door_aabb.position.x >= frame_aabb.position.x,
			"Closed door should not jut outside the left side of the frame."
		)
		_assert_true(
			door_aabb.end.x <= frame_aabb.end.x,
			"Closed door should not jut outside the right side of the frame."
		)


func _test_door_consumes_one_silver_key() -> void:
	var player := await _create_player()
	var door := await _create_passage(LOCKED_DOOR_SCENE)
	await _collect_item(player, SILVER_KEY_SCENE)

	_assert_true(door.try_unlock_with(player), "Door should unlock with a silver key.")
	_assert_true(door.is_unlocked(), "Door should report unlocked after consuming a silver key.")
	_assert_equal(_get_item_count(player, SILVER_KEY_ITEM_TYPE), 0, "Door should consume one silver key.")


func _test_multiple_doors_consume_separate_keys() -> void:
	var player := await _create_player()
	var first_door := await _create_passage(LOCKED_DOOR_SCENE)
	var second_door := await _create_passage(LOCKED_DOOR_SCENE)
	_assert_true(await _collect_item(player, SILVER_KEY_SCENE), "Player should collect the first silver key.")
	_assert_true(await _collect_item(player, SILVER_KEY_SCENE), "Player should collect the second silver key.")

	_assert_true(first_door.try_unlock_with(player), "First door should unlock with the first silver key.")
	_assert_equal(_get_item_count(player, SILVER_KEY_ITEM_TYPE), 1, "One silver key should remain.")
	_assert_true(second_door.try_unlock_with(player), "Second door should unlock with the second silver key.")
	_assert_equal(_get_item_count(player, SILVER_KEY_ITEM_TYPE), 0, "Both silver keys should be consumed.")


func _test_gate_rejects_silver_key() -> void:
	var player := await _create_player()
	var gate := await _create_passage(LOCKED_GATE_SCENE)
	await _collect_item(player, SILVER_KEY_SCENE)

	_assert_false(gate.try_unlock_with(player), "Gate should not unlock with a silver key.")
	_assert_true(gate.is_locked(), "Gate should remain locked after a silver key attempt.")
	_assert_equal(_get_item_count(player, SILVER_KEY_ITEM_TYPE), 1, "Silver key should not be consumed by the gate.")


func _test_gate_consumes_gold_key() -> void:
	var player := await _create_player()
	var gate := await _create_passage(LOCKED_GATE_SCENE)
	await _collect_item(player, GOLD_KEY_SCENE)

	_assert_true(gate.try_unlock_with(player), "Gate should unlock with a gold key.")
	_assert_true(gate.is_unlocked(), "Gate should report unlocked after consuming a gold key.")
	_assert_equal(_get_item_count(player, GOLD_KEY_ITEM_TYPE), 0, "Gate should consume one gold key.")


func _test_gate_completion_trigger() -> void:
	var player := await _create_player()
	var gate := await _create_passage(LOCKED_GATE_SCENE)
	var completed_counts: Array[int] = [0]
	gate.level_completed.connect(func() -> void: completed_counts[0] += 1)

	_assert_false(gate.try_complete_with(player), "Locked gate should not complete the level.")
	_assert_equal(completed_counts[0], 0, "Locked gate should not emit level_completed.")

	await _collect_item(player, GOLD_KEY_SCENE)
	_assert_true(gate.try_unlock_with(player), "Gate should unlock before completion.")
	_assert_true(gate.try_complete_with(player), "Unlocked gate should complete from the completion trigger.")
	_assert_equal(completed_counts[0], 1, "Gate should emit level_completed once.")
	_assert_false(gate.try_complete_with(player), "Gate should not complete twice.")
	_assert_equal(completed_counts[0], 1, "Gate should still have emitted level_completed only once.")


func _create_player() -> GDPlayer:
	var player := PLAYER_SCENE.instantiate() as GDPlayer
	add_child(player)
	player.global_position = Vector3.ZERO
	await get_tree().process_frame
	return player


func _create_passage(scene: PackedScene) -> GDLockableHingedPassage:
	var passage := scene.instantiate() as GDLockableHingedPassage
	passage.position = Vector3(20.0 + float(get_child_count()) * 4.0, 0.0, 0.0)
	add_child(passage)
	await get_tree().process_frame
	return passage


func _collect_item(player: GDPlayer, scene: PackedScene) -> bool:
	var pickup := scene.instantiate() as Node3D
	add_child(pickup)
	pickup.global_position = player.global_position + Vector3(0.0, 0.0, 1.0)
	await get_tree().process_frame
	var collected := player.try_collect_carried_item(pickup)
	pickup.queue_free()
	await get_tree().process_frame
	return collected


func _get_item_count(player: GDPlayer, item_type: StringName) -> int:
	var inventory := player.get_node_or_null("PlayerInventory")
	if inventory == null or not inventory.has_method("get_item_count"):
		return 0

	return inventory.get_item_count(item_type)


func _get_global_mesh_aabb(mesh_instance: MeshInstance3D) -> AABB:
	var mesh_aabb := mesh_instance.mesh.get_aabb()
	var points: Array[Vector3] = []
	for x in [mesh_aabb.position.x, mesh_aabb.end.x]:
		for y in [mesh_aabb.position.y, mesh_aabb.end.y]:
			for z in [mesh_aabb.position.z, mesh_aabb.end.z]:
				points.append(mesh_instance.global_transform * Vector3(x, y, z))

	var result := AABB(points[0], Vector3.ZERO)
	for point in points:
		result = result.expand(point)
	return result


func _clear_children() -> void:
	for child in get_children():
		child.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame


func _assert_true(value: bool, message: String) -> void:
	if value:
		return

	failure_count += 1
	push_error(message)


func _assert_false(value: bool, message: String) -> void:
	_assert_true(not value, message)


func _assert_equal(actual: Variant, expected: Variant, message: String) -> void:
	if actual == expected:
		return

	failure_count += 1
	push_error("%s Expected '%s', got '%s'." % [message, str(expected), str(actual)])
