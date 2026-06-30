extends Node3D
class_name GDLockableHingedPassage


signal unlocked
signal level_completed

enum KeyRequirement { GOLD_KEY, SILVER_KEY }

const GOLD_KEY_ITEM_TYPE := &"key"
const SILVER_KEY_ITEM_TYPE := &"silver_key"
const WORLD_COLLISION_LAYER := 1
const PLAYER_COLLISION_LAYER := 2

@export var key_requirement := KeyRequirement.GOLD_KEY
@export var starts_locked := true
@export var completes_level := false
@export var leaf_root_path: NodePath = ^"Leaves"
@export var unlock_area_path: NodePath = ^"UnlockArea"
@export var completion_area_path: NodePath = ^"CompletionArea"
@export var unlock_audio_player_path: NodePath = ^"UnlockAudioPlayer"
@export_file("*.mp3", "*.wav") var unlock_sound_path := ""

var locked := true
var completion_emitted := false
var leaves: Array[Node] = []

@onready var unlock_area := get_node_or_null(unlock_area_path) as Area3D
@onready var completion_area := get_node_or_null(completion_area_path) as Area3D
@onready var unlock_audio_player := get_node_or_null(unlock_audio_player_path) as AudioStreamPlayer3D


func _ready() -> void:
	locked = starts_locked
	leaves = _get_hinged_leaves()
	_apply_lock_state()
	_configure_area(unlock_area)
	_configure_area(completion_area)
	_connect_areas()


func is_locked() -> bool:
	return locked


func is_unlocked() -> bool:
	return not locked


func try_unlock_with(body: Node) -> bool:
	if not locked:
		return true
	if body == null or not body.has_method("take_carried_item_of_type"):
		return false
	if not _is_unlock_body_in_reach(body):
		return false

	var item: Variant = body.take_carried_item_of_type(_required_item_type())
	if item == null:
		return false

	locked = false
	_apply_lock_state()
	_play_unlock_sound()
	unlocked.emit()
	return true


func try_complete_with(body: Node) -> bool:
	if not completes_level or locked or completion_emitted:
		return false
	if body == null or not (body is CharacterBody3D):
		return false

	completion_emitted = true
	level_completed.emit()
	return true


func _connect_areas() -> void:
	if unlock_area != null:
		unlock_area.body_entered.connect(_on_unlock_area_body_entered)
	if completion_area != null:
		completion_area.body_entered.connect(_on_completion_area_body_entered)


func _configure_area(area: Area3D) -> void:
	if area == null:
		return

	area.collision_layer = 0
	area.collision_mask = PLAYER_COLLISION_LAYER
	area.monitoring = true
	area.monitorable = true


func _on_unlock_area_body_entered(body: Node3D) -> void:
	try_unlock_with(body)


func _on_completion_area_body_entered(body: Node3D) -> void:
	try_complete_with(body)


func _apply_lock_state() -> void:
	for leaf in leaves:
		if leaf != null and leaf.has_method("set_locked"):
			leaf.set_locked(locked)


func _is_unlock_body_in_reach(body: Node) -> bool:
	if unlock_area != null and unlock_area.get_overlapping_bodies().has(body):
		return true

	var collision_body := body as CollisionObject3D
	if collision_body == null or not is_inside_tree():
		return false

	var space_state := get_world_3d().direct_space_state
	for collision_shape in _get_body_collision_shapes(collision_body):
		var query := PhysicsShapeQueryParameters3D.new()
		query.shape = collision_shape.shape
		query.transform = collision_shape.global_transform
		query.collision_mask = WORLD_COLLISION_LAYER
		query.collide_with_areas = false
		query.collide_with_bodies = true
		query.exclude = [collision_body.get_rid()]

		for hit in space_state.intersect_shape(query):
			var collider := hit.get("collider") as Object
			if _is_leaf_collider(collider):
				return true

	return false


func _get_body_collision_shapes(body: CollisionObject3D) -> Array[CollisionShape3D]:
	var collision_shapes: Array[CollisionShape3D] = []
	_collect_collision_shapes(body, collision_shapes)
	return collision_shapes


func _collect_collision_shapes(root: Node, collision_shapes: Array[CollisionShape3D]) -> void:
	var collision_shape := root as CollisionShape3D
	if collision_shape != null and not collision_shape.disabled and collision_shape.shape != null:
		collision_shapes.append(collision_shape)

	for child in root.get_children():
		_collect_collision_shapes(child, collision_shapes)


func _is_leaf_collider(collider: Object) -> bool:
	var node := collider as Node
	while node != null:
		if leaves.has(node):
			return true
		node = node.get_parent()

	return false


func _play_unlock_sound() -> void:
	if unlock_audio_player != null:
		unlock_audio_player.play()
		return

	if unlock_sound_path.is_empty():
		return

	var unlock_sound := GDAudio.load_stream(unlock_sound_path)
	GDAudio.play_one_shot_3d(self, unlock_sound, "UnlockAudioPlayer")


func _get_hinged_leaves() -> Array[Node]:
	var root := get_node_or_null(leaf_root_path)
	if root == null:
		root = self

	var found: Array[Node] = []
	_collect_hinged_leaves(root, found)
	return found


func _collect_hinged_leaves(root: Node, found: Array[Node]) -> void:
	if root != self and root.has_method("set_locked"):
		found.append(root)

	for child in root.get_children():
		_collect_hinged_leaves(child, found)


func _required_item_type() -> StringName:
	match key_requirement:
		KeyRequirement.GOLD_KEY:
			return GOLD_KEY_ITEM_TYPE
		KeyRequirement.SILVER_KEY:
			return SILVER_KEY_ITEM_TYPE
		_:
			return &""
