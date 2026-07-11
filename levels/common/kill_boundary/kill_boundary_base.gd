@tool
@abstract
extends Path3D


const EDITOR_PREVIEW_CONTAINER_NAME := "EditorPreview"
const BOUNDARY_CENTER_NAME := "BoundaryCenter"
const ANIMATION_PLAYER_NAME := "BoundaryAnimationPlayer"
const DEFAULT_ANIMATION_NAME := &"kill_boundary"
const MOVEMENT_SPEED_TRACK_PATH := ^".:movement_speed"
const BOUNDARY_SIZE_X_TRACK_PATH := ^".:boundary_size_x"
const BOUNDARY_SIZE_Y_TRACK_PATH := ^".:boundary_size_y"
const BOUNDARY_SCALE_X_TRACK_PATH := ^".:boundary_scale_x"
const BOUNDARY_SCALE_Z_TRACK_PATH := ^".:boundary_scale_z"
const BOUNDARY_ROTATION_Z_RADIANS_TRACK_PATH := ^".:boundary_rotation_z_radians"
const LEGACY_SCALE_ROTATION_TARGET_TRACK_PATH := ^".:scale_rotation_target"
const LEGACY_SCALE_TRACK_PATH := ^"BoundaryCenter"
const PATH_POINT_MARKER_PREFIX := "Path Point "
const PATH_POINT_MARKER_COLOR := Color(0.25, 0.8, 1.0)
const NEAR_FLAMES_SOUND_PATH := "res://Assets/audio/near-the-flames.mp3"
const GHOST_BOUNDARY_SOUND_PATH := "res://Assets/audio/ghost-boundary.mp3"
const GHOST_BOUNDARY_VOLUME_BOOST_DB := 8.0
const DEFAULT_ANIMATED_BOUNDARY_SIZE := 16.0
const IDENTITY_BOUNDARY_SCALE := 1.0
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
const EDITOR_GHOST_PREVIEW_CYCLE_OFFSET := 0.38
const EDITOR_PATH_MARKER_REFRESH_DELAY := 0.75
@export_group("Animation")
## Animation controlling path progress, scale, shape morph, and future properties.
@export var boundary_animation: Animation:
	set(value):
		boundary_animation = value
		editor_speed_animation_snapshot = null
		editor_speed_observed_signature = ""
		editor_speed_stable_time = 0.0
		editor_path_marker_observed_signature = ""
		editor_path_marker_synced_signature = ""
		editor_path_marker_stable_time = 0.0
		_sync_animation_player()

## Starts the boundary animation automatically during gameplay.
@export var autoplay_boundary_animation := true

## Loops BoundaryCenter back to the start when movement passes the end of the path.
@export var loop_boundary_path := true:
	set(value):
		loop_boundary_path = value
		_configure_path_follow()

## Distance travelled along the path per second. Key this to create pressure changes.
@export_range(0.0, 20.0, 0.001, "or_greater", "suffix:mps") var movement_speed := 1.0

## Keeps other animation keys attached to their path positions after a single speed key value is edited.
@export var ripple_retime_after_speed_key_edit := true

## Width of the generated boundary geometry in local world units.
@export_range(0.1, 1000.0, 0.1, "or_greater", "suffix:m") var boundary_size_x := 8.0:
	set(value):
		boundary_size_x = maxf(value, 0.1)
		_sync_boundary()

## Depth of the generated boundary geometry in local world units.
@export_range(0.1, 1000.0, 0.1, "or_greater", "suffix:m") var boundary_size_y := 8.0:
	set(value):
		boundary_size_y = maxf(value, 0.1)
		_sync_boundary()

## Legacy BoundaryCenter local X scale retained for existing level animations.
@export_range(0.001, 20.0, 0.001, "or_greater") var boundary_scale_x := 1.0:
	set(value):
		boundary_scale_x = maxf(value, 0.001)
		_apply_boundary_scale_rotation()

## Legacy BoundaryCenter local Z scale retained for existing level animations.
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
## Legacy combined size retained so existing scenes deserialize without changing dimensions.
@export_storage var bounds_size: Vector2:
	get:
		return Vector2(boundary_size_x, boundary_size_y)
	set(value):
		boundary_size_x = maxf(value.x, 0.1)
		boundary_size_y = maxf(value.y, 0.1)
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
var editor_path_marker_observed_signature := ""
var editor_path_marker_synced_signature := ""
var editor_path_marker_stable_time := 0.0
var editor_speed_animation_snapshot: Animation
var editor_speed_observed_signature := ""
var editor_speed_stable_time := 0.0
var is_syncing_boundary := false


@abstract func _animate_runtime_bounds_multiplier(target_multiplier: float, seconds: float) -> void
@abstract func _apply_boundary_to_segments(meshes: Array[MeshInstance3D], collisions: Array[CollisionShape3D]) -> void
@abstract func _apply_boundary_scale_rotation() -> void
@abstract func _apply_flame_heat(delta: float) -> void
@abstract func _apply_ghosts_to_boundary(meshes: Array[MeshInstance3D], is_editor_preview := false) -> void
@abstract func _apply_player_blockers_to_segments(
    meshes: Array[MeshInstance3D],
    collisions: Array[CollisionShape3D],
) -> void
@abstract func _configure_path_follow() -> void
@abstract func _create_flame_material() -> void
@abstract func _create_ghost_material() -> void
@abstract func _create_near_flame_audio() -> void
@abstract func _create_strips() -> void
@abstract func _ensure_editor_preview() -> void
@abstract func _find_time_for_travel_distance(animation: Animation, target_distance: float) -> float
@abstract func _get_first_animation_key_time(animation: Animation) -> float
@abstract func _get_path_marker_source_signature() -> String
@abstract func _get_shape_profile_point(shape_index: int, perimeter_ratio: float) -> Vector2
@abstract func _get_speed_track_signature(animation: Animation) -> String
@abstract func _get_target_runtime_bounds_multiplier() -> float
@abstract func _integrate_speed_interval(
    animation: Animation,
    speed_track: int,
    start_time: float,
    end_time: float,
) -> float
@abstract func _is_editor_animation_edit_safe() -> bool
@abstract func _is_flame_effect_active() -> bool
@abstract func _is_ghost_effect_active() -> bool
@abstract func _restore_runtime_bounds_after(
    multiplier: float,
    active_seconds: float,
    transition_seconds: float,
) -> void
@abstract func _resume_runtime_motion_after(token: int, seconds: float) -> void
@abstract func _ripple_retime_tracks_after_speed_change(old_animation: Animation, new_animation: Animation) -> bool
@abstract func _sanitize_positive_range(value: Vector2, minimum: float) -> Vector2
@abstract func _set_runtime_motion_paused(paused: bool) -> void
@abstract func _set_center_progress(center: PathFollow3D, target_progress: float) -> void
@abstract func _sink_removed_boundary(seconds: float, distance: float) -> void
@abstract func _sync_animation_player() -> void
@abstract func _sync_boundary(update_removed_visuals := false) -> void
@abstract func _sync_boundary_scale_rotation_to_animation(animation: Animation, time: float) -> void
@abstract func _sync_editor_preview_animation() -> void
@abstract func _sync_movement_to_animation() -> void
@abstract func _update_ghost_billboards() -> void
@abstract func _update_ghost_boundary() -> void
@abstract func _update_near_flame_audio(delta: float) -> void
@abstract func _update_path_point_animation_markers(delta: float) -> void
@abstract func _update_player_blockers_enabled() -> void
@abstract func _update_removed_boundary_visuals(delta: float) -> void
@abstract func _update_runtime_blockers() -> void
@abstract func _update_runtime_boundary() -> void
@abstract func _update_speed_change_ripple_retime(delta: float) -> void
@abstract func _on_flame_body_entered(body: Node3D) -> void
@abstract func _on_flame_body_exited(body: Node3D) -> void
