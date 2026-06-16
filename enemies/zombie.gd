extends Path3D


const FOOTSTEP_SOUND_PATHS: Array[String] = [
	"res://Assets/audio/footstep1.wav",
	"res://Assets/audio/footstep2.wav",
	"res://Assets/audio/footstep3.wav",
	"res://Assets/audio/footstep4.wav",
]

## PathFollow3D that carries the zombie visual and contact area.
@export var path_follow_path: NodePath = ^"PathFollow3D"
## Node moved vertically while the zombie drops in.
@export var drop_pivot_path: NodePath = ^"PathFollow3D/DropPivot"
## Visual pivot rotated toward the zombie's current shuffle direction.
@export var pivot_path: NodePath = ^"PathFollow3D/DropPivot/Pivot"
## Imported zombie character subtree containing the AnimationPlayer.
@export var character_path: NodePath = ^"PathFollow3D/DropPivot/Pivot/Character"
## Area that kills the player on contact.
@export var kill_area_path: NodePath = ^"PathFollow3D/DropPivot/KillArea"
## Ground shadow shown while the zombie is active.
@export var shadow_path: NodePath = ^"PathFollow3D/ZombieShadow"
## Light used to make the zombie readable before the player gets close.
@export var zombie_light_path: NodePath = ^"PathFollow3D/DropPivot/Pivot/ZombieLight"
## Seconds a player must remain inside the contact area before death triggers.
@export var kill_confirmation_time := 0.08
## Seconds after scene start before this zombie drops in.
@export var drop_in_time := 0.0
## Height above the patrol path used at the start of the drop-in.
@export var drop_height := 3.2
## Seconds taken to fall from drop_height to the path.
@export var drop_duration := 0.55
## Starting position along the patrol path, where 0 is the path start and 1 is the path end.
@export_range(0.0, 1.0, 0.001) var start_progress_ratio := 0.0
## World units per second along the patrol path.
@export var shuffle_speed := 0.75
## If true, the zombie wraps from the end of an open path back to the start.
@export var loop_patrol := true
## If true, the zombie turns around at the ends of an open path.
@export var reverse_at_path_ends := true
## How quickly the visual turns toward the current movement direction.
@export var turn_speed := 1.5
## Animation played while the zombie is moving.
@export var walk_animation_name := "walk"
## Animation played if the zombie has no usable movement.
@export var idle_animation_name := "idle"
## Keeps the walk cycle at a shuffling pace even if path speed is adjusted.
@export var walk_animation_speed_scale := 0.45
## Minimum horizontal speed required to play zombie footstep sounds.
@export var footstep_speed_threshold := 0.1
## Base travel distance between zombie footsteps.
@export var footstep_distance := 0.95
## Random distance added or subtracted from each footstep interval.
@export var footstep_distance_variance := 0.24
## Lowest random pitch scale used for each zombie footstep.
@export var footstep_pitch_min := 0.58
## Highest random pitch scale used for each zombie footstep.
@export var footstep_pitch_max := 0.78
## Footstep volume at the speed threshold, in decibels.
@export var footstep_volume_min_db := -5.0
## Footstep volume near full shuffle speed, in decibels.
@export var footstep_volume_max_db := 0.0

@export_group("Light")
## Enables the zombie's warning light.
@export var zombie_light_enabled := true
## Color of the zombie's warning light.
@export var zombie_light_color := Color(0.85, 1.0, 0.62, 1.0)
## Brightness of the zombie's warning light.
@export var zombie_light_energy := 0.95
## Radius reached by the zombie's warning light.
@export var zombie_light_range := 4.2
## Falloff curve for the zombie's warning light.
@export var zombie_light_attenuation := 1.45
## Whether the zombie's warning light casts shadows.
@export var zombie_light_cast_shadows := true
@export_group("")

@onready var path_follow := get_node_or_null(path_follow_path) as PathFollow3D
@onready var drop_pivot := get_node_or_null(drop_pivot_path) as Node3D
@onready var pivot := get_node_or_null(pivot_path) as Node3D
@onready var character := get_node_or_null(character_path) as Node3D
@onready var kill_area := get_node_or_null(kill_area_path) as Area3D
@onready var shadow := get_node_or_null(shadow_path) as Node3D
@onready var zombie_light := get_node_or_null(zombie_light_path) as OmniLight3D

var patrol_direction := 1.0
var footstep_sounds: Array[AudioStream] = []
var footstep_distance_accumulator := 0.0
var next_footstep_distance := 1.0
var animation_player: AnimationPlayer
var current_animation := ""
var resolved_walk_animation := ""
var resolved_idle_animation := ""
var kill_overlap_times: Dictionary = {}
var elapsed_time := 0.0
var drop_elapsed := 0.0
var has_dropped_in := false
var is_dropping_in := false


func _ready() -> void:
	randomize()
	_load_footstep_sounds()
	_randomize_next_footstep_distance()
	_apply_start_progress()
	_configure_shadow_casting()
	_configure_zombie_light()

	if kill_area != null:
		kill_area.body_entered.connect(_on_kill_area_body_entered)

	if character != null:
		animation_player = _find_animation_player(character)
		_resolve_animation_names()

	if drop_in_time > 0.0:
		_set_active_visible(false)
	else:
		_finish_drop_in()


func _physics_process(delta: float) -> void:
	if path_follow == null or curve == null:
		_update_animation(0.0)
		return

	if not _update_drop_in(delta):
		_update_animation(0.0)
		return

	var previous_position := path_follow.global_position
	_advance_patrol(delta)

	var displacement := path_follow.global_position - previous_position
	var horizontal_displacement := Vector3(displacement.x, 0.0, displacement.z)
	var horizontal_speed := horizontal_displacement.length() / maxf(delta, 0.001)

	_update_facing(horizontal_displacement, delta)
	_update_animation(horizontal_speed)
	_update_footsteps(delta, horizontal_speed)
	_update_kill_overlaps(delta)


func _apply_start_progress() -> void:
	if path_follow == null or curve == null:
		return

	var path_length := curve.get_baked_length()
	if path_length <= 0.001:
		return

	path_follow.progress = clampf(start_progress_ratio, 0.0, 1.0) * path_length


func _update_drop_in(delta: float) -> bool:
	if has_dropped_in:
		return true

	elapsed_time += delta
	if not is_dropping_in and elapsed_time < drop_in_time:
		return false

	if not is_dropping_in:
		_start_drop_in()

	drop_elapsed += delta
	var duration := maxf(drop_duration, 0.001)
	var ratio := clampf(drop_elapsed / duration, 0.0, 1.0)
	var eased_ratio := 1.0 - pow(1.0 - ratio, 3.0)
	if drop_pivot != null:
		drop_pivot.position.y = lerpf(maxf(drop_height, 0.0), 0.0, eased_ratio)

	if ratio >= 1.0:
		_finish_drop_in()
		return true

	return false


func _start_drop_in() -> void:
	is_dropping_in = true
	drop_elapsed = 0.0
	if drop_pivot != null:
		drop_pivot.position.y = maxf(drop_height, 0.0)
	_set_active_visible(true)
	_set_kill_area_enabled(false)


func _finish_drop_in() -> void:
	has_dropped_in = true
	is_dropping_in = false
	if drop_pivot != null:
		drop_pivot.position.y = 0.0
	_set_active_visible(true)
	_set_kill_area_enabled(true)
	_update_animation(shuffle_speed)


func _set_active_visible(active: bool) -> void:
	if drop_pivot != null:
		drop_pivot.visible = active
	if shadow != null:
		shadow.visible = active
	if zombie_light != null:
		zombie_light.visible = active and zombie_light_enabled
	_set_kill_area_enabled(active and has_dropped_in)


func _set_kill_area_enabled(enabled: bool) -> void:
	kill_overlap_times.clear()
	if kill_area != null:
		kill_area.monitoring = enabled


func _configure_shadow_casting() -> void:
	if character == null:
		return

	_set_shadow_casting(character)


func _configure_zombie_light() -> void:
	if zombie_light == null:
		return

	zombie_light.light_color = zombie_light_color
	zombie_light.light_energy = zombie_light_energy
	zombie_light.omni_range = zombie_light_range
	zombie_light.omni_attenuation = zombie_light_attenuation
	zombie_light.shadow_enabled = zombie_light_cast_shadows
	zombie_light.visible = zombie_light_enabled


func _set_shadow_casting(node: Node) -> void:
	if node is GeometryInstance3D:
		(node as GeometryInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON

	for child in node.get_children():
		_set_shadow_casting(child)


func _advance_patrol(delta: float) -> void:
	var path_length := curve.get_baked_length()
	if path_length <= 0.001 or shuffle_speed <= 0.0:
		return

	var next_progress := path_follow.progress + shuffle_speed * patrol_direction * delta
	var should_loop := loop_patrol or curve.closed
	path_follow.loop = should_loop

	if should_loop:
		path_follow.progress = wrapf(next_progress, 0.0, path_length)
		return

	path_follow.loop = false

	if reverse_at_path_ends:
		while next_progress < 0.0 or next_progress > path_length:
			if next_progress > path_length:
				next_progress = path_length - (next_progress - path_length)
				patrol_direction = -1.0
			elif next_progress < 0.0:
				next_progress = -next_progress
				patrol_direction = 1.0

	path_follow.progress = clampf(next_progress, 0.0, path_length)


func _update_facing(horizontal_displacement: Vector3, delta: float) -> void:
	if pivot == null or horizontal_displacement.length_squared() <= 0.000001:
		return

	var direction := horizontal_displacement.normalized()
	pivot.rotation.y = lerp_angle(pivot.rotation.y, atan2(direction.x, direction.z), turn_speed * delta)


func _update_animation(horizontal_speed: float) -> void:
	if animation_player == null:
		return

	if horizontal_speed >= footstep_speed_threshold:
		animation_player.speed_scale = walk_animation_speed_scale
		_play_animation(walk_animation_name)
	else:
		animation_player.speed_scale = 1.0
		_play_animation(idle_animation_name)


func _play_animation(animation_name: String) -> void:
	var resolved_animation_name := _resolve_animation_name(animation_name)
	if resolved_animation_name.is_empty():
		return

	if current_animation == resolved_animation_name and animation_player.is_playing():
		return

	current_animation = resolved_animation_name
	animation_player.play(resolved_animation_name, 0.15)


func _resolve_animation_names() -> void:
	resolved_walk_animation = _resolve_animation_name(walk_animation_name)
	resolved_idle_animation = _resolve_animation_name(idle_animation_name)
	if resolved_walk_animation.is_empty():
		push_warning("Zombie character has no walk animation.")


func _resolve_animation_name(animation_name: String) -> String:
	if animation_player == null or animation_name.is_empty():
		return ""

	if animation_player.has_animation(animation_name):
		return animation_name

	var requested := animation_name.to_lower()
	for imported_animation_name in animation_player.get_animation_list():
		var imported := String(imported_animation_name)
		var normalized := imported.to_lower()
		if normalized == requested or normalized.ends_with("/" + requested):
			return imported

	return ""


func _load_footstep_sounds() -> void:
	footstep_sounds.clear()

	for sound_path in FOOTSTEP_SOUND_PATHS:
		var stream := load(sound_path) as AudioStream
		if stream != null:
			footstep_sounds.append(stream)


func _update_footsteps(delta: float, horizontal_speed: float) -> void:
	if footstep_sounds.is_empty():
		return

	if horizontal_speed < footstep_speed_threshold:
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
	next_footstep_distance = maxf(0.1, footstep_distance + randf_range(-variance, variance))


func _play_footstep(horizontal_speed: float) -> void:
	var sound_player := AudioStreamPlayer3D.new()
	sound_player.name = "ZombieFootstepAudio"
	sound_player.stream = footstep_sounds.pick_random()
	sound_player.pitch_scale = randf_range(footstep_pitch_min, footstep_pitch_max)
	var speed_volume_boost := clampf((horizontal_speed - footstep_speed_threshold) / maxf(shuffle_speed - footstep_speed_threshold, 0.001), 0.0, 1.0)
	sound_player.volume_db = lerpf(footstep_volume_min_db, footstep_volume_max_db, speed_volume_boost) + randf_range(-1.0, 1.0)
	sound_player.finished.connect(sound_player.queue_free)

	if path_follow != null:
		path_follow.add_child(sound_player)
	else:
		add_child(sound_player)

	sound_player.play()


func _update_kill_overlaps(delta: float) -> void:
	if kill_area == null:
		return

	var overlapping_bodies := kill_area.get_overlapping_bodies()
	for tracked_body in kill_overlap_times.keys():
		if not overlapping_bodies.has(tracked_body):
			kill_overlap_times.erase(tracked_body)

	for body in kill_area.get_overlapping_bodies():
		if body == null or not _is_live_player_body(body):
			continue

		var overlap_time := float(kill_overlap_times.get(body, 0.0)) + delta
		kill_overlap_times[body] = overlap_time
		if overlap_time >= kill_confirmation_time:
			_kill_body_if_player(body)


func _on_kill_area_body_entered(body: Node3D) -> void:
	if _is_live_player_body(body):
		kill_overlap_times[body] = 0.0


func _kill_body_if_player(body: Node) -> void:
	if not _is_live_player_body(body):
		return

	body.die_from_flames()


func _is_live_player_body(body: Node) -> bool:
	if body == null:
		return false

	if body.has_method("is_dead") and body.is_dead():
		return false

	return body.has_method("die_from_flames")


func _find_animation_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node

	for child in node.get_children():
		var result := _find_animation_player(child)
		if result != null:
			return result

	return null
