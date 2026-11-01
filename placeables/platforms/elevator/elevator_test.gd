extends "res://tests/test_case.gd"

const SUBJECT := preload("res://placeables/platforms/elevator/elevator.gd")
const SCENE := preload("res://placeables/platforms/elevator/elevator.tscn")
const FLOOR := preload("res://addons/floor_surface/floor_surface.tscn")
const PLACEMENT := preload("res://addons/floor_surface/editor/floor_surface_tile_placement.gd")
const COIN := preload("res://placeables/treasure/gold_coin.tscn")
const FLASK := preload("res://placeables/collectibles/health_flask.tscn")
const CRUMBLING := preload("res://placeables/traps/crumbling_floor/crumbling_floor.gd")


class Rider:
	extends CharacterBody3D
	var walk := 0.0

	func _ready() -> void:
		add_to_group(&"player")

	func _physics_process(delta: float) -> void:
		if not is_on_floor():
			velocity += get_gravity() * delta
		velocity.x = walk
		move_and_slide()


func run(tree: SceneTree) -> void:
	expect_script_contract(SUBJECT, "res://placeables/platforms/elevator/elevator.gd")
	_test_placement_and_stops()
	await _test_riding_and_jumping(tree)
	await _test_items(tree)
	await _test_obstructions(tree)
	await _test_crumbling_and_tight_clearance(tree)
	await _test_real_player(tree)
	await _test_floor_edits(tree)


func make_fixture(
	tree: SceneTree,
	mode := SUBJECT.ROUTE.TravelMode.AutomaticContinuous,
	authored_items := false,
	starting_height := 0.0
) -> Dictionary:
	var root := Node3D.new()
	var floor := FLOOR.instantiate() as FloorSurface
	floor.world_origin_xz = Vector2(-2.5, -2.5)
	floor.floor_map = FloorMap.new()
	floor.floor_map.dimensions = Vector2i(5, 5)
	floor.floor_map.default_present = true
	floor.floor_map.set_floor_present(Vector2i(2, 2), false)
	floor.floor_map.set_cell_elevation(Vector2i(3, 2), 4)
	floor.elevation_profile = FloorElevationProfile.new()
	var style := FloorStyle.new()
	style.top_material = StandardMaterial3D.new()
	style.wall_material = StandardMaterial3D.new()
	floor.styles.assign([style])
	root.add_child(floor)
	var elevator := SCENE.instantiate() as SUBJECT
	elevator.floor_surface = floor
	elevator.position.y = starting_height
	elevator.travel_mode = mode
	elevator.settings = elevator.settings.duplicate()
	elevator.settings.landing_pause = 0.1
	root.add_child(elevator)
	var child_coin: GDGoldCoin
	var child_flask: GDFlaskBase
	if authored_items:
		child_coin = COIN.instantiate() as GDGoldCoin
		child_coin.position = Vector3(-0.15, 0.03, 0.2)
		child_flask = FLASK.instantiate() as GDFlaskBase
		child_flask.position = Vector3(0.15, 0.0, 0.2)
		elevator.get_node(^"Platform/Contents").add_child(child_coin)
		elevator.get_node(^"Platform/Contents").add_child(child_flask)
		child_coin.owner = root
		child_flask.owner = root
	tree.root.add_child(root)
	return {"root": root, "floor": floor, "elevator": elevator, "child_coin": child_coin, "child_flask": child_flask}


func add_rider(root: Node3D, at: Vector3) -> Rider:
	var rider := Rider.new()
	rider.position = at
	rider.collision_layer = 2
	rider.collision_mask = 1
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.28
	capsule.height = 0.8
	shape.shape = capsule
	shape.position.y = 0.4
	rider.add_child(shape)
	root.add_child(rider)
	return rider


func frames(tree: SceneTree, count: int) -> void:
	for frame in count:
		await tree.physics_frame
		await tree.process_frame


func _test_placement_and_stops() -> void:
	var root := Node3D.new()
	var elevator := SCENE.instantiate() as SUBJECT
	var floor := FloorSurface.new()
	floor.floor_map = FloorMap.new()
	floor.floor_map.dimensions = Vector2i(3, 3)
	floor.floor_map.default_present = true
	floor.elevation_profile = FloorElevationProfile.new()
	floor.floor_map.set_floor_present(Vector2i.ONE, false)
	floor.floor_map.set_cell_elevation(Vector2i(2, 1), 8)
	floor.floor_map.set_cell_elevation(Vector2i(1, 0), 3)
	root.add_child(floor)
	root.add_child(elevator)
	elevator.floor_surface = floor
	elevator.position = Vector3(1.6, 9.0, 1.7)
	expect_equal(elevator.get_stop_heights(), [0.0, 0.75, 2.0], "All distinct surrounding flat heights become stops.")
	var before := floor.floor_map.get_presence_snapshot()
	var planned := PLACEMENT.calculate_auto_transform(elevator, floor)
	expect_equal(
		(planned["transform"] as Transform3D).origin, Vector3(1.5, 0.0, 1.5), "Elevators use crumbling-floor placement."
	)
	expect_equal(elevator.position.y, 9.0, "Planning preserves a manual vertical edit.")
	expect_equal(floor.floor_map.get_presence_snapshot(), before, "Placement leaves authored occupancy unchanged.")
	root.free()


func _test_riding_and_jumping(tree: SceneTree) -> void:
	var fixture := make_fixture(tree, SUBJECT.ROUTE.TravelMode.PlayerActivated)
	var root := fixture["root"] as Node3D
	var elevator := fixture["elevator"] as SUBJECT
	var rider := add_rider(root, Vector3(-1.0, 0.02, 0.0))
	await frames(tree, 12)
	expect(not elevator.route.active, "Standing on neighbouring ground does not activate the elevator.")
	rider.velocity.y = 4.0
	rider.walk = 2.0
	await frames(tree, 30)
	rider.walk = 0.0
	await frames(tree, 30)
	expect(rider.is_on_floor(), "Boarding establishes real grounded support.")
	expect(elevator.route.active, "A supported player activates the elevator.")
	await frames(tree, 42)
	expect(elevator.platform.global_position.y > 0.4, "A boarded elevator rises.")
	expect(
		absf(rider.global_position.y - elevator.platform.global_position.y) < 0.04,
		"The standing rider follows the rising slab."
	)
	rider.velocity.y = 4.0
	await frames(tree, 7)
	expect(not rider.is_on_floor(), "The player can jump off the moving slab.")
	expect(
		rider.global_position.y > elevator.platform.global_position.y + 0.2,
		"Jump motion is independent of platform motion."
	)
	await frames(tree, 60)
	expect(rider.is_on_floor(), "The player can land back on the slab.")
	await frames(tree, 65)
	expect(
		absf(rider.global_position.y - elevator.platform.global_position.y) < 0.04,
		"The rider remains supported while descending and reversing."
	)
	rider.walk = -2.0
	await frames(tree, 55)
	expect(rider.global_position.x < -1.0, "A rider can leave onto adjacent ground.")
	root.queue_free()
	await frames(tree, 3)


func _test_items(tree: SceneTree) -> void:
	var fixture := make_fixture(tree, SUBJECT.ROUTE.TravelMode.AutomaticContinuous, true)
	var root := fixture["root"] as Node3D
	var elevator := fixture["elevator"] as SUBJECT
	var coin := COIN.instantiate() as GDGoldCoin
	coin.position = Vector3(-0.2, 0.03, 0.0)
	coin.owner = null
	root.add_child(coin)
	var flask := FLASK.instantiate() as GDFlaskBase
	flask.position = Vector3(0.2, 0.0, 0.0)
	root.add_child(flask)
	await frames(tree, 2)
	var child_coin := fixture["child_coin"] as GDGoldCoin
	var child_flask := fixture["child_flask"] as GDFlaskBase
	expect(
		child_coin.get_parent() == root and child_flask.get_parent() == root,
		"Authored physics items detach from the moving hierarchy."
	)
	expect(
		child_coin.owner == root and child_coin.get_max_treasure_value() > 0,
		"Detaching keeps authored treasure ownership and scoring."
	)
	await frames(tree, 65)
	expect(child_coin.global_position.y > 0.5, "Authored coins ride with the platform.")
	expect(
		absf(child_flask.global_position.y - elevator.platform.global_position.y) < 0.03,
		"Authored frozen flasks receive exactly one displacement."
	)
	expect(coin.global_position.y > 0.5, "A loose active coin is carried upwards by real physics.")
	expect(
		absf(flask.global_position.y - elevator.platform.global_position.y) < 0.03,
		"A loose frozen flask follows the slab without drifting."
	)
	await frames(tree, 90)
	expect(
		absf(flask.global_position.y - elevator.platform.global_position.y) < 0.03,
		"The frozen flask also follows downward travel and reversal."
	)
	expect(
		coin.global_position.y > elevator.platform.global_position.y - 0.06,
		"The dynamic coin never falls through the slab."
	)
	flask.global_position.x = -1.4
	await frames(tree, 3)
	var departed := flask.global_position.y
	await frames(tree, 15)
	expect_equal(flask.global_position.y, departed, "Items moved away stop inheriting displacement.")
	root.queue_free()
	await frames(tree, 3)


func add_ceiling(root: Node3D, bottom: float) -> StaticBody3D:
	var ceiling := StaticBody3D.new()
	ceiling.position.y = bottom + 0.1
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(0.9, 0.2, 0.9)
	collision.shape = shape
	ceiling.add_child(collision)
	root.add_child(ceiling)
	return ceiling


func _test_obstructions(tree: SceneTree) -> void:
	for with_rider in [false, true]:
		var fixture := make_fixture(tree)
		var root := fixture["root"] as Node3D
		var elevator := fixture["elevator"] as SUBJECT
		var ceiling := add_ceiling(root, 1.2 if with_rider else 0.6)
		var rider: Rider
		if with_rider:
			rider = add_rider(root, Vector3(0.0, 0.02, 0.0))
		var peak := 0.0
		for frame in 105:
			await frames(tree, 1)
			peak = maxf(peak, elevator.platform.global_position.y)
		expect(peak > 0.2 and peak < 0.61, "Sweeps reverse before either a slab or its rider reaches the obstruction.")
		if with_rider:
			expect(rider.global_position.y + 0.8 < 1.21, "The rider stays below the overhead obstruction.")
		ceiling.queue_free()
		var restored_peak := 0.0
		for frame in 120:
			await frames(tree, 1)
			restored_peak = maxf(restored_peak, elevator.route.height)
		expect(restored_peak > 0.95, "Removing an obstruction restores full-height travel.")
		root.queue_free()
		await frames(tree, 3)


func _test_real_player(tree: SceneTree) -> void:
	var fixture := make_fixture(tree, SUBJECT.ROUTE.TravelMode.PlayerActivated)
	var root := fixture["root"] as Node3D
	var elevator := fixture["elevator"] as SUBJECT
	var player := (load("res://player/player.tscn") as PackedScene).instantiate() as GDPlayer
	player.position = Vector3(0.0, 0.02, 0.0)
	root.add_child(player)
	var coin := COIN.instantiate() as GDGoldCoin
	coin.position = Vector3(0.0, 0.03, 0.25)
	root.add_child(coin)
	await frames(tree, 35)
	expect(
		(player.inventory as GDPlayerInventory).get_carried_treasure_value() > 0,
		"The player collects a real coin while riding."
	)
	expect(
		player.is_on_floor() and elevator.route.height > 0.1, "The actual player scene boards and rides the elevator."
	)
	Input.action_press(&"jump")
	await frames(tree, 1)
	Input.action_release(&"jump")
	await frames(tree, 4)
	expect(not player.is_on_floor(), "The actual player jump action leaves the moving platform.")
	root.queue_free()
	await frames(tree, 3)


func _test_crumbling_and_tight_clearance(tree: SceneTree) -> void:
	var fixture := make_fixture(tree)
	var root := fixture["root"] as Node3D
	var elevator := fixture["elevator"] as SUBJECT
	var tile_scene := load("res://placeables/traps/crumbling_floor/crumbling_floor.tscn") as PackedScene
	var tile := tile_scene.instantiate() as CRUMBLING
	tile.position.y = 0.75
	tile.auto_place = false
	root.add_child(tile)
	var peak := 0.0
	for frame in 90:
		await frames(tree, 1)
		peak = maxf(peak, elevator.route.height)
	expect(peak > 0.3 and peak < 0.51, "An intact crumbling floor reverses the slab at its underside.")
	expect_equal(tile.state, CRUMBLING.State.Intact, "Contact with the elevator does not trigger the trap.")
	root.queue_free()
	await frames(tree, 3)

	fixture = make_fixture(tree, SUBJECT.ROUTE.TravelMode.AutomaticContinuous, false, 0.5)
	root = fixture["root"] as Node3D
	elevator = fixture["elevator"] as SUBJECT
	var above := add_ceiling(root, 0.501)
	var below := add_ceiling(root, 0.049)
	await frames(tree, 12)
	expect(absf(elevator.route.height - 0.5) < 0.002, "Obstructions on both sides hold the slab safely in place.")
	above.queue_free()
	below.queue_free()
	await frames(tree, 20)
	expect(
		absf(elevator.route.height - 0.5) > 0.15,
		"Clearing a blocked shaft resumes travel without resetting the elevator."
	)
	root.queue_free()
	await frames(tree, 3)

	fixture = make_fixture(tree, SUBJECT.ROUTE.TravelMode.AutomaticContinuous, false, 1.0)
	root = fixture["root"] as Node3D
	elevator = fixture["elevator"] as SUBJECT
	var crate := RigidBody3D.new()
	crate.freeze = true
	crate.collision_layer = 4
	crate.position.y = 0.3
	var collision := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(0.5, 0.6, 0.5)
	collision.shape = box
	crate.add_child(collision)
	root.add_child(crate)
	var lowest := 1.0
	for frame in 55:
		await frames(tree, 1)
		lowest = minf(lowest, elevator.route.height)
	expect(lowest > 0.84 and lowest < 0.95, "Descending travel reverses before striking an object beneath the slab.")
	root.queue_free()
	await frames(tree, 3)


func _test_floor_edits(tree: SceneTree) -> void:
	var fixture := make_fixture(tree)
	var root := fixture["root"] as Node3D
	var elevator := fixture["elevator"] as SUBJECT
	var floor := fixture["floor"] as FloorSurface
	await frames(tree, 20)
	elevator.set_physics_process(false)
	var before := elevator.route.height
	var material := StandardMaterial3D.new()
	(floor.styles[0] as FloorStyle).top_material = material
	await frames(tree, 3)
	expect(
		elevator.slab.mesh.surface_get_material(0) == material,
		"Replacing a floor material refreshes the elevator finish."
	)
	expect_equal(elevator.route.height, before, "A material refresh does not restart travel.")
	floor.floor_map.set_cell_elevation(Vector2i(2, 1), 8)
	await frames(tree, 3)
	expect_equal(elevator.route.stops, [0.0, 1.0, 2.0], "Floor editing updates the derived landing heights.")
	root.queue_free()
	await frames(tree, 3)
