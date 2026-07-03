extends SceneTree

const BAT_NEST_SCRIPT := preload("res://enemies/bat_nest.gd")

class TestGraveyard:
    extends GDGraveyard

    var win_requested := false


    func _store_result_stats() -> void:
        pass


    func _show_win_screen() -> void:
        win_requested = true


class TestKillBoundary:
    extends GDKillBoundary3D

    var sink_requested := false


    func _create_near_flame_audio() -> void:
        pass


    func _sink_removed_boundary(_seconds: float, _distance: float) -> void:
        sink_requested = true


func _init() -> void:
    _run_tests.call_deferred()


func _run_tests() -> void:
    var failed := false
    failed = not _test_coin_absorption_does_not_complete_level() or failed
    failed = not _test_gate_completion_completes_level() or failed
    failed = not _test_kill_boundary_loop_setting() or failed
    failed = not _test_no_boundary_removal_keeps_current_pose() or failed
    failed = not _test_bat_nest_swarms_then_rises_away() or failed
    failed = not _test_bat_nest_camera_scare_grows_one_bat() or failed
    await process_frame
    quit(1 if failed else 0)


func _test_coin_absorption_does_not_complete_level() -> bool:
    var graveyard := TestGraveyard.new()
    graveyard.max_coins_collected = 3
    graveyard.coins_collected = 2
    graveyard._on_coin_absorbed(1)

    var passed := _expect(graveyard.coins_collected == 3, "coin absorption still updates result coin count") \
        and _expect(not graveyard.win_requested, "banking the last coin does not complete the level")
    graveyard.free()
    return passed


func _test_gate_completion_completes_level() -> bool:
    var graveyard := TestGraveyard.new()
    graveyard._on_level_completed()

    var passed := _expect(graveyard.win_requested, "gate completion completes the level")
    graveyard.free()
    return passed


func _test_kill_boundary_loop_setting() -> bool:
    var boundary := TestKillBoundary.new()
    root.add_child(boundary)
    boundary.loop_boundary_path = false
    boundary._ensure_boundary_nodes()
    var center := boundary.get_node("BoundaryCenter") as PathFollow3D
    var passed := _expect(not center.loop, "kill boundary can disable path looping")

    boundary.loop_boundary_path = true
    passed = _expect(center.loop, "kill boundary can enable path looping") and passed
    boundary.queue_free()
    return passed


func _test_no_boundary_removal_keeps_current_pose() -> bool:
    var boundary := TestKillBoundary.new()
    boundary.boundary_animation = _create_pose_test_boundary_animation()
    root.add_child(boundary)
    boundary._ensure_boundary_nodes()
    boundary._sync_animation_player()

    var animation_player := boundary.get_node("BoundaryAnimationPlayer") as AnimationPlayer
    animation_player.play(&"kill_boundary")
    animation_player.seek(2.0, true)
    boundary._sync_movement_to_animation()
    boundary._sync_boundary()

    var center := boundary.get_node("BoundaryCenter") as PathFollow3D
    var center_position := center.global_position
    var center_progress := center.progress
    var scale_x := boundary.boundary_scale_x
    var scale_z := boundary.boundary_scale_z

    boundary.remove_for_level(1.0, 3.0)
    var passed := _expect(animation_player.is_playing(), "no-boundary removal keeps visual animation playing") \
        and _expect(center.global_position.is_equal_approx(center_position), "no-boundary removal keeps current center pose") \
        and _expect(is_equal_approx(boundary.boundary_scale_x, scale_x), "no-boundary removal keeps current x scale") \
        and _expect(is_equal_approx(boundary.boundary_scale_z, scale_z), "no-boundary removal keeps current z scale") \
        and _expect(boundary.sink_requested, "no-boundary removal still starts sink transition")
    animation_player.seek(3.0, true)
    boundary._physics_process(0.1)
    passed = _expect(center.progress > center_progress, "removed boundary keeps moving until sunk") and passed
    boundary.queue_free()
    return passed


func _create_pose_test_boundary_animation() -> Animation:
    var animation := Animation.new()
    animation.resource_name = "kill_boundary"
    animation.length = 4.0
    animation.loop_mode = Animation.LOOP_LINEAR

    var movement_track := animation.add_track(Animation.TYPE_VALUE)
    animation.track_set_path(movement_track, NodePath(".:movement_speed"))
    animation.track_set_interpolation_loop_wrap(movement_track, false)
    animation.track_insert_key(movement_track, 0.0, 1.0)

    var scale_x_track := animation.add_track(Animation.TYPE_VALUE)
    animation.track_set_path(scale_x_track, NodePath(".:boundary_scale_x"))
    animation.track_insert_key(scale_x_track, 0.0, 1.0)
    animation.track_insert_key(scale_x_track, 2.0, 2.0)

    var scale_z_track := animation.add_track(Animation.TYPE_VALUE)
    animation.track_set_path(scale_z_track, NodePath(".:boundary_scale_z"))
    animation.track_insert_key(scale_z_track, 0.0, 1.0)
    animation.track_insert_key(scale_z_track, 2.0, 1.5)

    var rotation_track := animation.add_track(Animation.TYPE_VALUE)
    animation.track_set_path(rotation_track, NodePath(".:boundary_rotation_z_radians"))
    animation.track_insert_key(rotation_track, 0.0, 0.0)
    animation.track_insert_key(rotation_track, 2.0, 0.25)
    return animation


func _test_bat_nest_swarms_then_rises_away() -> bool:
    var player := Node3D.new()
    player.position = Vector3(10.0, 0.0, 0.0)
    player.add_to_group(&"player")
    root.add_child(player)

    var nest := BAT_NEST_SCRIPT.new()
    nest.bat_scene = _create_test_bat_scene()
    nest.bat_count = 4
    nest.trigger_radius = 2.0
    nest.player_spawn_radius = 0.5
    nest.player_spawn_height = 1.0
    nest.swarm_seconds = 0.1
    nest.fly_off_seconds = 0.5
    nest.fly_off_turn_seconds = 0.2
    nest.fly_off_audio_fade_seconds = 0.5
    nest.flap_sound_interval_min = 0.01
    nest.flap_sound_interval_max = 0.01
    nest.flap_sound_max_concurrent = 2
    nest.squeak_sound_interval_min = 0.01
    nest.squeak_sound_interval_max = 0.01
    nest.squeak_sound_chance_percent = 100.0
    nest.squeak_sound_max_concurrent = 1
    root.add_child(nest)

    nest._physics_process(0.016)
    var passed := _expect(nest.get_runtime_bat_count() == 4, "bat nest creates the requested cluster count") \
        and _expect(nest.get_bat_nest_state() == BAT_NEST_SCRIPT.BatNestState.ROOSTING, "bat nest waits while the player is far away") \
        and _expect(_are_bats_visible(nest) == false, "bat nest hides bats before triggering")

    player.global_position = Vector3.ZERO
    nest._physics_process(0.016)
    passed = _expect(nest.get_bat_nest_state() == BAT_NEST_SCRIPT.BatNestState.SWARMING, "bat nest starts swarming when the player is close") and passed
    passed = _expect(_are_bats_visible(nest), "bat nest shows bats after triggering") and passed
    passed = _expect(_are_bats_spawned_near_player(nest, player.global_position), "bat nest spawns bats close to the player") and passed
    passed = _expect(_get_flap_audio_player_count(nest) > 0, "bat nest plays flap audio immediately on trigger") and passed
    passed = _expect(_get_squeak_audio_player_count(nest) > 0, "bat nest plays squeak audio immediately on trigger") and passed
    nest._physics_process(0.02)
    nest._physics_process(0.02)
    nest._physics_process(0.02)
    var flap_audio_count := _get_flap_audio_player_count(nest)
    var squeak_audio_count := _get_squeak_audio_player_count(nest)
    passed = _expect(flap_audio_count > 0, "bat nest plays flap one-shot audio") and passed
    passed = _expect(flap_audio_count <= 2, "bat nest caps concurrent flap one-shots") and passed
    passed = _expect(squeak_audio_count > 0, "bat nest plays squeak one-shot audio") and passed
    passed = _expect(squeak_audio_count <= 1, "bat nest caps concurrent squeak one-shots") and passed

    nest._physics_process(0.12)
    var first_bat_node := nest.bats[0].node as Node3D
    var first_bat := nest.bats[0]
    var first_bat_turn_start := first_bat.fly_start_direction as Vector3
    var first_bat_turn_target := first_bat.fly_direction as Vector3
    var animation_player := first_bat_node.get_node("AnimationPlayer") as AnimationPlayer
    var height_before_fly_off := first_bat_node.global_position.y
    var audio_volume_before_fade := _get_first_flap_audio_volume(nest)
    nest._physics_process(0.02)
    var first_bat_initial_fly_direction := _get_horizontal_direction(first_bat.velocity as Vector3)
    nest._physics_process(0.2)
    var first_bat_final_fly_direction := _get_horizontal_direction(first_bat.velocity as Vector3)
    var audio_volume_after_fade := _get_first_flap_audio_volume(nest)
    var height_after_fly_off := first_bat_node.global_position.y
    passed = _expect(nest.get_bat_nest_state() == BAT_NEST_SCRIPT.BatNestState.FLYING_OFF, "bat nest switches from swarming to flying off") and passed
    passed = _expect(height_after_fly_off > height_before_fly_off, "bat nest rises while flying away") and passed
    var halfway_turn := nest._slerp_horizontal_direction(Vector3.RIGHT, Vector3.FORWARD, 0.5)
    passed = _expect(halfway_turn.dot(Vector3.RIGHT) > 0.5 and halfway_turn.dot(Vector3.FORWARD) > 0.5, "bat nest blends fly-off turn directions") and passed
    passed = _expect(first_bat_final_fly_direction.dot(first_bat_turn_target) > 0.9, "bat nest finishes fly-off turn toward escape direction") and passed
    passed = _expect(audio_volume_after_fade < audio_volume_before_fade, "bat nest fades audio during fly-off") and passed
    passed = _expect(_are_bats_flying_as_group(nest), "bat nest flies away as a group") and passed
    passed = _expect(animation_player.has_animation(&"combined_flap"), "bat nest combines separate wing animations") and passed
    passed = _expect(animation_player.current_animation == &"combined_flap", "bat nest plays the combined wing animation") and passed

    nest.queue_free()
    player.queue_free()
    return passed


func _test_bat_nest_camera_scare_grows_one_bat() -> bool:
    var camera := Camera3D.new()
    camera.current = true
    camera.look_at_from_position(Vector3(0.0, 3.0, 5.0), Vector3.ZERO, Vector3.UP)
    root.add_child(camera)

    var player := Node3D.new()
    player.add_to_group(&"player")
    root.add_child(player)

    var nest := BAT_NEST_SCRIPT.new()
    nest.bat_scene = _create_test_bat_scene()
    nest.bat_count = 4
    nest.trigger_radius = 2.0
    nest.swarm_seconds = 1.0
    nest.camera_scare_chance_percent = 100.0
    nest.camera_scare_duration = 0.5
    nest.camera_scare_scale_multiplier = 3.0
    root.add_child(nest)

    nest._physics_process(0.016)
    var scare_count := _get_camera_scare_bat_count(nest)
    var scare_bat_node := nest.scare_bat.node as Node3D
    var scale_before := scare_bat_node.scale.x
    nest._physics_process(0.2)
    var scale_after := scare_bat_node.scale.x

    var passed := _expect(scare_count == 1, "bat nest selects one camera scare bat") \
        and _expect(scale_after > scale_before, "camera scare bat grows as it rushes the camera")

    nest.queue_free()
    player.queue_free()
    camera.queue_free()
    return passed


func _get_camera_scare_bat_count(nest: Node) -> int:
    var scare_count := 0
    for bat_state in nest.bats:
        if bat_state.is_camera_scare:
            scare_count += 1

    return scare_count


func _get_horizontal_direction(velocity: Vector3) -> Vector3:
    var horizontal := Vector3(velocity.x, 0.0, velocity.z)
    if horizontal.length_squared() <= 0.001:
        return Vector3.ZERO

    return horizontal.normalized()


func _are_bats_visible(nest: Node) -> bool:
    for bat_state in nest.bats:
        var bat_node := bat_state.node as Node3D
        if bat_node != null and bat_node.visible:
            return true

    return false


func _are_bats_spawned_near_player(nest: Node, player_position: Vector3) -> bool:
    for bat_state in nest.bats:
        var bat_node := bat_state.node as Node3D
        if bat_node == null:
            continue

        var offset := bat_node.global_position - player_position
        var horizontal_offset := Vector2(offset.x, offset.z)
        if horizontal_offset.length() > float(nest.player_spawn_radius) + 0.05:
            return false

        if absf(offset.y - float(nest.player_spawn_height)) > float(nest.player_spawn_radius) * 0.5 + 0.05:
            return false

    return true


func _get_flap_audio_player_count(nest: Node) -> int:
    var audio_player_count := 0
    for child in nest.get_children():
        if child is AudioStreamPlayer3D and child.name == "BatFlapOneShotAudio":
            audio_player_count += 1

    return audio_player_count


func _get_first_flap_audio_volume(nest: Node) -> float:
    for child in nest.get_children():
        if child is AudioStreamPlayer3D and child.name == "BatFlapOneShotAudio":
            return (child as AudioStreamPlayer3D).volume_db

    return -100.0


func _get_squeak_audio_player_count(nest: Node) -> int:
    var audio_player_count := 0
    for child in nest.get_children():
        if child is AudioStreamPlayer3D and child.name == "BatSqueakOneShotAudio":
            audio_player_count += 1

    return audio_player_count


func _are_bats_flying_as_group(nest: Node) -> bool:
    var group_direction := nest.fly_off_group_direction as Vector3
    for bat_state in nest.bats:
        var fly_direction := bat_state.fly_direction as Vector3
        if fly_direction.dot(group_direction) < 0.8:
            return false

    return true


func _create_test_bat_scene() -> PackedScene:
    var bat_root := Node3D.new()
    var left_wing := Node3D.new()
    var right_wing := Node3D.new()
    var animation_player := AnimationPlayer.new()
    var animation_library := AnimationLibrary.new()

    left_wing.name = "LeftWing"
    right_wing.name = "RightWing"
    animation_player.name = "AnimationPlayer"
    bat_root.add_child(left_wing)
    bat_root.add_child(right_wing)
    bat_root.add_child(animation_player)
    left_wing.owner = bat_root
    right_wing.owner = bat_root
    animation_player.owner = bat_root

    var left_animation := Animation.new()
    left_animation.length = 0.1
    var left_track := left_animation.add_track(Animation.TYPE_VALUE)
    left_animation.track_set_path(left_track, NodePath("../LeftWing:position"))
    left_animation.track_insert_key(left_track, 0.0, Vector3.ZERO)
    left_animation.track_insert_key(left_track, 0.1, Vector3.UP)

    var right_animation := Animation.new()
    right_animation.length = 0.1
    var right_track := right_animation.add_track(Animation.TYPE_VALUE)
    right_animation.track_set_path(right_track, NodePath("../RightWing:position"))
    right_animation.track_insert_key(right_track, 0.0, Vector3.ZERO)
    right_animation.track_insert_key(right_track, 0.1, Vector3.UP)

    animation_library.add_animation(&"left_flap", left_animation)
    animation_library.add_animation(&"right_flap", right_animation)
    animation_player.add_animation_library(&"", animation_library)

    var scene := PackedScene.new()
    scene.pack(bat_root)
    bat_root.free()
    return scene


func _expect(condition: bool, message: String) -> bool:
    if condition:
        print("PASS: %s" % message)
        return true

    push_error("FAIL: %s" % message)
    return false
