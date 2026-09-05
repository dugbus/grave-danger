extends "res://tests/test_case.gd"

const LEVEL_SCENE_PATH := "res://levels/close-escape/level.tscn"
const LEVEL_SCENE := preload("res://levels/close-escape/level.tscn")
const AUTHORED_LAYOUT := preload("res://levels/close-escape/authored_layout.tscn")
const GRID_SIZE := Vector2i(35, 29)
const START_CELL := Vector2i(2, 25)
const SILVER_DOOR_CELLS: Array[Vector2i] = [
	Vector2i(11, 21),
	Vector2i(22, 7),
	Vector2i(29, 17),
]
const FINAL_GATE_CELL := Vector2i(29, 0)
const SILVER_KEY_CELLS: Array[Vector2i] = [
	Vector2i(3, 4),
	Vector2i(20, 25),
	Vector2i(25, 14),
]
const GOLD_KEY_CELL := Vector2i(33, 26)
const TREASURE_CELLS: Array[Vector2i] = [
	Vector2i(2, 22),
	Vector2i(9, 23),
	Vector2i(7, 14),
	Vector2i(13, 25),
	Vector2i(20, 17),
	Vector2i(13, 3),
	Vector2i(24, 3),
	Vector2i(32, 12),
	Vector2i(24, 25),
	Vector2i(29, 22),
]
const DEPOSIT_CELLS: Array[Vector2i] = [
	Vector2i(9, 25),
	Vector2i(13, 17),
	Vector2i(32, 4),
	Vector2i(25, 20),
]
const SPIKE_CELLS: Array[Vector2i] = [
	Vector2i(25, 24),
	Vector2i(25, 25),
	Vector2i(28, 20),
	Vector2i(30, 20),
	Vector2i(32, 25),
	Vector2i(33, 25),
]
const ENEMY_ROUTE_CELLS: Array[Vector2i] = [
	Vector2i(3, 8),
	Vector2i(3, 16),
	Vector2i(13, 24),
	Vector2i(16, 24),
	Vector2i(18, 3),
	Vector2i(18, 11),
	Vector2i(24, 6),
	Vector2i(27, 6),
	Vector2i(24, 21),
	Vector2i(26, 21),
	Vector2i(5, 23),
	Vector2i(16, 16),
	Vector2i(30, 22),
	Vector2i(6, 12),
	Vector2i(14, 22),
	Vector2i(27, 11),
	Vector2i(27, 23),
]
const CARDINAL_DIRECTIONS: Array[Vector2i] = [
	Vector2i.UP,
	Vector2i.RIGHT,
	Vector2i.DOWN,
	Vector2i.LEFT,
]


func run(_tree: SceneTree) -> void:
	var level_scene_text := FileAccess.get_file_as_string(LEVEL_SCENE_PATH)
	var level := LEVEL_SCENE.instantiate() as Node3D
	var layout := AUTHORED_LAYOUT.instantiate() as Node3D
	var wall_grid := layout.get_node(^"WallGridMap") as GridMap
	var walkable_cells := _find_walkable_cells(wall_grid)
	var all_locks := _to_cell_set(SILVER_DOOR_CELLS)
	all_locks[FINAL_GATE_CELL] = true

	var district_one := _find_reachable_cells(START_CELL, walkable_cells, all_locks)
	expect(
		district_one.has(SILVER_KEY_CELLS[0])
			and not district_one.has(SILVER_KEY_CELLS[1]),
		"The first district contains only the silver key needed for its sealed exit."
	)

	all_locks.erase(SILVER_DOOR_CELLS[0])
	var district_two := _find_reachable_cells(START_CELL, walkable_cells, all_locks)
	expect(
		district_two.has(SILVER_KEY_CELLS[1])
			and not district_two.has(SILVER_KEY_CELLS[2]),
		"Opening the first door exposes the second key without bypassing the next lock."
	)

	all_locks.erase(SILVER_DOOR_CELLS[1])
	var district_three := _find_reachable_cells(START_CELL, walkable_cells, all_locks)
	expect(
		district_three.has(SILVER_KEY_CELLS[2])
			and not district_three.has(GOLD_KEY_CELL),
		"Opening the second door exposes the third key while the vault remains sealed."
	)

	all_locks.erase(SILVER_DOOR_CELLS[2])
	var unlocked_vault := _find_reachable_cells(START_CELL, walkable_cells, all_locks)
	expect(
		unlocked_vault.has(GOLD_KEY_CELL),
		"The third silver door exposes the spike-vault route to the gold key."
	)

	all_locks.erase(FINAL_GATE_CELL)
	var complete_route := _find_reachable_cells(START_CELL, walkable_cells, all_locks)
	var completion_targets := TREASURE_CELLS + DEPOSIT_CELLS + SILVER_KEY_CELLS
	completion_targets.append(GOLD_KEY_CELL)
	completion_targets.append(FINAL_GATE_CELL)
	expect(
		_all_cells_are_reachable(completion_targets, complete_route),
		"The intended unlock sequence leaves every treasure, deposit, key, and exit reachable."
	)
	expect(
		_all_cells_are_reachable(SPIKE_CELLS, walkable_cells),
		"Every authored spike occupies a real floor cell instead of a wall."
	)
	expect(
		_all_cells_are_reachable(ENEMY_ROUTE_CELLS, walkable_cells),
		"Every enemy spawn and patrol endpoint stays on the authored floor routes."
	)
	expect(
		_has_sealed_chokepoints(wall_grid),
		"Each locked passage is embedded in an unbroken GridMap wall and cannot be walked around."
	)
	expect(
		_has_correct_lock_requirements(level),
		"All three district doors require silver keys and only the final gate requires gold."
	)
	expect(
		_has_reversing_skeleton_patrols(level),
		"Every open skeleton path reverses at its endpoints instead of teleporting to its start."
	)
	expect(
		level_scene_text.count("instance=ExtResource(\"12_spike\")") == 6
			and level_scene_text.count("instance=ExtResource(\"13_skeleton\")") == 5
			and level_scene_text.count("instance=ExtResource(\"14_zombie\")") == 3
			and level_scene_text.count("instance=ExtResource(\"15_bat_nest\")") == 4,
		"The authored gauntlet includes a concentrated spike vault, five patrols, three hunters, and four bat nests."
	)
	expect(
		level_scene_text.count("instance=ExtResource(\"8_door\")") == 3
			and level_scene_text.count("instance=ExtResource(\"16_treasure\")") == 10
			and level_scene_text.count("instance=ExtResource(\"17_deposit\")") == 4,
		"Close Escape keeps three silver locks, ten treasure caches, and four deposit points."
	)
	expect(
		level_scene_text.count("instance=ExtResource(\"24_rolling_rock\")") == 2
			and level_scene_text.count("instance=ExtResource(\"25_millstone\")") == 1
			and level_scene_text.count("instance=ExtResource(\"26_hay_bale\")") == 2
			and level_scene_text.count("instance=ExtResource(\"27_breakable_wall\")") == 1,
		"Distinct districts use rolling obstacles and a breakable shortcut instead of repeating entrance spikes."
	)
	expect(
		_has_only_coin_caches(level)
			and level.get_node_or_null(^"EscapeWarning") == null
			and not level_scene_text.contains("text_trigger.tscn"),
		"Every cache contains only coins and the opening message has been removed."
	)
	var boundary := level.get_node(^"KillBoundary2") as GDKillBoundary2
	expect(
		_has_directed_room_phases(boundary),
		"The trailing flame leaves forward objectives open and closes completed ground without expansion gates."
	)
	layout.free()
	level.free()


func _find_walkable_cells(wall_grid: GridMap) -> Dictionary:
	var walkable_cells: Dictionary = {}
	for z in range(GRID_SIZE.y):
		for x in range(GRID_SIZE.x):
			if not _is_wall(wall_grid, Vector2i(x, z)):
				walkable_cells[Vector2i(x, z)] = true
	return walkable_cells


func _find_reachable_cells(
	start: Vector2i,
	walkable_cells: Dictionary,
	blocked_cells: Dictionary
) -> Dictionary:
	var reachable_cells: Dictionary = {}
	var frontier: Array[Vector2i] = [start]
	reachable_cells[start] = true
	var frontier_index := 0
	while frontier_index < frontier.size():
		var current_cell := frontier[frontier_index]
		frontier_index += 1
		for direction in CARDINAL_DIRECTIONS:
			var next_cell := current_cell + direction
			if not walkable_cells.has(next_cell):
				continue
			if blocked_cells.has(next_cell) or reachable_cells.has(next_cell):
				continue
			reachable_cells[next_cell] = true
			frontier.append(next_cell)
	return reachable_cells


func _to_cell_set(cells: Array[Vector2i]) -> Dictionary:
	var result: Dictionary = {}
	for cell in cells:
		result[cell] = true
	return result


func _all_cells_are_reachable(cells: Array[Vector2i], reachable_cells: Dictionary) -> bool:
	for cell in cells:
		if not reachable_cells.has(cell):
			return false
	return true


func _has_sealed_chokepoints(wall_grid: GridMap) -> bool:
	return (
		_is_wall(wall_grid, Vector2i(11, 20))
		and _is_wall(wall_grid, Vector2i(11, 22))
		and _is_wall(wall_grid, Vector2i(22, 6))
		and _is_wall(wall_grid, Vector2i(22, 8))
		and _is_wall(wall_grid, Vector2i(28, 17))
		and _is_wall(wall_grid, Vector2i(30, 17))
		and _is_wall(wall_grid, Vector2i(28, 0))
		and _is_wall(wall_grid, Vector2i(30, 0))
	)


func _is_wall(wall_grid: GridMap, cell: Vector2i) -> bool:
	var item := wall_grid.get_cell_item(Vector3i(cell.x, 0, cell.y))
	return item != GridMap.INVALID_CELL_ITEM and not wall_grid.mesh_library.get_item_shapes(item).is_empty()


func _has_correct_lock_requirements(level: Node3D) -> bool:
	var progression := level.get_node(^"Progression") as Node3D
	for door_name in [&"SilverDoor1", &"SilverDoor2", &"SilverDoor3"]:
		var door := progression.get_node(NodePath(door_name)) as GDLockableHingedPassage
		if door.key_requirement != GDLockableHingedPassage.KeyRequirement.SilverKey:
			return false
	var gate := progression.get_node(^"FinalGate") as GDLockableHingedPassage
	return (
		gate.key_requirement == GDLockableHingedPassage.KeyRequirement.GoldKey
		and gate.completes_level
	)


func _has_reversing_skeleton_patrols(level: Node3D) -> bool:
	var enemies := level.get_node(^"Enemies") as Node3D
	for skeleton_name in [&"SkeletonA", &"SkeletonB", &"SkeletonC", &"SkeletonD", &"SkeletonE"]:
		var skeleton := enemies.get_node(NodePath(skeleton_name)) as GDSkeletonPath
		if skeleton.loop_patrol or not skeleton.reverse_at_path_ends:
			return false
	return true


func _has_only_coin_caches(level: Node3D) -> bool:
	var treasure := level.get_node(^"Treasure") as Node3D
	if treasure.get_child_count() != 10:
		return false
	for child in treasure.get_children():
		if not child is GDGoldCoinPile or (child as GDGoldCoinPile).coin_count <= 0:
			return false
	return true


func _has_directed_room_phases(boundary: GDKillBoundary2) -> bool:
	var expected_times: Array[float] = [0.0, 32.0, 55.0, 105.0, 122.0, 140.0, 155.0, 170.0, 200.0, 215.0, 228.0, 239.0, 246.0]
	if (
		boundary.playback_mode != GDKillBoundary2Animator.PlaybackMode.SingleShot
		or not boundary.player_blocking_enabled
		or boundary.sequence.get_pose_count() != expected_times.size()
		or boundary.settings.boundary_segments != 64
	):
		return false
	for pose_index in expected_times.size():
		if not is_equal_approx(
			boundary.sequence.get_pose(pose_index).time_seconds,
			expected_times[pose_index]
		):
			return false

	# Forward access must not depend on waiting for an expansion. The east and north edges
	# remain fixed, while the trailing west and south edges advance into completed ground.
	for pose_index in expected_times.size():
		var pose := boundary.sequence.get_pose(pose_index)
		if not is_equal_approx(pose.position.x + pose.size.x * 0.5, 19.0):
			return false
		if not is_equal_approx(pose.position.z - pose.size.y * 0.5, -19.0):
			return false
		if pose_index == 0:
			continue
		var previous_pose := boundary.sequence.get_pose(pose_index - 1)
		if pose.size.x > previous_pose.size.x or pose.size.y > previous_pose.size.y:
			return false
	for target in TREASURE_CELLS + SILVER_KEY_CELLS + [GOLD_KEY_CELL, FINAL_GATE_CELL]:
		if not _pose_contains(boundary, 0, Vector2(target.x - 17, target.y - 14)):
			return false

	return (
		_pose_contains(boundary, 0, Vector2(-15, 11))
		and _pose_contains(boundary, 0, Vector2(-14, -10))
		and _pose_contains(boundary, 2, Vector2(3, 11))
		and _pose_contains(boundary, 5, Vector2(8, 0))
		and _pose_contains(boundary, 7, Vector2(16, 12))
		and _pose_contains(boundary, 12, Vector2(12, -14))
	)


func _pose_contains(boundary: GDKillBoundary2, pose_index: int, point: Vector2) -> bool:
	var pose := boundary.sequence.get_pose(pose_index)
	var perimeter := GDKillBoundary2Geometry.build_points(
		pose.size,
		pose.rounding,
		boundary.settings.boundary_segments
	)
	var local_point := point - Vector2(pose.position.x, pose.position.z)
	return GDKillBoundary2Geometry.get_signed_distance(local_point, perimeter) >= 0.0
