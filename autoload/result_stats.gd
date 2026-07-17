extends Node
class_name GDResultStats


## Treasure value deposited during the current level attempt.
var treasure_collected := 0
## Total treasure value available during the current level attempt.
var max_treasure_value := 0


func set_result(collected: int, max_collected: int) -> void:
	treasure_collected = maxi(collected, 0)
	max_treasure_value = maxi(max_collected, 0)


func get_completion_percentage() -> int:
	if max_treasure_value <= 0:
		return 0

	var completion := roundi(float(treasure_collected) / float(max_treasure_value) * 100.0)
	return clampi(completion, 0, 100)
