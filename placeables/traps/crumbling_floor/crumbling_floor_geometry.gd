@tool
extends RefCounted

## Reads the source once; tiles share immutable layouts, one box mesh, and cached primitive shapes.
const ASSET_PATH := "res://Assets/environment/flagstone.glb"
const THICKNESS := 0.25

enum PhysicsLayer { None = 0, Floor = 1, Player = 2 }

var _source_blocks: Array[AABB] = []
var _source_bounds := AABB()
var _source_material: Material
var _layouts: Dictionary[Vector3, Array] = {}
var _shapes: Dictionary[Vector3, BoxShape3D] = {}
var _unit_mesh: BoxMesh


## Only weakly retain the shared cache: the last tile or support owner releases all cached resources.
static func shared(script: GDScript) -> RefCounted:
	# The owner supplies the script to avoid a strong self-reference in this script's compiled constants.
	var geometry: RefCounted
	var shared_ref: WeakRef
	if script.has_meta(&"shared_geometry"):
		shared_ref = script.get_meta(&"shared_geometry") as WeakRef
	if shared_ref != null:
		geometry = shared_ref.get_ref() as RefCounted
	if geometry == null:
		geometry = script.new() as RefCounted
		script.set_meta(&"shared_geometry", weakref(geometry))
	return geometry


func populate_visual(visual: MultiMeshInstance3D, size: Vector3, material: Material) -> Material:
	var blocks := describe_blocks(size)
	var batch := MultiMesh.new()
	batch.transform_format = MultiMesh.TRANSFORM_3D
	batch.mesh = unit_mesh()
	batch.instance_count = blocks.size()
	batch.custom_aabb = AABB(Vector3(-size.x * 0.5, -size.y, -size.z * 0.5), size)
	visual.multimesh = batch
	visual.material_override = material if material != null else _source_material
	set_visual_offset(visual, blocks, Vector3.ZERO)
	return visual.material_override


## Equal cell dimensions share one read-only block layout rather than copying nodes or dictionaries.
func describe_blocks(size: Vector3) -> Array[AABB]:
	if _layouts.has(size):
		return _layouts[size] as Array[AABB]
	_load_source()
	var scale_value := size / _source_bounds.size
	var blocks: Array[AABB] = []
	for source in _source_blocks:
		var centre := (source.get_center() - _source_bounds.get_center()) * scale_value
		centre.y -= size.y * 0.5
		var extent := source.size * scale_value
		blocks.append(AABB(centre - extent * 0.5, extent))
	blocks.make_read_only()
	_layouts[size] = blocks
	return blocks


func set_visual_offset(visual: MultiMeshInstance3D, blocks: Array[AABB], offset: Vector3) -> void:
	for index in blocks.size():
		var bounds := blocks[index]
		visual.multimesh.set_instance_transform(
			index, Transform3D(Basis.from_scale(bounds.size), bounds.get_center() + offset)
		)


func box_shape(size: Vector3) -> BoxShape3D:
	if not _shapes.has(size):
		var shape := BoxShape3D.new()
		shape.size = size
		_shapes[size] = shape
	return _shapes[size]


func unit_mesh() -> BoxMesh:
	if _unit_mesh == null:
		_unit_mesh = BoxMesh.new()
		_unit_mesh.size = Vector3.ONE
	return _unit_mesh


## Debris remains ordinary short-lived rigid bodies, created only as blocks actually fall.
func release_fragment(
	container: Node3D,
	bounds: AABB,
	material: Material,
	seed_value: int,
	block_index: int,
	scatter: float,
	angular: float
) -> RigidBody3D:
	var random := RandomNumberGenerator.new()
	random.seed = hash(Vector2i(seed_value, block_index))
	var body := RigidBody3D.new()
	body.collision_layer = PhysicsLayer.None
	body.collision_mask = PhysicsLayer.Floor
	body.position = bounds.get_center()
	var fragment := MeshInstance3D.new()
	fragment.mesh = unit_mesh()
	fragment.scale = bounds.size
	fragment.material_override = material
	body.add_child(fragment)
	var collision := CollisionShape3D.new()
	collision.shape = box_shape(bounds.size)
	body.add_child(collision)
	container.add_child(body)
	var outward := Vector3(body.position.x, 0.0, body.position.z).normalized()
	body.apply_central_impulse(container.global_basis.orthonormalized() * outward * scatter)
	body.angular_velocity = Vector3(
		random.randf_range(-angular, angular),
		random.randf_range(-angular, angular),
		random.randf_range(-angular, angular)
	)
	return body


func _load_source() -> void:
	if not _source_blocks.is_empty():
		return
	var asset := _instantiate_asset()
	if asset != null:
		_collect_source(asset, Transform3D.IDENTITY)
		asset.free()
	if _source_blocks.is_empty():
		_source_blocks.append(AABB(Vector3(-0.5, -THICKNESS, -0.5), Vector3(1.0, THICKNESS, 1.0)))
	_source_bounds = _source_blocks[0]
	for bounds in _source_blocks:
		_source_bounds = _source_bounds.merge(bounds)
	_source_blocks.make_read_only()


func _collect_source(node: Node3D, parent_transform: Transform3D) -> void:
	var current := parent_transform * node.transform
	if node is MeshInstance3D:
		var mesh := node as MeshInstance3D
		_source_blocks.append(current * mesh.get_aabb())
		if _source_material == null and mesh.mesh != null and mesh.mesh.get_surface_count() > 0:
			_source_material = mesh.get_active_material(0)
	for child in node.get_children():
		if child is Node3D:
			_collect_source(child as Node3D, current)


## Read the source in development; exported games use Godot's packaged imported scene.
func _instantiate_asset() -> Node3D:
	if FileAccess.file_exists(ASSET_PATH):
		var document := GLTFDocument.new()
		var state := GLTFState.new()
		if document.append_from_file(ASSET_PATH, state) == OK:
			return document.generate_scene(state) as Node3D
	elif ResourceLoader.exists(ASSET_PATH):
		var packed := load(ASSET_PATH) as PackedScene
		if packed != null:
			return packed.instantiate() as Node3D
	return null
