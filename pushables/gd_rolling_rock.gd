# Rules for rolling rock.
# If pushed in a corner the player must be able to move it out by pushing against the ball.

class_name RollingRock
extends GDSpherePushable


@export_group("Visual Rolling")
@export var visual_rock_path: NodePath = NodePath("RollingRock")
@export_range(0.01, 10.0, 0.01) var visual_roll_radius := 0.5
@export var visual_roll_enabled := true

@export_group("Rolling Audio")
@export var rolling_audio_path: NodePath = NodePath("RollingRockAudio")
@export var min_audio_speed := 0.05
@export var max_audio_speed := 3.0
@export var rolling_volume_db := 12.0
@export var silent_volume_db := -80.0
@export var movement_sound_threshold := 0.025
@export_range(0.0, 1.0, 0.01) var trapped_audio_speed_threshold := 0.08
@export_range(0.0, 0.5, 0.01) var trapped_audio_hold_seconds := 0.08
@export_range(0.001, 0.5, 0.001) var audio_fade_in_seconds := 0.035
@export_range(0.001, 0.5, 0.001) var audio_fade_out_seconds := 0.09
@export_range(0.001, 0.5, 0.001) var trapped_audio_fade_seconds := 0.035

var visual_rock: Node3D
var rolling_audio: AudioStreamPlayer3D
var previous_position := Vector3.ZERO
var current_audio_volume_db := -80.0
var trapped_audio_timer := 0.0


func _ready() -> void:
	super._ready()

	previous_position = global_position
	visual_rock = get_node_or_null(visual_rock_path)
	rolling_audio = get_node_or_null(rolling_audio_path)
	current_audio_volume_db = silent_volume_db

	if rolling_audio:
		rolling_audio.volume_db = current_audio_volume_db
		rolling_audio.play()


func push_from_character(character_velocity: Vector3, collision_normal: Vector3, delta: float) -> void:
	super.push_from_character(character_velocity, collision_normal, delta)


func _physics_process(delta: float) -> void:
	var movement := global_position - previous_position
	movement.y = 0.0

	var distance := movement.length()
	var speed := distance / maxf(delta, 0.0001)

	_update_rolling_audio(speed, delta)

	if not visual_roll_enabled or visual_rock == null:
		previous_position = global_position
		return

	if distance <= 0.001:
		previous_position = global_position
		return

	var direction := movement.normalized()
	var roll_axis := Vector3.UP.cross(direction).normalized()
	var roll_angle := distance / visual_roll_radius

	visual_rock.rotate(roll_axis, roll_angle)

	previous_position = global_position


func _update_rolling_audio(speed: float, delta: float) -> void:
	if rolling_audio == null:
		return

	trapped_audio_timer = maxf(trapped_audio_timer - delta, 0.0)

	if is_recent_push_blocked_by_wall() and speed <= trapped_audio_speed_threshold:
		trapped_audio_timer = trapped_audio_hold_seconds

	var audible_speed_threshold := maxf(min_audio_speed, movement_sound_threshold)
	var target_volume_db := silent_volume_db

	if speed > audible_speed_threshold and trapped_audio_timer <= 0.0:
		target_volume_db = rolling_volume_db

	var fade_seconds := audio_fade_out_seconds

	if target_volume_db > current_audio_volume_db:
		fade_seconds = audio_fade_in_seconds

	if trapped_audio_timer > 0.0:
		fade_seconds = trapped_audio_fade_seconds

	current_audio_volume_db = _move_volume_towards(
		current_audio_volume_db,
		target_volume_db,
		fade_seconds,
		delta
	)

	rolling_audio.volume_db = current_audio_volume_db

	if current_audio_volume_db > silent_volume_db + 1.0 and not rolling_audio.playing:
		rolling_audio.play()


func _move_volume_towards(from_volume_db: float, to_volume_db: float, seconds: float, delta: float) -> float:
	if seconds <= 0.0:
		return to_volume_db

	var volume_range := maxf(absf(rolling_volume_db - silent_volume_db), 1.0)
	var max_step := volume_range * (delta / seconds)

	return move_toward(from_volume_db, to_volume_db, max_step)
