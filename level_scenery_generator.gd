extends Node

const GENERATED_ROOT_NAME := "GeneratedScenery"
const NORTH := 1
const EAST := 2
const SOUTH := 4
const WEST := 8

@export_file("*.json") var map_file_path := "res://map-01.json"
@export var straight_fence_scene: PackedScene = preload("res://Assets/iron-fence.glb")
@export var corner_fence_scene: PackedScene = preload("res://Assets/iron-fence-curve.glb")
@export var crypt_large_scene: PackedScene = preload("res://Assets/rocks-tall.glb")
@export var isolated_scenery_scenes: Array[PackedScene] = [
	preload("res://Assets/altar-wood.glb"),
	preload("res://Assets/altar-stone.glb"),
	preload("res://Assets/cross-column.glb"),
	preload("res://Assets/rocks-tall.glb")
]
@export var tile_size := 1.0
@export var center_map := true


func _ready() -> void:
	generate()


func generate() -> void:
	var map_data := _load_map_data()
	if map_data.is_empty():
		return

	var obstacle_tiles: Array = map_data.get("obstacleTiles", [])
	if obstacle_tiles.is_empty():
		push_warning("Level scenery map has no obstacleTiles: %s" % map_file_path)
		return

	var width := int(map_data.get("width", _longest_row_width(obstacle_tiles)))
	var height := int(map_data.get("height", obstacle_tiles.size()))
	var tile_offset := Vector2.ZERO
	if center_map:
		tile_offset = Vector2((float(width) - 1.0) * 0.5, (float(height) - 1.0) * 0.5)

	var generated_root := _get_or_create_generated_root()
	_clear_children(generated_root)
	var handled_tiles := {}

	_create_isolated_crypts(generated_root, obstacle_tiles, tile_offset, handled_tiles)

	for row_index in obstacle_tiles.size():
		var row = obstacle_tiles[row_index]
		if not row is Array:
			push_warning("Skipping non-array map row %d in %s" % [row_index, map_file_path])
			continue

		for column_index in row.size():
			if _is_handled(handled_tiles, column_index, row_index):
				continue
			if int(row[column_index]) == 1:
				if _is_isolated_single(obstacle_tiles, column_index, row_index):
					_create_isolated_scenery(generated_root, column_index, row_index, tile_offset)
					_mark_handled(handled_tiles, column_index, row_index)
					continue
				_create_fence(generated_root, obstacle_tiles, column_index, row_index, tile_offset)


func _load_map_data() -> Dictionary:
	var map_file := FileAccess.open(map_file_path, FileAccess.READ)
	if map_file == null:
		push_error("Could not open level scenery map: %s" % map_file_path)
		return {}

	var parsed = JSON.parse_string(map_file.get_as_text())
	if not parsed is Dictionary:
		push_error("Level scenery map is not a JSON object: %s" % map_file_path)
		return {}

	return parsed


func _longest_row_width(rows: Array) -> int:
	var longest := 0
	for row in rows:
		if row is Array:
			longest = maxi(longest, row.size())
	return longest


func _get_or_create_generated_root() -> Node3D:
	var existing := get_node_or_null(GENERATED_ROOT_NAME)
	if existing is Node3D:
		return existing

	var generated_root := Node3D.new()
	generated_root.name = GENERATED_ROOT_NAME
	add_child(generated_root)
	return generated_root


func _clear_children(parent: Node) -> void:
	for child in parent.get_children():
		child.free()


func _create_isolated_crypts(
	parent: Node3D,
	obstacle_tiles: Array,
	tile_offset: Vector2,
	handled_tiles: Dictionary
) -> void:
	for row_index in obstacle_tiles.size() - 1:
		var row = obstacle_tiles[row_index]
		if not row is Array:
			continue

		for column_index in row.size() - 1:
			if _is_handled(handled_tiles, column_index, row_index):
				continue
			if _is_isolated_2x2_block(obstacle_tiles, column_index, row_index):
				_create_crypt(parent, column_index, row_index, tile_offset)
				_mark_handled(handled_tiles, column_index, row_index)
				_mark_handled(handled_tiles, column_index + 1, row_index)
				_mark_handled(handled_tiles, column_index, row_index + 1)
				_mark_handled(handled_tiles, column_index + 1, row_index + 1)


func _create_isolated_scenery(
	parent: Node3D,
	column_index: int,
	row_index: int,
	tile_offset: Vector2
) -> void:
	var scene := _get_isolated_scenery_scene(column_index, row_index)
	var scenery_node := _instantiate_node3d(scene, "isolated scenery")
	if scenery_node == null:
		return

	scenery_node.name = "Scenery_%02d_%02d" % [column_index, row_index]
	scenery_node.position = _get_tile_position(column_index, row_index, tile_offset)
	parent.add_child(scenery_node)
	_add_box_collision(scenery_node)


func _create_crypt(parent: Node3D, column_index: int, row_index: int, tile_offset: Vector2) -> void:
	var crypt_node := _instantiate_node3d(crypt_large_scene, "crypt")
	if crypt_node == null:
		return

	crypt_node.name = "CryptLarge_%02d_%02d" % [column_index, row_index]
	crypt_node.position = _get_tile_position(
		column_index,
		row_index,
		tile_offset,
		Vector2(0.5, 0.5)
	)
	parent.add_child(crypt_node)
	_add_box_collision(crypt_node)


func _create_fence(
	parent: Node3D,
	obstacle_tiles: Array,
	column_index: int,
	row_index: int,
	tile_offset: Vector2
) -> void:
	var neighbor_mask := _get_neighbor_mask(obstacle_tiles, column_index, row_index)
	var fence_scene := _get_fence_scene(neighbor_mask)
	if fence_scene == null:
		push_error("No fence scene configured for level scenery generator.")
		return

	var fence_node := _instantiate_node3d(fence_scene, "fence")
	if fence_node == null:
		return

	fence_node.name = "Fence_%02d_%02d" % [column_index, row_index]
	fence_node.position = _get_tile_position(column_index, row_index, tile_offset)
	fence_node.rotation.y = _get_fence_rotation(obstacle_tiles, column_index, row_index, neighbor_mask)
	parent.add_child(fence_node)
	_add_box_collision(fence_node)


func _get_neighbor_mask(obstacle_tiles: Array, column_index: int, row_index: int) -> int:
	var mask := 0
	if _is_fence_tile(obstacle_tiles, column_index, row_index - 1):
		mask |= NORTH
	if _is_fence_tile(obstacle_tiles, column_index + 1, row_index):
		mask |= EAST
	if _is_fence_tile(obstacle_tiles, column_index, row_index + 1):
		mask |= SOUTH
	if _is_fence_tile(obstacle_tiles, column_index - 1, row_index):
		mask |= WEST
	return mask


func _is_fence_tile(obstacle_tiles: Array, column_index: int, row_index: int) -> bool:
	if row_index < 0 or row_index >= obstacle_tiles.size():
		return false

	var row = obstacle_tiles[row_index]
	if not row is Array:
		return false
	if column_index < 0 or column_index >= row.size():
		return false

	return int(row[column_index]) == 1


func _is_isolated_single(obstacle_tiles: Array, column_index: int, row_index: int) -> bool:
	for row_offset in range(-1, 2):
		for column_offset in range(-1, 2):
			if row_offset == 0 and column_offset == 0:
				continue
			if _is_fence_tile(obstacle_tiles, column_index + column_offset, row_index + row_offset):
				return false
	return true


func _is_isolated_2x2_block(obstacle_tiles: Array, column_index: int, row_index: int) -> bool:
	if not _is_fence_tile(obstacle_tiles, column_index, row_index):
		return false
	if not _is_fence_tile(obstacle_tiles, column_index + 1, row_index):
		return false
	if not _is_fence_tile(obstacle_tiles, column_index, row_index + 1):
		return false
	if not _is_fence_tile(obstacle_tiles, column_index + 1, row_index + 1):
		return false

	for test_row in range(row_index - 1, row_index + 3):
		for test_column in range(column_index - 1, column_index + 3):
			var inside_block := (
				test_column >= column_index
				and test_column <= column_index + 1
				and test_row >= row_index
				and test_row <= row_index + 1
			)
			if inside_block:
				continue
			if _is_fence_tile(obstacle_tiles, test_column, test_row):
				return false
	return true


func _get_isolated_scenery_scene(column_index: int, row_index: int) -> PackedScene:
	if isolated_scenery_scenes.is_empty():
		push_error("No isolated scenery scenes configured for level scenery generator.")
		return null

	var model_key := absi(column_index * row_index) & 0x7fffffff
	return isolated_scenery_scenes[model_key % isolated_scenery_scenes.size()]


func _get_tile_position(
	column_index: int,
	row_index: int,
	tile_offset: Vector2,
	local_offset := Vector2.ZERO
) -> Vector3:
	return Vector3(
		(float(column_index) + local_offset.x - tile_offset.x) * tile_size,
		0.0,
		(float(row_index) + local_offset.y - tile_offset.y) * tile_size
	)


func _instantiate_node3d(scene: PackedScene, scene_label: String) -> Node3D:
	if scene == null:
		push_error("No %s scene configured for level scenery generator." % scene_label)
		return null

	var instance := scene.instantiate()
	if not instance is Node3D:
		push_error("Configured %s scene root is not a Node3D." % scene_label)
		instance.free()
		return null

	return instance as Node3D


func _add_box_collision(node: Node3D) -> void:
	var bounds := _calculate_local_mesh_bounds(node)
	if bounds.size.is_zero_approx():
		push_warning("Could not calculate collision bounds for %s." % node.name)
		return

	var static_body := StaticBody3D.new()
	static_body.name = "GeneratedCollision"
	static_body.collision_layer = 1
	static_body.collision_mask = 1

	var collision_shape := CollisionShape3D.new()
	collision_shape.name = "CollisionShape3D"
	var box_shape := BoxShape3D.new()
	box_shape.size = bounds.size
	collision_shape.shape = box_shape
	collision_shape.position = bounds.get_center()

	static_body.add_child(collision_shape)
	node.add_child(static_body)


func _calculate_local_mesh_bounds(root: Node3D) -> AABB:
	var has_bounds := false
	var combined_bounds := AABB()
	var root_inverse := root.global_transform.affine_inverse()

	for mesh_instance in _find_mesh_instances(root):
		var mesh_bounds := _transform_aabb(root_inverse * mesh_instance.global_transform, mesh_instance.get_aabb())
		if not has_bounds:
			combined_bounds = mesh_bounds
			has_bounds = true
		else:
			combined_bounds = combined_bounds.merge(mesh_bounds)

	if not has_bounds:
		return AABB()
	return combined_bounds


func _find_mesh_instances(root: Node) -> Array[MeshInstance3D]:
	var mesh_instances: Array[MeshInstance3D] = []
	if root is MeshInstance3D:
		mesh_instances.append(root as MeshInstance3D)

	for child in root.get_children():
		mesh_instances.append_array(_find_mesh_instances(child))

	return mesh_instances


func _transform_aabb(transform: Transform3D, bounds: AABB) -> AABB:
	var transformed_bounds := AABB(transform * bounds.position, Vector3.ZERO)
	for corner_index in range(1, 8):
		transformed_bounds = transformed_bounds.expand(transform * _get_aabb_corner(bounds, corner_index))
	return transformed_bounds


func _get_aabb_corner(bounds: AABB, corner_index: int) -> Vector3:
	return Vector3(
		bounds.position.x + bounds.size.x * float(corner_index & 1),
		bounds.position.y + bounds.size.y * float((corner_index >> 1) & 1),
		bounds.position.z + bounds.size.z * float((corner_index >> 2) & 1)
	)


func _is_handled(handled_tiles: Dictionary, column_index: int, row_index: int) -> bool:
	return handled_tiles.has(_get_tile_key(column_index, row_index))


func _mark_handled(handled_tiles: Dictionary, column_index: int, row_index: int) -> void:
	handled_tiles[_get_tile_key(column_index, row_index)] = true


func _get_tile_key(column_index: int, row_index: int) -> String:
	return "%d,%d" % [column_index, row_index]


func _get_fence_scene(neighbor_mask: int) -> PackedScene:
	if _is_corner(neighbor_mask):
		return corner_fence_scene
	return straight_fence_scene


func _is_corner(neighbor_mask: int) -> bool:
	return (
		neighbor_mask == (NORTH | EAST)
		or neighbor_mask == (EAST | SOUTH)
		or neighbor_mask == (SOUTH | WEST)
		or neighbor_mask == (WEST | NORTH)
	)


func _get_fence_rotation(
	obstacle_tiles: Array,
	column_index: int,
	row_index: int,
	neighbor_mask: int
) -> float:
	if neighbor_mask == (EAST | SOUTH):
		return 0.0
	if neighbor_mask == (SOUTH | WEST):
		return -PI * 0.5
	if neighbor_mask == (WEST | NORTH):
		return PI
	if neighbor_mask == (NORTH | EAST):
		return PI * 0.5
	if _uses_vertical_straight(neighbor_mask):
		return _get_vertical_straight_rotation_from_corners(obstacle_tiles, column_index, row_index)
	return _get_horizontal_straight_rotation_from_corners(obstacle_tiles, column_index, row_index)


func _uses_vertical_straight(neighbor_mask: int) -> bool:
	if (neighbor_mask & (NORTH | SOUTH)) == (NORTH | SOUTH):
		return true

	var has_vertical_neighbor := (neighbor_mask & (NORTH | SOUTH)) != 0
	var has_horizontal_neighbor := (neighbor_mask & (EAST | WEST)) != 0
	return has_vertical_neighbor and not has_horizontal_neighbor


func _get_horizontal_straight_rotation_from_corners(
	obstacle_tiles: Array,
	column_index: int,
	row_index: int
) -> float:
	var west_corner_side := _find_horizontal_corner_side(obstacle_tiles, column_index, row_index, -1)
	var east_corner_side := _find_horizontal_corner_side(obstacle_tiles, column_index, row_index, 1)
	var corner_side := _choose_corner_side(west_corner_side, east_corner_side)
	if corner_side == NORTH:
		return PI
	return 0.0


func _get_vertical_straight_rotation_from_corners(
	obstacle_tiles: Array,
	column_index: int,
	row_index: int
) -> float:
	var north_corner_side := _find_vertical_corner_side(obstacle_tiles, column_index, row_index, -1)
	var south_corner_side := _find_vertical_corner_side(obstacle_tiles, column_index, row_index, 1)
	var corner_side := _choose_corner_side(north_corner_side, south_corner_side)
	if corner_side == WEST:
		return -PI * 0.5
	return PI * 0.5


func _find_horizontal_corner_side(
	obstacle_tiles: Array,
	column_index: int,
	row_index: int,
	column_step: int
) -> int:
	var test_column := column_index + column_step
	while _is_fence_tile(obstacle_tiles, test_column, row_index):
		var neighbor_mask := _get_neighbor_mask(obstacle_tiles, test_column, row_index)
		if _is_corner(neighbor_mask):
			if (neighbor_mask & NORTH) != 0:
				return NORTH
			if (neighbor_mask & SOUTH) != 0:
				return SOUTH
		test_column += column_step
	return 0


func _find_vertical_corner_side(
	obstacle_tiles: Array,
	column_index: int,
	row_index: int,
	row_step: int
) -> int:
	var test_row := row_index + row_step
	while _is_fence_tile(obstacle_tiles, column_index, test_row):
		var neighbor_mask := _get_neighbor_mask(obstacle_tiles, column_index, test_row)
		if _is_corner(neighbor_mask):
			if (neighbor_mask & EAST) != 0:
				return EAST
			if (neighbor_mask & WEST) != 0:
				return WEST
		test_row += row_step
	return 0


func _choose_corner_side(first_corner_side: int, second_corner_side: int) -> int:
	if first_corner_side != 0 and first_corner_side == second_corner_side:
		return first_corner_side
	if first_corner_side != 0:
		return first_corner_side
	return second_corner_side
