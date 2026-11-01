extends "res://tests/test_case.gd"

const SUBJECT := preload("res://placeables/platforms/elevator/elevator_route.gd")


func run(_tree: SceneTree) -> void:
	expect_script_contract(SUBJECT, "res://placeables/platforms/elevator/elevator_route.gd")
	_test_automatic_modes()
	_test_boarding_modes()
	_test_obstructions_and_invalid_stops()


func _route(mode: SUBJECT.TravelMode, behaviour := SUBJECT.BoardingBehaviour.WhileOccupied) -> SUBJECT:
	var route := SUBJECT.new()
	route.travel_mode = mode
	route.boarding_behaviour = behaviour
	route.configure([2.0, 0.0, 1.0, 1.0], 0.0)
	return route


func _advance(route: SUBJECT, frames: int, landings: Array[float]) -> void:
	for frame in frames:
		var next := route.propose(0.1, 1.0)
		if not is_equal_approx(next, route.height) and route.accept(next, 0.3):
			landings.append(route.height)


func _test_automatic_modes() -> void:
	for mode: SUBJECT.TravelMode in [SUBJECT.TravelMode.AutomaticWithPauses, SUBJECT.TravelMode.AutomaticContinuous]:
		var route := _route(mode)
		expect_equal(route.stops, [0.0, 1.0, 2.0], "Stops are sorted and deduplicated.")
		var first: Array[float] = []
		_advance(route, 60, first)
		expect(first.size() >= 4, "Automatic travel completes a full round trip.")
		expect_equal(first.slice(0, 4), [1.0, 2.0, 1.0, 0.0], "Intermediate landings are visited in both directions.")
		var replay := _route(mode)
		var second: Array[float] = []
		_advance(replay, 60, second)
		expect_equal(first, second, "Identical ticks produce identical travel.")
		expect_equal(route.height, replay.height, "Replay height agrees exactly.")
	var paused := _route(SUBJECT.TravelMode.AutomaticWithPauses)
	paused.accept(1.0, 1.0)
	expect_equal(paused.propose(0.1, 1.0), 1.0, "Pausing mode waits at a landing.")
	var continuous := _route(SUBJECT.TravelMode.AutomaticContinuous)
	continuous.accept(1.0, 1.0)
	expect(continuous.propose(0.1, 1.0) > 1.0, "Continuous mode immediately continues through intermediate stops.")


func _test_boarding_modes() -> void:
	for behaviour: SUBJECT.BoardingBehaviour in SUBJECT.BoardingBehaviour.values():
		var route := _route(SUBJECT.TravelMode.PlayerActivated, behaviour)
		var landings: Array[float] = []
		_advance(route, 10, landings)
		expect_equal(route.height, 0.0, "Player-activated travel waits for a supported player.")
		route.set_occupied(true)
		_advance(route, 4, landings)
		route.set_occupied(false)
		_advance(route, 60, landings)
		match behaviour:
			SUBJECT.BoardingBehaviour.ReturnTrip:
				expect_equal(landings, [1.0, 2.0, 1.0, 0.0], "Leaving mid-flight does not cancel a return trip.")
			SUBJECT.BoardingBehaviour.WhileOccupied, SUBJECT.BoardingBehaviour.NextLanding:
				expect_equal(landings, [1.0], "Leaving finishes the current leg, then waits.")
		expect(not route.active, "Completed player-triggered travel waits for another boarding.")
		route.set_occupied(true)
		_advance(route, 15, landings)
		expect(route.height > landings[0] or landings.size() > 4, "Reboarding starts another journey.")
	var occupied := _route(SUBJECT.TravelMode.PlayerActivated)
	occupied.set_occupied(true)
	var stops: Array[float] = []
	_advance(occupied, 55, stops)
	expect(stops.size() >= 4, "While-occupied mode keeps shuttling with a rider.")
	var single := _route(SUBJECT.TravelMode.PlayerActivated, SUBJECT.BoardingBehaviour.NextLanding)
	single.set_occupied(true)
	_advance(single, 50, stops)
	single.set_occupied(true)
	expect(not single.active, "Remaining aboard does not retrigger one-landing mode.")


func _test_obstructions_and_invalid_stops() -> void:
	var route := _route(SUBJECT.TravelMode.AutomaticContinuous)
	var landings: Array[float] = []
	_advance(route, 5, landings)
	var before := route.height
	route.reverse()
	expect(route.propose(0.1, 1.0) < before, "An obstruction reverses towards the previous reachable landing.")
	expect_equal(route.height, before, "Reversing does not teleport or consume travel.")
	route.configure([0.0], 0.0)
	expect_equal(route.propose(1.0, 1.0), 0.0, "A single stop remains stationary.")
	route.configure([], 3.0)
	expect_equal(route.propose(1.0, 1.0), 3.0, "Missing stops preserve authored height.")
