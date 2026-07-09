@tool
# gdlint: disable=max-file-lines
extends Path3D
class_name GDKillBoundary3D


const EDITOR_PREVIEW_CONTAINER_NAME := "EditorPreview"
const BOUNDARY_CENTER_NAME := "BoundaryCenter"
const ANIMATION_PLAYER_NAME := "BoundaryAnimationPlayer"
const DEFAULT_ANIMATION_NAME := &"kill_boundary"
const MOVEMENT_SPEED_TRACK_PATH := ^".:movement_speed"
const BOUNDARY_SCALE_X_TRACK_PATH := ^".:boundary_scale_x"
const BOUNDARY_SCALE_Z_TRACK_PATH := ^".:boundary_scale_z"
const BOUNDARY_ROTATION_Z_RADIANS_TRACK_PATH := ^".:boundary_rotation_z_radians"
const LEGACY_SCALE_ROTATION_TARGET_TRACK_PATH := ^".:scale_rotation_target"
const LEGACY_SCALE_TRACK_PATH := ^"BoundaryCenter"
const NEAR_FLAMES_SOUND_PATH := "res://Assets/audio/near-the-flames.mp3"
const GHOST_BOUNDARY_SOUND_PATH := "res://Assets/audio/ghost-boundary.mp3"
const GHOST_BOUNDARY_VOLUME_BOOST_DB := 8.0
const PLAYER_BOUNDARY_BLOCKER_COLLISION_LAYER := 16
const FLAME_SHADER := preload("res://levels/common/kill_boundary_effects/kill_boundary_flame_effect.gdshader")
const GHOST_SHADER := preload("res://levels/common/kill_boundary_effects/kill_boundary_ghost_effect.gdshader")
const GHOST_TEXTURE := preload("res://Assets/ghost1.png")
const SHAPE_RECTANGLE := 0
const SHAPE_CIRCLE := 1
const MAX_SHAPE_INDEX := 1
const EFFECT_FLAME := 0
const EFFECT_GHOST := 1
const EFFECT_NONE := 2
const EDITOR_SCRUB_TIME_EPSILON := 0.05
@export_group("Animation")
## Animation controlling path progress, scale, shape morph, and future properties.
@export var boundary_animation: Animation:
	set(value):
		boundary_animation = value
		_sync_animation_player()

## Total loop duration. Changing this retimes every animation track proportionally.
@export_range(0.1, 3600.0, 0.1, "or_greater", "suffix:s") var playback_duration := 4.0:
	set(value):
		var new_duration := maxf(value, 0.1)
		_retime_boundary_animation(new_duration)
		playback_duration = new_duration

## Starts the boundary animation automatically during gameplay.
@export var autoplay_boundary_animation := true

## Loops BoundaryCenter back to the start when movement passes the end of the path.
@export var loop_boundary_path := true:
	set(value):
		loop_boundary_path = value
		_configure_path_follow()

## Distance travelled along the path per second. Key this to create pressure changes.
@export_range(0.0, 20.0, 0.05, "or_greater", "suffix:m/s") var movement_speed := 1.0

## BoundaryCenter local X scale.
@export_range(0.001, 20.0, 0.001, "or_greater") var boundary_scale_x := 1.0:
	set(value):
		boundary_scale_x = maxf(value, 0.001)
		_apply_boundary_scale_rotation()

## BoundaryCenter local Z scale.
@export_range(0.001, 20.0, 0.001, "or_greater") var boundary_scale_z := 1.0:
	set(value):
		boundary_scale_z = maxf(value, 0.001)
		_apply_boundary_scale_rotation()

## Rotation-key value applied around BoundaryCenter's local Y (height) axis in radians.
@export var boundary_rotation_z_radians := 0.0:
	set(value):
		boundary_rotation_z_radians = value
		_apply_boundary_scale_rotation()

@export_group("Boundary")
## Width and depth available to the boundary shape, in world units.
@export var bounds_size := Vector2(8.0, 8.0):
	set(value):
		bounds_size = Vector2(maxf(value.x, 0.1), maxf(value.y, 0.1))
		_sync_boundary()

## Largest horizontal BoundaryCenter scale the camera will try to keep fully visible.
## The kill boundary itself may grow beyond this without forcing further zoom-out.
@export_range(0.1, 20.0, 0.05, "or_greater") var camera_fit_scale_limit := 1.75

## Shape index and interpolation: rectangle = 0, circle = 1.
## Future shapes can be added as successive indices in _get_shape_profile_point().
@export_range(0.0, 8.0, 0.001) var shape_morph := 0.0:
	set(value):
		shape_morph = clampf(value, 0.0, float(MAX_SHAPE_INDEX))
		_sync_boundary()

## Number of segments used by rendering, detection, and player blockers.
@export_range(8, 128, 1) var boundary_segments := 32:
	set(value):
		boundary_segments = maxi(value, 8)
		_sync_boundary()

## Visual effect rendered around the kill boundary. Damage, audio, and blockers are independent of this.
@export_enum("Flame", "Ghost", "None") var render_effect := EFFECT_FLAME:
	set(value):
		render_effect = clampi(value, EFFECT_FLAME, EFFECT_NONE)
		_sync_boundary()

## Thickness of each visible flame strip, in world units.
@export_range(0.01, 5.0, 0.01) var flame_thickness := 0.18:
	set(value):
		flame_thickness = maxf(value, 0.01)
		_sync_boundary()

## Depth of the volumetric fire, independent of its damage collision thickness.
@export_range(0.1, 3.0, 0.05) var flame_visual_depth := 0.7:
	set(value):
		flame_visual_depth = maxf(value, 0.1)
		_sync_boundary()

## Height of the flame mesh and damage volume.
@export_range(0.05, 10.0, 0.05) var flame_height := 1.55:
	set(value):
		flame_height = maxf(value, 0.05)
		_sync_boundary()

## Local Y offset of the kill boundary relative to its center path node.
@export var flame_y := 0.0:
	set(value):
		flame_y = value
		_sync_boundary()

@export_group("Flame Effect")
## Opacity multiplier for the flame effect only.
@export_range(0.0, 1.0, 0.01) var flame_effect_opacity := 1.0:
	set(value):
		flame_effect_opacity = clampf(value, 0.0, 1.0)
		_sync_boundary()

## Volumetric density multiplier for the flame effect.
@export_range(0.1, 8.0, 0.05) var flame_effect_density := 3.1:
	set(value):
		flame_effect_density = maxf(value, 0.1)
		_sync_boundary()

## Emission strength for the flame effect.
@export_range(0.0, 20.0, 0.1) var flame_effect_emission := 7.0:
	set(value):
		flame_effect_emission = maxf(value, 0.0)
		_sync_boundary()

## Animation speed for flame turbulence.
@export_range(0.0, 2.0, 0.01) var flame_effect_time_scale := 0.72:
	set(value):
		flame_effect_time_scale = maxf(value, 0.0)
		_sync_boundary()

@export var flame_effect_core_color := Color(1.0, 0.92, 0.42):
	set(value):
		flame_effect_core_color = value
		_sync_boundary()

@export var flame_effect_mid_color := Color(1.0, 0.28, 0.015):
	set(value):
		flame_effect_mid_color = value
		_sync_boundary()

@export var flame_effect_outer_color := Color(0.48, 0.008, 0.001):
	set(value):
		flame_effect_outer_color = value
		_sync_boundary()

@export_group("Ghost Effect")
@export var ghost_effect_color := Color(0.58, 0.9, 1.0):
	set(value):
		ghost_effect_color = value
		_sync_boundary()

@export_range(0.0, 20.0, 0.1) var ghost_effect_emission := 6.2:
	set(value):
		ghost_effect_emission = maxf(value, 0.0)
		_sync_boundary()

@export_range(0.0, 1.0, 0.01) var ghost_effect_edge_softness := 0.28:
	set(value):
		ghost_effect_edge_softness = clampf(value, 0.0, 1.0)
		_sync_boundary()

## Number of ghost ribbons spawned along each boundary segment.
@export_range(0, 8, 1) var ghost_ribbons_per_segment := 5:
	set(value):
		ghost_ribbons_per_segment = maxi(value, 0)
		_sync_boundary()

## Randomized height range for each spirit ribbon, in world units.
@export var ghost_height_range := Vector2(2.0, 3.45):
	set(value):
		ghost_height_range = _sanitize_positive_range(value, 0.1)
		_sync_boundary()

## Randomized width range for each spirit ribbon, in world units.
@export var ghost_width_range := Vector2(0.22, 0.52):
	set(value):
		ghost_width_range = _sanitize_positive_range(value, 0.01)
		_sync_boundary()

## Extra vertical travel before a spirit fades out.
@export_range(0.0, 4.0, 0.05) var ghost_rise_distance := 1.3:
	set(value):
		ghost_rise_distance = maxf(value, 0.0)
		_sync_boundary()

## Maximum sideways sine bend applied to each spirit.
@export_range(0.0, 2.0, 0.01) var ghost_wave_amplitude := 0.14:
	set(value):
		ghost_wave_amplitude = maxf(value, 0.0)
		_sync_boundary()

@export var ghost_opacity_range := Vector2(0.92, 1.18):
	set(value):
		ghost_opacity_range = _sanitize_positive_range(value, 0.0)
		_sync_boundary()

@export var ghost_rise_speed_range := Vector2(0.075, 0.18):
	set(value):
		ghost_rise_speed_range = _sanitize_positive_range(value, 0.0)
		_sync_boundary()

@export var ghost_wave_frequency_range := Vector2(3.4, 8.6):
	set(value):
		ghost_wave_frequency_range = _sanitize_positive_range(value, 0.01)
		_sync_boundary()

@export var ghost_wave_speed_range := Vector2(0.7, 1.9):
	set(value):
		ghost_wave_speed_range = _sanitize_positive_range(value, 0.0)
		_sync_boundary()

@export var ghost_lean_range := Vector2(-0.28, 0.28):
	set(value):
		ghost_lean_range = Vector2(minf(value.x, value.y), maxf(value.x, value.y))
		_sync_boundary()

@export var ghost_emerge_depth_ratio_range := Vector2(0.72, 1.02):
	set(value):
		ghost_emerge_depth_ratio_range = _sanitize_positive_range(value, 0.0)
		_sync_boundary()

@export_group("Player Blocking")
## Enables invisible collision walls around the kill boundary.
@export var player_blocking_enabled := true:
	set(value):
		player_blocking_enabled = value
		_sync_boundary()

## Extra distance outside the kill boundary where blocker walls are placed.
@export_range(0.0, 3.0, 0.01) var player_blocking_outset := 1.0:
	set(value):
		player_blocking_outset = maxf(value, 0.0)
		_sync_boundary()

## Thickness of the invisible player-blocking walls.
@export_range(0.01, 3.0, 0.01) var player_blocking_thickness := 0.75:
	set(value):
		player_blocking_thickness = maxf(value, 0.01)
		_sync_boundary()

## Height of the invisible player-blocking walls.
@export_range(0.05, 10.0, 0.05) var player_blocking_height := 1.6:
	set(value):
		player_blocking_height = maxf(value, 0.05)
		_sync_boundary()

@export_group("Flame Damage")
## Flame energy drained per second while the player is inside the flames.
@export var flame_damage_per_second := 35.0
## Distance inside the boundary edge that still counts as flame damage.
@export var flame_damage_inner_depth := 0.35
## Distance outside the boundary over which damage ramps up.
@export var outside_damage_ramp_depth := 0.65
## Highest outside-boundary damage multiplier after the ramp reaches full depth.
@export var max_outside_damage_multiplier := 6.0
## Extra vertical tolerance above and below the flame damage volume.
@export var flame_damage_vertical_margin := 0.75

@export_group("Near Flame Audio")
## Distance from flames where the near-flame audio starts fading in.
@export var near_flame_audio_distance := 4.0
## Audio volume at the far edge of the near-flame range, in decibels.
@export var near_flame_audio_min_db := -45.0
## Audio volume when the player is at or inside the flame edge, in decibels.
@export var near_flame_audio_max_db := 8.0
## Curve applied to distance-based near-flame volume; lower values rise sooner.
@export_range(0.1, 3.0, 0.05) var near_flame_audio_curve := 0.45
## Responsiveness of near-flame volume smoothing; higher values react faster.
@export var near_flame_audio_lag := 8.0

var strip_areas: Array[Area3D] = []
var strip_collisions: Array[CollisionShape3D] = []
var strip_meshes: Array[MeshInstance3D] = []
var ghost_meshes: Array[MeshInstance3D] = []
var blocker_bodies: Array[StaticBody3D] = []
var blocker_collisions: Array[CollisionShape3D] = []
var preview_meshes: Array[MeshInstance3D] = []
var preview_ghost_meshes: Array[MeshInstance3D] = []
var blocker_preview_meshes: Array[MeshInstance3D] = []
var flame_touching_bodies: Array[Node3D] = []
var preview_center_mesh: MeshInstance3D

var flame_material: ShaderMaterial
var ghost_material: ShaderMaterial
var ghost_mesh: ArrayMesh
var preview_material: StandardMaterial3D
var blocker_preview_material: StandardMaterial3D
var elapsed_time := 0.0
var near_flame_audio_player: AudioStreamPlayer
var movement_cycle_distance := 0.0
var last_animation_position := 0.0
var runtime_bounds_multiplier := 1.0
var runtime_effect_time := 0.0
var runtime_pause_token := 0
var boundary_removed_for_level := false
var runtime_bounds_tween: Tween
var permanent_runtime_bounds_multiplier := 1.0
var active_runtime_bounds_multipliers: Array[float] = []
var editor_preview_initialized := false
var editor_preview_time := 0.0
var editor_preview_animation: Animation
var is_syncing_boundary := false


func _ready() -> void:
	add_to_group("kill_boundary")
	_ensure_boundary_nodes()
	_configure_path_follow()
	_sync_animation_player()
	if boundary_animation != null:
		_sync_boundary_scale_rotation_to_animation(boundary_animation, _get_first_animation_key_time(boundary_animation))
	_apply_boundary_scale_rotation()
	_create_flame_material()
	_create_ghost_material()

	if Engine.is_editor_hint():
		_ensure_editor_preview()
		_sync_editor_preview_animation()
		_sync_boundary()
		set_process(true)
		return

	_sync_movement_to_animation()
	if not _runtime_effects_enabled():
		_set_runtime_effects_enabled(false)
		return

	_create_strips()
	_create_near_flame_audio()
	_sync_boundary()


func _notification(what: int) -> void:
	if Engine.is_editor_hint() or what != NOTIFICATION_VISIBILITY_CHANGED or not is_inside_tree():
		return

	if boundary_removed_for_level:
		return

	_set_runtime_effects_enabled(visible)


func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		_sync_editor_preview_animation()
		_sync_boundary()


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return

	if boundary_removed_for_level:
		_update_removed_boundary_visuals(delta)
		return

	if not _runtime_effects_enabled():
		_set_runtime_effects_enabled(false)
		return

	_ensure_runtime_effect_nodes()
	elapsed_time += delta
	runtime_effect_time += delta
	_sync_movement_to_animation()
	_sync_boundary()
	_update_ghost_billboards()
	_apply_flame_heat(delta)
	_update_player_blockers_enabled()
	_update_near_flame_audio(delta)


func get_bounds_center() -> Vector3:
	if not is_inside_tree():
		return position + Vector3(0.0, flame_y, 0.0)

	return _get_center_node().global_transform * Vector3(0.0, flame_y, 0.0)


func get_bounds_transform() -> Transform3D:
	if not is_inside_tree():
		return Transform3D(global_basis, get_bounds_center())

	var bounds_transform := _get_center_node().global_transform
	bounds_transform.origin = bounds_transform * Vector3(0.0, flame_y, 0.0)
	return bounds_transform


func get_camera_fit_transform() -> Transform3D:
	var fit_transform := get_bounds_transform()
	var scale_limit := maxf(camera_fit_scale_limit, 0.1)
	fit_transform.basis.x = fit_transform.basis.x.normalized() * minf(fit_transform.basis.x.length(), scale_limit)
	fit_transform.basis.z = fit_transform.basis.z.normalized() * minf(fit_transform.basis.z.length(), scale_limit)
	return fit_transform


func get_bounds_size() -> Vector2:
	if boundary_removed_for_level:
		return Vector2.ZERO

	return bounds_size * runtime_bounds_multiplier


func get_bounds_height() -> float:
	if boundary_removed_for_level:
		return 0.0

	return flame_height


func get_elapsed_time() -> float:
	return elapsed_time


func get_boundary_animation_position() -> float:
	var animation_player := get_node_or_null(ANIMATION_PLAYER_NAME) as AnimationPlayer
	if animation_player == null or animation_player.current_animation.is_empty():
		return last_animation_position

	return animation_player.current_animation_position


func get_boundary_animation_duration() -> float:
	var animation_player := get_node_or_null(ANIMATION_PLAYER_NAME) as AnimationPlayer
	if animation_player == null or not animation_player.has_animation(DEFAULT_ANIMATION_NAME):
		return 0.0

	var animation := animation_player.get_animation(DEFAULT_ANIMATION_NAME)
	return animation.length if animation != null else 0.0


func pause_runtime_for(seconds: float) -> bool:
	if boundary_removed_for_level or not _runtime_effects_enabled():
		return false

	runtime_pause_token += 1
	_set_runtime_motion_paused(true)
	_resume_runtime_motion_after(runtime_pause_token, maxf(seconds, 0.01))
	return true


func expand_runtime_bounds_percent(percent: float) -> bool:
	if boundary_removed_for_level or not _runtime_effects_enabled():
		return false

	var multiplier := 1.0 + maxf(percent, 0.0) * 0.01
	if multiplier <= 1.0:
		return false

	permanent_runtime_bounds_multiplier *= multiplier
	runtime_bounds_multiplier = _get_target_runtime_bounds_multiplier()
	_sync_boundary()
	return true


func expand_runtime_bounds_percent_for(percent: float, active_seconds: float, transition_seconds: float) -> bool:
	if boundary_removed_for_level or not _runtime_effects_enabled():
		return false

	var multiplier := 1.0 + maxf(percent, 0.0) * 0.01
	if multiplier <= 1.0:
		return false

	active_runtime_bounds_multipliers.append(multiplier)
	_animate_runtime_bounds_multiplier(_get_target_runtime_bounds_multiplier(), transition_seconds)
	_restore_runtime_bounds_after(multiplier, active_seconds, transition_seconds)
	return true


func remove_for_level(sink_seconds := 1.0, sink_distance := 3.0) -> bool:
	if boundary_removed_for_level:
		return false

	runtime_pause_token += 1
	if runtime_bounds_tween != null and runtime_bounds_tween.is_valid():
		runtime_bounds_tween.kill()
	_sync_movement_to_animation()
	_sync_boundary()
	boundary_removed_for_level = true
	_set_runtime_effects_enabled(false, true)
	set_process(false)
	_sink_removed_boundary(sink_seconds, sink_distance)
	return true


func _runtime_effects_enabled() -> bool:
	return not boundary_removed_for_level and is_inside_tree() and visible


func _ensure_runtime_effect_nodes() -> void:
	if strip_areas.is_empty():
		_create_strips()
	if near_flame_audio_player == null:
		_create_near_flame_audio()


func _set_runtime_effects_enabled(enabled: bool, keep_visuals := false) -> void:
	if boundary_removed_for_level and enabled:
		return

	for area in strip_areas:
		if is_instance_valid(area):
			area.monitoring = enabled

	for collision in strip_collisions:
		if is_instance_valid(collision):
			collision.disabled = not enabled

	for mesh in strip_meshes:
		if is_instance_valid(mesh):
			mesh.visible = (enabled or keep_visuals) and _is_flame_effect_active()

	for mesh in ghost_meshes:
		if is_instance_valid(mesh):
			mesh.visible = (enabled or keep_visuals) and _is_ghost_effect_active()

	if not enabled:
		flame_touching_bodies.clear()

	for collision in blocker_collisions:
		if is_instance_valid(collision):
			collision.disabled = true if not enabled else not player_blocking_enabled

	var animation_player := get_node_or_null(ANIMATION_PLAYER_NAME) as AnimationPlayer
	if animation_player != null:
		if (
			enabled
			and autoplay_boundary_animation
			and animation_player.has_animation(DEFAULT_ANIMATION_NAME)
			and not animation_player.is_playing()
		):
			animation_player.play(DEFAULT_ANIMATION_NAME)
		elif not enabled and keep_visuals:
			animation_player.speed_scale = 1.0
			if (
				autoplay_boundary_animation
				and animation_player.has_animation(DEFAULT_ANIMATION_NAME)
				and not animation_player.is_playing()
			):
				animation_player.play(DEFAULT_ANIMATION_NAME)
		elif not enabled and animation_player.is_playing():
			animation_player.stop(true)

	if near_flame_audio_player != null:
		near_flame_audio_player.stream_paused = not enabled
		if not enabled:
			near_flame_audio_player.volume_db = near_flame_audio_min_db


func begin_runtime_animation() -> void:
	_sync_boundary()
	play_runtime_animation()


func play_runtime_animation() -> void:
	if not autoplay_boundary_animation or not _runtime_effects_enabled():
		return

	var animation_player := get_node_or_null(ANIMATION_PLAYER_NAME) as AnimationPlayer
	if animation_player != null and animation_player.has_animation(DEFAULT_ANIMATION_NAME):
		movement_cycle_distance = 0.0
		last_animation_position = 0.0
		var center := _get_center_node() as PathFollow3D
		if center != null:
			var animation := animation_player.get_animation(DEFAULT_ANIMATION_NAME)
			_sync_boundary_scale_rotation_to_animation(animation, 0.0)
			_set_center_progress(center, 0.0)
		animation_player.play(DEFAULT_ANIMATION_NAME)


func _ensure_boundary_nodes() -> void:
	if curve == null:
		curve = _create_default_curve()

	var center := get_node_or_null(BOUNDARY_CENTER_NAME) as PathFollow3D
	if center == null:
		center = PathFollow3D.new()
		center.name = BOUNDARY_CENTER_NAME
		add_child(center)
		_set_authored_owner(center)

	_configure_path_follow()

	var animation_player := get_node_or_null(ANIMATION_PLAYER_NAME) as AnimationPlayer
	if animation_player == null:
		animation_player = AnimationPlayer.new()
		animation_player.name = ANIMATION_PLAYER_NAME
		add_child(animation_player)
		_set_authored_owner(animation_player)
	animation_player.root_node = NodePath("..")


func _set_authored_owner(node: Node) -> void:
	if not Engine.is_editor_hint():
		return

	var edited_scene_root := get_tree().edited_scene_root
	if edited_scene_root != null and (edited_scene_root == self or edited_scene_root.is_ancestor_of(self)):
		node.owner = edited_scene_root
	elif owner != null:
		node.owner = owner
	else:
		node.owner = self


func _create_default_curve() -> Curve3D:
	var default_curve := Curve3D.new()
	default_curve.add_point(Vector3.ZERO)
	default_curve.add_point(Vector3(4.0, 0.0, 0.0))
	return default_curve


func _configure_path_follow() -> void:
	var path_follow := get_node_or_null(BOUNDARY_CENTER_NAME) as PathFollow3D
	if path_follow == null:
		return

	path_follow.rotation_mode = PathFollow3D.ROTATION_NONE
	path_follow.loop = loop_boundary_path


func _get_center_node() -> Node3D:
	var center := get_node_or_null(BOUNDARY_CENTER_NAME) as Node3D
	if center != null:
		return center

	return self


func _sync_animation_player() -> void:
	if not is_inside_tree():
		return

	_ensure_boundary_nodes()
	if boundary_animation == null:
		boundary_animation = _create_default_animation()
	_upgrade_boundary_animation_tracks(boundary_animation)

	var animation_player := get_node_or_null(ANIMATION_PLAYER_NAME) as AnimationPlayer
	if animation_player == null:
		return

	if animation_player.has_animation_library(""):
		animation_player.remove_animation_library("")
	var library := AnimationLibrary.new()
	library.add_animation(DEFAULT_ANIMATION_NAME, boundary_animation)
	animation_player.add_animation_library("", library)
	animation_player.assigned_animation = DEFAULT_ANIMATION_NAME


func _create_default_animation() -> Animation:
	var animation := Animation.new()
	animation.resource_name = String(DEFAULT_ANIMATION_NAME)
	animation.length = playback_duration
	animation.loop_mode = Animation.LOOP_LINEAR

	var movement_speed_track := animation.add_track(Animation.TYPE_VALUE)
	animation.track_set_path(movement_speed_track, MOVEMENT_SPEED_TRACK_PATH)
	animation.track_set_interpolation_loop_wrap(movement_speed_track, false)
	animation.track_insert_key(movement_speed_track, 0.0, movement_speed)

	var scale_x_track := animation.add_track(Animation.TYPE_VALUE)
	animation.track_set_path(scale_x_track, BOUNDARY_SCALE_X_TRACK_PATH)
	animation.track_insert_key(scale_x_track, 0.0, boundary_scale_x)
	animation.track_insert_key(scale_x_track, playback_duration, boundary_scale_x)

	var scale_z_track := animation.add_track(Animation.TYPE_VALUE)
	animation.track_set_path(scale_z_track, BOUNDARY_SCALE_Z_TRACK_PATH)
	animation.track_insert_key(scale_z_track, 0.0, boundary_scale_z)
	animation.track_insert_key(scale_z_track, playback_duration, boundary_scale_z)

	var rotation_z_track := animation.add_track(Animation.TYPE_VALUE)
	animation.track_set_path(rotation_z_track, BOUNDARY_ROTATION_Z_RADIANS_TRACK_PATH)
	animation.track_insert_key(rotation_z_track, 0.0, boundary_rotation_z_radians)
	animation.track_insert_key(rotation_z_track, playback_duration, boundary_rotation_z_radians)

	var shape_track := animation.add_track(Animation.TYPE_VALUE)
	animation.track_set_path(shape_track, NodePath(".:shape_morph"))
	animation.track_insert_key(shape_track, 0.0, shape_morph)
	animation.track_insert_key(shape_track, playback_duration, shape_morph)
	return animation


func _sync_movement_to_animation() -> void:
	if not is_inside_tree():
		return

	var animation_player := get_node_or_null(ANIMATION_PLAYER_NAME) as AnimationPlayer
	var center := _get_center_node() as PathFollow3D
	if animation_player == null or center == null or not animation_player.has_animation(DEFAULT_ANIMATION_NAME):
		return

	var animation := animation_player.get_animation(DEFAULT_ANIMATION_NAME)
	if animation_player.current_animation.is_empty():
		return
	var animation_position := animation_player.current_animation_position
	if (
		not Engine.is_editor_hint()
		and animation_player.is_playing()
		and animation_position + 0.001 < last_animation_position
	):
		movement_cycle_distance += _calculate_travel_distance(animation, animation.length)

	_sync_boundary_scale_rotation_to_animation(animation, animation_position)
	_set_center_progress(center, movement_cycle_distance + _calculate_travel_distance(animation, animation_position))
	last_animation_position = animation_position


func _update_removed_boundary_visuals(delta: float) -> void:
	elapsed_time += delta
	runtime_effect_time += delta
	_sync_movement_to_animation()
	_sync_boundary(true)
	_update_ghost_billboards()


func _sync_editor_preview_animation() -> void:
	if not Engine.is_editor_hint() or not is_inside_tree():
		return

	var animation_player := get_node_or_null(ANIMATION_PLAYER_NAME) as AnimationPlayer
	var center := _get_center_node() as PathFollow3D
	if animation_player == null or center == null or not animation_player.has_animation(DEFAULT_ANIMATION_NAME):
		return

	var animation := animation_player.get_animation(DEFAULT_ANIMATION_NAME)
	var preview_time := _get_editor_preview_time(animation_player, animation)
	_sync_boundary_scale_rotation_to_animation(animation, preview_time)
	_set_center_progress(center, _calculate_travel_distance(animation, preview_time))
	last_animation_position = preview_time


func _set_center_progress(center: PathFollow3D, target_progress: float) -> void:
	var sanitized_progress := maxf(target_progress, 0.0)
	if Engine.is_editor_hint() and is_zero_approx(sanitized_progress) and is_zero_approx(center.progress):
		center.progress = 0.001
	center.progress = sanitized_progress
	_apply_boundary_scale_rotation()


func _apply_boundary_scale_rotation() -> void:
	var center := get_node_or_null(BOUNDARY_CENTER_NAME) as Node3D
	if center == null:
		return

	center.scale = Vector3(boundary_scale_x, 1.0, boundary_scale_z)
	center.rotation = Vector3(0.0, boundary_rotation_z_radians, 0.0)


func _sync_boundary_scale_rotation_to_animation(animation: Animation, time: float) -> void:
	var sample_time := clampf(time, 0.0, animation.length)
	var scale_x_track := animation.find_track(BOUNDARY_SCALE_X_TRACK_PATH, Animation.TYPE_VALUE)
	if scale_x_track >= 0:
		boundary_scale_x = float(animation.value_track_interpolate(scale_x_track, sample_time))

	var scale_z_track := animation.find_track(BOUNDARY_SCALE_Z_TRACK_PATH, Animation.TYPE_VALUE)
	if scale_z_track >= 0:
		boundary_scale_z = float(animation.value_track_interpolate(scale_z_track, sample_time))

	var rotation_z_track := animation.find_track(BOUNDARY_ROTATION_Z_RADIANS_TRACK_PATH, Animation.TYPE_VALUE)
	if rotation_z_track >= 0:
		boundary_rotation_z_radians = float(animation.value_track_interpolate(rotation_z_track, sample_time))


func _upgrade_boundary_animation_tracks(animation: Animation) -> void:
	var legacy_vector_track := animation.find_track(LEGACY_SCALE_ROTATION_TARGET_TRACK_PATH, Animation.TYPE_VALUE)
	if legacy_vector_track >= 0:
		_upgrade_boundary_scale_rotation_tracks_from_source(animation, legacy_vector_track, true)
		animation.remove_track(legacy_vector_track)

	var legacy_scale_track := animation.find_track(LEGACY_SCALE_TRACK_PATH, Animation.TYPE_SCALE_3D)
	if legacy_scale_track >= 0:
		_upgrade_boundary_scale_rotation_tracks_from_source(animation, legacy_scale_track, false)
		animation.remove_track(legacy_scale_track)


func _upgrade_boundary_scale_rotation_tracks_from_source(
	animation: Animation,
	source_track: int,
	source_has_rotation: bool
) -> void:
	if _has_boundary_scale_rotation_tracks(animation):
		return

	var scale_x_track := _add_boundary_value_track(animation, BOUNDARY_SCALE_X_TRACK_PATH, source_track)
	var scale_z_track := _add_boundary_value_track(animation, BOUNDARY_SCALE_Z_TRACK_PATH, source_track)
	var rotation_z_track := _add_boundary_value_track(animation, BOUNDARY_ROTATION_Z_RADIANS_TRACK_PATH, source_track)

	for key_index in animation.track_get_key_count(source_track):
		var key_time := animation.track_get_key_time(source_track, key_index)
		var key_transition := animation.track_get_key_transition(source_track, key_index)
		var source_value := animation.track_get_key_value(source_track, key_index) as Vector3
		var scale_x := source_value.x
		var scale_z := source_value.y if source_has_rotation else source_value.z
		var rotation_z := source_value.z if source_has_rotation else 0.0
		animation.track_insert_key(scale_x_track, key_time, scale_x, key_transition)
		animation.track_insert_key(scale_z_track, key_time, scale_z, key_transition)
		animation.track_insert_key(rotation_z_track, key_time, rotation_z, key_transition)


func _has_boundary_scale_rotation_tracks(animation: Animation) -> bool:
	return (
		animation.find_track(BOUNDARY_SCALE_X_TRACK_PATH, Animation.TYPE_VALUE) >= 0
		and animation.find_track(BOUNDARY_SCALE_Z_TRACK_PATH, Animation.TYPE_VALUE) >= 0
		and animation.find_track(BOUNDARY_ROTATION_Z_RADIANS_TRACK_PATH, Animation.TYPE_VALUE) >= 0
	)


func _add_boundary_value_track(animation: Animation, track_path: NodePath, source_track: int) -> int:
	var track := animation.add_track(Animation.TYPE_VALUE)
	animation.track_set_path(track, track_path)
	animation.track_set_interpolation_type(track, animation.track_get_interpolation_type(source_track))
	animation.track_set_interpolation_loop_wrap(
		track,
		animation.track_get_interpolation_loop_wrap(source_track)
	)
	return track


func _get_editor_preview_time(animation_player: AnimationPlayer, animation: Animation) -> float:
	if editor_preview_animation != animation:
		editor_preview_animation = animation
		editor_preview_initialized = false

	if not editor_preview_initialized:
		editor_preview_time = _get_first_animation_key_time(animation)
		editor_preview_initialized = true

	if (
		animation_player.current_animation == DEFAULT_ANIMATION_NAME
		and (
			animation_player.is_playing()
			or absf(animation_player.current_animation_position - editor_preview_time) >= EDITOR_SCRUB_TIME_EPSILON
		)
	):
		editor_preview_time = animation_player.current_animation_position

	return clampf(editor_preview_time, 0.0, animation.length)


func _get_first_animation_key_time(animation: Animation) -> float:
	var first_key_time := INF
	for track_index in animation.get_track_count():
		if animation.track_get_key_count(track_index) == 0:
			continue

		first_key_time = minf(first_key_time, animation.track_get_key_time(track_index, 0))

	if is_inf(first_key_time):
		return 0.0

	return clampf(first_key_time, 0.0, animation.length)


func _calculate_travel_distance(animation: Animation, time: float) -> float:
	var speed_track := animation.find_track(MOVEMENT_SPEED_TRACK_PATH, Animation.TYPE_VALUE)
	if speed_track < 0:
		return maxf(movement_speed, 0.0) * maxf(time, 0.0)

	var key_count := animation.track_get_key_count(speed_track)
	if key_count == 0:
		return maxf(movement_speed, 0.0) * maxf(time, 0.0)
	if key_count == 1:
		return maxf(float(animation.track_get_key_value(speed_track, 0)), 0.0) * maxf(time, 0.0)

	var target_time := clampf(time, 0.0, animation.length)
	var distance := 0.0
	var interval_start := 0.0
	for key_index in key_count:
		var key_time := animation.track_get_key_time(speed_track, key_index)
		if key_time > interval_start:
			var interval_end := minf(key_time, target_time)
			if interval_end > interval_start:
				distance += _integrate_speed_interval(animation, speed_track, interval_start, interval_end)
		if key_time >= target_time:
			return distance
		interval_start = key_time

	if target_time > interval_start:
		distance += _integrate_speed_interval(animation, speed_track, interval_start, target_time)
	return distance


func _integrate_speed_interval(animation: Animation, speed_track: int, start_time: float, end_time: float) -> float:
	const SAMPLE_COUNT := 8
	var step := (end_time - start_time) / float(SAMPLE_COUNT)
	var weighted_speed := 0.0
	for sample_index in SAMPLE_COUNT + 1:
		var sample_time := start_time + step * float(sample_index)
		var speed := maxf(float(animation.value_track_interpolate(speed_track, sample_time)), 0.0)
		var weight := 1.0 if sample_index == 0 or sample_index == SAMPLE_COUNT else (4.0 if sample_index % 2 == 1 else 2.0)
		weighted_speed += speed * weight
	return weighted_speed * step / 3.0


func _retime_boundary_animation(new_duration: float) -> void:
	if boundary_animation == null:
		return

	var old_duration := maxf(boundary_animation.length, 0.0001)
	if is_equal_approx(old_duration, new_duration):
		return

	var time_scale := new_duration / old_duration
	for track_index in boundary_animation.get_track_count():
		var key_times: Array[float] = []
		for key_index in boundary_animation.track_get_key_count(track_index):
			key_times.append(boundary_animation.track_get_key_time(track_index, key_index))
		for key_index in key_times.size():
			boundary_animation.track_set_key_time(track_index, key_index, key_times[key_index] * time_scale)
	boundary_animation.length = new_duration
	_sync_animation_player()


func _create_flame_material() -> void:
	flame_material = ShaderMaterial.new()
	flame_material.shader = FLAME_SHADER

	var noise := FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.frequency = 0.08
	noise.fractal_octaves = 4
	noise.fractal_lacunarity = 2.0
	noise.fractal_gain = 0.52

	var noise_texture := NoiseTexture3D.new()
	noise_texture.width = 64
	noise_texture.height = 64
	noise_texture.depth = 64
	noise_texture.seamless = true
	noise_texture.normalize = true
	noise_texture.noise = noise
	flame_material.set_shader_parameter("sample_noise", noise_texture)
	_apply_flame_effect_parameters()


func _create_ghost_material() -> void:
	ghost_material = ShaderMaterial.new()
	ghost_material.shader = GHOST_SHADER
	ghost_material.set_shader_parameter("ghost_texture", GHOST_TEXTURE)
	_apply_ghost_effect_material_parameters()


func _is_flame_effect_active() -> bool:
	return render_effect == EFFECT_FLAME


func _is_ghost_effect_active() -> bool:
	return render_effect == EFFECT_GHOST


func _apply_effect_material_parameters() -> void:
	_apply_flame_effect_parameters()
	_apply_ghost_effect_material_parameters()


func _apply_flame_effect_parameters() -> void:
	if flame_material == null:
		return

	flame_material.set_shader_parameter("boundary_time", runtime_effect_time)
	flame_material.set_shader_parameter("density_multiplier", flame_effect_density)
	flame_material.set_shader_parameter("opacity_multiplier", flame_effect_opacity)
	flame_material.set_shader_parameter("emission_strength", flame_effect_emission)
	flame_material.set_shader_parameter("time_scale", flame_effect_time_scale)
	flame_material.set_shader_parameter("color_core", _color_to_vec3(flame_effect_core_color))
	flame_material.set_shader_parameter("color_mid", _color_to_vec3(flame_effect_mid_color))
	flame_material.set_shader_parameter("color_outer", _color_to_vec3(flame_effect_outer_color))


func _apply_ghost_effect_material_parameters() -> void:
	if ghost_material == null:
		return

	ghost_material.set_shader_parameter("ghost_texture", GHOST_TEXTURE)
	ghost_material.set_shader_parameter("boundary_time", runtime_effect_time)
	ghost_material.set_shader_parameter("ghost_color", _color_to_vec3(ghost_effect_color))
	ghost_material.set_shader_parameter("emission_strength", ghost_effect_emission)
	ghost_material.set_shader_parameter("edge_softness", ghost_effect_edge_softness)


func _color_to_vec3(color: Color) -> Vector3:
	return Vector3(color.r, color.g, color.b)


func _get_ghost_mesh() -> ArrayMesh:
	if ghost_mesh != null:
		return ghost_mesh

	const RIBBON_SEGMENTS := 18
	var vertices := PackedVector3Array()
	var uvs := PackedVector2Array()
	var indices := PackedInt32Array()
	for i in RIBBON_SEGMENTS + 1:
		var y := float(i) / float(RIBBON_SEGMENTS)
		vertices.append(Vector3(-1.0, y, 0.0))
		uvs.append(Vector2(0.0, y))
		vertices.append(Vector3(1.0, y, 0.0))
		uvs.append(Vector2(1.0, y))

	for i in RIBBON_SEGMENTS:
		var base := i * 2
		indices.append(base)
		indices.append(base + 1)
		indices.append(base + 2)
		indices.append(base + 1)
		indices.append(base + 3)
		indices.append(base + 2)

	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices

	ghost_mesh = ArrayMesh.new()
	ghost_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return ghost_mesh


func _create_preview_material() -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = Color(0.55, 0.9, 1.0, 0.38)
	material.emission_enabled = true
	material.emission = Color(0.45, 0.85, 1.0)
	material.emission_energy_multiplier = 0.55
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return material


func _create_blocker_preview_material() -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = Color(0.15, 0.6, 1.0, 0.28)
	material.emission_enabled = true
	material.emission = Color(0.05, 0.35, 0.9)
	material.emission_energy_multiplier = 0.35
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return material


func _ensure_editor_preview() -> void:
	if not Engine.is_editor_hint() or not is_inside_tree():
		return

	preview_material = _create_preview_material()
	blocker_preview_material = _create_blocker_preview_material()
	var preview_container := _get_or_create_editor_preview_container()
	if preview_meshes.is_empty() and preview_ghost_meshes.is_empty() and blocker_preview_meshes.is_empty():
		for child in preview_container.get_children(true):
			preview_container.remove_child(child)
			child.queue_free()

	while preview_meshes.size() < boundary_segments:
		var mesh_instance := MeshInstance3D.new()
		mesh_instance.name = "Preview%d" % preview_meshes.size()
		mesh_instance.mesh = BoxMesh.new()
		mesh_instance.material_override = flame_material
		preview_container.add_child(mesh_instance, false, Node.INTERNAL_MODE_BACK)
		_lock_editor_preview_node(mesh_instance)
		mesh_instance.owner = null
		preview_meshes.append(mesh_instance)

	while preview_meshes.size() > boundary_segments:
		var removed_preview: MeshInstance3D = preview_meshes.pop_back()
		removed_preview.queue_free()

	var target_ghost_count := boundary_segments * ghost_ribbons_per_segment
	while preview_ghost_meshes.size() < target_ghost_count:
		var ghost_preview := MeshInstance3D.new()
		ghost_preview.name = "GhostPreview%d" % preview_ghost_meshes.size()
		ghost_preview.mesh = _get_ghost_mesh()
		ghost_preview.material_override = ghost_material
		ghost_preview.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		ghost_preview.extra_cull_margin = maxf(ghost_height_range.y + ghost_rise_distance + ghost_wave_amplitude, 1.0)
		preview_container.add_child(ghost_preview, false, Node.INTERNAL_MODE_BACK)
		_lock_editor_preview_node(ghost_preview)
		ghost_preview.owner = null
		preview_ghost_meshes.append(ghost_preview)

	while preview_ghost_meshes.size() > target_ghost_count:
		var removed_ghost_preview: MeshInstance3D = preview_ghost_meshes.pop_back()
		removed_ghost_preview.queue_free()

	if preview_center_mesh == null:
		preview_center_mesh = MeshInstance3D.new()
		preview_center_mesh.name = "BoundaryCenterPreview"
		var center_mesh := SphereMesh.new()
		center_mesh.radius = 0.18
		center_mesh.height = 0.36
		preview_center_mesh.mesh = center_mesh
		preview_center_mesh.material_override = preview_material
		preview_container.add_child(preview_center_mesh, false, Node.INTERNAL_MODE_BACK)
		_lock_editor_preview_node(preview_center_mesh)
		preview_center_mesh.owner = null

	while blocker_preview_meshes.size() < boundary_segments:
		var blocker_mesh := MeshInstance3D.new()
		blocker_mesh.name = "PlayerBlockerPreview%d" % blocker_preview_meshes.size()
		blocker_mesh.mesh = BoxMesh.new()
		blocker_mesh.material_override = blocker_preview_material
		preview_container.add_child(blocker_mesh, false, Node.INTERNAL_MODE_BACK)
		_lock_editor_preview_node(blocker_mesh)
		blocker_mesh.owner = null
		blocker_preview_meshes.append(blocker_mesh)

	while blocker_preview_meshes.size() > boundary_segments:
		var removed_blocker: MeshInstance3D = blocker_preview_meshes.pop_back()
		removed_blocker.queue_free()


func _get_or_create_editor_preview_container() -> Node3D:
	var center := _get_center_node()
	var existing := center.get_node_or_null(EDITOR_PREVIEW_CONTAINER_NAME) as Node3D
	if existing != null:
		return existing

	var preview_container := Node3D.new()
	preview_container.name = EDITOR_PREVIEW_CONTAINER_NAME
	center.add_child(preview_container, false, Node.INTERNAL_MODE_BACK)
	_lock_editor_preview_node(preview_container)
	preview_container.owner = null
	return preview_container


func _lock_editor_preview_node(node: Node) -> void:
	node.set_meta("_edit_lock_", true)


func _create_strips() -> void:
	_ensure_runtime_segment_count()


func _ensure_runtime_segment_count() -> void:
	var center := _get_center_node()

	while strip_areas.size() < boundary_segments:
		var i := strip_areas.size()
		var area := Area3D.new()
		area.name = "FlameArea%d" % i
		area.collision_layer = 0
		area.collision_mask = 2
		area.body_entered.connect(_on_flame_body_entered)
		area.body_exited.connect(_on_flame_body_exited)
		center.add_child(area)
		strip_areas.append(area)

		var collision := CollisionShape3D.new()
		collision.name = "FlameCollision%d" % i
		collision.shape = BoxShape3D.new()
		area.add_child(collision)
		strip_collisions.append(collision)

		var mesh_instance := MeshInstance3D.new()
		mesh_instance.name = "FlameMesh%d" % i
		mesh_instance.mesh = BoxMesh.new()
		mesh_instance.material_override = flame_material
		mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		area.add_child(mesh_instance)
		strip_meshes.append(mesh_instance)

	while strip_areas.size() > boundary_segments:
		var removed_area: Area3D = strip_areas.pop_back()
		strip_collisions.pop_back()
		strip_meshes.pop_back()
		removed_area.queue_free()

	_ensure_ghost_ribbon_count(center)
	_ensure_player_blocker_count(center)


func _ensure_ghost_ribbon_count(center: Node3D) -> void:
	if ghost_material == null:
		_create_ghost_material()

	var target_count := boundary_segments * ghost_ribbons_per_segment
	while ghost_meshes.size() < target_count:
		var i := ghost_meshes.size()
		var mesh_instance := MeshInstance3D.new()
		mesh_instance.name = "GhostRibbon%d" % i
		mesh_instance.mesh = _get_ghost_mesh()
		mesh_instance.material_override = ghost_material
		mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mesh_instance.extra_cull_margin = maxf(ghost_height_range.y + ghost_rise_distance + ghost_wave_amplitude, 1.0)
		center.add_child(mesh_instance)
		ghost_meshes.append(mesh_instance)

	while ghost_meshes.size() > target_count:
		var removed_mesh: MeshInstance3D = ghost_meshes.pop_back()
		removed_mesh.queue_free()


func _ensure_player_blocker_count(center: Node3D) -> void:
	while blocker_bodies.size() < boundary_segments:
		var i := blocker_bodies.size()
		var body := StaticBody3D.new()
		body.name = "PlayerBlocker%d" % i
		body.collision_layer = PLAYER_BOUNDARY_BLOCKER_COLLISION_LAYER
		body.collision_mask = 0
		center.add_child(body)
		blocker_bodies.append(body)

		var collision := CollisionShape3D.new()
		collision.name = "PlayerBlockerCollision%d" % i
		collision.shape = BoxShape3D.new()
		body.add_child(collision)
		blocker_collisions.append(collision)

	while blocker_bodies.size() > boundary_segments:
		var removed_body: StaticBody3D = blocker_bodies.pop_back()
		blocker_collisions.pop_back()
		removed_body.queue_free()


func _sync_boundary(update_removed_visuals := false) -> void:
	if not is_inside_tree() or is_syncing_boundary:
		return
	if boundary_removed_for_level and not update_removed_visuals:
		return

	is_syncing_boundary = true
	_apply_effect_material_parameters()

	if Engine.is_editor_hint():
		var target_ghost_count := boundary_segments * ghost_ribbons_per_segment
		if (
			preview_meshes.size() != boundary_segments
			or preview_ghost_meshes.size() != target_ghost_count
			or blocker_preview_meshes.size() != boundary_segments
		):
			_ensure_editor_preview()
		_update_preview_boundary()
		is_syncing_boundary = false
		return

	if not _runtime_effects_enabled() and not update_removed_visuals:
		_set_runtime_effects_enabled(false)
		is_syncing_boundary = false
		return

	_ensure_runtime_segment_count()
	if strip_collisions.size() == boundary_segments and strip_meshes.size() == boundary_segments:
		_update_runtime_boundary()

	if ghost_meshes.size() == boundary_segments * ghost_ribbons_per_segment:
		_update_ghost_boundary()

	if blocker_collisions.size() == boundary_segments:
		_update_runtime_blockers()

	is_syncing_boundary = false


func _update_preview_boundary() -> void:
	if preview_meshes.size() != boundary_segments:
		return

	var no_collisions: Array[CollisionShape3D] = []
	_apply_boundary_to_segments(preview_meshes, no_collisions)
	if preview_ghost_meshes.size() == boundary_segments * ghost_ribbons_per_segment:
		_apply_ghosts_to_boundary(preview_ghost_meshes)
	if preview_center_mesh != null:
		preview_center_mesh.position = Vector3(0.0, flame_y + 0.18, 0.0)

	if blocker_preview_meshes.size() == boundary_segments:
		var no_blocker_collisions: Array[CollisionShape3D] = []
		_apply_player_blockers_to_segments(blocker_preview_meshes, no_blocker_collisions)


func _update_runtime_boundary() -> void:
	_apply_boundary_to_segments(strip_meshes, strip_collisions)


func _update_ghost_boundary() -> void:
	_apply_ghosts_to_boundary(ghost_meshes)
	_update_ghost_billboards()


func _update_runtime_blockers() -> void:
	var no_meshes: Array[MeshInstance3D] = []
	_apply_player_blockers_to_segments(no_meshes, blocker_collisions)
	_update_player_blockers_enabled()


func _apply_boundary_to_segments(meshes: Array[MeshInstance3D], collisions: Array[CollisionShape3D]) -> void:
	var points := _get_boundary_points()
	var perimeter_offset := 0.0
	for i in boundary_segments:
		var start := points[i]
		var finish := points[(i + 1) % boundary_segments]
		var delta := finish - start
		var segment_length := delta.length()
		var midpoint := (start + finish) * 0.5
		var visual_size := Vector3(segment_length + flame_visual_depth, flame_height, flame_visual_depth)
		var mesh_instance := meshes[i]
		mesh_instance.visible = _is_flame_effect_active()
		(mesh_instance.mesh as BoxMesh).size = visual_size
		mesh_instance.set_instance_shader_parameter("fire_size", visual_size)
		mesh_instance.set_instance_shader_parameter("segment_half_length", segment_length * 0.5)
		mesh_instance.set_instance_shader_parameter("noise_along_offset", perimeter_offset + segment_length * 0.5)
		mesh_instance.rotation = Vector3(0.0, atan2(-delta.y, delta.x), 0.0)
		var segment_position := Vector3(midpoint.x, flame_y + flame_height * 0.5, midpoint.y)

		if collisions.is_empty():
			mesh_instance.position = segment_position
		else:
			var collision := collisions[i]
			var area := collision.get_parent() as Area3D
			area.position = segment_position
			area.rotation = mesh_instance.rotation
			mesh_instance.position = Vector3.ZERO
			mesh_instance.rotation = Vector3.ZERO
			(collision.shape as BoxShape3D).size = Vector3(segment_length + flame_thickness, flame_height, flame_thickness)
		perimeter_offset += segment_length


func _apply_ghosts_to_boundary(meshes: Array[MeshInstance3D]) -> void:
	if meshes.is_empty():
		return

	var points := _get_boundary_points()
	var ghost_index := 0
	var spirits_visible := _is_ghost_effect_active() and ghost_ribbons_per_segment > 0
	for i in boundary_segments:
		var start := points[i]
		var finish := points[(i + 1) % boundary_segments]
		var delta := finish - start
		var outward := Vector2(delta.y, -delta.x).normalized()
		for slot in ghost_ribbons_per_segment:
			var mesh_instance := meshes[ghost_index]
			var rng := _create_ghost_rng(ghost_index)
			var along := (float(slot) + rng.randf_range(0.12, 0.88)) / float(ghost_ribbons_per_segment)
			var ground_position := start.lerp(finish, clampf(along, 0.0, 1.0))
			ground_position += outward * rng.randf_range(-flame_visual_depth * 0.35, flame_visual_depth * 0.35)

			mesh_instance.visible = spirits_visible
			mesh_instance.position = Vector3(ground_position.x, flame_y, ground_position.y)
			mesh_instance.rotation = Vector3.ZERO
			mesh_instance.extra_cull_margin = maxf(ghost_height_range.y + ghost_rise_distance + ghost_wave_amplitude, 1.0)
			_configure_ghost_ribbon(mesh_instance, rng)
			ghost_index += 1


func _configure_ghost_ribbon(mesh_instance: MeshInstance3D, rng: RandomNumberGenerator) -> void:
	var height := rng.randf_range(ghost_height_range.x, ghost_height_range.y)
	var width := rng.randf_range(ghost_width_range.x, ghost_width_range.y)
	var size_ratio := (
		0.0
		if is_equal_approx(ghost_height_range.x, ghost_height_range.y)
		else inverse_lerp(ghost_height_range.x, ghost_height_range.y, height)
	)
	mesh_instance.set_instance_shader_parameter("ghost_width", width)
	mesh_instance.set_instance_shader_parameter("ghost_height", height)
	mesh_instance.set_instance_shader_parameter("rise_distance", ghost_rise_distance * rng.randf_range(0.72, 1.18))
	mesh_instance.set_instance_shader_parameter(
		"emerge_depth",
		height * rng.randf_range(ghost_emerge_depth_ratio_range.x, ghost_emerge_depth_ratio_range.y)
	)
	mesh_instance.set_instance_shader_parameter(
		"rise_speed",
		rng.randf_range(ghost_rise_speed_range.x, ghost_rise_speed_range.y)
	)
	mesh_instance.set_instance_shader_parameter("cycle_offset", rng.randf())
	mesh_instance.set_instance_shader_parameter("wave_phase", rng.randf_range(0.0, TAU))
	mesh_instance.set_instance_shader_parameter(
		"wave_amplitude",
		ghost_wave_amplitude * rng.randf_range(0.45, 1.3) * lerpf(0.85, 1.15, size_ratio)
	)
	mesh_instance.set_instance_shader_parameter(
		"wave_frequency",
		rng.randf_range(ghost_wave_frequency_range.x, ghost_wave_frequency_range.y)
	)
	mesh_instance.set_instance_shader_parameter(
		"wave_speed",
		rng.randf_range(ghost_wave_speed_range.x, ghost_wave_speed_range.y)
	)
	mesh_instance.set_instance_shader_parameter("lean", rng.randf_range(ghost_lean_range.x, ghost_lean_range.y))
	mesh_instance.set_instance_shader_parameter("opacity", rng.randf_range(ghost_opacity_range.x, ghost_opacity_range.y))


func _update_ghost_billboards() -> void:
	if ghost_meshes.is_empty() or not _is_ghost_effect_active():
		return

	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return

	for mesh_instance in ghost_meshes:
		if not is_instance_valid(mesh_instance) or not mesh_instance.visible:
			continue

		var target := camera.global_position
		target.y = mesh_instance.global_position.y
		if mesh_instance.global_position.distance_squared_to(target) <= 0.0001:
			continue

		mesh_instance.look_at(target, Vector3.UP)


func _create_ghost_rng(index: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = 918273 + index * 104729
	return rng


func _sanitize_positive_range(value: Vector2, minimum: float) -> Vector2:
	var low := maxf(minf(value.x, value.y), minimum)
	var high := maxf(maxf(value.x, value.y), low)
	return Vector2(low, high)


func _apply_player_blockers_to_segments(meshes: Array[MeshInstance3D], collisions: Array[CollisionShape3D]) -> void:
	var points := _get_boundary_points()
	var center_offset := flame_thickness * 0.5 + player_blocking_outset + player_blocking_thickness * 0.5
	for i in boundary_segments:
		var start := points[i]
		var finish := points[(i + 1) % boundary_segments]
		var delta := finish - start
		var segment_length := delta.length()
		var outward := Vector2(delta.y, -delta.x).normalized()
		var midpoint := (start + finish) * 0.5 + outward * center_offset
		var blocker_size := Vector3(segment_length + center_offset * 2.0, player_blocking_height, player_blocking_thickness)
		var segment_rotation := Vector3(0.0, atan2(-delta.y, delta.x), 0.0)
		var segment_position := Vector3(midpoint.x, flame_y + player_blocking_height * 0.5, midpoint.y)
		if not meshes.is_empty():
			var mesh_instance := meshes[i]
			mesh_instance.visible = player_blocking_enabled
			mesh_instance.position = segment_position
			mesh_instance.rotation = segment_rotation
			(mesh_instance.mesh as BoxMesh).size = blocker_size

		if collisions.is_empty():
			continue

		var collision := collisions[i]
		var body := collision.get_parent() as StaticBody3D
		body.position = segment_position
		body.rotation = segment_rotation
		(collision.shape as BoxShape3D).size = blocker_size


func _get_boundary_points() -> PackedVector2Array:
	var points := PackedVector2Array()
	var first_shape := floori(shape_morph)
	var second_shape := mini(first_shape + 1, MAX_SHAPE_INDEX)
	var shape_blend := shape_morph - float(first_shape)
	for i in boundary_segments:
		var perimeter_ratio := float(i) / float(boundary_segments)
		var first_point := _get_shape_profile_point(first_shape, perimeter_ratio)
		var second_point := _get_shape_profile_point(second_shape, perimeter_ratio)
		points.append(first_point.lerp(second_point, shape_blend))
	return points


func _get_shape_profile_point(shape_index: int, perimeter_ratio: float) -> Vector2:
	var angle := perimeter_ratio * TAU + PI * 0.25
	var direction := Vector2(cos(angle), sin(angle))
	var half_size := bounds_size * runtime_bounds_multiplier * 0.5
	match shape_index:
		SHAPE_RECTANGLE:
			var ray_scale := minf(
				half_size.x / maxf(absf(direction.x), 0.0001),
				half_size.y / maxf(absf(direction.y), 0.0001)
			)
			return direction * ray_scale
		SHAPE_CIRCLE:
			return direction * minf(half_size.x, half_size.y)
		_:
			return direction * minf(half_size.x, half_size.y)


func _update_player_blockers_enabled() -> void:
	var disabled := not _runtime_effects_enabled() or not player_blocking_enabled or _has_dead_flame_vulnerable_body()
	for collision in blocker_collisions:
		if is_instance_valid(collision):
			collision.disabled = disabled


func _has_dead_flame_vulnerable_body() -> bool:
	for body in get_tree().get_nodes_in_group("flame_vulnerable"):
		if not is_instance_valid(body):
			continue

		if body.has_method("is_dead") and bool(body.call("is_dead")):
			return true

	return false


func _create_near_flame_audio() -> void:
	var stream := GDAudio.load_stream(_get_boundary_audio_path())
	if stream == null:
		return

	near_flame_audio_player = AudioStreamPlayer.new()
	near_flame_audio_player.name = "NearFlameAudio"
	var loop_stream := stream.duplicate() as AudioStream
	if loop_stream is AudioStreamMP3:
		(loop_stream as AudioStreamMP3).loop = true
	near_flame_audio_player.stream = loop_stream
	near_flame_audio_player.volume_db = _get_boundary_audio_volume_db(near_flame_audio_min_db)
	add_child(near_flame_audio_player)
	near_flame_audio_player.play()


func _get_boundary_audio_path() -> String:
	if _is_ghost_effect_active():
		return GHOST_BOUNDARY_SOUND_PATH

	return NEAR_FLAMES_SOUND_PATH


func _get_boundary_audio_volume_db(base_volume_db: float) -> float:
	if _is_ghost_effect_active():
		return base_volume_db + GHOST_BOUNDARY_VOLUME_BOOST_DB

	return base_volume_db


func _apply_flame_heat(delta: float) -> void:
	if not _runtime_effects_enabled():
		return

	for body in get_tree().get_nodes_in_group("flame_vulnerable"):
		if not body is Node3D:
			continue

		var body_3d := body as Node3D
		if not is_instance_valid(body_3d):
			continue

		if not _is_inside_flame_damage_height(body_3d.global_position):
			continue

		var outside_depth := _get_outside_flame_depth(body_3d.global_position)
		var touching_flames := flame_touching_bodies.has(body_3d)
		if not touching_flames and outside_depth <= 0.0:
			var inside_edge_distance := _get_inside_edge_distance(body_3d.global_position)
			touching_flames = inside_edge_distance <= flame_damage_inner_depth

		if not touching_flames and outside_depth <= 0.0:
			continue

		var damage_multiplier := 1.0
		if outside_depth > 0.0:
			var outside_ratio := clampf(outside_depth / maxf(outside_damage_ramp_depth, 0.001), 0.0, 1.0)
			damage_multiplier = lerpf(1.0, maxf(max_outside_damage_multiplier, 1.0), outside_ratio)

		if body_3d.has_method("apply_flame_damage"):
			body_3d.apply_flame_damage(flame_damage_per_second * damage_multiplier * delta)
		elif body_3d.has_method("die_from_flames"):
			body_3d.die_from_flames()


func _update_near_flame_audio(delta: float) -> void:
	if near_flame_audio_player == null:
		return

	if not _runtime_effects_enabled():
		near_flame_audio_player.volume_db = _get_boundary_audio_volume_db(near_flame_audio_min_db)
		return

	var closest_distance := INF
	for body in get_tree().get_nodes_in_group("flame_vulnerable"):
		if not body is Node3D:
			continue

		var body_3d := body as Node3D
		if not is_instance_valid(body_3d):
			continue

		closest_distance = minf(closest_distance, _get_distance_to_flames(body_3d.global_position))

	var target_volume := near_flame_audio_min_db
	if closest_distance < INF:
		var closeness := 1.0 - clampf(closest_distance / maxf(near_flame_audio_distance, 0.001), 0.0, 1.0)
		closeness = pow(closeness, near_flame_audio_curve)
		target_volume = lerpf(near_flame_audio_min_db, near_flame_audio_max_db, closeness)

	target_volume = _get_boundary_audio_volume_db(target_volume)
	var t := 1.0 - exp(-near_flame_audio_lag * delta)
	near_flame_audio_player.volume_db = lerpf(near_flame_audio_player.volume_db, target_volume, t)


func _sink_removed_boundary(seconds: float, distance: float) -> void:
	var duration := maxf(seconds, 0.05)
	var drop_distance := maxf(distance, 0.1)
	var tween := create_tween()
	tween.tween_property(
		self,
		"position",
		position + Vector3.DOWN * drop_distance,
		duration
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.finished.connect(queue_free)


func _set_runtime_motion_paused(paused: bool) -> void:
	var animation_player := get_node_or_null(ANIMATION_PLAYER_NAME) as AnimationPlayer
	if animation_player == null:
		return

	animation_player.speed_scale = 0.0 if paused else 1.0
	if not paused and autoplay_boundary_animation and _runtime_effects_enabled() and not animation_player.is_playing():
		animation_player.play(DEFAULT_ANIMATION_NAME)


func _resume_runtime_motion_after(token: int, seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout
	if token == runtime_pause_token and is_inside_tree() and not boundary_removed_for_level:
		_set_runtime_motion_paused(false)


func _animate_runtime_bounds_multiplier(target_multiplier: float, seconds: float) -> void:
	if boundary_removed_for_level:
		return

	if runtime_bounds_tween != null and runtime_bounds_tween.is_valid():
		runtime_bounds_tween.kill()

	runtime_bounds_tween = create_tween()
	runtime_bounds_tween.tween_method(
		func(value: float) -> void:
			if boundary_removed_for_level:
				return
			runtime_bounds_multiplier = maxf(value, 0.01)
			_sync_boundary(),
		runtime_bounds_multiplier,
		maxf(target_multiplier, 0.01),
		maxf(seconds, 0.01)
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _restore_runtime_bounds_after(multiplier: float, active_seconds: float, transition_seconds: float) -> void:
	await get_tree().create_timer(maxf(active_seconds, 0.01)).timeout
	if is_inside_tree() and not boundary_removed_for_level:
		active_runtime_bounds_multipliers.erase(multiplier)
		_animate_runtime_bounds_multiplier(_get_target_runtime_bounds_multiplier(), transition_seconds)


func _get_target_runtime_bounds_multiplier() -> float:
	var multiplier := permanent_runtime_bounds_multiplier
	for active_multiplier in active_runtime_bounds_multipliers:
		multiplier *= active_multiplier
	return maxf(multiplier, 0.01)


func _get_distance_to_flames(world_position: Vector3) -> float:
	var outside_depth := _get_outside_flame_depth(world_position)
	if outside_depth > 0.0:
		return 0.0

	return maxf(_get_inside_edge_distance(world_position), 0.0)


func _get_inside_edge_distance(world_position: Vector3) -> float:
	var local_position: Vector3 = _get_center_node().global_transform.affine_inverse() * world_position
	return _get_signed_distance_to_boundary(Vector2(local_position.x, local_position.z))


func _get_outside_flame_depth(world_position: Vector3) -> float:
	var local_position: Vector3 = _get_center_node().global_transform.affine_inverse() * world_position
	return maxf(-_get_signed_distance_to_boundary(Vector2(local_position.x, local_position.z)), 0.0)


func _get_signed_distance_to_boundary(point: Vector2) -> float:
	var polygon := _get_boundary_points()
	var closest_distance := INF
	for i in polygon.size():
		closest_distance = minf(closest_distance, _distance_to_segment(point, polygon[i], polygon[(i + 1) % polygon.size()]))
	return closest_distance if Geometry2D.is_point_in_polygon(point, polygon) else -closest_distance


func _distance_to_segment(point: Vector2, start: Vector2, finish: Vector2) -> float:
	var segment := finish - start
	var length_squared := segment.length_squared()
	if length_squared <= 0.000001:
		return point.distance_to(start)
	var ratio := clampf((point - start).dot(segment) / length_squared, 0.0, 1.0)
	return point.distance_to(start + segment * ratio)


func _is_inside_flame_damage_height(world_position: Vector3) -> bool:
	var local_position: Vector3 = _get_center_node().global_transform.affine_inverse() * world_position
	var margin := maxf(flame_damage_vertical_margin, 0.0)
	return local_position.y >= flame_y - margin and local_position.y <= flame_y + flame_height + margin


func _on_flame_body_entered(body: Node3D) -> void:
	if not flame_touching_bodies.has(body):
		flame_touching_bodies.append(body)


func _on_flame_body_exited(body: Node3D) -> void:
	flame_touching_bodies.erase(body)
