extends "res://enemies/zombie/zombie_base.gd"


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
        pivot.rotation.y = lerp_angle(
            pivot.rotation.y,
            atan2(facing_direction.x, facing_direction.z),
            turn_speed * delta
        )

func _face_position(world_position: Vector3, delta: float) -> void:
    var direction := world_position - _get_body_position()
    direction.y = 0.0
    _face_direction(direction, delta)

func _update_animation(horizontal_speed: float) -> void:
    if animation_player == null or is_dead:
        return

    if state == ZombieState.Sitdown:
        animation_player.speed_scale = 1.0
        _play_animation(idle_animation_name)
    elif (
        state == ZombieState.Chase
        and horizontal_speed >= footstep_speed_threshold
        and not resolved_run_animation.is_empty()
    ):
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

    var max_movement_speed := shuffle_speed
    var audio_parent: Node = zombie_body as Node if zombie_body != null else self as Node
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
    var audio_parent: Node = zombie_body as Node if zombie_body != null else self as Node
    GDAudio.play_one_shot_3d(audio_parent, punch_hit_sound, "ZombiePunchHitAudio", punch_hit_volume_db)

func _play_death_scream() -> void:
    var audio_parent: Node = zombie_body as Node if zombie_body != null else self as Node
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
