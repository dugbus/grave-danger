extends Node
class_name GDResultStats


## Treasure value deposited during the current level attempt.
var treasure_collected := 0
## Total treasure value available during the current level attempt.
var max_treasure_value := 0
## Deposited treasure objects grouped by their stable carried-item type.
var collected_treasure_by_type: Dictionary = {}
var rewards_banked := false


func begin_attempt(max_collected: int) -> void:
	treasure_collected = 0
	max_treasure_value = maxi(max_collected, 0)
	collected_treasure_by_type.clear()
	rewards_banked = false


func set_result(collected: int, max_collected: int) -> void:
	treasure_collected = maxi(collected, 0)
	max_treasure_value = maxi(max_collected, 0)


func add_treasure(item_type: StringName, value: int, count := 1) -> void:
	var safe_count := maxi(count, 0)
	treasure_collected += maxi(value, 0)
	if item_type.is_empty() or safe_count <= 0:
		return

	var key := String(item_type)
	collected_treasure_by_type[key] = int(collected_treasure_by_type.get(key, 0)) + safe_count


func take_unbanked_treasure() -> Dictionary:
	if rewards_banked:
		return {}

	rewards_banked = true
	return collected_treasure_by_type.duplicate(true)


func get_completion_percentage() -> int:
	if max_treasure_value <= 0:
		return 0

	var completion := roundi(float(treasure_collected) / float(max_treasure_value) * 100.0)
	return clampi(completion, 0, 100)
