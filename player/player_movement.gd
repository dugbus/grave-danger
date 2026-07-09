extends Node
class_name GDPlayerMovement


# Movement is a child component of Player. It writes to the parent
# CharacterBody3D velocity, but leaves move_and_slide() to player.gd so every
# feature contributes to one final physics move each frame.

# Base movement tuning for an unloaded character.
const SPEED = 5.0
const ROTATION_SPEED = 12.0
const ACCELERATION = 18.0
const DECELERATION = 22.0

# How much analogue stick input is needed before the player starts walking.
const WALK_INPUT_THRESHOLD = 0.05

# Lowest movement multipliers when carrying the maximum number of coins.
const MIN_WEIGHT_SPEED_MULTIPLIER = 0.35
const MIN_WEIGHT_ACCELERATION_MULTIPLIER = 0.28
const MIN_WEIGHT_DECELERATION_MULTIPLIER = 0.2
const MIN_WEIGHT_ROTATION_MULTIPLIER = 0.35

const JUMP_SETTINGS := preload("res://game/player_jump_settings.tres")
const DETERMINISTIC_SEED := preload("res://game/deterministic_seed.gd")
const FOOTSTEP_SOUND_PATHS: Array[String] = [
	"res://Assets/audio/footstep1.wav",
	"res://Assets/audio/footstep2.wav",
	"res://Assets/audio/footstep3.wav",
	"res://Assets/audio/footstep4.wav",
]

## Visual pivot rotated toward the current movement direction.
@export var pivot_path: NodePath = ^"../Pivot"
## Minimum horizontal speed required to play footstep sounds.
@export var footstep_speed_threshold := 0.35
## Base travel distance between footstep sounds.
@export var footstep_distance := 0.7
## Random distance added or subtracted from each footstep interval.
@export var footstep_distance_variance := 0.18
## Lowest random pitch scale used for each footstep.
@export var footstep_pitch_min := 0.92
## Highest random pitch scale used for each footstep.
@export var footstep_pitch_max := 1.08
## Footstep volume at the speed threshold, in decibels.
@export var footstep_volume_min_db := 0.0
## Footstep volume near full walking speed, in decibels.
@export var footstep_volume_max_db := 4.0
## Height above the player origin used by sideways squeeze probes.
@export var squeeze_probe_height := 0.35
## Maximum side clearance distance checked while moving through gaps.
@export var squeeze_probe_distance := 0.85
## Gap width that applies the minimum squeeze speed multiplier.
@export var squeeze_min_gap_width := 0.72
## Gap width at which no squeeze speed reduction is applied.
@export var squeeze_full_speed_gap_width := 1.35
## Slowest movement multiplier allowed while squeezing through tight gaps.
@export var squeeze_min_speed_multiplier := 0.45

@onready var player := get_parent() as CharacterBody3D
@onready var pivot: Node3D = get_node_or_null(pivot_path)

var footstep_sounds: Array[AudioStream] = []
var jump_sound: AudioStream
var footstep_distance_accumulator := 0.0
var next_footstep_distance := 1.0
var audio_rng := RandomNumberGenerator.new()


func _ready() -> void:
	audio_rng.seed = DETERMINISTIC_SEED.from_node(self, 0, &"player_movement_audio")
	_load_footstep_sounds()
	_load_jump_sound()
	_randomize_next_footstep_distance()


func apply_gravity_and_jump(delta: float, gold_inventory: Node) -> void:
	# Vertical motion is handled before horizontal movement so jumping and
	# falling are independent of analogue stick direction.
	if player == null:
		return

	if not player.is_on_floor():
		player.velocity += player.get_gravity() * delta

	if Input.is_action_just_pressed("jump") and player.is_on_floor():
		# Carrying coins makes jumps shorter through the inventory weight curve.
		var settings := JUMP_SETTINGS as GDPlayerJumpSettings
		var gravity_magnitude := player.get_gravity().length()
		var jump_velocity := settings.get_jump_velocity(gravity_magnitude)
		player.velocity.y = jump_velocity * gold_inventory.weight_multiplier(1.0, settings.min_weight_jump_multiplier)
		_play_jump_sound(settings)


func update_walk(delta: float, gold_inventory: Node) -> float:
	# Returns input strength so the animation component can match walk playback
	# speed to the same analogue input used for movement.
	if player == null:
		return 0.0

	# Input.get_vector gives a normalized keyboard direction and preserves
	# partial analogue stick tilt for slower movement.
	var input_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var input_strength := clampf(input_dir.length(), 0.0, 1.0)
	var effective_input_strength := input_strength
	var direction := _get_camera_relative_direction(input_dir)

	# Only the X/Z velocity is steered here. Y velocity is owned by gravity/jump.
	var horizontal_velocity := Vector2(player.velocity.x, player.velocity.z)

	# The inventory component owns the carrying-weight curve; movement only asks
	# for the multiplier it needs for each tuning value.
	var speed: float = SPEED * gold_inventory.weight_multiplier(1.0, MIN_WEIGHT_SPEED_MULTIPLIER)
	var acceleration: float = ACCELERATION * gold_inventory.weight_multiplier(1.0, MIN_WEIGHT_ACCELERATION_MULTIPLIER)
	var deceleration: float = DECELERATION * gold_inventory.weight_multiplier(1.0, MIN_WEIGHT_DECELERATION_MULTIPLIER)
	var rotation_speed: float = ROTATION_SPEED * gold_inventory.weight_multiplier(1.0, MIN_WEIGHT_ROTATION_MULTIPLIER)

	if input_strength > WALK_INPUT_THRESHOLD:
		var squeeze_speed_multiplier := _get_squeeze_speed_multiplier(direction)
		effective_input_strength *= squeeze_speed_multiplier

		# Full stick tilt reaches full speed. Partial tilt creates a slower
		# walk without needing a separate "walk" button.
		var target_velocity: Vector2 = Vector2(direction.x, direction.z) * speed * effective_input_strength
		horizontal_velocity = horizontal_velocity.move_toward(target_velocity, acceleration * delta)

		if pivot != null:
			# The visual pivot rotates toward movement while the physics body
			# keeps its authored collision orientation.
			pivot.rotation.y = lerp_angle(pivot.rotation.y, atan2(direction.x, direction.z), rotation_speed * delta)
	else:
		horizontal_velocity = horizontal_velocity.move_toward(Vector2.ZERO, deceleration * delta)

	player.velocity.x = horizontal_velocity.x
	player.velocity.z = horizontal_velocity.y

	_update_footsteps(delta, horizontal_velocity.length())

	return effective_input_strength


func update_dead_motion(delta: float) -> void:
	# Dead players no longer accept input, but they still decelerate and obey
	# gravity so the body settles naturally after the death trigger.
	if player == null:
		return

	player.velocity.x = move_toward(player.velocity.x, 0.0, DECELERATION * delta)
	player.velocity.z = move_toward(player.velocity.z, 0.0, DECELERATION * delta)
	footstep_distance_accumulator = 0.0

	if not player.is_on_floor():
		player.velocity += player.get_gravity() * delta


func _load_footstep_sounds() -> void:
	footstep_sounds = GDAudio.load_streams(FOOTSTEP_SOUND_PATHS)


func _load_jump_sound() -> void:
	var settings := JUMP_SETTINGS as GDPlayerJumpSettings
	jump_sound = GDAudio.load_stream(settings.jump_sound_path)


func _update_footsteps(delta: float, horizontal_speed: float) -> void:
	if footstep_sounds.is_empty():
		return

	if (
		player == null
		or not player.is_on_floor()
		or player.velocity.y > 0.05
		or horizontal_speed < footstep_speed_threshold
	):
		footstep_distance_accumulator = 0.0
		return

	footstep_distance_accumulator += horizontal_speed * delta
	if footstep_distance_accumulator < next_footstep_distance:
		return

	footstep_distance_accumulator = 0.0
	_randomize_next_footstep_distance()
	_play_footstep(horizontal_speed)


func _randomize_next_footstep_distance() -> void:
	var variance := maxf(footstep_distance_variance, 0.0)
	next_footstep_distance = maxf(0.1, footstep_distance + audio_rng.randf_range(-variance, variance))


func _play_jump_sound(settings: GDPlayerJumpSettings) -> void:
	if jump_sound == null:
		return

	var audio_parent: Node = player as Node if player != null else self as Node
	GDAudio.play_one_shot_3d(
		audio_parent,
		jump_sound,
		"JumpAudio",
		settings.jump_volume_db,
		audio_rng.randf_range(settings.jump_pitch_min, settings.jump_pitch_max)
	)


func _play_footstep(horizontal_speed: float) -> void:
	var audio_parent: Node = player as Node if player != null else self as Node

	GDAudio.play_random_footstep_3d(
		audio_parent,
		footstep_sounds,
		"FootstepAudio",
		horizontal_speed,
		footstep_speed_threshold,
		SPEED,
		footstep_volume_min_db,
		footstep_volume_max_db,
		footstep_pitch_min,
		footstep_pitch_max,
		audio_rng
	)


func _get_squeeze_speed_multiplier(direction: Vector3) -> float:
	if player == null or direction.is_zero_approx() or squeeze_probe_distance <= 0.0:
		return 1.0

	var side := Vector3(-direction.z, 0.0, direction.x).normalized()
	var origin := player.global_position + Vector3.UP * squeeze_probe_height
	var left_clearance := _probe_side_clearance(origin, side)
	var right_clearance := _probe_side_clearance(origin, -side)

	if left_clearance >= squeeze_probe_distance or right_clearance >= squeeze_probe_distance:
		return 1.0

	var gap_width := left_clearance + right_clearance
	var min_gap_width := maxf(squeeze_min_gap_width, 0.01)
	var full_speed_gap_width := maxf(squeeze_full_speed_gap_width, min_gap_width + 0.01)
	var gap_factor := clampf((gap_width - min_gap_width) / (full_speed_gap_width - min_gap_width), 0.0, 1.0)
	var min_multiplier := clampf(squeeze_min_speed_multiplier, 0.05, 1.0)

	return lerpf(min_multiplier, 1.0, gap_factor)


func _probe_side_clearance(origin: Vector3, direction: Vector3) -> float:
	var world := player.get_world_3d()
	if world == null:
		return squeeze_probe_distance

	var query := PhysicsRayQueryParameters3D.create(
		origin,
		origin + direction * squeeze_probe_distance,
		player.collision_mask,
		[player.get_rid()]
	)
	query.collide_with_areas = false
	query.collide_with_bodies = true

	var hit := world.direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return squeeze_probe_distance

	return origin.distance_to(hit["position"])


func _get_camera_relative_direction(input_dir: Vector2) -> Vector3:
	# Converts 2D movement input into world-space X/Z movement using the active
	# camera. This keeps controls intuitive as the follow camera rotates.
	if input_dir.is_zero_approx():
		return Vector3.ZERO

	var camera := get_viewport().get_camera_3d()
	if camera == null:
		# Fallback for tests or scenes without a camera.
		return Vector3(input_dir.x, 0.0, input_dir.y).normalized()

	# Flatten the camera basis so input never adds vertical movement.
	var camera_forward := -camera.global_transform.basis.z
	camera_forward.y = 0.0
	camera_forward = camera_forward.normalized()

	var camera_right := camera.global_transform.basis.x
	camera_right.y = 0.0
	camera_right = camera_right.normalized()

	# In this project pressing up should move deeper into the camera view.
	return (camera_right * input_dir.x - camera_forward * input_dir.y).normalized()
