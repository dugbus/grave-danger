@tool
extends Node3D
class_name GDLevel05TreeSurround

const RENDER_ROOT_NAME := "TreeChunks"
const COLLISION_BODY_NAME := "TreeBlockers"

@export var tree_scene_paths: Array[String] = [
	"res://Assets/kenney-graveyard/pine.glb",
	"res://Assets/kenney-graveyard/pine-crooked.glb",
	"res://Assets/kenney-graveyard/pine-fall.glb",
]
@export_range(0.5, 16.0, 0.1) var tree_spacing := 2.0
@export_range(0.0, 8.0, 0.1) var inner_gap := 1.8
@export_range(4.0, 80.0, 0.5) var surround_depth := 20.0
@export_range(0.0, 4.0, 0.1) var placement_jitter := 1.1
@export_range(0.1, 4.0, 0.05) var minimum_tree_scale := 1.35
@export_range(0.1, 4.0, 0.05) var maximum_tree_scale := 4.2
@export_range(8.0, 64.0, 1.0) var chunk_size := 18.0
@export_range(0.0, 1.0, 0.01) var far_row_keep_chance := 0.72
@export_range(0.5, 12.0, 0.1) var blocker_thickness := 3.0
@export_range(2.0, 32.0, 0.5) var blocker_height := 14.0


func rebuild(level_size: Vector2, height_sampler: Callable, random_seed: int) -> void:
	_clear_generated()

	level_size = Vector2(maxf(level_size.x, 1.0), maxf(level_size.y, 1.0))
	var tree_meshes := _load_tree_meshes()
	if tree_meshes.is_empty():
		return

	var transforms_by_chunk := _build_tree_transforms(level_size, height_sampler, random_seed, tree_meshes.size())
	_create_tree_chunks(transforms_by_chunk, tree_meshes)
	_create_tree_blockers(level_size)
	_assign_editor_owners()


func _clear_generated() -> void:
	for child in get_children():
		remove_child(child)
		child.free()


func _load_tree_meshes() -> Array[Mesh]:
	var meshes: Array[Mesh] = []
	for scene_path in tree_scene_paths:
		var packed_scene := load(scene_path) as PackedScene
		if packed_scene == null:
			continue

		var scene_root := packed_scene.instantiate()
		var mesh_instance := _find_first_mesh_instance(scene_root)
		if mesh_instance != null and mesh_instance.mesh != null:
			meshes.append(mesh_instance.mesh)
		scene_root.free()

	return meshes


func _find_first_mesh_instance(root: Node) -> MeshInstance3D:
	if root is MeshInstance3D:
		return root as MeshInstance3D

	for child in root.get_children():
		var mesh_instance := _find_first_mesh_instance(child)
		if mesh_instance != null:
			return mesh_instance

	return null


func _build_tree_transforms(
	level_size: Vector2,
	height_sampler: Callable,
	random_seed: int,
	tree_mesh_count: int
) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = random_seed + 17041

	var transforms_by_chunk := {}
	var half_size := level_size * 0.5
	var outer_half := half_size - Vector2.ONE * inner_gap
	var inner_half := outer_half - Vector2.ONE * surround_depth

	var min_x := floori(-outer_half.x / tree_spacing) - 1
	var max_x := ceili(outer_half.x / tree_spacing) + 1
	var min_z := floori(-outer_half.y / tree_spacing) - 1
	var max_z := ceili(outer_half.y / tree_spacing) + 1

	for z_index in range(min_z, max_z + 1):
		for x_index in range(min_x, max_x + 1):
			var position_2d := Vector2(float(x_index) * tree_spacing, float(z_index) * tree_spacing)
			position_2d += Vector2(
				rng.randf_range(-placement_jitter, placement_jitter),
				rng.randf_range(-placement_jitter, placement_jitter)
			)

			if not _is_in_surround_ring(position_2d, inner_half, outer_half):
				continue

			var band_depth := _get_ring_depth(position_2d, inner_half)
			var keep_chance := lerpf(1.0, far_row_keep_chance, clampf(band_depth / surround_depth, 0.0, 1.0))
			if rng.randf() > keep_chance:
				continue

			var mesh_index := rng.randi_range(0, tree_mesh_count - 1)
			var transform := _build_tree_transform(position_2d, height_sampler, rng)
			var chunk_key := Vector3i(
				floori(position_2d.x / chunk_size),
				mesh_index,
				floori(position_2d.y / chunk_size)
			)

			if not transforms_by_chunk.has(chunk_key):
				transforms_by_chunk[chunk_key] = []
			transforms_by_chunk[chunk_key].append(transform)

	return transforms_by_chunk


func _is_in_surround_ring(position_2d: Vector2, inner_half: Vector2, outer_half: Vector2) -> bool:
	var abs_position := position_2d.abs()
	return (
		abs_position.x <= outer_half.x
		and abs_position.y <= outer_half.y
		and (abs_position.x >= inner_half.x or abs_position.y >= inner_half.y)
	)


func _get_ring_depth(position_2d: Vector2, inner_half: Vector2) -> float:
	var abs_position := position_2d.abs()
	return maxf(abs_position.x - inner_half.x, abs_position.y - inner_half.y)


func _build_tree_transform(position_2d: Vector2, height_sampler: Callable, rng: RandomNumberGenerator) -> Transform3D:
	var terrain_height := 0.0
	if height_sampler.is_valid():
		terrain_height = float(height_sampler.call(position_2d.x, position_2d.y))

	var tree_scale := rng.randf_range(minimum_tree_scale, maximum_tree_scale)
	var rotation := rng.randf_range(-PI, PI)
	var basis := Basis(Vector3.UP, rotation).scaled(Vector3.ONE * tree_scale)
	return Transform3D(basis, Vector3(position_2d.x, terrain_height, position_2d.y))


func _create_tree_chunks(transforms_by_chunk: Dictionary, tree_meshes: Array[Mesh]) -> void:
	var render_root := Node3D.new()
	render_root.name = RENDER_ROOT_NAME
	add_child(render_root)

	for chunk_key in transforms_by_chunk.keys():
		var transforms: Array = transforms_by_chunk[chunk_key]
		if transforms.is_empty():
			continue

		var mesh_index := (chunk_key as Vector3i).y
		var multimesh := MultiMesh.new()
		multimesh.transform_format = MultiMesh.TRANSFORM_3D
		multimesh.mesh = tree_meshes[mesh_index]
		multimesh.instance_count = transforms.size()
		multimesh.custom_aabb = _calculate_chunk_aabb(transforms)

		for index in transforms.size():
			multimesh.set_instance_transform(index, transforms[index])

		var chunk := MultiMeshInstance3D.new()
		chunk.name = "TreeChunk_%d_%d_model_%d" % [(chunk_key as Vector3i).x, (chunk_key as Vector3i).z, mesh_index]
		chunk.multimesh = multimesh
		chunk.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		chunk.gi_mode = GeometryInstance3D.GI_MODE_DISABLED
		_set_property_if_available(chunk, "ignore_occlusion_culling", false)
		render_root.add_child(chunk)


func _calculate_chunk_aabb(transforms: Array) -> AABB:
	var first_transform := transforms[0] as Transform3D
	var first_scale := _get_uniform_scale(first_transform)
	var bounds := AABB(
		first_transform.origin + Vector3(-1.0, -0.2, -1.0) * first_scale,
		Vector3(2.0, 3.2, 2.0) * first_scale
	)

	for index in range(1, transforms.size()):
		var transform := transforms[index] as Transform3D
		var scale := _get_uniform_scale(transform)
		var tree_bounds := AABB(
			transform.origin + Vector3(-1.0, -0.2, -1.0) * scale,
			Vector3(2.0, 3.2, 2.0) * scale
		)
		bounds = bounds.merge(tree_bounds)

	return bounds.grow(1.0)


func _get_uniform_scale(transform: Transform3D) -> float:
	var scale := transform.basis.get_scale()
	return maxf(maxf(absf(scale.x), absf(scale.y)), absf(scale.z))


func _create_tree_blockers(level_size: Vector2) -> void:
	var body := StaticBody3D.new()
	body.name = COLLISION_BODY_NAME
	body.collision_layer = 1
	body.collision_mask = 0
	add_child(body)

	var half_size := level_size * 0.5
	var center_y := blocker_height * 0.5 - 2.0
	var edge_offset := blocker_thickness * 0.5

	_add_blocker(
		body,
		"North",
		Vector3(0.0, center_y, half_size.y + edge_offset),
		Vector3(level_size.x + blocker_thickness * 2.0, blocker_height, blocker_thickness)
	)
	_add_blocker(
		body,
		"South",
		Vector3(0.0, center_y, -half_size.y - edge_offset),
		Vector3(level_size.x + blocker_thickness * 2.0, blocker_height, blocker_thickness)
	)
	_add_blocker(
		body,
		"East",
		Vector3(half_size.x + edge_offset, center_y, 0.0),
		Vector3(blocker_thickness, blocker_height, level_size.y)
	)
	_add_blocker(
		body,
		"West",
		Vector3(-half_size.x - edge_offset, center_y, 0.0),
		Vector3(blocker_thickness, blocker_height, level_size.y)
	)


func _add_blocker(body: StaticBody3D, blocker_name: String, local_position: Vector3, size: Vector3) -> void:
	var shape := BoxShape3D.new()
	shape.size = size

	var collision := CollisionShape3D.new()
	collision.name = blocker_name
	collision.position = local_position
	collision.shape = shape
	body.add_child(collision)


func _set_property_if_available(object: Object, property_name: StringName, value: Variant) -> void:
	for property in object.get_property_list():
		if property.get("name", "") == property_name:
			object.set(property_name, value)
			return


func _assign_editor_owners() -> void:
	if not Engine.is_editor_hint() or not is_inside_tree():
		return

	var edited_scene_root := get_tree().edited_scene_root
	if edited_scene_root == null:
		return

	_assign_owner_recursive(self, edited_scene_root)


func _assign_owner_recursive(node: Node, edited_scene_root: Node) -> void:
	if node != edited_scene_root:
		node.owner = edited_scene_root

	for child in node.get_children():
		_assign_owner_recursive(child, edited_scene_root)
