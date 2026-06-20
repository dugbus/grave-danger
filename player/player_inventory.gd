extends Node
class_name GDPlayerInventory


const GOLD_COIN_ITEM_TYPE := &"gold_coin"
const DEFAULT_GOLD_COIN_ITEM := preload("res://inventory/items/gold_coin.tres")

# A carried item can only be collected if it is roughly in front of the character.
const PICKUP_FACING_DOT = 0.35

# Where dropped items are placed relative to the player.
const DROP_BACK_DISTANCE = 0.75
const DROP_UPWARD_OFFSET = 0.28

# How quickly held drop input sheds carried items.
const DROP_REPEAT_INTERVAL = 0.02

# How much space a dropped coin needs, and how hard nearby coins are nudged.
const DROP_CLEAR_RADIUS = 0.18
const DROP_NUDGE_RADIUS = 0.35
const DROP_NUDGE_IMPULSE = 0.025
const COIN_SOUND_VOLUME_OFFSET_DB := -2.5
const COIN_SOUND_PITCH_MIN := 0.86
const COIN_SOUND_PITCH_MAX := 1.0
const ITEM_SOUND_PITCH_MIN := 0.92
const ITEM_SOUND_PITCH_MAX := 1.1
const ITEM_SOUND_VOLUME_MIN_DB := -4.0
const ITEM_SOUND_VOLUME_MAX_DB := 0.5

signal item_count_changed(item_type: StringName, carried_count: int)
signal carried_gold_coins_changed(carried_count: int)

## Visual pivot used to determine pickup facing and drop direction.
@export var pivot_path: NodePath = ^"../Pivot"
## Total carried item weight the bag can hold.
@export var max_carry_weight := 100.0

@onready var player := get_parent() as CharacterBody3D
@onready var pivot: Node3D = get_node_or_null(pivot_path)

var carried_items := {}
var drop_cooldown := 0.0


func update_drop_input(delta: float) -> void:
	if not Input.is_action_pressed("drop_carried"):
		drop_cooldown = 0.0
		return

	drop_cooldown -= delta
	if drop_cooldown > 0.0:
		return

	drop_next_item()
	drop_cooldown = DROP_REPEAT_INTERVAL


func try_collect_item_pickup(pickup: Node3D) -> bool:
	if pickup == null or not pickup.has_method("get_carried_item"):
		return false

	var item: Resource = pickup.get_carried_item()
	var item_type := _item_type(item)
	if item == null or item_type == &"":
		return false
	if _item_requires_facing_for_pickup(item) and not _is_facing(pickup.global_position):
		return false
	if get_item_count(item_type) >= _item_max_count(item):
		return _drop_unstored_pickup(item)
	if not _make_room_for_item(item):
		return _drop_unstored_pickup(item)

	_add_item(item)
	_play_item_sound(item, _item_pickup_sound(item), "PickupItemAudio")
	return true


func drop_next_item() -> bool:
	var item: Resource = _get_next_drop_item()
	if item == null:
		return false

	return drop_item_of_type(_item_type(item))


func drop_item_of_type(item_type: StringName) -> bool:
	var item: Resource = peek_item_of_type(item_type)
	if item == null or player == null or pivot == null:
		return false

	if not _spawn_dropped_item(item):
		return false

	take_item(item_type)
	_play_item_sound(item, _item_drop_sound(item), "DropItemAudio")
	return true


func _spawn_dropped_item(item: Resource) -> bool:
	if item == null or player == null or pivot == null:
		return false

	var scene := load(_item_world_scene_path(item)) as PackedScene
	if scene == null:
		push_warning("Inventory item '%s' has no valid world scene." % String(_item_type(item)))
		return false

	var dropped_item := scene.instantiate() as Node3D
	if dropped_item == null:
		return false

	var spawn_parent := get_tree().current_scene
	if spawn_parent == null:
		spawn_parent = player.get_parent()
	spawn_parent.add_child(dropped_item)

	var forward := pivot.global_transform.basis.z.normalized()
	var back := -forward
	var spawn_position := _find_drop_position(item, player.global_position + back * DROP_BACK_DISTANCE, back)
	var spawn_transform := Transform3D(Basis(), spawn_position + Vector3.UP * DROP_UPWARD_OFFSET)
	if dropped_item.has_method("throw_from"):
		dropped_item.throw_from(spawn_transform, Vector3.ZERO)
	else:
		dropped_item.global_transform = spawn_transform

	return true


func take_item(item_type: StringName, count := 1) -> bool:
	count = maxi(count, 1)
	if get_item_count(item_type) < count:
		return false

	var entry: Dictionary = carried_items[item_type]
	entry["count"] = int(entry["count"]) - count
	carried_items[item_type] = entry
	if int(entry["count"]) <= 0:
		carried_items.erase(item_type)

	_emit_item_count_changed(item_type)
	return true


func take_item_of_type(item_type: StringName):
	var item: Resource = peek_item_of_type(item_type)
	if item == null:
		return null

	take_item(item_type)
	return item


func peek_item_of_type(item_type: StringName) -> Resource:
	if not carried_items.has(item_type):
		return null

	var entry: Dictionary = carried_items[item_type]
	return entry.get("item") as Resource


func has_item_type(item_type: StringName) -> bool:
	return get_item_count(item_type) > 0


func get_item_count(item_type: StringName) -> int:
	if not carried_items.has(item_type):
		return 0

	var entry: Dictionary = carried_items[item_type]
	return int(entry.get("count", 0))


func get_carried_weight() -> float:
	var total := 0.0
	for item_type in carried_items.keys():
		var item: Resource = peek_item_of_type(item_type)
		if item == null:
			continue

		total += _item_weight(item) * float(get_item_count(_item_type(item)))

	return total


func try_collect_gold_coin(gold_coin: Node3D) -> bool:
	return try_collect_item_pickup(gold_coin)


func spend_carried_gold_coin() -> bool:
	return take_item(GOLD_COIN_ITEM_TYPE)


func get_carried_gold_coins() -> int:
	return get_item_count(GOLD_COIN_ITEM_TYPE)


func get_max_carried_gold_coins() -> int:
	var item: Resource = peek_item_of_type(GOLD_COIN_ITEM_TYPE)
	if item != null:
		return _item_max_count(item)

	return _item_max_count(DEFAULT_GOLD_COIN_ITEM)


func weight_multiplier(empty_value: float, full_value: float) -> float:
	return lerpf(empty_value, full_value, _weight_ratio())


func _add_item(item: Resource) -> void:
	var item_type := _item_type(item)
	var entry: Dictionary = carried_items.get(item_type, {"item": item, "count": 0})
	entry["item"] = item
	entry["count"] = int(entry["count"]) + 1
	carried_items[item_type] = entry
	_emit_item_count_changed(item_type)


func _get_next_drop_item() -> Resource:
	var best_item: Resource = null
	for item_type in carried_items.keys():
		var item: Resource = peek_item_of_type(item_type)
		if item == null or get_item_count(_item_type(item)) <= 0:
			continue
		if best_item == null or _item_drop_order(item) < _item_drop_order(best_item):
			best_item = item

	return best_item


func _make_room_for_item(item: Resource) -> bool:
	var required_weight := _item_weight(item)
	if get_carried_weight() + required_weight <= max_carry_weight:
		return true

	while get_carried_weight() + required_weight > max_carry_weight:
		var shed_item := _get_next_auto_shed_item(item)
		if shed_item == null:
			return false
		if not drop_item_of_type(_item_type(shed_item)):
			return false

	return true


func _drop_unstored_pickup(item: Resource) -> bool:
	if _item_type(item) != GOLD_COIN_ITEM_TYPE:
		return false
	if not _spawn_dropped_item(item):
		return false

	_play_item_sound(item, _item_drop_sound(item), "DropItemAudio")
	return true


func _get_next_auto_shed_item(incoming_item: Resource) -> Resource:
	var best_item: Resource = null
	var incoming_drop_order := _item_drop_order(incoming_item)
	for item_type in carried_items.keys():
		var item: Resource = peek_item_of_type(item_type)
		if item == null or get_item_count(_item_type(item)) <= 0:
			continue
		if _item_drop_order(item) >= incoming_drop_order:
			continue
		if best_item == null or _item_drop_order(item) < _item_drop_order(best_item):
			best_item = item

	return best_item


func _find_drop_position(item: Resource, base_position: Vector3, back: Vector3) -> Vector3:
	if _item_type(item) == GOLD_COIN_ITEM_TYPE:
		_nudge_blocking_coins(base_position, back)

	var right := back.cross(Vector3.UP).normalized()
	var offsets: Array[Vector3] = [
		Vector3.ZERO,
		back * DROP_CLEAR_RADIUS,
		right * DROP_CLEAR_RADIUS,
		-right * DROP_CLEAR_RADIUS,
		(back + right).normalized() * DROP_CLEAR_RADIUS,
		(back - right).normalized() * DROP_CLEAR_RADIUS,
		right * DROP_CLEAR_RADIUS * 2.0,
		-right * DROP_CLEAR_RADIUS * 2.0,
		back * DROP_CLEAR_RADIUS * 2.0,
	]

	for offset: Vector3 in offsets:
		var candidate: Vector3 = base_position + offset
		if not _is_drop_position_blocked(item, candidate):
			return candidate

	return base_position


func _is_drop_position_blocked(item: Resource, position: Vector3) -> bool:
	if _item_type(item) != GOLD_COIN_ITEM_TYPE:
		return false

	for coin in get_tree().get_nodes_in_group("gold_coin"):
		if not coin is Node3D:
			continue

		var coin_position := (coin as Node3D).global_position
		var delta := Vector2(coin_position.x - position.x, coin_position.z - position.z)
		if delta.length() < DROP_CLEAR_RADIUS:
			return true

	return false


func _nudge_blocking_coins(position: Vector3, fallback_direction: Vector3) -> void:
	for coin in get_tree().get_nodes_in_group("gold_coin"):
		if not coin is RigidBody3D:
			continue

		var rigid_coin := coin as RigidBody3D
		var offset := rigid_coin.global_position - position
		offset.y = 0.0
		var distance := offset.length()
		if distance >= DROP_NUDGE_RADIUS:
			continue

		var direction := offset.normalized() if distance > 0.001 else fallback_direction
		var strength := 1.0 - clampf(distance / DROP_NUDGE_RADIUS, 0.0, 1.0)
		rigid_coin.apply_impulse(direction * DROP_NUDGE_IMPULSE * strength)


func _is_facing(world_position: Vector3) -> bool:
	if player == null or pivot == null:
		return false

	var to_position := world_position - player.global_position
	to_position.y = 0.0
	if to_position.is_zero_approx():
		return true

	var forward := pivot.global_transform.basis.z
	forward.y = 0.0
	return forward.normalized().dot(to_position.normalized()) >= PICKUP_FACING_DOT


func _weight_ratio() -> float:
	return clampf(get_carried_weight() / maxf(max_carry_weight, 1.0), 0.0, 1.0)


func _emit_item_count_changed(item_type: StringName) -> void:
	var carried_count := get_item_count(item_type)
	item_count_changed.emit(item_type, carried_count)
	if item_type == GOLD_COIN_ITEM_TYPE:
		carried_gold_coins_changed.emit(carried_count)


func _item_type(item: Resource) -> StringName:
	return item.get("item_type") if item != null else &""


func _item_max_count(item: Resource) -> int:
	return maxi(int(item.get("max_count")), 1) if item != null else 1


func _item_weight(item: Resource) -> float:
	return maxf(float(item.get("weight")), 0.0) if item != null else 0.0


func _item_drop_order(item: Resource) -> int:
	return int(item.get("drop_order")) if item != null else 100


func _item_world_scene_path(item: Resource) -> String:
	return String(item.get("world_scene_path")) if item != null else ""


func _item_requires_facing_for_pickup(item: Resource) -> bool:
	return bool(item.get("require_facing_for_pickup")) if item != null else false


func _item_pickup_sound(item: Resource) -> AudioStream:
	return item.get("pickup_sound") as AudioStream if item != null else null


func _item_drop_sound(item: Resource) -> AudioStream:
	return item.get("drop_sound") as AudioStream if item != null else null


func _play_item_sound(item: Resource, sound: AudioStream, player_name: String) -> void:
	if sound == null:
		return

	var sound_player := AudioStreamPlayer.new()
	sound_player.name = player_name if not player_name.is_empty() else "InventoryItemAudio"
	sound_player.stream = sound
	if _item_type(item) == GOLD_COIN_ITEM_TYPE:
		sound_player.pitch_scale = randf_range(COIN_SOUND_PITCH_MIN, COIN_SOUND_PITCH_MAX)
		sound_player.volume_db = randf_range(
			ITEM_SOUND_VOLUME_MIN_DB + COIN_SOUND_VOLUME_OFFSET_DB,
			ITEM_SOUND_VOLUME_MAX_DB + COIN_SOUND_VOLUME_OFFSET_DB
		)
	else:
		sound_player.pitch_scale = randf_range(ITEM_SOUND_PITCH_MIN, ITEM_SOUND_PITCH_MAX)
		sound_player.volume_db = randf_range(ITEM_SOUND_VOLUME_MIN_DB, ITEM_SOUND_VOLUME_MAX_DB)
	sound_player.finished.connect(sound_player.queue_free)

	if player != null:
		player.add_child(sound_player)
	else:
		add_child(sound_player)

	sound_player.play()
