extends "res://tests/test_case.gd"

const SUBJECT := preload("res://placeables/platforms/elevator/elevator_passengers.gd")
const FIXTURE := preload("res://placeables/platforms/elevator/elevator_test.gd")
const COIN := preload("res://placeables/treasure/gold_coin.tscn")


func run(tree: SceneTree) -> void:
	expect_script_contract(SUBJECT, "res://placeables/platforms/elevator/elevator_passengers.gd")
	var fixture := FIXTURE.new()
	var world := fixture.make_fixture(tree)
	var root := world["root"] as Node3D
	var elevator := world["elevator"] as Node3D
	elevator.set_physics_process(false)
	var platform := elevator.get_node(^"Platform") as AnimatableBody3D
	var sensor := elevator.get_node(^"Platform/PassengerSensor") as Area3D
	var passengers := SUBJECT.new()
	var rider := fixture.add_rider(root, Vector3(0.0, 0.02, 0.0))
	await fixture.frames(tree, 8)
	passengers.gather(platform, sensor, 0.06)
	expect(passengers.occupied, "A grounded player is detected as aboard.")
	expect(
		not passengers.blocked(platform, Vector3.UP * 0.01, 0.002), "The rider does not obstruct their own elevator."
	)
	rider.position.x = -0.55
	await fixture.frames(tree, 4)
	passengers.gather(platform, sensor, 0.06)
	expect(passengers.occupied, "A grounded capsule partly over the slab remains a supported passenger.")
	rider.position.x = 0.0
	rider.velocity.y = 4.0
	await fixture.frames(tree, 4)
	passengers.gather(platform, sensor, 0.06)
	expect(not passengers.occupied, "An airborne overlapping player does not count as boarding.")
	rider.queue_free()
	var coin := COIN.instantiate() as GDGoldCoin
	coin.position.y = 0.02
	root.add_child(coin)
	await fixture.frames(tree, 20)
	passengers.gather(platform, sensor, 0.06)
	expect(passengers.bodies.has(coin), "A loose resting coin is supported.")
	coin.is_being_collected = true
	passengers.gather(platform, sensor, 0.06)
	expect(not passengers.bodies.has(coin), "An item being collected stops participating in transport and clearance.")
	root.queue_free()
	await fixture.frames(tree, 3)
