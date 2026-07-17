extends Node
class_name GDPlayerInventory


const GOLD_COIN_ITEM_TYPE := &"gold_coin"
const GEM_ITEM_TYPES: Array[StringName] = [
	&"diamond",
	&"ruby",
	&"sapphire",
	&"emerald",
	&"amethyst",
]
const DETERMINISTIC_SEED := preload("res://game/deterministic_seed.gd")

# A carried item can only be collected if it is roughly in front of the character.
const PICKUP_FACING_DOT = 0.35

# Where dropped items are placed relative to the player.
const DROP_BACK_DISTANCE = 0.75
const DROP_UPWARD_OFFSET = 0.28

# How quickly held drop input starts and finishes shedding carried items.
const DROP_REPEAT_START_INTERVAL := 0.06
const DROP_REPEAT_MIN_INTERVAL := 1.0 / 120.0
const DROP_REPEAT_ACCELERATION_TIME := 0.75
# Maximum sideways angle applied to the direction of each dropped item.
const DROP_DIRECTION_VARIANCE_RADIANS := PI / 15.0

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
signal inventory_capacity_changed(max_units: int)

## Visual pivot used to determine pickup facing and drop direction.
@export var pivot_path: NodePath = ^"../Pivot"
## Total carried item weight the bag can hold.
@export var max_carry_weight := 100.0

@onready var player := get_parent() as CharacterBody3D
@onready var pivot: Node3D = get_node_or_null(pivot_path)

var carried_items := {}
var drop_cooldown := 0.0
var drop_hold_time := 0.0
var bonus_inventory_space := 0
var audio_rng := RandomNumberGenerator.new()
var drop_position_rng := RandomNumberGenerator.new()


func _ready() -> void:
	audio_rng.seed = DETERMINISTIC_SEED.from_node(self, 0, &"player_inventory_audio")
	drop_position_rng.seed = DETERMINISTIC_SEED.from_node(self, 0, &"player_inventory_drop_position")


func update_drop_input(delta: float) -> void:
	if not Input.is_action_pressed("drop_carried"):
		drop_cooldown = 0.0
		drop_hold_time = 0.0
		return

	drop_hold_time += delta
	drop_cooldown -= delta
	while drop_cooldown <= 0.0:
		if not drop_next_item():
			return
		drop_cooldown += _get_drop_repeat_interval(drop_hold_time)


func _get_drop_repeat_interval(hold_time: float) -> float:
	var acceleration_ratio := clampf(hold_time / DROP_REPEAT_ACCELERATION_TIME, 0.0, 1.0)
	var curved_ratio := acceleration_ratio * acceleration_ratio
	return lerpf(DROP_REPEAT_START_INTERVAL, DROP_REPEAT_MIN_INTERVAL, curved_ratio)


func try_collect_item_pickup(pickup: Node3D) -> bool:
	if pickup == null or not pickup.has_method("get_carried_item"):
		return false

	var item: Resource = pickup.get_carried_item()
	var item_type := _item_type(item)
	if item == null or item_type == &"":
		return false
	if _item_requires_facing_for_pickup(item) and not _is_facing(pickup.global_position):
		return false
	if get_item_count(item_type) >= _get_effective_item_max_count(item):
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
	var back := _get_varied_drop_direction(-forward)
	var spawn_position := _find_drop_position(item, player.global_position + back * DROP_BACK_DISTANCE, back)
	var spawn_transform := Transform3D(Basis(), spawn_position + Vector3.UP * DROP_UPWARD_OFFSET)
	if dropped_item.has_method("throw_from"):
		dropped_item.throw_from(spawn_transform, Vector3.ZERO)
	else:
		dropped_item.global_transform = spawn_transform

	return true


func _get_varied_drop_direction(back: Vector3) -> Vector3:
	var angle := drop_position_rng.randf_range(
		-DROP_DIRECTION_VARIANCE_RADIANS,
		DROP_DIRECTION_VARIANCE_RADIANS
	)
	return back.rotated(Vector3.UP, angle).normalized()


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
	for item_type in _get_sorted_carried_item_types():
		var item: Resource = peek_item_of_type(item_type)
		if item == null:
			continue

		total += _item_weight(item) * float(get_item_count(_item_type(item)))

	return total


## Returns the score value of all treasure currently carried in the sack.
func get_carried_treasure_value() -> int:
	var total := 0
	for item_type in _get_sorted_carried_item_types():
		var item: Resource = peek_item_of_type(item_type)
		if item == null:
			continue

		total += _item_treasure_value(item) * get_item_count(_item_type(item))

	return total


## Returns the occupied sack capacity shown to the player.
func get_used_inventory_units() -> int:
	return ceili(get_carried_weight())


## Returns the total sack capacity shown to the player.
func get_max_inventory_units() -> int:
	return maxi(floori(max_carry_weight), 1)


## Removes and returns the most valuable carried treasure available for depositing.
func take_highest_value_carried_treasure() -> Resource:
	var best_item: Resource = null
	for item_type in _get_sorted_carried_item_types():
		var item: Resource = peek_item_of_type(item_type)
		if item == null or _item_treasure_value(item) <= 0:
			continue
		if best_item == null or _item_treasure_value(item) > _item_treasure_value(best_item):
			best_item = item

	if best_item == null:
		return null

	take_item(_item_type(best_item))
	return best_item


func weight_multiplier(empty_value: float, full_value: float) -> float:
	return lerpf(empty_value, full_value, _weight_ratio())


func increase_inventory_space(extra_space: int) -> bool:
	extra_space = maxi(extra_space, 0)
	if extra_space <= 0:
		return false

	bonus_inventory_space += extra_space
	max_carry_weight += float(extra_space)
	inventory_capacity_changed.emit(get_max_inventory_units())
	return true


func _add_item(item: Resource) -> void:
	var item_type := _item_type(item)
	var entry: Dictionary = carried_items.get(item_type, {"item": item, "count": 0})
	entry["item"] = item
	entry["count"] = int(entry["count"]) + 1
	carried_items[item_type] = entry
	_emit_item_count_changed(item_type)


func _get_next_drop_item() -> Resource:
	var best_item: Resource = null
	for item_type in _get_sorted_carried_item_types():
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
	for item_type in _get_sorted_carried_item_types():
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

	for coin in _get_sorted_gold_coins():
		if not coin is Node3D:
			continue

		var coin_position := (coin as Node3D).global_position
		var delta := Vector2(coin_position.x - position.x, coin_position.z - position.z)
		if delta.length() < DROP_CLEAR_RADIUS:
			return true

	return false


func _nudge_blocking_coins(position: Vector3, fallback_direction: Vector3) -> void:
	for coin in _get_sorted_gold_coins():
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


func _item_type(item: Resource) -> StringName:
	return item.get("item_type") if item != null else &""


func _item_max_count(item: Resource) -> int:
	return maxi(int(item.get("max_count")), 1) if item != null else 1


func _get_effective_item_max_count(item: Resource) -> int:
	var max_count := _item_max_count(item)
	if _item_type(item) == GOLD_COIN_ITEM_TYPE:
		max_count += bonus_inventory_space
	return max_count


func _item_weight(item: Resource) -> float:
	return maxf(float(item.get("weight")), 0.0) if item != null else 0.0


func _item_treasure_value(item: Resource) -> int:
	return maxi(int(item.get("treasure_value")), 0) if item != null else 0


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

	var pitch_scale := ITEM_SOUND_PITCH_MIN
	var volume_db := ITEM_SOUND_VOLUME_MIN_DB
	if _uses_coin_sound_profile(item):
		pitch_scale = audio_rng.randf_range(COIN_SOUND_PITCH_MIN, COIN_SOUND_PITCH_MAX)
		volume_db = audio_rng.randf_range(
			ITEM_SOUND_VOLUME_MIN_DB + COIN_SOUND_VOLUME_OFFSET_DB,
			ITEM_SOUND_VOLUME_MAX_DB + COIN_SOUND_VOLUME_OFFSET_DB
		)
	else:
		pitch_scale = audio_rng.randf_range(ITEM_SOUND_PITCH_MIN, ITEM_SOUND_PITCH_MAX)
		volume_db = audio_rng.randf_range(ITEM_SOUND_VOLUME_MIN_DB, ITEM_SOUND_VOLUME_MAX_DB)

	var audio_parent: Node = player as Node if player != null else self as Node
	var sound_name := player_name if not player_name.is_empty() else "InventoryItemAudio"
	GDAudio.play_one_shot(audio_parent, sound, sound_name, volume_db, pitch_scale)


func _uses_coin_sound_profile(item: Resource) -> bool:
	var item_type := _item_type(item)
	return item_type == GOLD_COIN_ITEM_TYPE or item_type in GEM_ITEM_TYPES


func _get_sorted_carried_item_types() -> Array[StringName]:
	var item_types: Array[StringName] = []
	for item_type in carried_items.keys():
		item_types.append(item_type as StringName)

	item_types.sort_custom(_sort_string_names)
	return item_types


func _get_sorted_gold_coins() -> Array[Node]:
	var coins: Array[Node] = []
	for coin in get_tree().get_nodes_in_group("gold_coin"):
		if coin is Node:
			coins.append(coin as Node)

	coins.sort_custom(_sort_nodes_by_path)
	return coins


func _sort_string_names(a: StringName, b: StringName) -> bool:
	return String(a) < String(b)


func _sort_nodes_by_path(a: Node, b: Node) -> bool:
	return str(a.get_path()) < str(b.get_path())
