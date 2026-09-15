extends "res://tests/test_case.gd"

const LEVEL := preload("res://levels/close-escape/level.tscn")
const PRESSURE := preload("res://levels/close-escape/boundary_progression.gd")
const DIRECTIONS: Array[Vector2i] = [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]
# Conservative travel pace includes steering; dwell budgets allow collecting, banking and threats.
const WALK_SPEED := 2.5
const ROUTE: Array[NodePath] = [
	^"Treasure/CacheA1", ^"Treasure/CacheA2", ^"Deposits/DepositA",
	^"Treasure/CacheA3", ^"Progression/SilverKey1", ^"Progression/SilverDoor1",
	^"Treasure/CacheB1", ^"Progression/SilverKey2", ^"Treasure/CacheB2",
	^"Deposits/DepositB", ^"Treasure/CacheB3", ^"Progression/SilverDoor2",
	^"Treasure/CacheC1", ^"Deposits/DepositC", ^"Treasure/CacheC2",
	^"Progression/SilverKey3", ^"Progression/SilverDoor3",
	^"Treasure/CacheC3", ^"Deposits/VaultDeposit", ^"Treasure/CacheC4",
	^"Progression/GoldKey", ^"Deposits/VaultDeposit", ^"Progression/FinalGate",
]


func run(tree: SceneTree) -> void:
	await _check_route(tree, WALK_SPEED, true)
	await _check_route(tree, 4.5, false)
	await _check_route(tree, 4.5, true)
	await _check_route(tree, WALK_SPEED, true, 10.0)


func _check_route(tree: SceneTree, walk_speed: float, collect_all: bool, pause_seconds := 0.0) -> void:
	var level := LEVEL.instantiate() as Node3D
	var grid := level.get_node(^"AuthoredLayout/WallGridMap") as GridMap
	var boundary := level.get_node(^"KillBoundary2") as GDKillBoundary2
	var animator := GDKillBoundary2Animator.new()
	animator.configure(boundary.sequence, boundary.playback_mode, 1.0)
	animator.restart()
	var pressure := level.get_node(^"BoundaryProgression") as PRESSURE
	var blocked: Dictionary = {}
	for node in (level.get_node(^"Progression") as Node3D).get_children():
		if node is GDLockableHingedPassage:
			blocked[_cell(node as Node3D)] = true
	# Treat physics obstacles as immovable; the proven route must have a way around them.
	for node in (level.get_node(^"Hazards") as Node3D).get_children():
		if not node is GDSpikeTrap:
			blocked[_cell(node as Node3D)] = true
	for node in (level.get_node(^"Deposits") as Node3D).get_children():
		blocked[_cell(node as Node3D)] = true
	var current := _cell(level.get_node(^"Player") as Node3D)
	var seconds := 0.0
	var silver_keys := 0
	var gold_key := false
	var coins := 0
	var carried := 0
	var visited: Dictionary = {}
	var unsafe_samples := 0
	for target_path in ROUTE:
		if not collect_all and (String(target_path).begins_with("Treasure/") or String(target_path).begins_with("Deposits/")):
			continue
		var target := level.get_node(target_path) as Node3D
		var target_cell := _cell(target)
		if target is GDLockableHingedPassage:
			var passage := target as GDLockableHingedPassage
			if passage.key_requirement == GDLockableHingedPassage.KeyRequirement.SilverKey:
				expect(silver_keys > 0, "Route has a silver key before %s." % target.name)
				silver_keys -= 1
			else:
				expect(gold_key, "Route has the gold key before the final gate.")
			blocked.erase(target_cell)
		var path := _path(current, target_cell, grid, blocked, String(target_path).begins_with("Deposits/"))
		expect(not path.is_empty(), "Physical floor route reaches %s around obstacles." % target.name)
		if path.is_empty():
			break
		for cell in path:
			# Unlock areas reach slightly before the door centre; start pressure on approach.
			if current.distance_to(target_cell) <= 1.0:
				for index in pressure.passages.size():
					if target == pressure.passages[index]:
						pressure.request_checkpoint(pressure.checkpoints[index])
			var origin := Vector2(current.x - 17, current.y - 14)
			var destination := Vector2(cell.x - 17, cell.y - 14)
			for sample in range(1, 5):
				var step := 1.0 / (walk_speed * 4.0)
				seconds += step
				animator.advance(step)
				pressure.advance_catch_up(animator, step)
				if not _safe(animator, animator.authored_position, origin.lerp(destination, float(sample) / 4.0)):
					unsafe_samples += 1
					print("Unsafe approach %s at real %.1f / flame %.1f: %s" % [target.name, seconds, animator.authored_position, origin.lerp(destination, float(sample) / 4.0)])
			current = cell
		for index in pressure.passages.size():
			if target == pressure.passages[index]:
				pressure.request_checkpoint(pressure.checkpoints[index])
		var dwell := 3.0
		# The optional 30-coin vault requires baiting two traps on the way in and back out.
		if target_path == ^"Treasure/CacheC3":
			dwell = 9.0
		if target is GDGoldCoinPile:
			var pile := target as GDGoldCoinPile
			coins += pile.coin_count
			carried += pile.coin_count
			visited[target_path] = true
			expect(carried <= 100, "Route banks coins before exceeding the base sack capacity.")
		elif String(target_path).begins_with("Deposits/"):
			carried = 0
			dwell = 4.0
		elif String(target.name).begins_with("SilverKey"):
			silver_keys += 1
		elif target.name == &"GoldKey":
			gold_key = true
		for sample in int(dwell * 10.0):
			seconds += 0.1
			animator.advance(0.1)
			pressure.advance_catch_up(animator, 0.1)
			if not _safe(animator, animator.authored_position, Vector2(current.x - 17, current.y - 14)):
				unsafe_samples += 1
				print("Unsafe dwell %s at real %.1f / flame %.1f" % [target.name, seconds, animator.authored_position])
		print("Close Escape route: %.1fs %s" % [seconds, target.name])
		if target_path == ^"Progression/SilverDoor1" and pause_seconds > 0.0:
			var before_pause := animator.authored_position
			animator.set_paused(true)
			for sample in int(pause_seconds * 10.0):
				animator.advance(0.1)
				pressure.advance_catch_up(animator, 0.1)
			seconds += pause_seconds
			expect(is_equal_approx(animator.authored_position, before_pause), "Pause relief does not become delayed forward access.")
			animator.set_paused(false)
	if collect_all:
		expect(visited.size() == 10 and coins == 240, "Route visits all ten caches and all 240 coins.")
	expect(unsafe_samples == 0, "Whole collection route clears the moving flame by 0.6m (%d unsafe samples)." % unsafe_samples)
	var vault_entry := _cell(level.get_node(^"Progression/SilverDoor3") as Node3D)
	var optional_cache := _cell(level.get_node(^"Treasure/CacheC3") as Node3D)
	var gold_key_cell := _cell(level.get_node(^"Progression/GoldKey") as Node3D)
	blocked[Vector2i(25, 24)] = true
	blocked[Vector2i(25, 25)] = true
	expect(_path(vault_entry, optional_cache, grid, blocked, false).is_empty(), "Optional 30-coin cache requires crossing its spike branch.")
	expect(not _path(vault_entry, gold_key_cell, grid, blocked, false).is_empty(), "Gold-key route can skip the optional spike branch.")
	await _check_passage_clearance(tree, level)
	animator.free()
	level.free()


func _cell(node: Node3D) -> Vector2i:
	return Vector2i(roundi(node.position.x) + 17, roundi(node.position.z) + 14)


func _safe(animator: GDKillBoundary2Animator, seconds: float, point: Vector2) -> bool:
	var state := animator.evaluate_at(seconds)
	var polygon := GDKillBoundary2Geometry.build_points(state.size, state.rounding, 64)
	return GDKillBoundary2Geometry.get_signed_distance(point - Vector2(state.position.x, state.position.z), polygon) >= 0.6


func _path(start: Vector2i, goal: Vector2i, grid: GridMap, blocked: Dictionary, adjacent: bool) -> Array[Vector2i]:
	var queue: Array[Vector2i] = [start]
	var previous: Dictionary = {start: start}
	var index := 0
	while index < queue.size():
		var cell := queue[index]
		index += 1
		if cell == goal or (adjacent and cell.distance_to(goal) <= 1.0):
			var result: Array[Vector2i] = []
			while cell != start:
				result.push_front(cell)
				cell = previous[cell] as Vector2i
			if result.is_empty():
				result.append(start)
			return result
		for direction in DIRECTIONS:
			var next := cell + direction
			if next.x < 0 or next.x >= 35 or next.y < 0 or next.y >= 29:
				continue
			if blocked.has(next) or previous.has(next):
				continue
			# Decorative road stones occupy cells but have no blocking collision.
			var item := grid.get_cell_item(Vector3i(next.x, 0, next.y))
			if item != GridMap.INVALID_CELL_ITEM and not grid.mesh_library.get_item_shapes(item).is_empty():
				continue
			previous[next] = cell
			queue.append(next)
	return []


func _check_passage_clearance(tree: SceneTree, level: Node3D) -> void:
	var harness := Node3D.new()
	harness.add_child(level.get_node(^"AuthoredLayout").duplicate())
	harness.add_child(level.get_node(^"FloorSurface").duplicate())
	var passages: Array[GDLockableHingedPassage] = []
	for child in level.get_node(^"Progression").get_children():
		if child is GDLockableHingedPassage:
			var passage := child.duplicate() as GDLockableHingedPassage
			harness.add_child(passage)
			passages.append(passage)
	tree.root.add_child(harness)
	await tree.physics_frame
	await tree.physics_frame
	for passage in passages:
		expect(_passage_sweep(passage) < 0.99, "%s blocks passage while locked." % passage.name)
		for leaf in passage.get_node(^"Leaves").get_children():
			var hinged_leaf := leaf as GDLockableHingedLeaf
			hinged_leaf.set_physics_process(false)
			hinged_leaf.rotation.y += PI * 0.5
	await tree.physics_frame
	await tree.physics_frame
	for passage in passages:
		expect(_passage_sweep(passage) >= 0.99, "%s has capsule clearance through its opened frame and adjacent walls." % passage.name)
	harness.free()


func _passage_sweep(passage: GDLockableHingedPassage) -> float:
	var normal := passage.global_basis.x if passage.completes_level else passage.global_basis.z
	# Use the player, not the smaller zombie capsule, when proving door clearance.
	var player_scene := preload("res://player/player.tscn").instantiate() as CharacterBody3D
	var player_collision := player_scene.get_node(^"CollisionShape3D") as CollisionShape3D
	var capsule := player_collision.shape
	var capsule_offset := player_collision.position
	player_scene.free()
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = capsule
	query.collision_mask = 1
	query.transform.origin = passage.global_position + capsule_offset + Vector3.UP * 0.001 - normal
	query.motion = normal * 2.0
	var fractions := passage.get_world_3d().direct_space_state.cast_motion(query)
	return fractions[0]
