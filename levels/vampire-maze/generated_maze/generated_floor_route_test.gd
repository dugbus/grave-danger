extends "res://tests/test_case.gd"

const SUBJECT := preload("res://levels/vampire-maze/generated_maze/generated_floor_route.gd")
const SUBJECT_PATH := "res://levels/vampire-maze/generated_maze/generated_floor_route.gd"


func run(_tree: SceneTree) -> void:
	expect_script_contract(SUBJECT, SUBJECT_PATH)
	var subject_script := SUBJECT as Script
	expect(
		subject_script.is_tool(),
		"The routed floor component executes while GeneratedMaze previews in the editor."
	)
	var walkable := {
		Vector2i(0, 0): true,
		Vector2i(1, 0): true,
		Vector2i(2, 0): true,
		Vector2i(1, 1): true,
		Vector2i(1, 2): true,
	}
	var content_plan := {
		"keys": [
			{"cell": Vector2i(2, 0), "item_type": &"silver_key"},
			{"cell": Vector2i(1, 2), "item_type": &"key"},
		],
	}
	var gate_route := SUBJECT.build_route(
		walkable,
		Vector3i(0, 0, 0),
		Vector3i(2, 0, 0),
		content_plan,
		SUBJECT.Destination.Gate
	)
	var key_route := SUBJECT.build_route(
		walkable,
		Vector3i(0, 0, 0),
		Vector3i(2, 0, 0),
		content_plan,
		SUBJECT.Destination.GateKey
	)
	expect_equal(
		gate_route,
		[Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0)] as Array[Vector2i],
		"The gate destination follows the walkable route to the exit."
	)
	expect_equal(
		key_route,
		[Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, 1), Vector2i(1, 2)] as Array[Vector2i],
		"The gate-key destination follows the walkable route to the gold key."
	)
	var corridor_floor := {}
	var corridor_route: Array[Vector2i] = []
	for x_coordinate in 8:
		corridor_route.append(Vector2i(x_coordinate, 0))
		corridor_floor[Vector2i(x_coordinate, 0)] = true
		corridor_floor[Vector2i(x_coordinate, 1)] = true
	var corridor_band := SUBJECT.build_corridor_band(
		corridor_route,
		corridor_floor
	) as Array[Vector2i]
	expect(
		corridor_band.size() == 16 \
			and corridor_band.has(Vector2i(3, 0)) \
			and corridor_band.has(Vector2i(3, 1)),
		"The route band spans both walkable lanes of a two-tile-wide corridor."
	)

	var long_route: Array[Vector2i] = []
	for x_coordinate in 100:
		long_route.append(Vector2i(x_coordinate, 0))
	var destination := long_route[-1]
	var selected := SUBJECT.select_tile_cells(
		long_route,
		1730,
		50.0,
		destination
	) as Array[Vector2i]
	var repeated := SUBJECT.select_tile_cells(
		long_route,
		1730,
		50.0,
		destination
	) as Array[Vector2i]
	expect(
		selected == repeated \
			and selected.size() >= 35 \
			and selected.size() <= 65 \
			and selected.has(destination),
		"Half-chance route tiles are deterministic and always identify their destination."
	)
	expect(
		(SUBJECT.select_tile_cells(long_route, 1730, 0.0) as Array).is_empty() \
			and (SUBJECT.select_tile_cells(long_route, 1730, 100.0) as Array).size() \
				== long_route.size(),
		"Route tile placement respects the full configured percentage range."
	)
