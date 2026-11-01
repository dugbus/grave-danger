extends "res://tests/test_case.gd"

const LEVEL := preload("res://levels/debug-level/level.tscn")
const ELEVATOR := preload("res://placeables/platforms/elevator/elevator.gd")


func run(_tree: SceneTree) -> void:
	var level := LEVEL.instantiate() as Node3D
	var stations := level.get_node(^"Objects/ElevatorTests")
	var surface := level.get_node(^"FloorSurface") as FloorSurface
	expect_equal(stations.get_child_count(), 7, "The debug level has seven independently labelled stations.")
	var modes := [
		ELEVATOR.ROUTE.TravelMode.AutomaticWithPauses,
		ELEVATOR.ROUTE.TravelMode.AutomaticContinuous,
		ELEVATOR.ROUTE.TravelMode.PlayerActivated,
		ELEVATOR.ROUTE.TravelMode.PlayerActivated,
		ELEVATOR.ROUTE.TravelMode.PlayerActivated,
		ELEVATOR.ROUTE.TravelMode.AutomaticWithPauses,
		ELEVATOR.ROUTE.TravelMode.AutomaticWithPauses,
	]
	for index in 7:
		var station := stations.get_child(index) as Node3D
		var elevator := station.get_node(^"Elevator") as ELEVATOR
		var label := station.get_node(^"Label") as Label3D
		expect(not label.text.is_empty(), "Every station explains its expected behaviour in the level.")
		expect_equal(elevator.travel_mode, modes[index], "The authored travel mode matches the validation matrix.")
		expect(elevator.floor_surface == surface, "The station uses the actual debug FloorSurface.")
		var world := ELEVATOR.PLACEMENT._world_transform(elevator).origin
		expect(
			not surface.floor_map.has_floor(surface.world_to_cell(world)),
			"Each elevator has an explicitly authored shaft."
		)
		expect(elevator.get_stop_heights().size() >= 2, "Every station has actual floor-defined travel heights.")
		if index in [1, 4]:
			expect_equal(elevator.get_stop_heights().size(), 3, "Multi-height stations exercise intermediate landings.")
		if index in [2, 3, 4]:
			expect_equal(elevator.boarding_behaviour, index - 2, "All three boarding settings are represented.")
		if index == 0:
			expect_equal(
				elevator.get_node(^"Platform/Contents").get_child_count(),
				2,
				"The primary station has authored child coin and flask."
			)
		if index == 1:
			expect(
				station.has_node(^"Coin") and station.has_node(^"Flask"),
				"Continuous mode includes independently placed pickups."
			)
		expect_equal(elevator.settings.thickness, 0.25, "The station retains the shared slab thickness.")
	expect(
		stations.get_node(^"Station6").has_node(^"CrumblingObstruction"),
		"Station six uses the real crumbling-floor obstacle."
	)
	expect(
		stations.get_node(^"Station7").has_node(^"OverheadObstacle"),
		"Station seven tests rider clearance separately from slab clearance."
	)
	expect(
		level.has_node(^"Objects/SkeletonCrumblingDemo"), "The existing raised collapse demonstration remains intact."
	)
	level.free()
