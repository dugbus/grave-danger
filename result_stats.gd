extends Node


var coins_collected := 0
var max_coins_collected := 0


func set_result(collected: int, max_collected: int) -> void:
	coins_collected = maxi(collected, 0)
	max_coins_collected = maxi(max_collected, 0)


func get_completion_percentage() -> int:
	if max_coins_collected <= 0:
		return 0

	var completion := roundi(float(coins_collected) / float(max_coins_collected) * 100.0)
	return clampi(completion, 0, 100)
