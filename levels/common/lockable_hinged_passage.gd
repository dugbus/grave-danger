extends Node3D
class_name GDLockableHingedPassage


signal unlocked
signal level_completed

enum KeyRequirement { GOLD_KEY, SILVER_KEY }

const GOLD_KEY_ITEM_TYPE := &"key"
const SILVER_KEY_ITEM_TYPE := &"silver_key"
const PLAYER_COLLISION_LAYER := 2

@export var key_requirement := KeyRequirement.GOLD_KEY
@export var starts_locked := true
@export var completes_level := false
@export var leaf_root_path: NodePath = ^"Leaves"
@export var unlock_area_path: NodePath = ^"UnlockArea"
@export var completion_area_path: NodePath = ^"CompletionArea"

var locked := true
var completion_emitted := false
var leaves: Array[Node] = []

@onready var unlock_area := get_node_or_null(unlock_area_path) as Area3D
@onready var completion_area := get_node_or_null(completion_area_path) as Area3D


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

	var item: Variant = body.take_carried_item_of_type(_required_item_type())
	if item == null:
		return false

	locked = false
	_apply_lock_state()
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
