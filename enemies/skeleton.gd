extends Path3D
class_name GDSkeletonPath


const FOOTSTEP_SOUND_PATHS: Array[String] = [
    "res://Assets/audio/footstep1.wav",
    "res://Assets/audio/footstep2.wav",
    "res://Assets/audio/footstep3.wav",
    "res://Assets/audio/footstep4.wav",
]
const CHARACTER_GROUP: StringName = &"character"
const SKELETON_GROUP: StringName = &"skeleton"
const WILHELM_SCREAM := preload("res://Assets/audio/wilhelm-scream.mp3")
const DETERMINISTIC_SEED := preload("res://game/deterministic_seed.gd")
const WORLD_COLLISION_LAYER := 1

## PathFollow3D that carries the skeleton visual and contact area.
@export var path_follow_path: NodePath = ^"PathFollow3D"
## Node moved vertically while the skeleton drops in.
@export var drop_pivot_path: NodePath = ^"PathFollow3D/DropPivot"
## Visual pivot rotated toward the skeleton's current shuffle direction.
@export var pivot_path: NodePath = ^"PathFollow3D/DropPivot/Pivot"
## Imported skeleton character subtree containing the AnimationPlayer.
@export var character_path: NodePath = ^"PathFollow3D/DropPivot/Pivot/Character"
## Area that kills the player on contact.
@export var kill_area_path: NodePath = ^"PathFollow3D/DropPivot/KillArea"
## Ground shadow shown while the skeleton is active.
@export var shadow_path: NodePath = ^"PathFollow3D/SkeletonShadow"
## Light used to make the skeleton readable before the player gets close.
@export var skeleton_light_path: NodePath = ^"PathFollow3D/DropPivot/Pivot/SkeletonLight"
## Seconds a player must remain inside the contact area before death triggers.
@export var kill_confirmation_time := 0.08
## Seconds after scene start before this skeleton drops in.
@export var drop_in_time := 0.0
## Height above the patrol path used at the start of the drop-in.
@export var drop_height := 3.2
## Seconds taken to fall from drop_height to the path.
@export var drop_duration := 0.55
## Starting position along the patrol path, where 0 is the path start and 1 is the path end.
@export_range(0.0, 1.0, 0.001) var start_progress_ratio := 0.0
## World units per second along the patrol path.
@export var shuffle_speed := 0.75
## If true, the skeleton wraps from the end of an open path back to the start.
@export var loop_patrol := true
## If true, the skeleton turns around at the ends of an open path.
@export var reverse_at_path_ends := true
## How quickly the visual turns toward the current movement direction.
@export var turn_speed := 1.5
## Yaw correction for the imported skeleton model's local forward direction.
@export_range(-180.0, 180.0, 1.0, "radians_as_degrees") var facing_yaw_offset := -PI / 2.0
## Physics layers that make the skeleton reverse when detected ahead on its path.
@export_flags_3d_physics var map_collision_mask := WORLD_COLLISION_LAYER
## Height above the path used for the map collision probe.
@export_range(0.0, 2.0, 0.01) var map_collision_probe_height := 0.45
## Extra distance ahead of the skeleton checked for map blockers.
@export_range(0.0, 2.0, 0.01) var map_collision_probe_distance := 0.35
## Ray hits with normals above this are treated as floors instead of blockers.
@export_range(0.0, 1.0, 0.01) var map_collision_floor_normal_y := 0.65
## Radius used to detect pushable map blockers such as rolling rocks.
@export_range(0.05, 2.0, 0.01) var map_collision_pushable_probe_radius := 0.48
## Height above the path used for pushable blocker overlap checks.
@export_range(0.0, 2.0, 0.01) var map_collision_pushable_probe_height := 0.5
## Number of overlap samples checked ahead of the skeleton.
@export_range(1, 8, 1) var map_collision_pushable_probe_steps := 3
## Animation played while the skeleton is moving.
@export var walk_animation_name := "walk"
## Animation played if the skeleton has no usable movement.
@export var idle_animation_name := "idle"
## Animation played when a rolling ball crushes the skeleton.
@export var death_animation_name := "die"
## Keeps the walk cycle at a shuffling pace even if path speed is adjusted.
@export var walk_animation_speed_scale := 0.45
## Speed scale used for the skeleton death animation.
@export var death_animation_speed_scale := 0.5
## Minimum horizontal speed required to play skeleton footstep sounds.
@export var footstep_speed_threshold := 0.1
## Base travel distance between skeleton footsteps.
@export var footstep_distance := 0.7
## Random distance added or subtracted from each footstep interval.
@export var footstep_distance_variance := 0.18
## Lowest random pitch scale used for each skeleton footstep.
@export var footstep_pitch_min := 0.92
## Highest random pitch scale used for each skeleton footstep.
@export var footstep_pitch_max := 1.08
## Footstep volume at the speed threshold, in decibels.
@export var footstep_volume_min_db := 0.0
## Footstep volume near full shuffle speed, in decibels.
@export var footstep_volume_max_db := 4.0

@export_group("Rolling Ball Death")
## Enables rolling balls to kill the skeleton when they push far enough into its detection area.
@export var rolling_ball_death_enabled := true
## Percentage of the detection radius the ball must encroach before killing the skeleton.
@export_range(0.0, 100.0, 1.0) var rolling_ball_death_encroachment_percent := 25.0
## Radius around the skeleton contact area used for rolling ball death checks.
@export_range(0.05, 2.0, 0.01) var rolling_ball_death_detection_radius := 0.65
## Approximate rolling ball radius used to calculate encroachment percentage.
@export_range(0.05, 2.0, 0.01) var rolling_ball_death_radius := 0.52
## Seconds after death before the skeleton fades and sinks underground.
@export_range(0.0, 10.0, 0.1) var death_disappear_delay := 3.0
## Seconds used for the underground movement.
@export_range(0.0, 5.0, 0.05) var death_disappear_duration := 1.35
## Local Y distance the skeleton moves underground while disappearing.
@export_range(0.0, 5.0, 0.05) var death_sink_depth := 2.4
## Portion of the sink animation completed before fading starts.
@export_range(0.0, 1.0, 0.05) var death_fade_start_ratio := 0.55
## Volume of the skeleton death scream, in decibels.
@export var death_scream_volume_db := 2.0
@export_group("")

@export_group("Light")
## Enables the skeleton's warning light.
@export var skeleton_light_enabled := true
## Color of the skeleton's warning light.
@export var skeleton_light_color := Color(0.85, 1.0, 0.62, 1.0)
## Brightness of the skeleton's warning light.
@export var skeleton_light_energy := 0.95
## Radius reached by the skeleton's warning light.
@export var skeleton_light_range := 4.2
## Falloff curve for the skeleton's warning light.
@export var skeleton_light_attenuation := 1.45
## Whether the skeleton's warning light casts shadows.
@export var skeleton_light_cast_shadows := true
@export_group("")

@onready var path_follow := get_node_or_null(path_follow_path) as PathFollow3D
@onready var drop_pivot := get_node_or_null(drop_pivot_path) as Node3D
@onready var pivot := get_node_or_null(pivot_path) as Node3D
@onready var character := get_node_or_null(character_path) as Node3D
@onready var kill_area := get_node_or_null(kill_area_path) as Area3D
@onready var shadow := get_node_or_null(shadow_path) as Node3D
@onready var skeleton_light := get_node_or_null(skeleton_light_path) as OmniLight3D

var patrol_direction := 1.0
var footstep_sounds: Array[AudioStream] = []
var footstep_rng := RandomNumberGenerator.new()
var footstep_distance_accumulator := 0.0
var next_footstep_distance := 1.0
var animation_player: AnimationPlayer
var current_animation := ""
var resolved_walk_animation := ""
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
    add_to_group(SKELETON_GROUP)
    footstep_rng.seed = DETERMINISTIC_SEED.from_node(self, 0, &"skeleton_audio")
    _load_footstep_sounds()
    _randomize_next_footstep_distance()
    _apply_start_progress()
    _configure_shadow_casting()
    _configure_skeleton_light()

    if kill_area != null:
        kill_area.body_entered.connect(_on_kill_area_body_entered)

    if character != null:
        animation_player = _find_animation_player(character)
        _resolve_animation_names()

    if drop_in_time > 0.0:
        _set_active_visible(false)
    else:
        _finish_drop_in()


func die_from_spike_trap() -> void:
    _die_from_rolling_ball()


func can_be_hit_by_spike_trap() -> bool:
    return not is_dead


func get_spike_trap_position() -> Vector3:
    return path_follow.global_position if path_follow != null else global_position


func _physics_process(delta: float) -> void:
    if path_follow == null or curve == null:
        _update_animation(0.0)
        return

    if is_dead:
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
    _update_rolling_ball_death()


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
    _set_skeleton_transparency(0.0)
    _set_active_visible(true)
    _set_kill_area_enabled(true)
    _update_animation(shuffle_speed)


func _set_active_visible(active: bool) -> void:
    if drop_pivot != null:
        drop_pivot.visible = active
    if shadow != null:
        shadow.visible = active
    if skeleton_light != null:
        skeleton_light.visible = active and skeleton_light_enabled
    _set_kill_area_enabled(active and has_dropped_in)


func _set_kill_area_enabled(enabled: bool) -> void:
    kill_overlap_times.clear()
    if kill_area != null:
        kill_area.monitoring = enabled


func _set_skeleton_transparency(transparency: float) -> void:
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


func _configure_skeleton_light() -> void:
    if skeleton_light == null:
        return

    skeleton_light.light_color = skeleton_light_color
    skeleton_light.light_energy = skeleton_light_energy
    skeleton_light.omni_range = skeleton_light_range
    skeleton_light.omni_attenuation = skeleton_light_attenuation
    skeleton_light.shadow_enabled = skeleton_light_cast_shadows
    skeleton_light.visible = skeleton_light_enabled


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
        var wrapped_progress := wrapf(next_progress, 0.0, path_length)
        if _would_hit_map_collision(wrapped_progress, absf(shuffle_speed * delta)):
            _reverse_patrol_direction()
            return

        path_follow.progress = wrapped_progress
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

    var target_progress := clampf(next_progress, 0.0, path_length)
    if _would_hit_map_collision(target_progress, absf(shuffle_speed * delta)):
        _reverse_patrol_direction()
        return

    path_follow.progress = target_progress


func _would_hit_map_collision(target_progress: float, travel_distance: float) -> bool:
    if map_collision_mask == 0 or path_follow == null or curve == null:
        return false

    var world := get_world_3d()
    if world == null:
        return false

    var current_position := path_follow.global_position
    var target_position := to_global(curve.sample_baked(target_progress, true))
    var horizontal_displacement := target_position - current_position
    horizontal_displacement.y = 0.0

    if horizontal_displacement.length_squared() <= 0.000001:
        return false

    var probe_direction := horizontal_displacement.normalized()
    var probe_origin := current_position + Vector3.UP * map_collision_probe_height
    var probe_distance := map_collision_probe_distance + maxf(horizontal_displacement.length(), travel_distance)
    var query := PhysicsRayQueryParameters3D.create(
        probe_origin,
        probe_origin + probe_direction * probe_distance,
        map_collision_mask
    )
    query.collide_with_areas = false
    query.collide_with_bodies = true

    var hit := world.direct_space_state.intersect_ray(query)
    if hit.is_empty():
        return _would_hit_pushable_collision(world, current_position, probe_direction, probe_distance)

    var hit_normal := hit.get("normal", Vector3.ZERO) as Vector3
    if hit_normal.y < map_collision_floor_normal_y:
        return true

    return _would_hit_pushable_collision(world, current_position, probe_direction, probe_distance)


func _would_hit_pushable_collision(
    world: World3D,
    current_position: Vector3,
    probe_direction: Vector3,
    probe_distance: float
) -> bool:
    var probe_shape := SphereShape3D.new()
    probe_shape.radius = map_collision_pushable_probe_radius

    var query := PhysicsShapeQueryParameters3D.new()
    query.shape = probe_shape
    query.collision_mask = map_collision_mask
    query.collide_with_areas = false
    query.collide_with_bodies = true

    var sample_count := maxi(map_collision_pushable_probe_steps, 1)
    for sample_index in range(sample_count):
        var sample_ratio := float(sample_index + 1) / float(sample_count)
        query.transform = Transform3D(
            Basis.IDENTITY,
            current_position
                + Vector3.UP * map_collision_pushable_probe_height
                + probe_direction * probe_distance * sample_ratio
        )

        var hits := world.direct_space_state.intersect_shape(query, 8)
        for hit: Dictionary in hits:
            var collider := hit.get("collider") as Object
            if _is_pushable_blocker(collider):
                return true

    return false


func _is_pushable_blocker(collider: Object) -> bool:
    if collider == null or not collider is Node:
        return false

    var node := collider as Node
    return node.is_in_group("pushable") or node.has_method("push_from_character")


func _reverse_patrol_direction() -> void:
    patrol_direction *= -1.0


func _update_facing(horizontal_displacement: Vector3, delta: float) -> void:
    if pivot == null or horizontal_displacement.length_squared() <= 0.000001:
        return

    var direction := horizontal_displacement.normalized()
    var target_yaw := atan2(direction.x, direction.z) + facing_yaw_offset
    pivot.rotation.y = lerp_angle(pivot.rotation.y, target_yaw, turn_speed * delta)


func _update_animation(horizontal_speed: float) -> void:
    if animation_player == null or is_dead:
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
    resolved_death_animation = _resolve_animation_name(death_animation_name)
    if resolved_walk_animation.is_empty():
        push_warning("Skeleton character has no walk animation.")
    if resolved_death_animation.is_empty():
        push_warning("Skeleton character has no death animation.")


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

    var audio_parent: Node = path_follow as Node if path_follow != null else self as Node
    GDAudio.play_random_footstep_3d(
        audio_parent,
        footstep_sounds,
        "FootstepAudio",
        horizontal_speed,
        footstep_speed_threshold,
        shuffle_speed,
        footstep_volume_min_db,
        footstep_volume_max_db,
        footstep_pitch_min,
        footstep_pitch_max,
        footstep_rng
    )


func _update_rolling_ball_death() -> void:
    if not rolling_ball_death_enabled or is_dead or kill_area == null:
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

    return path_follow.global_position if path_follow != null else global_position


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
    footstep_distance_accumulator = 0.0
    _set_kill_area_enabled(false)
    _play_death_scream()
    _play_death_animation()

    if skeleton_light != null:
        skeleton_light.visible = false

    _disappear_after_death()


func _play_death_scream() -> void:
    var audio_parent: Node = path_follow as Node if path_follow != null else self as Node
    GDAudio.play_one_shot_3d(audio_parent, WILHELM_SCREAM, "SkeletonDeathScreamAudio", death_scream_volume_db)


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
