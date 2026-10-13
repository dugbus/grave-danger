extends "res://placeables/path_placeable.gd"

@warning_ignore("unused_signal")
signal navigation_ready_changed(is_ready: bool)

enum ZombieState {
	LevelStart,
	Patrol,
	Chase,
	SearchLastSeen,
	ReturnToPatrol,
	PositionForAttack,
	Attack,
	Sitdown,
	Crushed,
	Die,
}

const FOOTSTEP_SOUND_PATHS: Array[String] = [
	"res://Assets/audio/footstep1.mp3",
	"res://Assets/audio/footstep2.mp3",
	"res://Assets/audio/footstep3.mp3",
	"res://Assets/audio/footstep4.mp3",
]
const WILHELM_SCREAM := preload("res://Assets/audio/wilhelm-scream.mp3")
const DEFAULT_PUNCH_HIT_SOUND_PATH := "res://Assets/audio/punch.mp3"
const LANDING_SOUND_PATH := "res://Assets/audio/enemy-landing.mp3"
const LANDING_AUDIO_NAME := "ZombieLandingAudio"
const LANDING_AUDIO_VOLUME_DB := 4.0
const LANDING_AUDIO_MAX_DISTANCE := 48.0
const LANDING_AUDIO_UNIT_SIZE := 16.0
const CHARACTER_GROUP: StringName = &"character"
const ENEMY_GROUP: StringName = &"enemy"
const NAVIGATION_BLOCKER_GROUP := &"navigation_blocker"
const PLAYER_GROUP := &"player"
const SMART_ZOMBIE_GROUP: StringName = &"smart_zombie"
const WORLD_COLLISION_LAYER := 1
const PLAYER_COLLISION_LAYER := 2
const PICKUP_COLLISION_LAYER := 4
const ZOMBIE_COLLISION_LAYER := 8
const PLAYER_BOUNDARY_BLOCKER_COLLISION_LAYER := 1 << 4
const SKELETON_COLLISION_LAYER := 1 << 5
const ENEMY_GEOMETRY_VISUAL_LAYER := 1 << 18
const ALL_VISUAL_LAYERS := (1 << 20) - 1
const ALL_SHADOW_CASTER_LAYERS := (1 << 32) - 1
const ENEMY_LIGHT_SHADOW_CASTER_MASK := ALL_SHADOW_CASTER_LAYERS & ~ENEMY_GEOMETRY_VISUAL_LAYER
const INVALID_GRID_CELL := Vector3i(2147483647, 2147483647, 2147483647)

## Compatibility sampler for existing level `PathFollow3D` overrides.
@export_storage var path_follow_path: NodePath = ^"PathFollow3D"
## CharacterBody3D that owns movement and navigation.
@export_storage var zombie_body_path: NodePath = ^"ZombieBody"
## NavigationAgent3D used for all smart-zombie target following.
@export_storage var navigation_agent_path: NodePath = ^"ZombieBody/NavigationAgent3D"
## Node moved vertically while the zombie drops in.
@export_storage var drop_pivot_path: NodePath = ^"ZombieBody/DropPivot"
## Visual pivot rotated toward the zombie's current shuffle direction.
@export_storage var pivot_path: NodePath = ^"ZombieBody/DropPivot/Pivot"
## Imported zombie character subtree containing the AnimationPlayer.
@export_storage var character_path: NodePath = ^"ZombieBody/DropPivot/Pivot/Character"
## Raycast origin for player vision.
@export_storage var vision_origin_path: NodePath = ^"ZombieBody/VisionOrigin"
## Legacy contact area retained for crush detection placement only. Zombies damage through attack hitboxes.
@export_storage var kill_area_path: NodePath = ^"ZombieBody/DropPivot/KillArea"
## Ground shadow shown while the zombie is active.
@export_storage var shadow_path: NodePath = ^"ZombieBody/ZombieShadow"
## Light used to make the zombie readable before the player gets close.
@export_storage var zombie_light_path: NodePath = ^"ZombieBody/DropPivot/Pivot/ZombieLight"
## Area used to detect player hits during right-side attacks.
@export_storage var attack_hitbox_right_path: NodePath = ^"ZombieBody/AttackHitboxRight"
## Area used to detect player hits during left-side attacks.
@export_storage var attack_hitbox_left_path: NodePath = ^"ZombieBody/AttackHitboxLeft"
## Area used to detect rolling balls that can crush this zombie.
@export_storage var crush_check_area_path: NodePath = ^"ZombieBody/CrushCheckArea"

## Inspector group for Startup settings.
@export_group("Startup")
## Starts the zombie's AI automatically when it enters the scene.
@export var ai_enabled_on_ready := true
## Runtime readiness managed by startup and navigation bootstrap; never authored in a level.
var navigation_ready := false
## Seconds a player must remain inside the contact area before death triggers.
@export var kill_confirmation_time := 0.08
## Legacy serialized enemy delay; new level editing uses the shared Spawn Time field.
@export_storage var drop_in_time: float:
	get:
		return spawn_time
	set(value):
		spawn_time = maxf(value, 0.0)
## Height above the patrol path used at the start of the drop-in.
@export var drop_height := 3.2
## Seconds taken to fall from drop_height to the path.
@export var drop_duration := 0.55
## Ends the preceding Inspector group.
@export_group("")

## Inspector group for Patrol settings.
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
## Distance in world units at which the next patrol point counts as reached.
@export_storage var patrol_point_reached_distance := 0.35
## World units per second squared used when a zombie starts moving from a stop.
@export var movement_acceleration := 8.0
## World units per second squared used when a zombie needs to slow for a turn.
@export var movement_deceleration := 14.0
## Turn angle where zombies slow down instead of snapping to full movement speed.
@export_range(0.0, 180.0, 1.0) var sharp_turn_slow_angle_degrees := 70.0
## Fraction of requested speed used while the visual is still making a sharp turn.
@export_range(0.0, 1.0, 0.01) var sharp_turn_speed_multiplier := 0.45
## Ends the preceding Inspector group.
@export_group("")

## Inspector group for Smart AI settings.
@export_group("Smart AI")
## Maximum distance in world units at which the zombie can see the player.
@export var vision_range := 5.0
## Total width of the zombie's vision cone, in degrees.
@export var fov_degrees := 70.0
## Height above the player origin used for sight checks, in world units.
@export_storage var player_target_height := 0.65
## Body-center distance where an extended arm can reach the player capsule.
@export var attack_range := 0.6
## Small hysteresis margin before a missed punch resumes chasing the player.
@export_storage var attack_continue_range := 0.65
## Number of candidate positions checked around the player when another zombie blocks the chase.
@export_storage var attack_position_slot_count := 8
## Minimum spacing kept from other zombies when choosing a melee attack position.
@export_storage var attack_position_clearance := 0.7
## Distance from the chosen attack position where the zombie resumes normal attack checks.
@export_storage var attack_position_reached_distance := 0.25
## Seconds the zombie remembers the player after losing sight.
@export var lost_sight_seconds := 7.0
## Seconds between route updates while pursuing the player.
@export_storage var repath_interval := 0.25
## Seconds between player sight checks while active.
@export_storage var vision_interval := 0.2
## Seconds spent searching near the last known player position.
@export var search_duration := 2.0
## Shortest pause in seconds between idle look directions.
@export var idle_scan_min_seconds := 1.2
## Longest pause in seconds between idle look directions.
@export var idle_scan_max_seconds := 2.8
## Maximum angle in degrees for an idle look away from the current heading.
@export_range(0.0, 180.0, 1.0) var idle_scan_max_turn_degrees := 140.0
## Seconds between route updates while the zombie is sitting.
@export_storage var sit_repath_interval := 1.0
## Seconds between player sight checks while the zombie is sitting.
@export_storage var sit_vision_interval := 0.35
## Seconds without useful movement before the zombie sits down.
@export var stuck_seconds_before_sit := 2.0
## Minimum movement in world units that counts as progress when detecting a stuck zombie.
@export_storage var stuck_min_move_distance := 0.03
## Extra grid cells around the route search area to allow detours.
@export_storage var grid_navigation_padding_cells := 3
## Maximum number of grid cells searched when finding a route.
@export_storage var grid_navigation_max_search_cells := 4096
## Allows direct movement toward the target when a grid route cannot be found.
@export_storage var direct_navigation_fallback_enabled := true
## Physics layers checked for the player and obstacles that block sight.
@export_storage var vision_collision_mask := WORLD_COLLISION_LAYER | PLAYER_COLLISION_LAYER
## Physics layers checked for static obstacles when planning and following zombie routes.
@export_storage var map_collision_mask := WORLD_COLLISION_LAYER
## Ends the preceding Inspector group.
@export_group("")

## Inspector group for Attack settings.
@export_group("Attack")
## Energy removed from the player by a successful attack.
@export var attack_damage := 10.0
## Minimum seconds between attacks.
@export var attack_cooldown := 1.0
## Extra distance in world units used when checking close contact for an attack.
@export_storage var player_touch_attack_probe_margin := 0.04
## Fraction of the attack animation elapsed before its hitbox becomes active.
@export_range(0.0, 1.0, 0.01) var attack_hit_start_ratio := 0.78
## Fraction of the attack animation elapsed when its hitbox stops being active.
@export_range(0.0, 1.0, 0.01) var attack_hit_end_ratio := 0.94
## Fallback hitbox start time in seconds when the attack animation has no known duration.
@export_storage var attack_hit_start_seconds := 0.78
## Fallback hitbox end time in seconds when the attack animation has no known duration.
@export_storage var attack_hit_end_seconds := 0.94
## Minimum upward collision normal component treated as floor rather than a navigation obstacle.
@export_storage var navigation_collision_floor_normal_y := 0.65
## Audio sample played when a zombie attack lands on the player.
@export_file("*.mp3", "*.wav", "*.ogg") var punch_hit_sound_path := DEFAULT_PUNCH_HIT_SOUND_PATH
## Volume of a successful zombie attack sound, in decibels.
@export var punch_hit_volume_db := 0.0
## Ends the preceding Inspector group.
@export_group("")

## Inspector group for Crush settings.
@export_group("Crush")
## Enables rolling balls to kill the zombie when they push far enough into its detection area.
@export var rolling_ball_death_enabled := true
## Percentage of the detection radius the ball must encroach before killing the zombie.
@export_range(0.0, 100.0, 1.0) var rolling_ball_death_encroachment_percent := 25.0
## Radius around the zombie contact area used for rolling ball death checks.
@export_storage var rolling_ball_death_detection_radius := 0.65
## Approximate rolling ball radius used to calculate encroachment percentage.
@export_storage var rolling_ball_death_radius := 0.52
## Seconds a crushing contact must persist before the zombie dies.
@export_storage var crush_confirm_seconds := 0.1
## Seconds after death before the zombie fades and sinks underground.
@export_range(0.0, 10.0, 0.1) var death_disappear_delay := 3.0
## Seconds used for the underground movement.
@export_range(0.0, 5.0, 0.05) var death_disappear_duration := 1.35
## Local Y distance the zombie moves underground while disappearing.
@export_range(0.0, 5.0, 0.05) var death_sink_depth := 2.4
## Portion of the sink animation completed before fading starts.
@export_range(0.0, 1.0, 0.05) var death_fade_start_ratio := 0.55
## Volume of the zombie death scream, in decibels.
@export var death_scream_volume_db := 2.0
## Ends the preceding Inspector group.
@export_group("")

## Inspector group for Animation settings.
@export_group("Animation")
## Animation clip used for the zombie's static pose.
@export_storage var static_animation_name := "static"
## Animation played while the zombie is moving.
@export_storage var walk_animation_name := "walk"
## Animation clip used while the zombie runs.
@export_storage var run_animation_name := "run"
## Animation played if the zombie has no usable movement.
@export_storage var idle_animation_name := "idle"
## Animation clip used while the zombie sits.
@export_storage var sit_animation_name := "sit"
## Animation played when a rolling ball crushes the zombie.
@export_storage var death_animation_name := "die"
## Keeps the walk cycle at a shuffling pace even if path speed is adjusted.
@export var walk_animation_speed_scale := 0.45
## Playback speed multiplier for the running animation.
@export var run_animation_speed_scale := 1.0
## Speed scale used for the zombie death animation.
@export var death_animation_speed_scale := 0.5
## Ordered attack animation clips cycled through when the zombie attacks.
@export_storage var attack_animation_names: Array[String] = [
	"attack-kick-right",
	"attack-kick-left",
	"attack-melee-right",
	"attack-melee-left",
]
## Ends the preceding Inspector group.
@export_group("")

## Inspector group for Footsteps settings.
@export_group("Footsteps")
## Minimum horizontal speed required to play footstep sounds.
@export var footstep_speed_threshold := 0.1
## Base travel distance between footstep sounds.
@export var footstep_distance := 0.7
## Random distance added or subtracted from each footstep interval.
@export var footstep_distance_variance := 0.08
## Lowest random pitch scale used for each footstep.
@export var footstep_pitch_min := 0.92
## Highest random pitch scale used for each footstep.
@export var footstep_pitch_max := 1.08
## Footstep volume at the speed threshold, in decibels.
@export var footstep_volume_min_db := 0.0
## Footstep volume near full walking speed, in decibels.
@export var footstep_volume_max_db := 4.0
## Random volume variation applied to each zombie footstep, in decibels.
@export var footstep_volume_variance_db := 0.35
## Ends the preceding Inspector group.
@export_group("")

## Inspector group for Light settings.
@export_group("Light")
## Enables the zombie's warning light.
@export var zombie_light_enabled := true
## Color of the zombie's warning light.
@export var zombie_light_color := Color(0.85, 1.0, 0.62, 1.0)
## Brightness of the zombie's warning light.
@export var zombie_light_energy := 0.95
## Reach of the zombie's warning light, in world units.
@export var zombie_light_range := 4.2
## Falloff curve for the zombie's warning light.
@export var zombie_light_attenuation := 1.45
## Ends the preceding Inspector group.
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

var state := ZombieState.LevelStart
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
var landing_sound: AudioStream
var footstep_distance_accumulator := 0.0
var next_footstep_distance := 1.0
var footstep_rng := RandomNumberGenerator.new()
var previous_walk_animation_phase := -1.0
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
var has_moved_body_this_frame := false


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

	var navigation_position := player.global_position
	navigation_position.y = _get_body_position().y
	return navigation_position


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

	return body.has_method("apply_flame_damage") or body.has_method("die_from_enemy")


func has_reserved_attack_position() -> bool:
	return has_attack_position_target


func get_reserved_attack_position() -> Vector3:
	return attack_position_target
