@tool
extends RefCounted

## Deterministic travel decisions, independent of physics and presentation.

enum TravelMode { AutomaticWithPauses, AutomaticContinuous, PlayerActivated }
enum BoardingBehaviour { WhileOccupied, ReturnTrip, NextLanding }

var stops: Array[float] = []
var height := 0.0
var direction := 1
var target_index := 0
var pause_remaining := 0.0
var active := false
var occupied := false
var trip_origin := 0
var returning := false
var travel_mode := TravelMode.AutomaticWithPauses
var boarding_behaviour := BoardingBehaviour.WhileOccupied


func configure(heights: Array[float], starting_height: float) -> void:
	stops.assign(heights)
	stops.sort()
	for index in range(stops.size() - 1, 0, -1):
		if is_equal_approx(stops[index], stops[index - 1]):
			stops.remove_at(index)
	height = starting_height
	direction = -1 if not stops.is_empty() and height >= stops.back() else 1
	target_index = _next_index(direction)
	active = travel_mode != TravelMode.PlayerActivated
	pause_remaining = 0.0
	occupied = false
	returning = false


func set_occupied(value: bool) -> void:
	var boarding := value and not occupied
	occupied = value
	if travel_mode != TravelMode.PlayerActivated or stops.size() < 2:
		return
	if boarding and not active:
		active = true
		trip_origin = _nearest_index()
		returning = false
	elif value and boarding_behaviour == BoardingBehaviour.WhileOccupied:
		active = true


## Propose only; an obstructed move must not advance route height or landing timers.
func propose(delta: float, speed: float) -> float:
	if stops.size() < 2 or not active:
		return height
	if pause_remaining > 0.0:
		pause_remaining = maxf(pause_remaining - delta, 0.0)
		return height
	return move_toward(height, stops[target_index], maxf(speed, 0.0) * delta)


func accept(next_height: float, landing_pause: float) -> bool:
	height = next_height
	if not is_equal_approx(height, stops[target_index]):
		return false
	height = stops[target_index]
	var arrived := target_index
	if travel_mode == TravelMode.PlayerActivated:
		match boarding_behaviour:
			BoardingBehaviour.NextLanding:
				active = false
			BoardingBehaviour.WhileOccupied:
				active = occupied
			BoardingBehaviour.ReturnTrip:
				if returning and arrived == trip_origin:
					active = false
				elif arrived == 0 or arrived == stops.size() - 1:
					returning = true
	if arrived == 0:
		direction = 1
	elif arrived == stops.size() - 1:
		direction = -1
	target_index = clampi(arrived + direction, 0, stops.size() - 1)
	pause_remaining = 0.0 if travel_mode == TravelMode.AutomaticContinuous else landing_pause
	return true


## Reverse towards a reachable landing; at a blocked endpoint retain the valid inward target.
func reverse() -> void:
	var opposite := _next_index(-direction)
	if stops.is_empty() or is_equal_approx(stops[opposite], height):
		return
	direction = -direction
	target_index = opposite
	if boarding_behaviour == BoardingBehaviour.ReturnTrip:
		returning = true


func _next_index(towards: int) -> int:
	if towards > 0:
		for index in stops.size():
			if stops[index] > height + 0.00001:
				return index
	else:
		for index in range(stops.size() - 1, -1, -1):
			if stops[index] < height - 0.00001:
				return index
	return _nearest_index()


func _nearest_index() -> int:
	var nearest := 0
	for index in stops.size():
		if absf(stops[index] - height) < absf(stops[nearest] - height):
			nearest = index
	return nearest
