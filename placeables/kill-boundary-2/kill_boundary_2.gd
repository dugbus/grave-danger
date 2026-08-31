@tool
class_name GDKillBoundary2
extends Node

## Composed Kill Boundary 2 provider. Authored spatial state lives on its pose nodes.

signal editor_active_pose_changed(pose_index: int)
signal boundary_removed
signal playback_configuration_changed

const KILL_BOUNDARY_GROUP: StringName = &"kill_boundary"
const DEFAULT_SETTINGS := preload(
	"res://placeables/kill-boundary-2/kill_boundary_2_settings.tres"
)

## Start moving automatically when the level begins. Turn this off when another level event
## should decide when the boundary starts; the boundary still appears at Pose 1.
@export var autoplay_boundary_animation := true
## Choose what happens at the end: Single Shot stays at the final pose, Loop moves back to
## Pose 1 and repeats, and Ping Pong reverses through the poses before repeating.
@export var playback_mode := GDKillBoundary2Animator.PlaybackMode.SingleShot:
	set(value):
		playback_mode = value as GDKillBoundary2Animator.PlaybackMode
		_sync_animator_configuration()
		playback_configuration_changed.emit()
## Make the boundary animation run slower or faster without changing the pose times. Use 0 to
## freeze movement while keeping the boundary active.
@export_range(0.0, 8.0, 0.05, "or_greater", "suffix:×") var playback_speed := 1.0:
	set(value):
		playback_speed = maxf(value, 0.0)
		_sync_animator_configuration()
		playback_configuration_changed.emit()
## In Loop mode, choose how long the boundary takes to move from the final pose back to Pose 1.
## Increase this for a gentler return or reduce it for a quicker return.
@export_range(0.01, 3600.0, 0.01, "or_greater", "suffix:s") var loop_return_seconds := 1.0:
	set(value):
		loop_return_seconds = maxf(value, 0.01)
		_sync_animator_configuration()
		playback_configuration_changed.emit()
## Choose how the boundary looks. Flame burns players, while Ghost and None remain deadly but do
## not report a fire death; None is useful for an invisible hazard.
@export var render_effect := GDKillBoundary2Settings.RenderEffect.Flame:
	set(value):
		render_effect = value as GDKillBoundary2Settings.RenderEffect
		_sync_render_effect()
## Stop living players from crossing the boundary line. Turn this off when players should be able
## to pass through the hazard; touching or crossing it can still cause damage.
@export var player_blocking_enabled := true:
	set(value):
		player_blocking_enabled = value
		if blockers != null:
			blockers.set_blocking_enabled(value)
## Limit how strongly this boundary can influence automatic camera framing. Lower values keep the
## camera closer; raise it when the whole boundary should remain visible.
@export_range(0.1, 10.0, 0.05, "or_greater") var camera_fit_scale_limit := 1.0
## Choose what happens to later poses when this pose's time changes. Shift Following keeps later
## timing gaps, while Move This Pose Only changes just the selected pose.
@export var retiming_mode := GDKillBoundary2Sequence.RetimingMode.ShiftFollowing
## Shared fine-tuning for the boundary's appearance, damage, blocking, and sound. Change the shared
## resource to keep these details consistent across levels; use the controls above for this boundary.
@export var settings: GDKillBoundary2Settings = DEFAULT_SETTINGS

var sequence: GDKillBoundary2Sequence:
	get:
		var authored_sequence := get_node_or_null(^"Poses") as GDKillBoundary2Sequence
		if authored_sequence == null:
			authored_sequence = GDKillBoundary2Sequence.new()
			authored_sequence.name = "Poses"
			add_child(authored_sequence)
		_assign_sequence_editor_owner(authored_sequence)
		if authored_sequence.get_pose_count() == 0:
			authored_sequence.ensure_default_pose()
		return authored_sequence

var animator: GDKillBoundary2Animator
var geometry: GDKillBoundary2Geometry
var boundary_space: Node3D
var state_root: Node3D
var presentation: GDKillBoundary2Presentation
var damage: GDKillBoundary2Damage
var blockers: GDKillBoundary2Blockers
var proximity_audio: GDKillBoundary2Audio

var editor_active_pose_index := 0
var elapsed_time := 0.0
var permanent_runtime_bounds_multiplier := 1.0
var runtime_bounds_multiplier := 1.0
var active_runtime_bounds_multipliers: Array[float] = []
var boundary_removed_for_level := false
var runtime_pause_token := 0
var runtime_bounds_tween: Tween
var removal_tween: Tween


func _ready() -> void:
	add_to_group(KILL_BOUNDARY_GROUP)
	_cache_components()
	if sequence != null:
		sequence.ensure_default_pose()
		if not sequence.sequence_changed.is_connected(_on_sequence_changed):
			sequence.sequence_changed.connect(_on_sequence_changed)
	_configure_components()
	_connect_component_signals()
	_sync_animator_configuration()
	if animator != null:
		animator.restart(false)
	_set_runtime_effects_enabled(not Engine.is_editor_hint(), Engine.is_editor_hint())
	if Engine.is_editor_hint():
		preview_seek(0.0)
	set_physics_process(not Engine.is_editor_hint())


func _physics_process(delta: float) -> void:
	if boundary_removed_for_level or not _is_boundary_visible():
		_set_runtime_effects_enabled(false, boundary_removed_for_level)
		return
	elapsed_time += maxf(delta, 0.0)
	if animator != null:
		animator.advance(delta)
	if presentation != null:
		presentation.advance_effect_time(delta)
	if damage != null:
		damage.apply_damage(delta)
	if blockers != null:
		blockers.update_enabled_state()
	if proximity_audio != null:
		proximity_audio.update_proximity(delta)


## Starts or resumes runtime playback without resetting the authored clock.
func play_runtime_animation() -> void:
	if animator == null or boundary_removed_for_level:
		return
	animator.playing = autoplay_boundary_animation
	animator.set_paused(false)
	_set_runtime_effects_enabled(_is_boundary_visible())


## Compatibility alias used by run-preview startup.
func begin_runtime_animation() -> void:
	play_runtime_animation()


func restart_runtime_animation() -> void:
	if animator == null or boundary_removed_for_level:
		return
	animator.restart(true)
	_set_runtime_effects_enabled(_is_boundary_visible())


func set_runtime_paused(value: bool) -> void:
	if animator != null:
		animator.set_paused(value)


func set_playback_mode(value: GDKillBoundary2Animator.PlaybackMode) -> void:
	playback_mode = value


func set_playback_speed(value: float) -> void:
	playback_speed = value


func set_render_effect(value: GDKillBoundary2Settings.RenderEffect) -> void:
	render_effect = value


func get_elapsed_time() -> float:
	return elapsed_time


func get_boundary_animation_position() -> float:
	return animator.authored_position if animator != null else 0.0


func get_boundary_animation_duration() -> float:
	if animator != null:
		return animator.get_playback_duration()
	if sequence == null:
		return 0.0
	var authored_duration := sequence.get_duration()
	return (
		authored_duration + loop_return_seconds
		if playback_mode == GDKillBoundary2Animator.PlaybackMode.Loop
		and sequence.get_pose_count() > 1
		and authored_duration > 0.0
		else authored_duration
	)


func get_bounds_center() -> Vector3:
	if boundary_removed_for_level:
		return Vector3.ZERO
	if state_root == null:
		return Vector3.ZERO
	var local_center := Vector3(0.0, settings.flame_y if settings != null else 0.0, 0.0)
	return state_root.global_transform * local_center if state_root.is_inside_tree() else local_center


func get_bounds_transform() -> Transform3D:
	if state_root == null or boundary_removed_for_level:
		return Transform3D.IDENTITY
	var result := state_root.global_transform if state_root.is_inside_tree() else state_root.transform
	result.origin = get_bounds_center()
	return result


func get_camera_fit_transform() -> Transform3D:
	var result := get_bounds_transform()
	var scale_limit := maxf(camera_fit_scale_limit, 0.1)
	result.basis.x = result.basis.x.normalized() * minf(result.basis.x.length(), scale_limit)
	result.basis.z = result.basis.z.normalized() * minf(result.basis.z.length(), scale_limit)
	return result


func get_bounds_size() -> Vector2:
	if boundary_removed_for_level or animator == null:
		return Vector2.ZERO
	return animator.state.size * runtime_bounds_multiplier


func get_bounds_height() -> float:
	return 0.0 if boundary_removed_for_level or settings == null else settings.flame_height


## Returns the exact canonical perimeter currently used by visuals and collision.
func get_boundary_world_points() -> PackedVector3Array:
	return geometry.get_world_points() if geometry != null and not boundary_removed_for_level \
		else PackedVector3Array()


func pause_runtime_for(seconds: float) -> bool:
	if boundary_removed_for_level or animator == null or not _is_boundary_visible():
		return false
	runtime_pause_token += 1
	var pause_token := runtime_pause_token
	animator.set_paused(true)
	_resume_runtime_after(pause_token, maxf(seconds, 0.01))
	return true


func expand_runtime_bounds_percent(percent: float) -> bool:
	if boundary_removed_for_level or not _is_boundary_visible():
		return false
	var multiplier := 1.0 + maxf(percent, 0.0) * 0.01
	if multiplier <= 1.0:
		return false
	permanent_runtime_bounds_multiplier *= multiplier
	_apply_runtime_bounds_multiplier(_get_target_runtime_bounds_multiplier())
	return true


func expand_runtime_bounds_percent_for(
	percent: float,
	active_seconds: float,
	expansion_transition_seconds: float,
	contraction_transition_seconds := -1.0
) -> bool:
	if boundary_removed_for_level or not _is_boundary_visible():
		return false
	var multiplier := 1.0 + maxf(percent, 0.0) * 0.01
	if multiplier <= 1.0:
		return false
	active_runtime_bounds_multipliers.append(multiplier)
	_animate_runtime_bounds_multiplier(
		_get_target_runtime_bounds_multiplier(), expansion_transition_seconds
	)
	var contraction_seconds := contraction_transition_seconds \
		if contraction_transition_seconds >= 0.0 else expansion_transition_seconds
	_restore_runtime_bounds_after(multiplier, maxf(active_seconds, 0.0), contraction_seconds)
	return true


func remove_for_level(sink_seconds := 1.0, sink_distance := 3.0) -> bool:
	if boundary_removed_for_level:
		return false
	boundary_removed_for_level = true
	runtime_pause_token += 1
	if animator != null:
		animator.stop()
	if runtime_bounds_tween != null and runtime_bounds_tween.is_valid():
		runtime_bounds_tween.kill()
	_set_runtime_effects_enabled(false, true)
	if boundary_space != null:
		if removal_tween != null and removal_tween.is_valid():
			removal_tween.kill()
		removal_tween = create_tween()
		removal_tween.tween_property(
			boundary_space,
			^"position:y",
			boundary_space.position.y - maxf(sink_distance, 0.0),
			maxf(sink_seconds, 0.01)
		)
		removal_tween.tween_callback(queue_free)
	else:
		queue_free()
	boundary_removed.emit()
	return true


func preview_seek(time_seconds: float) -> void:
	if animator == null:
		return
	animator.stop()
	animator.set_paused(false)
	animator.seek(time_seconds)


func preview_play() -> void:
	if animator == null:
		return
	if animator.authored_position >= get_boundary_animation_duration():
		animator.restart(true)
	else:
		animator.playing = true
		animator.set_paused(false)


func preview_stop() -> void:
	if animator != null:
		animator.stop()


func advance_editor_preview(delta: float) -> void:
	if animator != null:
		animator.advance(delta)
	if presentation != null:
		presentation.advance_effect_time(delta)


func set_editor_active_pose(pose_index: int) -> void:
	if sequence == null or sequence.get_pose_count() == 0:
		editor_active_pose_index = 0
		return
	editor_active_pose_index = clampi(pose_index, 0, sequence.get_pose_count() - 1)
	var pose := sequence.get_pose(editor_active_pose_index)
	if pose != null:
		preview_seek(pose.time_seconds)
	for authored_pose in sequence.get_poses():
		authored_pose.update_gizmos()
	editor_active_pose_changed.emit(editor_active_pose_index)


func _cache_components() -> void:
	animator = get_node_or_null(^"Animator") as GDKillBoundary2Animator
	geometry = get_node_or_null(^"Geometry") as GDKillBoundary2Geometry
	boundary_space = get_node_or_null(^"BoundarySpace") as Node3D
	state_root = get_node_or_null(^"BoundarySpace/StateRoot") as Node3D
	presentation = get_node_or_null(^"BoundarySpace/StateRoot/Presentation") \
		as GDKillBoundary2Presentation
	damage = get_node_or_null(^"BoundarySpace/StateRoot/Damage") as GDKillBoundary2Damage
	blockers = get_node_or_null(^"BoundarySpace/StateRoot/Blockers") as GDKillBoundary2Blockers
	proximity_audio = get_node_or_null(^"ProximityAudio") as GDKillBoundary2Audio


func _assign_sequence_editor_owner(authored_sequence: GDKillBoundary2Sequence) -> void:
	if not Engine.is_editor_hint() or not is_inside_tree():
		return
	var edited_root := get_tree().edited_scene_root
	if edited_root != null and edited_root != self and edited_root.is_ancestor_of(authored_sequence):
		authored_sequence.owner = edited_root


func _configure_components() -> void:
	if settings == null:
		settings = DEFAULT_SETTINGS
	if geometry != null:
		geometry.configure(state_root, settings.boundary_segments)
	if presentation != null:
		presentation.configure(settings, render_effect)
	if damage != null:
		damage.configure(settings, geometry)
		damage.set_render_effect(render_effect)
	if blockers != null:
		blockers.configure(settings)
		blockers.set_blocking_enabled(player_blocking_enabled)
	if proximity_audio != null:
		proximity_audio.configure(settings, geometry, render_effect)


func _connect_component_signals() -> void:
	if animator != null and not animator.state_changed.is_connected(_on_state_changed):
		animator.state_changed.connect(_on_state_changed)
	if geometry != null and not geometry.geometry_changed.is_connected(_on_geometry_changed):
		geometry.geometry_changed.connect(_on_geometry_changed)


func _sync_animator_configuration() -> void:
	if animator == null or sequence == null:
		return
	animator.configure(sequence, playback_mode, playback_speed, loop_return_seconds)


func _sync_render_effect() -> void:
	if presentation != null:
		presentation.set_render_effect(render_effect)
	if damage != null:
		damage.set_render_effect(render_effect)
	if proximity_audio != null:
		proximity_audio.set_render_effect(render_effect)


func _on_sequence_changed() -> void:
	if animator == null:
		return
	editor_active_pose_index = clampi(
		editor_active_pose_index, 0, maxi(sequence.get_pose_count() - 1, 0)
	)
	animator.seek(animator.authored_position)


func _on_state_changed(state: GDKillBoundary2State) -> void:
	if geometry != null:
		geometry.apply_state(state, runtime_bounds_multiplier)


func _on_geometry_changed(points: PackedVector2Array) -> void:
	if presentation != null:
		presentation.apply_geometry(points)
	if damage != null:
		damage.apply_geometry(points)
	if blockers != null:
		blockers.apply_geometry(points)


func _set_runtime_effects_enabled(enabled: bool, keep_visuals := false) -> void:
	if presentation != null:
		presentation.set_effects_enabled(enabled, keep_visuals)
	if damage != null:
		damage.set_effects_enabled(enabled)
	if blockers != null:
		blockers.set_effects_enabled(enabled)
	if proximity_audio != null:
		proximity_audio.set_effects_enabled(enabled)


func _is_boundary_visible() -> bool:
	return (
		not boundary_removed_for_level
		and boundary_space != null
		and boundary_space.visible
	)


func _get_target_runtime_bounds_multiplier() -> float:
	var result := permanent_runtime_bounds_multiplier
	for multiplier in active_runtime_bounds_multipliers:
		result *= multiplier
	return result


func _apply_runtime_bounds_multiplier(value: float) -> void:
	runtime_bounds_multiplier = maxf(value, 0.01)
	if animator != null:
		_on_state_changed(animator.state)


func _animate_runtime_bounds_multiplier(target: float, seconds: float) -> void:
	if runtime_bounds_tween != null and runtime_bounds_tween.is_valid():
		runtime_bounds_tween.kill()
	if not is_inside_tree() or seconds <= 0.0:
		_apply_runtime_bounds_multiplier(target)
		return
	runtime_bounds_tween = create_tween()
	runtime_bounds_tween.tween_method(
		_apply_runtime_bounds_multiplier, runtime_bounds_multiplier, target, seconds
	)


func _resume_runtime_after(pause_token: int, seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout
	if pause_token == runtime_pause_token and not boundary_removed_for_level and animator != null:
		animator.set_paused(false)


func _restore_runtime_bounds_after(
	multiplier: float, active_seconds: float, contraction_seconds: float
) -> void:
	await get_tree().create_timer(active_seconds).timeout
	if boundary_removed_for_level:
		return
	active_runtime_bounds_multipliers.erase(multiplier)
	_animate_runtime_bounds_multiplier(
		_get_target_runtime_bounds_multiplier(), maxf(contraction_seconds, 0.0)
	)
