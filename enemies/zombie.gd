extends Path3D
class_name GDZombiePath


signal navigation_ready_changed(is_ready: bool)

enum ZombieState {
    LEVEL_START,
    PATROL,
    CHASE,
    SEARCH_LAST_SEEN,
    RETURN_TO_PATROL,
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
@export_group("")

@export_group("Smart AI")
@export var vision_range := 5.0
@export var fov_degrees := 70.0
@export var player_target_height := 0.65
@export var attack_range := 0.95
@export var attack_continue_range := 1.35
@export var chase_speed_multiplier := 2.0
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


func _ready() -> void:
    add_to_group(CHARACTER_GROUP)
    add_to_group(SMART_ZOMBIE_GROUP)
    _seed_deterministic_rng()
    _load_footstep_sounds()
    _load_punch_hit_sound()
    _randomize_next_footstep_distance()
    _configure_nodes()
    _apply_start_progress()
    _build_patrol_points()
    _sync_body_to_path_start()
    _configure_shadow_casting()
    _configure_zombie_light()
    _set_attack_hitboxes_enabled(false)

    if character != null:
        animation_player = _find_animation_player(character)
        _resolve_animation_names()

    previous_body_position = _get_body_position()
    navigation_ready = ai_enabled_on_ready
    state = ZombieState.PATROL if navigation_ready else ZombieState.LEVEL_START

    if drop_in_time > 0.0:
        _set_active_visible(false)
    else:
        _finish_drop_in()


func _physics_process(delta: float) -> void:
    if zombie_body == null:
        _update_animation(0.0)
        return

    if is_dead:
        return

    if not _update_drop_in(delta):
        _update_animation(0.0)
        return

    if not navigation_ready:
        _change_state(ZombieState.LEVEL_START)
        _stop_body()
        _update_animation(0.0)
        return

    _resolve_player()
    _update_rolling_ball_death(delta)
    _update_state(delta)


func set_navigation_ready(is_ready: bool) -> void:
    navigation_ready = is_ready
    navigation_ready_changed.emit(navigation_ready)
    if navigation_ready and state == ZombieState.LEVEL_START:
        _change_state(ZombieState.PATROL)
        _set_next_patrol_target()
    elif not navigation_ready:
        _change_state(ZombieState.LEVEL_START)
        _stop_body()


func set_ai_enabled(enabled: bool) -> void:
    set_navigation_ready(enabled)


func set_ai_player(target_player: Node3D) -> void:
    player = target_player
    vision_timer = 0.0
    last_seen_timer = lost_sight_seconds
    cached_player_visible = false


func set_navigation_grid_maps(grid_maps: Array[GridMap]) -> void:
    navigation_grid_maps.clear()
    navigation_grid_bounds_by_id.clear()

    for grid_map in grid_maps:
        if grid_map == null:
            continue

        navigation_grid_maps.append(grid_map)
        navigation_grid_bounds_by_id[grid_map.get_instance_id()] = _get_grid_navigation_bounds(grid_map)


func get_zombie_state() -> ZombieState:
    return state


func die_from_spike_trap() -> void:
    _die_from_rolling_ball()


func can_be_hit_by_spike_trap() -> bool:
    return not is_dead


func get_spike_trap_position() -> Vector3:
    return _get_body_position()


func force_state_for_test(next_state: ZombieState) -> void:
    _change_state(next_state)


func _configure_nodes() -> void:
    if zombie_body != null:
        zombie_body.collision_layer |= ZOMBIE_COLLISION_LAYER
        zombie_body.collision_mask |= WORLD_COLLISION_LAYER | PLAYER_COLLISION_LAYER | ZOMBIE_COLLISION_LAYER

    if navigation_agent != null:
        navigation_agent.path_desired_distance = 0.18
        navigation_agent.target_desired_distance = 0.35
        navigation_agent.avoidance_enabled = false

    if crush_check_area != null:
        crush_check_area.monitoring = true
        crush_check_area.monitorable = false


func _seed_deterministic_rng() -> void:
    var seed_source := "%s:%s" % [scene_file_path, str(get_path()) if is_inside_tree() else name]
    footstep_rng.seed = hash(seed_source)


func _resolve_player() -> void:
    if is_instance_valid(player):
        return

    var tree := get_tree()
    if tree == null:
        return

    var player_nodes := tree.get_nodes_in_group(PLAYER_GROUP)
    for player_node in player_nodes:
        if player_node is Node3D:
            player = player_node as Node3D
            return

    var root := tree.current_scene
    if root == null:
        root = tree.root
    player = _find_player(root)


func _find_player(node: Node) -> Node3D:
    if node == null:
        return null

    if node is Node3D and node.has_method("die_from_flames"):
        return node as Node3D

    for child in node.get_children():
        var result := _find_player(child)
        if result != null:
            return result

    return null


func _update_state(delta: float) -> void:
    if is_dead:
        _change_state(ZombieState.DIE)
        return

    if _is_crushed(delta):
        _change_state(ZombieState.CRUSHED)
        _die_from_rolling_ball()
        return

    if _is_player_dead():
        _return_to_patrol_after_player_death()

    var visible_player := false if _is_player_dead() else _can_see_player(_should_force_vision_update())
    if visible_player:
        last_seen_position = _get_player_navigation_position()
        last_seen_timer = 0.0
        if state != ZombieState.ATTACK and _is_route_reachable(last_seen_position):
            if _can_start_attack():
                _change_state(ZombieState.ATTACK)
            else:
                _change_state(ZombieState.CHASE)
    else:
        last_seen_timer += delta

    match state:
        ZombieState.LEVEL_START:
            _stop_body()
        ZombieState.PATROL:
            _update_patrol(delta)
        ZombieState.CHASE:
            _update_chase(delta, visible_player)
        ZombieState.SEARCH_LAST_SEEN:
            _update_search_last_seen(delta, visible_player)
        ZombieState.RETURN_TO_PATROL:
            _update_return_to_patrol(delta, visible_player)
        ZombieState.ATTACK:
            _update_attack(delta, visible_player)
        ZombieState.SITDOWN:
            _update_sitdown(delta, visible_player)
        ZombieState.CRUSHED:
            _stop_body()
        ZombieState.DIE:
            _stop_body()


func _update_patrol(delta: float) -> void:
    if patrol_points.is_empty():
        _change_state(ZombieState.SITDOWN)
        return

    var body_position := _get_body_position()
    if body_position.distance_to(current_target) <= patrol_point_reached_distance:
        _advance_patrol_target()

    if not _is_route_reachable(current_target):
        _update_stuck(delta, 0.0)
        if stuck_timer >= stuck_seconds_before_sit:
            _change_state(ZombieState.SITDOWN)
        return

    var horizontal_speed := _follow_navigation_target(current_target, delta)
    _after_motion(delta, horizontal_speed)


func _update_chase(delta: float, visible_player: bool) -> void:
    if player == null or _is_player_dead():
        _change_state(ZombieState.RETURN_TO_PATROL)
        return

    if visible_player:
        last_seen_position = _get_player_navigation_position()
        last_seen_timer = 0.0

    if _can_start_attack():
        _change_state(ZombieState.ATTACK)
        return

    if last_seen_timer >= lost_sight_seconds:
        _change_state(ZombieState.SEARCH_LAST_SEEN)
        _set_navigation_target(last_seen_position)
        return

    var chase_target := _get_player_navigation_position() if visible_player else last_seen_position
    repath_timer -= delta
    if repath_timer <= 0.0:
        repath_timer = repath_interval
        if visible_player and not _is_route_reachable(chase_target):
            _change_state(ZombieState.SITDOWN)
            return
        _set_navigation_target(chase_target)

    var horizontal_speed := _follow_navigation_target(chase_target, delta, false, _get_chase_speed())
    if visible_player:
        _after_motion(delta, horizontal_speed)
    else:
        _update_animation(horizontal_speed)
        _update_footsteps(delta, horizontal_speed)


func _update_search_last_seen(delta: float, visible_player: bool) -> void:
    if visible_player:
        _change_state(ZombieState.CHASE)
        return

    search_timer += delta
    var body_position := _get_body_position()
    if body_position.distance_to(last_seen_position) > patrol_point_reached_distance:
        var horizontal_speed := _follow_navigation_target(last_seen_position, delta, false)
        _after_motion(delta, horizontal_speed)
        if search_timer < search_duration:
            return

    _stop_body()
    _scan_deterministically(delta)
    _update_animation(0.0)
    if search_timer >= search_duration:
        _change_state(ZombieState.RETURN_TO_PATROL)


func _update_return_to_patrol(delta: float, visible_player: bool) -> void:
    if visible_player:
        _change_state(ZombieState.CHASE)
        return

    if patrol_points.is_empty():
        _change_state(ZombieState.SITDOWN)
        return

    var body_position := _get_body_position()
    if body_position.distance_to(current_target) <= patrol_point_reached_distance:
        _change_state(ZombieState.PATROL)
        return

    var horizontal_speed := _follow_navigation_target(current_target, delta)
    _after_motion(delta, horizontal_speed)


func _update_attack(delta: float, visible_player: bool) -> void:
    _stop_body()

    if not _can_continue_attack():
        _set_attack_hitboxes_enabled(false)
        if player != null and _is_player_dead():
            _change_state(ZombieState.RETURN_TO_PATROL)
        elif player == null or last_seen_timer >= lost_sight_seconds:
            _change_state(ZombieState.SEARCH_LAST_SEEN)
        else:
            _change_state(ZombieState.CHASE)
        return

    _face_position(_get_player_target_position(), delta)
    attack_timer += delta

    if attack_timer >= current_attack_hit_start_seconds and attack_timer <= current_attack_hit_end_seconds:
        _set_attack_hitbox_enabled(active_attack_hitbox, true)
        if not attack_hit_applied:
            attack_hit_applied = _apply_attack_damage()

    if attack_timer >= current_attack_hit_end_seconds:
        _set_attack_hitboxes_enabled(false)

    var attack_cycle_seconds := maxf(attack_cooldown, current_attack_hit_end_seconds)
    if attack_timer < attack_cycle_seconds:
        return

    if not visible_player:
        if last_seen_timer >= lost_sight_seconds:
            _change_state(ZombieState.SEARCH_LAST_SEEN)
        else:
            _change_state(ZombieState.CHASE)
    elif _can_start_attack():
        _start_attack()
    else:
        _change_state(ZombieState.CHASE)


func _update_sitdown(delta: float, visible_player: bool) -> void:
    _stop_body()
    sit_vision_timer -= delta
    sit_repath_timer -= delta

    if _is_player_dead() and not patrol_points.is_empty():
        _change_state(ZombieState.RETURN_TO_PATROL)
        return

    if visible_player:
        if _can_start_attack():
            _change_state(ZombieState.ATTACK)
        else:
            _change_state(ZombieState.CHASE)
        return

    _scan_randomly_while_idle(delta)
    _update_animation(0.0)

    if sit_repath_timer <= 0.0:
        sit_repath_timer = sit_repath_interval
        if _select_closest_reachable_patrol_target():
            _change_state(ZombieState.RETURN_TO_PATROL)


func _change_state(next_state: ZombieState) -> void:
    if state == next_state:
        return

    state = next_state
    stuck_timer = 0.0

    match state:
        ZombieState.LEVEL_START:
            _play_animation(static_animation_name)
        ZombieState.PATROL:
            _set_next_patrol_target()
        ZombieState.CHASE:
            repath_timer = 0.0
        ZombieState.SEARCH_LAST_SEEN:
            search_timer = 0.0
            _set_navigation_target(last_seen_position)
        ZombieState.RETURN_TO_PATROL:
            _select_closest_reachable_patrol_target()
        ZombieState.ATTACK:
            _start_attack()
        ZombieState.SITDOWN:
            sit_repath_timer = 0.0
            sit_vision_timer = 0.0
            idle_scan_timer = 0.0
            _set_attack_hitboxes_enabled(false)
            _play_animation(idle_animation_name)
        ZombieState.CRUSHED:
            _set_attack_hitboxes_enabled(false)
        ZombieState.DIE:
            _set_attack_hitboxes_enabled(false)


func _return_to_patrol_after_player_death() -> void:
    cached_player_visible = false
    last_seen_timer = lost_sight_seconds
    _set_attack_hitboxes_enabled(false)

    if patrol_points.is_empty():
        if state != ZombieState.SITDOWN:
            _change_state(ZombieState.SITDOWN)
        return

    if state != ZombieState.PATROL and state != ZombieState.RETURN_TO_PATROL:
        _change_state(ZombieState.RETURN_TO_PATROL)


func _start_attack() -> void:
    attack_timer = 0.0
    attack_hit_applied = false
    var animation_name := attack_animation_names[attack_index % attack_animation_names.size()]
    active_attack_hitbox = attack_hitbox_right if attack_index % 2 == 0 else attack_hitbox_left
    attack_index += 1
    if animation_player != null:
        animation_player.speed_scale = 1.0
    _configure_attack_hit_window(animation_name)
    _set_attack_hitboxes_enabled(false)
    _play_animation(animation_name)


func _configure_attack_hit_window(animation_name: String) -> void:
    var animation_duration := _get_animation_duration_seconds(animation_name)
    if animation_duration <= 0.0:
        current_attack_hit_start_seconds = maxf(attack_hit_start_seconds, 0.0)
        current_attack_hit_end_seconds = maxf(attack_hit_end_seconds, current_attack_hit_start_seconds + 0.01)
        return

    var start_ratio := clampf(attack_hit_start_ratio, 0.0, 1.0)
    var end_ratio := clampf(attack_hit_end_ratio, start_ratio, 1.0)
    current_attack_hit_start_seconds = animation_duration * start_ratio
    current_attack_hit_end_seconds = maxf(animation_duration * end_ratio, current_attack_hit_start_seconds + 0.01)


func _get_animation_duration_seconds(animation_name: String) -> float:
    if animation_player == null:
        return 0.0

    var resolved_animation_name := _resolve_animation_name(animation_name)
    if resolved_animation_name.is_empty() or not animation_player.has_animation(resolved_animation_name):
        return 0.0

    var animation := animation_player.get_animation(resolved_animation_name)
    if animation == null:
        return 0.0

    return animation.length


func _apply_attack_damage() -> bool:
    var targets := _get_attack_damage_targets()
    var hit_landed := false

    for target in targets:
        if not _is_live_player_body(target):
            continue

        if target.has_method("apply_flame_damage"):
            target.apply_flame_damage(attack_damage)
            hit_landed = true
        elif target.has_method("die_from_flames"):
            target.die_from_flames()
            hit_landed = true

    if hit_landed:
        _play_punch_hit_sound()

    return hit_landed


func _get_attack_damage_targets() -> Array[Node]:
    var targets := _get_attack_hitbox_targets(active_attack_hitbox)
    if _is_player_within_attack_range(attack_range):
        _append_unique_node_target(targets, player)
    return targets


func _get_attack_hitbox_targets(hitbox: Area3D) -> Array[Node]:
    var targets: Array[Node] = []
    if hitbox == null:
        return targets

    for body in hitbox.get_overlapping_bodies():
        _append_unique_node_target(targets, body)

    var world := get_world_3d()
    if world == null:
        return targets

    for child in hitbox.get_children():
        var collision_shape := child as CollisionShape3D
        if collision_shape == null or collision_shape.disabled or collision_shape.shape == null:
            continue

        var query := PhysicsShapeQueryParameters3D.new()
        query.shape = collision_shape.shape
        query.transform = collision_shape.global_transform
        query.collision_mask = hitbox.collision_mask
        query.collide_with_areas = false
        query.collide_with_bodies = true
        query.exclude = _get_vision_excludes()

        for hit: Dictionary in world.direct_space_state.intersect_shape(query, 16):
            _append_unique_node_target(targets, hit.get("collider") as Object)

    return targets


func _append_unique_node_target(targets: Array[Node], candidate: Object) -> void:
    if candidate == null or not candidate is Node:
        return

    var node := candidate as Node
    if not targets.has(node):
        targets.append(node)


func _should_force_vision_update() -> bool:
    return state == ZombieState.CHASE or state == ZombieState.SEARCH_LAST_SEEN or state == ZombieState.RETURN_TO_PATROL


func _can_see_player(force_update := false) -> bool:
    vision_timer -= get_physics_process_delta_time()
    if vision_timer > 0.0 and not force_update:
        return cached_player_visible

    vision_timer = vision_interval
    if player == null or _is_player_dead():
        cached_player_visible = false
        return false

    var origin := _get_vision_origin()
    var target := _get_player_target_position()
    var to_player := target - origin
    if to_player.length() > vision_range:
        cached_player_visible = false
        return false

    var horizontal_to_player := Vector3(to_player.x, 0.0, to_player.z)
    if horizontal_to_player.length_squared() <= 0.0001:
        cached_player_visible = _has_line_of_sight_to_player()
        return cached_player_visible

    var angle_cos := cos(deg_to_rad(fov_degrees * 0.5))
    if absf(facing_direction.normalized().dot(horizontal_to_player.normalized())) < angle_cos:
        cached_player_visible = false
        return false

    cached_player_visible = _has_line_of_sight_to_player()
    return cached_player_visible


func _has_line_of_sight_to_player() -> bool:
    if player == null:
        return false

    var world := get_world_3d()
    if world == null:
        return false

    var excludes := _get_vision_excludes()
    var query := PhysicsRayQueryParameters3D.create(
        _get_vision_origin(),
        _get_player_target_position(),
        vision_collision_mask
    )
    query.collide_with_areas = false
    query.collide_with_bodies = true

    while true:
        query.exclude = excludes
        var hit := world.direct_space_state.intersect_ray(query)
        if hit.is_empty():
            return true

        var collider := hit.get("collider") as Object
        if collider == player or _is_descendant_of(collider, player):
            return true

        if collider == zombie_body or _is_descendant_of(collider, zombie_body):
            var rid := hit.get("rid", RID()) as RID
            if rid.is_valid():
                excludes.append(rid)
                continue

        return false

    return false


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


func _is_player_dead() -> bool:
    return player != null and player.has_method("is_dead") and player.is_dead()


func _get_chase_speed() -> float:
    return shuffle_speed * maxf(chase_speed_multiplier, 0.0)


func _can_start_attack() -> bool:
    return _is_player_within_attack_range(attack_range) or _is_touching_player_collision(false)


func _can_continue_attack() -> bool:
    return _is_player_within_attack_range(maxf(attack_continue_range, attack_range))


func _is_player_within_attack_range(range: float) -> bool:
    if player == null or not _is_live_player_body(player):
        return false

    var to_player := player.global_position - _get_body_position()
    to_player.y = 0.0
    return to_player.length() <= maxf(range, 0.0)


func _is_touching_player_collision(include_slide_collisions := true) -> bool:
    if player == null or zombie_body == null:
        return false

    if include_slide_collisions:
        for collision_index in zombie_body.get_slide_collision_count():
            var collision := zombie_body.get_slide_collision(collision_index)
            if collision != null and _is_live_player_body(collision.get_collider() as Node):
                return true

    var body_shape := _find_collision_shape(zombie_body)
    if body_shape == null or body_shape.shape == null:
        return false

    var world := get_world_3d()
    if world == null:
        return false

    var query := PhysicsShapeQueryParameters3D.new()
    query.shape = _get_touch_attack_query_shape(body_shape.shape)
    query.transform = body_shape.global_transform
    query.collision_mask = PLAYER_COLLISION_LAYER
    query.collide_with_areas = false
    query.collide_with_bodies = true
    query.exclude = _get_vision_excludes()

    for hit: Dictionary in world.direct_space_state.intersect_shape(query, 8):
        var collider := hit.get("collider") as Node
        if _is_live_player_body(collider):
            return true

    return false


func _get_touch_attack_query_shape(source_shape: Shape3D) -> Shape3D:
    var margin := maxf(player_touch_attack_probe_margin, 0.0)
    if source_shape is CapsuleShape3D:
        var source_capsule := source_shape as CapsuleShape3D
        var capsule := CapsuleShape3D.new()
        capsule.radius = source_capsule.radius + margin
        capsule.height = source_capsule.height + margin * 2.0
        return capsule

    if source_shape is SphereShape3D:
        var source_sphere := source_shape as SphereShape3D
        var sphere := SphereShape3D.new()
        sphere.radius = source_sphere.radius + margin
        return sphere

    if source_shape is BoxShape3D:
        var source_box := source_shape as BoxShape3D
        var box := BoxShape3D.new()
        box.size = source_box.size + Vector3.ONE * margin * 2.0
        return box

    return source_shape


func _is_route_reachable(target_position: Vector3) -> bool:
    if target_position == Vector3.ZERO and patrol_points.is_empty():
        return false

    if _has_grid_navigation_path(target_position):
        return true

    if _has_navigation_path(target_position):
        return true

    return direct_navigation_fallback_enabled and not _has_static_blocker_between(_get_body_position(), target_position)


func _has_navigation_path(target_position: Vector3) -> bool:
    if navigation_agent == null:
        return false

    navigation_agent.target_position = target_position
    if navigation_agent.is_target_reachable():
        return true

    var next_position := navigation_agent.get_next_path_position()
    return next_position.distance_squared_to(_get_body_position()) > 0.0001


func _has_static_blocker_between(from_position: Vector3, to_position: Vector3) -> bool:
    var world := get_world_3d()
    if world == null:
        return false

    var from := from_position + Vector3.UP * 0.5
    var to := to_position + Vector3.UP * 0.5
    var query := PhysicsRayQueryParameters3D.create(from, to, map_collision_mask)
    query.collide_with_areas = false
    query.collide_with_bodies = true
    query.exclude = _get_vision_excludes()
    return not world.direct_space_state.intersect_ray(query).is_empty()


func _follow_navigation_target(target_position: Vector3, delta: float, stop_on_static_blocker := true, movement_speed := -1.0) -> float:
    _set_navigation_target(target_position)
    var has_static_blocker := _has_static_blocker_between(_get_body_position(), target_position)
    var has_grid_blocker := _has_grid_blocker_between(_get_body_position(), target_position)
    var routed_with_grid := has_static_blocker or has_grid_blocker
    var speed := movement_speed if movement_speed > 0.0 else shuffle_speed

    var next_position := target_position
    if routed_with_grid:
        next_position = _get_grid_navigation_next_position(target_position)

    if next_position == Vector3.INF:
        if stop_on_static_blocker:
            _stop_body()
            _update_stuck(delta, 0.0)
            return 0.0
        next_position = target_position
    elif not has_static_blocker and navigation_agent != null and not navigation_agent.is_navigation_finished():
        next_position = navigation_agent.get_next_path_position()

    var direction := next_position - _get_body_position()
    direction.y = 0.0
    if direction.length_squared() <= 0.0001:
        direction = target_position - _get_body_position()
        direction.y = 0.0

    if direction.length_squared() <= 0.0001:
        _stop_body()
        return 0.0

    direction = direction.normalized()
    var previous_position := _get_body_position()
    zombie_body.velocity.x = direction.x * speed
    zombie_body.velocity.z = direction.z * speed
    zombie_body.move_and_slide()

    if _has_blocking_slide_collision() and not routed_with_grid:
        var slide_direction := _get_wall_slide_direction(direction)
        if slide_direction.length_squared() > 0.0001:
            zombie_body.velocity.x = slide_direction.x * speed
            zombie_body.velocity.z = slide_direction.z * speed
            zombie_body.move_and_slide()
            repath_timer = 0.0
            direction = slide_direction

        var reroute_position := _get_grid_navigation_next_position(target_position)
        if reroute_position != Vector3.INF:
            next_position = reroute_position
            direction = next_position - _get_body_position()
            direction.y = 0.0
            if direction.length_squared() > 0.0001:
                direction = direction.normalized()
                zombie_body.velocity.x = direction.x * speed
                zombie_body.velocity.z = direction.z * speed
                zombie_body.move_and_slide()
                repath_timer = 0.0
                routed_with_grid = true

    if _would_hit_navigation_blocker(direction) or (_has_blocking_slide_collision() and not routed_with_grid):
        _stop_body()
        _update_stuck(delta, 0.0)
        repath_timer = 0.0
        return 0.0

    var horizontal_displacement := _get_body_position() - previous_position
    horizontal_displacement.y = 0.0
    var horizontal_speed := horizontal_displacement.length() / maxf(delta, 0.001)
    _face_direction(direction, delta)
    _update_stuck(delta, horizontal_displacement.length())
    return horizontal_speed


func _has_blocking_slide_collision() -> bool:
    if zombie_body == null:
        return false

    for collision_index in zombie_body.get_slide_collision_count():
        var collision := zombie_body.get_slide_collision(collision_index)
        if collision == null:
            continue

        if collision.get_normal().y < navigation_collision_floor_normal_y:
            return true

    return false


func _get_blocking_slide_normal() -> Vector3:
    if zombie_body == null:
        return Vector3.ZERO

    for collision_index in zombie_body.get_slide_collision_count():
        var collision := zombie_body.get_slide_collision(collision_index)
        if collision == null:
            continue

        if collision.get_normal().y < navigation_collision_floor_normal_y:
            return collision.get_normal()

    return Vector3.ZERO


func _get_wall_slide_direction(direction: Vector3) -> Vector3:
    var normal := _get_blocking_slide_normal()
    if normal.length_squared() <= 0.0001:
        return Vector3.ZERO

    var slide_direction := direction.slide(normal)
    slide_direction.y = 0.0
    if slide_direction.length_squared() <= 0.0001:
        return Vector3.ZERO

    return slide_direction.normalized()


func _get_grid_navigation_next_position(target_position: Vector3) -> Vector3:
    var grid_map := _select_navigation_grid_map(_get_body_position(), target_position)
    if grid_map == null:
        return Vector3.INF

    var start_cell := grid_map.local_to_map(grid_map.to_local(_get_body_position()))
    var target_cell := grid_map.local_to_map(grid_map.to_local(target_position))
    if _is_grid_cell_blocked(grid_map, target_cell):
        var nearest_cell := _find_nearest_unblocked_grid_cell(grid_map, target_cell)
        if nearest_cell == INVALID_GRID_CELL:
            return Vector3.INF
        target_cell = nearest_cell

    if start_cell == target_cell:
        return target_position

    var path := _find_grid_path(grid_map, start_cell, target_cell)
    if path.size() < 2:
        return Vector3.INF

    var next_position := grid_map.to_global(grid_map.map_to_local(path[1]))
    next_position.y = _get_body_position().y
    return next_position


func _has_grid_navigation_path(target_position: Vector3) -> bool:
    var grid_map := _select_navigation_grid_map(_get_body_position(), target_position)
    if grid_map == null:
        return false

    var start_cell := grid_map.local_to_map(grid_map.to_local(_get_body_position()))
    var target_cell := grid_map.local_to_map(grid_map.to_local(target_position))
    if _is_grid_cell_blocked(grid_map, target_cell):
        target_cell = _find_nearest_unblocked_grid_cell(grid_map, target_cell)
        if target_cell == INVALID_GRID_CELL:
            return false

    if start_cell == target_cell:
        return true

    return not _find_grid_path(grid_map, start_cell, target_cell).is_empty()


func _select_navigation_grid_map(from_position: Vector3, to_position: Vector3) -> GridMap:
    for grid_map in navigation_grid_maps:
        if grid_map == null:
            continue

        var bounds := navigation_grid_bounds_by_id.get(grid_map.get_instance_id(), Rect2i()) as Rect2i
        var from_cell := grid_map.local_to_map(grid_map.to_local(from_position))
        var to_cell := grid_map.local_to_map(grid_map.to_local(to_position))
        if bounds.has_point(Vector2i(from_cell.x, from_cell.z)) and bounds.has_point(Vector2i(to_cell.x, to_cell.z)):
            return grid_map

    return null


func _has_grid_blocker_between(from_position: Vector3, to_position: Vector3) -> bool:
    var grid_map := _select_navigation_grid_map(from_position, to_position)
    if grid_map == null:
        return false

    var from_cell := grid_map.local_to_map(grid_map.to_local(from_position))
    var to_cell := grid_map.local_to_map(grid_map.to_local(to_position))
    var step_count := maxi(absi(to_cell.x - from_cell.x), absi(to_cell.z - from_cell.z))
    if step_count <= 1:
        return false

    for step in range(1, step_count):
        var ratio := float(step) / float(step_count)
        var sample_cell := Vector3i(
            roundi(lerpf(float(from_cell.x), float(to_cell.x), ratio)),
            from_cell.y,
            roundi(lerpf(float(from_cell.z), float(to_cell.z), ratio))
        )
        if _is_grid_cell_blocked(grid_map, sample_cell):
            return true

    return false


func _find_grid_path(grid_map: GridMap, start_cell: Vector3i, target_cell: Vector3i) -> Array[Vector3i]:
    var bounds := navigation_grid_bounds_by_id.get(grid_map.get_instance_id(), Rect2i()) as Rect2i
    if not bounds.has_point(Vector2i(start_cell.x, start_cell.z)) or not bounds.has_point(Vector2i(target_cell.x, target_cell.z)):
        return []

    var open_cells: Array[Vector3i] = [start_cell]
    var came_from := {start_cell: start_cell}
    var search_count := 0

    while not open_cells.is_empty() and search_count < grid_navigation_max_search_cells:
        search_count += 1
        var current := open_cells.pop_front() as Vector3i
        if current == target_cell:
            return _reconstruct_grid_path(came_from, current)

        for neighbor in _get_grid_neighbors(current):
            if came_from.has(neighbor):
                continue

            var neighbor_point := Vector2i(neighbor.x, neighbor.z)
            if not bounds.has_point(neighbor_point):
                continue

            if _is_grid_cell_blocked(grid_map, neighbor):
                continue

            came_from[neighbor] = current
            open_cells.append(neighbor)

    return []


func _reconstruct_grid_path(came_from: Dictionary, end_cell: Vector3i) -> Array[Vector3i]:
    var path: Array[Vector3i] = [end_cell]
    var current := end_cell
    while came_from.has(current) and came_from[current] != current:
        current = came_from[current] as Vector3i
        path.push_front(current)
    return path


func _get_grid_neighbors(cell: Vector3i) -> Array[Vector3i]:
    return [
        cell + Vector3i(1, 0, 0),
        cell + Vector3i(-1, 0, 0),
        cell + Vector3i(0, 0, 1),
        cell + Vector3i(0, 0, -1),
    ]


func _find_nearest_unblocked_grid_cell(grid_map: GridMap, blocked_cell: Vector3i) -> Vector3i:
    var bounds := navigation_grid_bounds_by_id.get(grid_map.get_instance_id(), Rect2i()) as Rect2i
    var open_cells: Array[Vector3i] = [blocked_cell]
    var visited := {blocked_cell: true}

    while not open_cells.is_empty() and visited.size() < grid_navigation_max_search_cells:
        var current := open_cells.pop_front() as Vector3i
        if bounds.has_point(Vector2i(current.x, current.z)) and not _is_grid_cell_blocked(grid_map, current):
            return current

        for neighbor in _get_grid_neighbors(current):
            if visited.has(neighbor):
                continue

            visited[neighbor] = true
            if bounds.has_point(Vector2i(neighbor.x, neighbor.z)):
                open_cells.append(neighbor)

    return INVALID_GRID_CELL


func _is_grid_cell_blocked(grid_map: GridMap, cell: Vector3i) -> bool:
    var item_id := grid_map.get_cell_item(cell)
    if item_id == GridMap.INVALID_CELL_ITEM:
        return false

    var library := grid_map.mesh_library
    if library == null:
        return false

    var item_name := library.get_item_name(item_id).to_lower()
    return item_name.contains("wall")


func _get_grid_navigation_bounds(grid_map: GridMap) -> Rect2i:
    var used_cells := grid_map.get_used_cells()
    if used_cells.is_empty():
        return Rect2i(Vector2i.ZERO, Vector2i.ZERO)

    var min_x := 2147483647
    var min_z := 2147483647
    var max_x := -2147483648
    var max_z := -2147483648
    for cell in used_cells:
        min_x = mini(min_x, cell.x)
        min_z = mini(min_z, cell.z)
        max_x = maxi(max_x, cell.x)
        max_z = maxi(max_z, cell.z)

    var padding := maxi(grid_navigation_padding_cells, 0)
    var position := Vector2i(min_x - padding, min_z - padding)
    var end := Vector2i(max_x + padding + 1, max_z + padding + 1)
    return Rect2i(position, end - position)


func _set_navigation_target(target_position: Vector3) -> void:
    current_target = target_position
    if navigation_agent != null:
        navigation_agent.target_position = target_position


func _after_motion(delta: float, horizontal_speed: float) -> void:
    _update_animation(horizontal_speed)
    _update_footsteps(delta, horizontal_speed)
    if stuck_timer >= stuck_seconds_before_sit:
        _change_state(ZombieState.SITDOWN)


func _stop_body() -> void:
    if zombie_body == null:
        return
    zombie_body.velocity = Vector3.ZERO


func _update_stuck(delta: float, moved_distance: float) -> void:
    if moved_distance < stuck_min_move_distance:
        stuck_timer += delta
    else:
        stuck_timer = 0.0


func _would_hit_navigation_blocker(direction: Vector3) -> bool:
    var world := get_world_3d()
    if world == null:
        return false

    var probe_shape := SphereShape3D.new()
    probe_shape.radius = 0.42
    var query := PhysicsShapeQueryParameters3D.new()
    query.shape = probe_shape
    query.transform = Transform3D(Basis.IDENTITY, _get_body_position() + Vector3.UP * 0.5 + direction * 0.35)
    query.collision_mask = map_collision_mask
    query.collide_with_areas = false
    query.collide_with_bodies = true

    for hit in world.direct_space_state.intersect_shape(query, 8):
        var collider := hit.get("collider") as Object
        if _is_navigation_blocker(collider):
            return true

    return false


func _is_navigation_blocker(collider: Object) -> bool:
    if collider == null or not collider is Node:
        return false

    var node := collider as Node
    return node.is_in_group(NAVIGATION_BLOCKER_GROUP)


func _build_patrol_points() -> void:
    patrol_points.clear()
    if curve == null:
        return

    for point_index in range(curve.point_count):
        patrol_points.append(to_global(curve.get_point_position(point_index)))

    if patrol_points.is_empty() and curve.get_baked_length() > 0.001:
        patrol_points.append(to_global(curve.sample_baked(0.0, true)))
        patrol_points.append(to_global(curve.sample_baked(curve.get_baked_length(), true)))

    patrol_index = _get_closest_patrol_index(_get_body_position())
    _initialize_patrol_facing()
    _set_next_patrol_target()


func _initialize_patrol_facing() -> void:
    if patrol_points.size() < 2:
        return

    var current_index := clampi(patrol_index, 0, patrol_points.size() - 1)
    var next_index := current_index
    if loop_patrol or curve.closed:
        next_index = wrapi(current_index + 1, 0, patrol_points.size())
    else:
        next_index = mini(current_index + 1, patrol_points.size() - 1)

    var direction := patrol_points[next_index] - patrol_points[current_index]
    direction.y = 0.0
    if direction.length_squared() > 0.0001:
        facing_direction = direction.normalized()


func _set_next_patrol_target() -> void:
    if patrol_points.is_empty():
        return
    patrol_index = clampi(patrol_index, 0, patrol_points.size() - 1)
    _set_navigation_target(patrol_points[patrol_index])


func _advance_patrol_target() -> void:
    if patrol_points.size() <= 1:
        return

    if loop_patrol or curve.closed:
        patrol_index = wrapi(patrol_index + 1, 0, patrol_points.size())
    elif reverse_at_path_ends:
        var next_index := patrol_index + patrol_direction
        if next_index >= patrol_points.size():
            patrol_direction = -1
            next_index = max(patrol_points.size() - 2, 0)
        elif next_index < 0:
            patrol_direction = 1
            next_index = min(1, patrol_points.size() - 1)
        patrol_index = next_index
    else:
        patrol_index = mini(patrol_index + 1, patrol_points.size() - 1)

    _set_next_patrol_target()


func _select_closest_reachable_patrol_target() -> bool:
    if patrol_points.is_empty():
        return false

    var candidates: Array[Dictionary] = []
    var body_position := _get_body_position()
    for index in range(patrol_points.size()):
        candidates.append({
            "index": index,
            "distance": body_position.distance_squared_to(patrol_points[index]),
        })

    candidates.sort_custom(_sort_patrol_candidates)
    for candidate in candidates:
        var index := int(candidate["index"])
        if _is_route_reachable(patrol_points[index]):
            patrol_index = index
            _set_next_patrol_target()
            return true

    return false


func _sort_patrol_candidates(a: Dictionary, b: Dictionary) -> bool:
    var distance_a := float(a["distance"])
    var distance_b := float(b["distance"])
    if is_equal_approx(distance_a, distance_b):
        return int(a["index"]) < int(b["index"])
    return distance_a < distance_b


func _get_closest_patrol_index(world_position: Vector3) -> int:
    var closest_index := 0
    var closest_distance := INF
    for index in range(patrol_points.size()):
        var distance := world_position.distance_squared_to(patrol_points[index])
        if distance < closest_distance:
            closest_distance = distance
            closest_index = index
    return closest_index


func _scan_deterministically(delta: float) -> void:
    if pivot == null:
        return
    var scan_phase := fmod(search_timer, 1.0)
    var scan_direction := -1.0 if scan_phase < 0.5 else 1.0
    pivot.rotation.y = lerp_angle(pivot.rotation.y, scan_direction * 0.65, turn_speed * delta)


func _scan_randomly_while_idle(delta: float) -> void:
    if pivot == null:
        return

    idle_scan_timer -= delta
    if idle_scan_timer <= 0.0:
        var min_seconds := maxf(idle_scan_min_seconds, 0.1)
        var max_seconds := maxf(idle_scan_max_seconds, min_seconds)
        idle_scan_timer = footstep_rng.randf_range(min_seconds, max_seconds)
        var max_turn := deg_to_rad(maxf(idle_scan_max_turn_degrees, 0.0))
        idle_scan_target_yaw = pivot.rotation.y + footstep_rng.randf_range(-max_turn, max_turn)

    pivot.rotation.y = lerp_angle(pivot.rotation.y, idle_scan_target_yaw, turn_speed * delta)


func _apply_start_progress() -> void:
    if path_follow == null or curve == null:
        return

    var path_length := curve.get_baked_length()
    if path_length <= 0.001:
        return

    path_follow.progress = clampf(start_progress_ratio, 0.0, 1.0) * path_length


func _sync_body_to_path_start() -> void:
    if zombie_body == null:
        return

    if path_follow != null:
        zombie_body.global_position = path_follow.global_position
    elif not patrol_points.is_empty():
        zombie_body.global_position = patrol_points[0]


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
    _set_zombie_transparency(0.0)
    _set_active_visible(true)
    _set_kill_area_enabled(false)
    _update_animation(0.0)


func _set_active_visible(active: bool) -> void:
    if drop_pivot != null:
        drop_pivot.visible = active
    if shadow != null:
        shadow.visible = active
    if zombie_light != null:
        zombie_light.visible = active and zombie_light_enabled
    _set_kill_area_enabled(false)


func _set_kill_area_enabled(_enabled: bool) -> void:
    kill_overlap_times.clear()
    if kill_area != null:
        kill_area.monitoring = false


func _set_attack_hitboxes_enabled(enabled: bool) -> void:
    _set_attack_hitbox_enabled(attack_hitbox_right, enabled)
    _set_attack_hitbox_enabled(attack_hitbox_left, enabled)


func _set_attack_hitbox_enabled(hitbox: Area3D, enabled: bool) -> void:
    if hitbox == null:
        return
    hitbox.monitoring = enabled


func _set_zombie_transparency(transparency: float) -> void:
    if drop_pivot != null:
        _set_geometry_transparency(drop_pivot, transparency)
    if shadow != null:
        _set_geometry_transparency(shadow, transparency)


func _set_geometry_transparency(node: Node, transparency: float) -> void:
    if node is GeometryInstance3D:
        (node as GeometryInstance3D).transparency = transparency

    for child in node.get_children():
        _set_geometry_transparency(child, transparency)


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


func _face_direction(direction: Vector3, delta: float) -> void:
    if direction.length_squared() <= 0.0001:
        return

    facing_direction = Vector3(direction.x, 0.0, direction.z).normalized()
    if pivot != null:
        pivot.rotation.y = lerp_angle(pivot.rotation.y, atan2(facing_direction.x, facing_direction.z), turn_speed * delta)


func _face_position(world_position: Vector3, delta: float) -> void:
    var direction := world_position - _get_body_position()
    direction.y = 0.0
    _face_direction(direction, delta)


func _update_animation(horizontal_speed: float) -> void:
    if animation_player == null or is_dead:
        return

    if state == ZombieState.SITDOWN:
        animation_player.speed_scale = 1.0
        _play_animation(idle_animation_name)
    elif state == ZombieState.CHASE and horizontal_speed >= footstep_speed_threshold and not resolved_run_animation.is_empty():
        animation_player.speed_scale = run_animation_speed_scale
        _play_animation(run_animation_name)
    elif horizontal_speed >= footstep_speed_threshold:
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
    resolved_run_animation = _resolve_animation_name(run_animation_name)
    resolved_death_animation = _resolve_animation_name(death_animation_name)
    if _resolve_animation_name(walk_animation_name).is_empty():
        push_warning("Zombie character has no walk animation.")
    if resolved_death_animation.is_empty():
        push_warning("Zombie character has no death animation.")


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
    footstep_sounds = GDAudio.load_streams(FOOTSTEP_SOUND_PATHS)


func _load_punch_hit_sound() -> void:
    punch_hit_sound = GDAudio.load_stream(punch_hit_sound_path)


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
    next_footstep_distance = maxf(0.1, footstep_distance + footstep_rng.randf_range(-variance, variance))


func _play_footstep(horizontal_speed: float) -> void:
    if is_dead:
        return

    var max_movement_speed := maxf(_get_chase_speed(), shuffle_speed)
    var audio_parent: Node = zombie_body if zombie_body != null else self
    GDAudio.play_random_footstep_3d(
        audio_parent,
        footstep_sounds,
        "FootstepAudio",
        horizontal_speed,
        footstep_speed_threshold,
        max_movement_speed,
        footstep_volume_min_db,
        footstep_volume_max_db,
        footstep_pitch_min,
        footstep_pitch_max,
        footstep_rng
    )


func _play_punch_hit_sound() -> void:
    var audio_parent: Node = zombie_body if zombie_body != null else self
    GDAudio.play_one_shot_3d(audio_parent, punch_hit_sound, "ZombiePunchHitAudio", punch_hit_volume_db)


func _is_crushed(delta: float) -> bool:
    if crush_check_area == null:
        return false

    var crushed := false
    for body in crush_check_area.get_overlapping_bodies():
        if _is_rolling_ball_body(body):
            crushed = true
            break

    crush_timer = crush_timer + delta if crushed else 0.0
    return crush_timer >= crush_confirm_seconds


func _update_rolling_ball_death(_delta: float) -> void:
    if not rolling_ball_death_enabled or is_dead:
        return

    var world := get_world_3d()
    if world == null:
        return

    var detection_center := _get_detection_center()
    var query_shape := SphereShape3D.new()
    query_shape.radius = rolling_ball_death_detection_radius

    var query := PhysicsShapeQueryParameters3D.new()
    query.shape = query_shape
    query.transform = Transform3D(Basis.IDENTITY, detection_center)
    query.collision_mask = map_collision_mask
    query.collide_with_areas = false
    query.collide_with_bodies = true

    var hits := world.direct_space_state.intersect_shape(query, 8)
    for hit: Dictionary in hits:
        var collider := hit.get("collider") as Object
        if not _is_rolling_ball_body(collider):
            continue

        var collider_3d := collider as Node3D
        if collider_3d == null:
            continue

        var encroachment_percent := _get_rolling_ball_encroachment_percent(detection_center, collider_3d.global_position)
        if encroachment_percent >= rolling_ball_death_encroachment_percent:
            _die_from_rolling_ball()
            return


func _get_detection_center() -> Vector3:
    var collision_shape := _find_collision_shape(kill_area)
    if collision_shape != null:
        return collision_shape.global_position

    return _get_body_position()


func _get_rolling_ball_encroachment_percent(detection_center: Vector3, ball_position: Vector3) -> float:
    var horizontal_delta := ball_position - detection_center
    horizontal_delta.y = 0.0

    var overlap_depth := rolling_ball_death_detection_radius + rolling_ball_death_radius - horizontal_delta.length()
    if overlap_depth <= 0.0:
        return 0.0

    var detection_radius := maxf(rolling_ball_death_detection_radius, 0.001)
    return clampf(overlap_depth / detection_radius * 100.0, 0.0, 100.0)


func _die_from_rolling_ball() -> void:
    if is_dead:
        return

    is_dead = true
    _change_state(ZombieState.DIE)
    footstep_distance_accumulator = 0.0
    _stop_body()
    _set_kill_area_enabled(false)
    _set_attack_hitboxes_enabled(false)
    _play_death_scream()
    _play_death_animation()

    if zombie_light != null:
        zombie_light.visible = false

    _disappear_after_death()


func _play_death_scream() -> void:
    var audio_parent: Node = zombie_body if zombie_body != null else self
    GDAudio.play_one_shot_3d(audio_parent, WILHELM_SCREAM, "ZombieDeathScreamAudio", death_scream_volume_db)


func _play_death_animation() -> void:
    if animation_player == null or resolved_death_animation.is_empty():
        return

    animation_player.speed_scale = death_animation_speed_scale
    current_animation = resolved_death_animation
    animation_player.play(resolved_death_animation, 0.1)


func _disappear_after_death() -> void:
    await get_tree().create_timer(maxf(death_disappear_delay, 0.0)).timeout

    if not is_inside_tree() or is_disappearing:
        return

    is_disappearing = true
    var disappear_duration := maxf(death_disappear_duration, 0.0)
    var fade_delay := disappear_duration * clampf(death_fade_start_ratio, 0.0, 1.0)
    var fade_duration := maxf(disappear_duration - fade_delay, 0.0)
    var tween := create_tween()
    tween.set_parallel(true)
    tween.set_trans(Tween.TRANS_SINE)
    tween.set_ease(Tween.EASE_IN)

    if drop_pivot != null:
        tween.tween_property(
            drop_pivot,
            "position:y",
            drop_pivot.position.y - death_sink_depth,
            disappear_duration
        )

    for geometry in _get_fade_geometry():
        tween.tween_property(
            geometry,
            "transparency",
            1.0,
            fade_duration
        ).set_delay(fade_delay)

    await tween.finished
    _set_active_visible(false)


func _get_fade_geometry() -> Array[GeometryInstance3D]:
    var geometry_instances: Array[GeometryInstance3D] = []
    if drop_pivot != null:
        _collect_geometry(drop_pivot, geometry_instances)
    if shadow != null:
        _collect_geometry(shadow, geometry_instances)

    return geometry_instances


func _collect_geometry(node: Node, geometry_instances: Array[GeometryInstance3D]) -> void:
    if node is GeometryInstance3D:
        geometry_instances.append(node as GeometryInstance3D)

    for child in node.get_children():
        _collect_geometry(child, geometry_instances)


func _is_rolling_ball_body(collider: Object) -> bool:
    if collider == null or not collider is Node:
        return false

    var node := collider as Node
    return node is RollingRock or String(node.name).contains("RollingRock")


func _is_live_player_body(body: Node) -> bool:
    if body == null:
        return false

    if body.has_method("is_dead") and body.is_dead():
        return false

    return body.has_method("die_from_flames")


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

    if node is CollisionShape3D:
        return node

    for child in node.get_children():
        var result := _find_collision_shape(child)
        if result != null:
            return result

    return null


func _find_animation_player(node: Node) -> AnimationPlayer:
    if node is AnimationPlayer:
        return node

    for child in node.get_children():
        var result := _find_animation_player(child)
        if result != null:
            return result

    return null
