extends Path3D


signal navigation_ready_changed(is_ready: bool)

enum ZombieState {
    LEVEL_START,
    PATROL,
    CHASE,
    SEARCH_LAST_SEEN,
    RETURN_TO_PATROL,
    POSITION_FOR_ATTACK,
    ATTACK,
    SITDOWN,
    CRUSHED,
    DIE,
}

const FOOTSTEP_SOUND_PATHS: Array[String] = [
    "res://Assets/audio/footstep1.wav",
    "res://Assets/audio/footstep2.wav",
    "res://Assets/audio/footstep3.wav",
    "res://Assets/audio/footstep4.wav",
]
const WILHELM_SCREAM := preload("res://Assets/audio/wilhelm-scream.mp3")
const DEFAULT_PUNCH_HIT_SOUND_PATH := "res://Assets/audio/punch.mp3"
const CHARACTER_GROUP: StringName = &"character"
const NAVIGATION_BLOCKER_GROUP := &"navigation_blocker"
const PLAYER_GROUP := &"player"
const SMART_ZOMBIE_GROUP: StringName = &"smart_zombie"
const WORLD_COLLISION_LAYER := 1
const PLAYER_COLLISION_LAYER := 2
const PICKUP_COLLISION_LAYER := 4
const ZOMBIE_COLLISION_LAYER := 8
const INVALID_GRID_CELL := Vector3i(2147483647, 2147483647, 2147483647)

## Compatibility sampler for existing level `PathFollow3D` overrides.
@export var path_follow_path: NodePath = ^"PathFollow3D"
## CharacterBody3D that owns movement and navigation.
@export var zombie_body_path: NodePath = ^"ZombieBody"
## NavigationAgent3D used for all smart-zombie target following.
@export var navigation_agent_path: NodePath = ^"ZombieBody/NavigationAgent3D"
## Node moved vertically while the zombie drops in.
@export var drop_pivot_path: NodePath = ^"ZombieBody/DropPivot"
## Visual pivot rotated toward the zombie's current shuffle direction.
@export var pivot_path: NodePath = ^"ZombieBody/DropPivot/Pivot"
## Imported zombie character subtree containing the AnimationPlayer.
@export var character_path: NodePath = ^"ZombieBody/DropPivot/Pivot/Character"
## Raycast origin for player vision.
@export var vision_origin_path: NodePath = ^"ZombieBody/VisionOrigin"
## Legacy contact area retained for crush detection placement only. Zombies damage through attack hitboxes.
@export var kill_area_path: NodePath = ^"ZombieBody/DropPivot/KillArea"
## Ground shadow shown while the zombie is active.
@export var shadow_path: NodePath = ^"ZombieBody/ZombieShadow"
## Light used to make the zombie readable before the player gets close.
@export var zombie_light_path: NodePath = ^"ZombieBody/DropPivot/Pivot/ZombieLight"
@export var attack_hitbox_right_path: NodePath = ^"ZombieBody/AttackHitboxRight"
@export var attack_hitbox_left_path: NodePath = ^"ZombieBody/AttackHitboxLeft"
@export var crush_check_area_path: NodePath = ^"ZombieBody/CrushCheckArea"

@export_group("Startup")
@export var ai_enabled_on_ready := true
@export var navigation_ready := false
## Seconds a player must remain inside the contact area before death triggers.
@export var kill_confirmation_time := 0.08
## Seconds after scene start before this zombie drops in.
@export var drop_in_time := 0.0
## Height above the patrol path used at the start of the drop-in.
@export var drop_height := 3.2
## Seconds taken to fall from drop_height to the path.
@export var drop_duration := 0.55
@export_group("")

@export_group("Patrol")
## Starting position along the patrol path, where 0 is the path start and 1 is the path end.
@export_range(0.0, 1.0, 0.001) var start_progress_ratio := 0.0
## World units per second along patrol, chase, and return paths. Zombies never sprint.
@export var shuffle_speed := 2.5
## If true, the zombie wraps from the end of an open path back to the start.
@export var loop_patrol := true
## If true, the zombie turns around at the ends of an open path.
@export var reverse_at_path_ends := true
## How quickly the visual turns toward the current movement direction.
@export var turn_speed := 6.0
@export var patrol_point_reached_distance := 0.35
## World units per second squared used when a zombie starts moving from a stop.
@export var movement_acceleration := 8.0
## World units per second squared used when a zombie needs to slow for a turn.
@export var movement_deceleration := 14.0
## Turn angle where zombies slow down instead of snapping to full movement speed.
@export_range(0.0, 180.0, 1.0) var sharp_turn_slow_angle_degrees := 70.0
## Fraction of requested speed used while the visual is still making a sharp turn.
@export_range(0.0, 1.0, 0.01) var sharp_turn_speed_multiplier := 0.45
@export_group("")

@export_group("Smart AI")
@export var vision_range := 5.0
@export var fov_degrees := 70.0
@export var player_target_height := 0.65
@export var attack_range := 0.95
@export var attack_continue_range := 1.35
## Number of candidate positions checked around the player when another zombie blocks the chase.
@export var attack_position_slot_count := 8
## Minimum spacing kept from other zombies when choosing a melee attack position.
@export var attack_position_clearance := 0.7
## Distance from the chosen attack position where the zombie resumes normal attack checks.
@export var attack_position_reached_distance := 0.25
@export var lost_sight_seconds := 7.0
@export var repath_interval := 0.25
@export var vision_interval := 0.2
@export var search_duration := 2.0
@export var idle_scan_min_seconds := 1.2
@export var idle_scan_max_seconds := 2.8
@export_range(0.0, 180.0, 1.0) var idle_scan_max_turn_degrees := 140.0
@export var sit_repath_interval := 1.0
@export var sit_vision_interval := 0.35
@export var stuck_seconds_before_sit := 2.0
@export var stuck_min_move_distance := 0.03
@export var grid_navigation_padding_cells := 3
@export var grid_navigation_max_search_cells := 4096
@export var direct_navigation_fallback_enabled := true
@export_flags_3d_physics var vision_collision_mask := WORLD_COLLISION_LAYER | PLAYER_COLLISION_LAYER
@export_flags_3d_physics var map_collision_mask := WORLD_COLLISION_LAYER
@export_group("")

@export_group("Attack")
@export var attack_damage := 10.0
@export var attack_cooldown := 1.0
@export var player_touch_attack_probe_margin := 0.04
@export_range(0.0, 1.0, 0.01) var attack_hit_start_ratio := 0.78
@export_range(0.0, 1.0, 0.01) var attack_hit_end_ratio := 0.94
@export var attack_hit_start_seconds := 0.78
@export var attack_hit_end_seconds := 0.94
@export var navigation_collision_floor_normal_y := 0.65
@export_file("*.mp3", "*.wav", "*.ogg") var punch_hit_sound_path := DEFAULT_PUNCH_HIT_SOUND_PATH
@export var punch_hit_volume_db := 0.0
@export_group("")

@export_group("Crush")
@export var rolling_ball_death_enabled := true
@export_range(0.0, 100.0, 1.0) var rolling_ball_death_encroachment_percent := 25.0
@export_range(0.05, 2.0, 0.01) var rolling_ball_death_detection_radius := 0.65
@export_range(0.05, 2.0, 0.01) var rolling_ball_death_radius := 0.52
@export_range(0.0, 1.0, 0.01) var crush_confirm_seconds := 0.1
@export_range(0.0, 10.0, 0.1) var death_disappear_delay := 3.0
@export_range(0.0, 5.0, 0.05) var death_disappear_duration := 1.35
@export_range(0.0, 5.0, 0.05) var death_sink_depth := 2.4
@export_range(0.0, 1.0, 0.05) var death_fade_start_ratio := 0.55
@export var death_scream_volume_db := 2.0
@export_group("")

@export_group("Animation")
@export var static_animation_name := "static"
@export var walk_animation_name := "walk"
@export var run_animation_name := "run"
@export var idle_animation_name := "idle"
@export var sit_animation_name := "sit"
@export var death_animation_name := "die"
@export var walk_animation_speed_scale := 0.45
@export var run_animation_speed_scale := 1.0
@export var death_animation_speed_scale := 0.5
@export var attack_animation_names: Array[String] = [
    "attack-kick-right",
    "attack-kick-left",
    "attack-melee-right",
    "attack-melee-left",
]
@export_group("")

@export_group("Footsteps")
@export var footstep_speed_threshold := 0.1
@export var footstep_distance := 0.7
@export var footstep_distance_variance := 0.18
@export var footstep_pitch_min := 0.92
@export var footstep_pitch_max := 1.08
@export var footstep_volume_min_db := 0.0
@export var footstep_volume_max_db := 4.0
@export_group("")

@export_group("Light")
@export var zombie_light_enabled := true
@export var zombie_light_color := Color(0.85, 1.0, 0.62, 1.0)
@export var zombie_light_energy := 0.95
@export var zombie_light_range := 4.2
@export var zombie_light_attenuation := 1.45
@export var zombie_light_cast_shadows := true
@export_group("")

@onready var path_follow := get_node_or_null(path_follow_path) as PathFollow3D
@onready var zombie_body := get_node_or_null(zombie_body_path) as CharacterBody3D
@onready var navigation_agent := get_node_or_null(navigation_agent_path) as NavigationAgent3D
@onready var drop_pivot := get_node_or_null(drop_pivot_path) as Node3D
@onready var pivot := get_node_or_null(pivot_path) as Node3D
@onready var character := get_node_or_null(character_path) as Node3D
@onready var vision_origin := get_node_or_null(vision_origin_path) as Marker3D
@onready var kill_area := get_node_or_null(kill_area_path) as Area3D
@onready var shadow := get_node_or_null(shadow_path) as Node3D
@onready var zombie_light := get_node_or_null(zombie_light_path) as OmniLight3D
@onready var attack_hitbox_right := get_node_or_null(attack_hitbox_right_path) as Area3D
@onready var attack_hitbox_left := get_node_or_null(attack_hitbox_left_path) as Area3D
@onready var crush_check_area := get_node_or_null(crush_check_area_path) as Area3D

var state := ZombieState.LEVEL_START
var player: Node3D
var patrol_points: Array[Vector3] = []
var navigation_grid_maps: Array[GridMap] = []
var navigation_grid_bounds_by_id: Dictionary = {}
var patrol_index := 0
var patrol_direction := 1
var current_target := Vector3.ZERO
var attack_position_target := Vector3.ZERO
var attack_position_player_anchor := Vector3.ZERO
var has_attack_position_target := false
var last_seen_position := Vector3.ZERO
var last_seen_timer := 0.0
var vision_timer := 0.0
var cached_player_visible := false
var repath_timer := 0.0
var search_timer := 0.0
var sit_repath_timer := 0.0
var sit_vision_timer := 0.0
var idle_scan_timer := 0.0
var idle_scan_target_yaw := 0.0
var stuck_timer := 0.0
var attack_timer := 0.0
var attack_index := 0
var attack_hit_applied := false
var current_attack_hit_start_seconds := 0.0
var current_attack_hit_end_seconds := 0.0
var active_attack_hitbox: Area3D
var crush_timer := 0.0
var previous_body_position := Vector3.ZERO
var facing_direction := Vector3.BACK
var current_movement_velocity := Vector3.ZERO
var footstep_sounds: Array[AudioStream] = []
var punch_hit_sound: AudioStream
var footstep_distance_accumulator := 0.0
var next_footstep_distance := 1.0
var footstep_rng := RandomNumberGenerator.new()
var animation_player: AnimationPlayer
var current_animation := ""
var resolved_run_animation := ""
var resolved_death_animation := ""
var kill_overlap_times: Dictionary = {}
var elapsed_time := 0.0
var drop_elapsed := 0.0
var has_dropped_in := false
var is_dropping_in := false
var is_dead := false
var is_disappearing := false


func _get_body_position() -> Vector3:
    return zombie_body.global_position if zombie_body != null else global_position


func _get_vision_origin() -> Vector3:
    if vision_origin != null:
        return vision_origin.global_position
    return _get_body_position() + Vector3.UP * 0.9


func _get_player_target_position() -> Vector3:
    if player == null:
        return last_seen_position + Vector3.UP * player_target_height
    return player.global_position + Vector3.UP * player_target_height


func _get_player_navigation_position() -> Vector3:
    if player == null:
        return last_seen_position

    var position := player.global_position
    position.y = _get_body_position().y
    return position


func _find_collision_shape(node: Node) -> CollisionShape3D:
    if node == null:
        return null

    for child in node.get_children():
        if child is CollisionShape3D:
            return child as CollisionShape3D

        var result := _find_collision_shape(child)
        if result != null:
            return result

    return null


func _find_animation_player(node: Node) -> AnimationPlayer:
    if node is AnimationPlayer:
        return node as AnimationPlayer

    for child in node.get_children():
        var result := _find_animation_player(child)
        if result != null:
            return result

    return null


func _is_descendant_of(candidate: Object, ancestor: Node) -> bool:
    if candidate == null or ancestor == null or not candidate is Node:
        return false

    var node := candidate as Node
    while node != null:
        if node == ancestor:
            return true
        node = node.get_parent()

    return false


func _get_vision_excludes() -> Array[RID]:
    var excludes: Array[RID] = []
    if zombie_body != null:
        excludes.append(zombie_body.get_rid())
    return excludes


func _is_live_player_body(body: Node) -> bool:
    if body == null:
        return false

    if body.has_method("is_dead") and body.is_dead():
        return false

    return body.has_method("die_from_flames")


func has_reserved_attack_position() -> bool:
    return has_attack_position_target


func get_reserved_attack_position() -> Vector3:
    return attack_position_target
