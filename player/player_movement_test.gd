extends "res://tests/test_case.gd"

const SUBJECT := preload("res://player/player_movement.gd")
const SUBJECT_PATH := "res://player/player_movement.gd"


# Flow: Animation caps never alter the original gameplay speed, load curve or movement response.
func run(tree: SceneTree) -> void:
	expect_script_contract(SUBJECT, SUBJECT_PATH)
	var body := CharacterBody3D.new()
	var movement := SUBJECT.new() as GDPlayerMovement
	body.add_child(movement)
	var inventory := InventoryStub.new()
	tree.root.add_child(body)
	await tree.process_frame
	var maximum_speed := movement.SPEED
	Input.action_press(&"move_down", 1.0)
	movement.update_walk(1.0, inventory)
	expect(
		is_equal_approx(Vector2(body.velocity.x, body.velocity.z).length(), maximum_speed),
		"Full input reaches the original gameplay top speed."
	)
	Input.action_press(&"move_right", 1.0)
	movement.update_walk(1.0, inventory)
	expect(
		is_equal_approx(Vector2(body.velocity.x, body.velocity.z).length(), maximum_speed),
		"Diagonal input reaches the same original top speed."
	)
	Input.action_release(&"move_right")
	inventory.load_fraction = 1.0
	movement.update_walk(1.0, inventory)
	expect(
		is_equal_approx(
			Vector2(body.velocity.x, body.velocity.z).length(), maximum_speed * movement.MIN_WEIGHT_SPEED_MULTIPLIER
		),
		"Carrying treasure retains the original speed multiplier."
	)
	inventory.load_fraction = 0.0
	Input.action_release(&"move_down")
	Input.action_press(&"move_down", 0.5)
	movement.update_walk(1.0, inventory)
	expect(
		(
			Vector2(body.velocity.x, body.velocity.z).length() > 0.0
			and Vector2(body.velocity.x, body.velocity.z).length() < maximum_speed
		),
		"Partial analogue input remains slower than the cap."
	)
	Input.action_release(&"move_down")
	movement.update_walk(1.0, inventory)
	expect(
		Vector2(body.velocity.x, body.velocity.z).is_zero_approx(), "Releasing input still brakes to a complete stop."
	)
	body.velocity = Vector3(0.0, 0.0, 20.0)
	Input.action_press(&"move_down", 1.0)
	movement.update_walk(0.001, inventory)
	expect(
		Vector2(body.velocity.x, body.velocity.z).length() > maximum_speed,
		"External push velocity decelerates normally instead of being clamped by animation."
	)
	var vertical_before := body.velocity.y
	movement.footstep_distance_accumulator = 0.3
	movement.update_stagger_motion(0.1)
	expect(
		body.velocity.x == 0.0 and body.velocity.z == 0.0,
		"Stagger immediately cancels horizontal momentum despite held input."
	)
	expect(body.velocity.y < vertical_before, "Stagger preserves airborne gravity.")
	expect(
		movement.current_horizontal_speed == 0.0 and movement.footstep_distance_accumulator == 0.0,
		"Stagger cannot retain walking speed or pending footsteps."
	)
	movement.update_walk(1.0, inventory)
	expect(is_equal_approx(body.velocity.z, maximum_speed), "Normal top speed remains available when walking resumes.")
	Input.action_release(&"move_down")
	inventory.free()
	body.free()
	await tree.process_frame


class InventoryStub:
	extends Node

	var load_fraction := 0.0

	func weight_multiplier(unloaded: float, loaded: float) -> float:
		return lerpf(unloaded, loaded, load_fraction)
