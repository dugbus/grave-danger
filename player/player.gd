extends CharacterBody3D
class_name GDPlayer


signal flask_effect_started(effect_id: StringName, liquid_color: Color, duration: float)

const CHARACTER_GROUP: StringName = &"character"
const FLAME_VULNERABLE_GROUP: StringName = &"flame_vulnerable"
const PLAYER_GROUP: StringName = &"player"
const BOUNDARY_BLOCKER_COLLISION_LAYER := 16
const PUSH_FLOOR_MIN_NORMAL_Y := 0.65
const PUSH_FLOOR_IGNORE_SECONDS := 0.25

# Player stays as the public API for other gameplay objects.
# Coins and kill-boundary areas still talk to this CharacterBody3D, while the actual
# behavior is split into focused child components below.
@onready var movement: Node = $PlayerMovement
@onready var inventory: Node = $PlayerInventory
@onready var animation_controller: Node = $PlayerAnimation
@onready var death_controller: Node = $PlayerDeath

var pickup_radius_multiplier := 1.0
var base_pickup_radius_multiplier := 1.0
var active_pickup_radius_multipliers: Array[float] = []
var floor_push_ignore_timers: Dictionary = {}


func _ready() -> void:
	# Randomness is currently used by the pickup sound pitch/volume variation.
	randomize()
	add_to_group(CHARACTER_GROUP)
	add_to_group(PLAYER_GROUP)
	add_to_group(FLAME_VULNERABLE_GROUP)
	collision_mask |= BOUNDARY_BLOCKER_COLLISION_LAYER


func _physics_process(delta: float) -> void:
	# Death owns the top-level state gate. A dead player still falls and slides to
	# a stop, but input, pickup, dropping, and walk animation stop immediately.
	if death_controller.is_dead:
		movement.update_dead_motion(delta)
		move_and_slide()
		return

	# Keep the frame order explicit:
	# gravity/jump first, then repeatable drop input, then horizontal movement,
	# then animation from the final input strength.
	movement.apply_gravity_and_jump(delta, inventory)
	inventory.update_drop_input(delta)

	var input_strength: float = movement.update_walk(delta, inventory)
	animation_controller.update_movement(input_strength, inventory)

	var push_velocity := velocity
	move_and_slide()
	_push_slide_colliders(push_velocity, delta)


func try_collect_gold_coin(gold_coin: Node3D) -> bool:
	return try_collect_carried_item(gold_coin)


func try_collect_carried_item(pickup: Node3D) -> bool:
	if death_controller.is_dead:
		return false

	return inventory.try_collect_item_pickup(pickup)


func try_collect_health_flask(_health_flask: Node3D, heal_percent_of_max: float, heal_duration: float) -> bool:
	if death_controller.is_dead:
		return false

	return death_controller.heal_percent_over_time(heal_percent_of_max, heal_duration)


func increase_inventory_space(extra_space: int) -> bool:
	if death_controller.is_dead:
		return false

	return inventory.increase_inventory_space(extra_space)


func apply_temporary_poison_damage(damage_points: float, restore_after_seconds: float) -> bool:
	if death_controller.is_dead:
		return false

	return death_controller.apply_temporary_damage(damage_points, restore_after_seconds)


func increase_pickup_radius_percent(percent: float) -> bool:
	if death_controller.is_dead:
		return false

	var multiplier := 1.0 + maxf(percent, 0.0) * 0.01
	if multiplier <= 1.0:
		return false

	base_pickup_radius_multiplier *= multiplier
	_refresh_pickup_radius_multiplier()
	return true


func increase_pickup_radius_percent_for(percent: float, seconds: float) -> bool:
	if death_controller.is_dead:
		return false

	var multiplier := 1.0 + maxf(percent, 0.0) * 0.01
	if multiplier <= 1.0:
		return false

	active_pickup_radius_multipliers.append(multiplier)
	_refresh_pickup_radius_multiplier()
	_restore_pickup_radius_after(multiplier, seconds)
	return true


func get_pickup_radius_multiplier() -> float:
	return pickup_radius_multiplier


func show_flask_effect_countdown(effect_id: StringName, liquid_color: Color, duration: float) -> void:
	flask_effect_started.emit(effect_id, liquid_color, duration)


func spend_carried_gold_coin() -> bool:
	if death_controller.is_dead:
		return false

	return inventory.spend_carried_gold_coin()


func get_carried_gold_coins() -> int:
	return inventory.get_carried_gold_coins()


func take_carried_item_of_type(item_type: StringName):
	if death_controller.is_dead:
		return null

	return inventory.take_item_of_type(item_type)


func take_key():
	return take_carried_item_of_type(&"key")


func is_dead() -> bool:
	return death_controller != null and death_controller.is_dead


func die_from_flames() -> void:
	# KillBoundary calls this on any body that exposes the method.
	death_controller.die_from_flames()


func apply_flame_damage(amount: float) -> void:
	var was_dead := is_dead()
	death_controller.apply_flame_damage(amount)
	if was_dead or is_dead() or amount <= 0.0:
		return
	if animation_controller.has_method("play_hit_reaction"):
		animation_controller.play_hit_reaction()


func apply_spike_trap_damage(percent_of_max: float) -> void:
	var was_dead := is_dead()
	death_controller.apply_percent_damage(percent_of_max)
	if was_dead or is_dead() or percent_of_max <= 0.0:
		return
	if animation_controller.has_method("play_hit_reaction"):
		animation_controller.play_hit_reaction()


func can_be_hit_by_spike_trap() -> bool:
	return not is_dead()


func drain_flame_energy() -> void:
	death_controller.drain_flame_energy()


func _restore_pickup_radius_after(multiplier: float, seconds: float) -> void:
	await get_tree().create_timer(maxf(seconds, 0.01)).timeout
	active_pickup_radius_multipliers.erase(multiplier)
	_refresh_pickup_radius_multiplier()


func _refresh_pickup_radius_multiplier() -> void:
	pickup_radius_multiplier = base_pickup_radius_multiplier
	for multiplier in active_pickup_radius_multipliers:
		pickup_radius_multiplier *= multiplier

	get_tree().call_group("pickup_radius_scalable", "set_pickup_radius_multiplier", pickup_radius_multiplier)


func _push_slide_colliders(push_velocity: Vector3, delta: float) -> void:
	for ignored_collider_id in floor_push_ignore_timers.keys():
		var remaining_seconds := float(floor_push_ignore_timers[ignored_collider_id]) - delta

		if remaining_seconds <= 0.0:
			floor_push_ignore_timers.erase(ignored_collider_id)
		else:
			floor_push_ignore_timers[ignored_collider_id] = remaining_seconds

	for collision_index in get_slide_collision_count():
		var collision := get_slide_collision(collision_index)
		var collider := collision.get_collider()

		if collider != null and collision.get_normal().y >= PUSH_FLOOR_MIN_NORMAL_Y:
			floor_push_ignore_timers[collider.get_instance_id()] = PUSH_FLOOR_IGNORE_SECONDS

	for collision_index in get_slide_collision_count():
		var collision := get_slide_collision(collision_index)
		var collider := collision.get_collider()
		if collider == null or not collider.has_method("push_from_character"):
			continue

		if floor_push_ignore_timers.has(collider.get_instance_id()):
			continue

		collider.push_from_character(push_velocity, collision.get_normal(), delta)
