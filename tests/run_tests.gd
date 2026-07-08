extends SceneTree

const BAT_NEST_SCRIPT := preload("res://enemies/bat_nest.gd")
const DETERMINISTIC_SEED := preload("res://game/deterministic_seed.gd")
const GOLD_COIN_PILE_SCRIPT := preload("res://collectibles/gold_coin_pile.gd")
const LEVEL_SETTINGS_SCRIPT := preload("res://levels/common/level_settings.gd")
const LOW_HEALTH_VIGNETTE_SCRIPT := preload("res://ui/hud/low_health_vignette.gd")
const MINIMAP_VIEW_SCRIPT := preload("res://game/minimap_view.gd")
const MINIMAP_VIEW_SETTINGS := preload("res://game/minimap_view_settings.tres")
const PANEL_SCENE := preload("res://ui/hud/panel.tscn")
const SKELETON_SCENE := preload("res://enemies/skeleton.tscn")
const TEST_TEXT_OVERLAY_VISUAL_LAYER := 1 << 19

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


class TestMinimapBoundary:
    extends Node3D

    var bounds_size := Vector2(42.0, 28.0)
    var bounds_height := 8.0


    func get_bounds_center() -> Vector3:
        return global_position


    func get_bounds_transform() -> Transform3D:
        return global_transform


    func get_camera_fit_transform() -> Transform3D:
        return global_transform


    func get_bounds_size() -> Vector2:
        return bounds_size


    func get_bounds_height() -> float:
        return bounds_height


func _init() -> void:
    _run_tests.call_deferred()


func _run_tests() -> void:
    var failed := false
    failed = not _test_deterministic_seed_helper_is_stable() or failed
    failed = not _test_coin_pile_derives_stable_seed_and_disables_camera_gate_by_default() or failed
    failed = not _test_audio_fallback_is_deterministic() or failed
    failed = not _test_coin_absorption_does_not_complete_level() or failed
    failed = not _test_gate_completion_completes_level() or failed
    failed = not _test_graveyard_scene_does_not_embed_default_level() or failed
    failed = not _test_kill_boundary_loop_setting() or failed
    failed = not _test_no_boundary_removal_keeps_current_pose() or failed
    failed = not _test_level_settings_control_minimap_visibility() or failed
    failed = not _test_low_health_vignette_maps_health_to_warning_intensity() or failed
    failed = not _test_hud_panel_sets_split_value_labels() or failed
    failed = not _test_skeleton_facing_is_driven_by_movement() or failed
    failed = not _test_minimap_disables_processing_and_rendering() or failed
    failed = not _test_minimap_camera_scrolls_wide_level_without_empty_space() or failed
    failed = not _test_minimap_camera_scrolls_tall_level_without_empty_space() or failed
    failed = not _test_bat_nest_swarms_then_rises_away() or failed
    failed = not _test_bat_nest_camera_scare_grows_one_bat() or failed
    await process_frame
    quit(1 if failed else 0)


func _test_deterministic_seed_helper_is_stable() -> bool:
    var first_seed := DETERMINISTIC_SEED.from_text("stable-source", 23)
    var second_seed := DETERMINISTIC_SEED.from_text("stable-source", 23)
    var different_seed := DETERMINISTIC_SEED.from_text("stable-source", 24)

    return _expect(first_seed == second_seed, "deterministic seed helper repeats the same seed") \
        and _expect(first_seed != different_seed, "deterministic seed helper changes with salt")


func _test_coin_pile_derives_stable_seed_and_disables_camera_gate_by_default() -> bool:
    var parent := Node3D.new()
    parent.name = "DeterministicSeedParent"
    root.add_child(parent)

    var pile: Node = GOLD_COIN_PILE_SCRIPT.new()
    pile.name = "GoldCoinPile"
    parent.add_child(pile)

    var expected_seed := DETERMINISTIC_SEED.from_node(pile, 0, &"gold_coin_pile")
    var runtime_seed := int(pile.get_runtime_random_seed())
    var passed := _expect(runtime_seed == expected_seed, "coin pile derives a stable fallback seed") \
        and _expect(not bool(pile.get("spawn_when_near_camera")), "coin pile does not camera-gate spawn timing by default")

    parent.queue_free()
    return passed


func _test_audio_fallback_is_deterministic() -> bool:
    var first_stream := AudioStreamMP3.new()
    var second_stream := AudioStreamMP3.new()
    var streams: Array[AudioStream] = [first_stream, second_stream]
    var picked_stream := GDAudio._pick_stream(streams, null)
    var midpoint := GDAudio._randf_range(0.25, 0.75, null)

    return _expect(picked_stream == first_stream, "audio fallback picks the first stream deterministically") \
        and _expect(is_equal_approx(midpoint, 0.5), "audio fallback uses deterministic midpoint variation")


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


func _test_graveyard_scene_does_not_embed_default_level() -> bool:
    var scene := load("res://game/graveyard.tscn") as PackedScene
    if not _expect(scene != null, "graveyard scene loads"):
        return false

    var graveyard := scene.instantiate()
    var passed := _expect(graveyard.get_node_or_null("CurrentLevel") == null, "graveyard editor scene does not embed level 1")
    graveyard.queue_free()
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


func _test_level_settings_control_minimap_visibility() -> bool:
    var graveyard := TestGraveyard.new()
    var level := Node3D.new()
    var level_settings: Node = LEVEL_SETTINGS_SCRIPT.new()
    level_settings.set("show_minimap", true)
    level.add_child(level_settings)
    graveyard.current_level = level

    var passed := _expect(graveyard.call("_should_show_minimap"), "level settings can enable the minimap")

    level_settings.set("show_minimap", false)
    passed = _expect(not bool(graveyard.call("_should_show_minimap")), "level settings can disable the minimap") and passed

    level.queue_free()
    graveyard.queue_free()
    return passed


func _test_low_health_vignette_maps_health_to_warning_intensity() -> bool:
    var vignette: CanvasLayer = LOW_HEALTH_VIGNETTE_SCRIPT.new()
    var vignette_rect := ColorRect.new()
    vignette_rect.name = "VignetteRect"
    var shader_material := ShaderMaterial.new()
    shader_material.shader = load("res://ui/hud/low_health_vignette.gdshader")
    vignette_rect.material = shader_material
    vignette.add_child(vignette_rect)
    root.add_child(vignette)

    vignette.call("set_health_ratio", 1.0, false)
    var passed := _expect(is_equal_approx(float(vignette.call("get_target_intensity")), 0.0), "healthy player hides low-health vignette")
    passed = _expect(vignette.layer == 0, "low-health vignette renders under gameplay HUD layers") and passed

    vignette.call("set_health_ratio", 0.35, false)
    passed = _expect(is_equal_approx(float(vignette.call("get_target_intensity")), 0.0), "vignette starts below configured health threshold") and passed

    vignette.call("set_health_ratio", 0.12, false)
    passed = _expect(is_equal_approx(float(vignette.call("get_target_intensity")), 1.0), "vignette reaches full strength at critical health") and passed

    vignette.call("set_health_ratio", 1.0, true)
    passed = _expect(is_equal_approx(float(vignette.call("get_target_intensity")), 1.0), "dead player keeps warning vignette visible") and passed

    vignette.queue_free()
    return passed


func _test_hud_panel_sets_split_value_labels() -> bool:
    var panel := PANEL_SCENE.instantiate()
    root.add_child(panel)
    panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
    panel.size = Vector2(2560.0, 1080.0)
    panel.set("reference_screen_size", Vector2(1920.0, 1080.0))
    panel.call("_sync_screen_container")

    panel.call("set_sack_counts", 7, 12)
    panel.call("set_treasure_total", 30)
    panel.call("add_score", 4)

    var sack_contents := panel.get_node("ScreenContainer/PanelPlacement/PanelArt/SackContents") as Label
    var sack_max := panel.get_node("ScreenContainer/PanelPlacement/PanelArt/SackMax") as Label
    var treasure_lifted := panel.get_node("ScreenContainer/PanelPlacement/PanelArt/TreasureLifted") as Label
    var treasure_on_level := panel.get_node("ScreenContainer/PanelPlacement/PanelArt/TreasureOnLevel") as Label
    var screen_container := panel.get_node("ScreenContainer") as Control
    var passed := _expect(sack_contents.text == "7", "HUD panel displays carried sack count") \
        and _expect(sack_max.text == "of 12", "HUD panel displays sack capacity") \
        and _expect(treasure_lifted.text == "4", "HUD panel displays lifted treasure count") \
        and _expect(treasure_on_level.text == "of 30", "HUD panel displays level treasure total") \
        and _expect(panel.get_node_or_null("ScreenContainer") != null, "HUD panel has a full-screen editor container") \
        and _expect(panel.get_node_or_null("ScreenContainer/PanelPlacement") != null, "HUD panel has an editor-owned placement node") \
        and _expect(not panel.get_node("ScreenContainer/PanelPlacement/PlacementGuide").visible, "HUD panel hides placement guide at runtime") \
        and _expect(is_equal_approx(screen_container.scale.x, screen_container.scale.y), "HUD panel scales reference screen uniformly") \
        and _expect(is_equal_approx(screen_container.position.x, 320.0), "HUD panel centers reference screen on wide viewports")

    panel.queue_free()
    return passed


func _test_skeleton_facing_is_driven_by_movement() -> bool:
    var skeleton := SKELETON_SCENE.instantiate()
    root.add_child(skeleton)

    var exposes_facing_offset := false
    for property: Dictionary in skeleton.get_property_list():
        if property.get("name") == "facing_yaw_offset":
            exposes_facing_offset = true
            break

    skeleton.set("turn_speed", 1.0)
    var pivot := skeleton.get_node("PathFollow3D/DropPivot/Pivot") as Node3D
    pivot.rotation.y = 0.0
    skeleton.call("_update_facing", Vector3.RIGHT, 1.0)

    var passed := _expect(not exposes_facing_offset, "skeleton facing offset is not editable per instance") \
        and _expect(is_equal_approx(pivot.rotation.y, PI / 2.0), "skeleton visual faces rightward patrol movement")

    skeleton.queue_free()
    return passed


func _test_minimap_disables_processing_and_rendering() -> bool:
    var minimap: Control = MINIMAP_VIEW_SCRIPT.new()
    minimap.set("settings", MINIMAP_VIEW_SETTINGS)
    var viewport_container := SubViewportContainer.new()
    viewport_container.name = "ViewportContainer"
    var minimap_viewport := SubViewport.new()
    minimap_viewport.name = "MinimapViewport"
    var minimap_camera := Camera3D.new()
    minimap_camera.name = "MinimapCamera"

    minimap.add_child(viewport_container)
    viewport_container.add_child(minimap_viewport)
    minimap_viewport.add_child(minimap_camera)
    root.add_child(minimap)

    minimap.call("set_minimap_enabled", true)
    minimap.call("set_minimap_enabled", false)

    var passed := _expect(not minimap.visible, "disabled minimap hides the HUD") \
        and _expect(not minimap.is_processing(), "disabled minimap stops script processing") \
        and _expect(minimap_viewport.process_mode == Node.PROCESS_MODE_DISABLED, "disabled minimap stops SubViewport processing") \
        and _expect(minimap_viewport.render_target_update_mode == SubViewport.UPDATE_DISABLED, "disabled minimap stops SubViewport rendering") \
        and _expect(not minimap_camera.current, "disabled minimap camera is not current")

    minimap.queue_free()
    return passed


func _test_minimap_camera_scrolls_wide_level_without_empty_space() -> bool:
    var minimap: Control = MINIMAP_VIEW_SCRIPT.new()
    minimap.set("settings", MINIMAP_VIEW_SETTINGS)
    var viewport_container := SubViewportContainer.new()
    viewport_container.name = "ViewportContainer"
    var minimap_viewport := SubViewport.new()
    minimap_viewport.name = "MinimapViewport"
    var minimap_camera := Camera3D.new()
    minimap_camera.name = "MinimapCamera"
    var source_camera := Camera3D.new()
    source_camera.current = true
    root.add_child(source_camera)

    minimap.add_child(viewport_container)
    viewport_container.add_child(minimap_viewport)
    minimap_viewport.add_child(minimap_camera)
    root.add_child(minimap)

    var level_root := Node3D.new()
    var level_mesh := MeshInstance3D.new()
    var level_box := BoxMesh.new()
    level_box.size = Vector3(120.0, 2.0, 80.0)
    level_mesh.mesh = level_box
    level_mesh.position = Vector3(80.0, 0.0, -30.0)
    level_root.add_child(level_mesh)
    var outlier_light := SpotLight3D.new()
    outlier_light.position = Vector3(-500.0, 20.0, -500.0)
    level_root.add_child(outlier_light)
    var hidden_text_visual := MeshInstance3D.new()
    var hidden_text_box := BoxMesh.new()
    hidden_text_box.size = Vector3(400.0, 2.0, 400.0)
    hidden_text_visual.mesh = hidden_text_box
    hidden_text_visual.layers = TEST_TEXT_OVERLAY_VISUAL_LAYER
    hidden_text_visual.position = Vector3(-500.0, 0.0, -500.0)
    level_root.add_child(hidden_text_visual)
    root.add_child(level_root)

    var target := Node3D.new()
    target.position = Vector3.ZERO
    var boundary := TestMinimapBoundary.new()
    boundary.bounds_size = Vector2(8.0, 8.0)
    boundary.position = Vector3.ZERO
    root.add_child(target)
    root.add_child(boundary)

    minimap.call("set_runtime_references", target, boundary, level_root)
    minimap.call("set_minimap_enabled", true)
    minimap.call("_process", 0.016)

    var level_center := level_mesh.global_position
    var visible_width := _get_camera_visible_world_width(minimap_camera, minimap)
    var expected_clamped_x := level_center.x - level_box.size.x * 0.5 + visible_width * 0.5
    var minimap_environment := minimap_camera.get("environment") as Environment
    var expected_panel_width := maxf(
        root.get_visible_rect().size.x * MINIMAP_VIEW_SETTINGS.viewport_width_fraction,
        MINIMAP_VIEW_SETTINGS.minimum_panel_width
    )
    var panel_width := minimap.offset_right - minimap.offset_left
    var passed := _expect(minimap_camera.current, "minimap camera is current in its viewport") \
        and _expect(minimap_viewport.world_3d == root.world_3d, "minimap viewport shares the main world") \
        and _expect(is_equal_approx(panel_width, expected_panel_width), "minimap width follows the configured viewport fraction") \
        and _expect(viewport_container.stretch, "minimap render target stretches to fill the visible panel content") \
        and _expect(minimap_camera.projection == Camera3D.PROJECTION_ORTHOGONAL, "minimap camera uses an orthographic top-down view") \
        and _expect(is_equal_approx(minimap_camera.size, level_box.size.z), "wide minimap fits the level depth to avoid vertical empty space") \
        and _expect(minimap_camera.size < 150.0, "minimap bounds ignore outlier light volumes") \
        and _expect((source_camera.cull_mask & TEST_TEXT_OVERLAY_VISUAL_LAYER) != 0, "main camera keeps the text overlay visual layer") \
        and _expect((minimap_camera.cull_mask & TEST_TEXT_OVERLAY_VISUAL_LAYER) == 0, "minimap camera hides the text overlay visual layer") \
        and _expect(minimap_environment != null, "minimap camera has its own environment override") \
        and _expect(is_equal_approx(minimap_environment.ambient_light_energy, MINIMAP_VIEW_SETTINGS.ambient_light_energy), "minimap environment has ambient light") \
        and _expect(is_equal_approx(minimap_camera.global_position.x, expected_clamped_x), "wide minimap clamps horizontally at the level edge") \
        and _expect(is_equal_approx(minimap_camera.global_position.z, level_center.z), "wide minimap keeps the full level depth visible") \
        and _expect(minimap_camera.global_position.y > level_center.y, "minimap camera uses an elevated view")

    minimap.queue_free()
    source_camera.queue_free()
    level_root.queue_free()
    target.queue_free()
    boundary.queue_free()
    return passed


func _test_minimap_camera_scrolls_tall_level_without_empty_space() -> bool:
    var minimap: Control = MINIMAP_VIEW_SCRIPT.new()
    minimap.set("settings", MINIMAP_VIEW_SETTINGS)
    var viewport_container := SubViewportContainer.new()
    viewport_container.name = "ViewportContainer"
    var minimap_viewport := SubViewport.new()
    minimap_viewport.name = "MinimapViewport"
    var minimap_camera := Camera3D.new()
    minimap_camera.name = "MinimapCamera"

    minimap.add_child(viewport_container)
    viewport_container.add_child(minimap_viewport)
    minimap_viewport.add_child(minimap_camera)
    root.add_child(minimap)

    var level_root := Node3D.new()
    var level_mesh := MeshInstance3D.new()
    var level_box := BoxMesh.new()
    level_box.size = Vector3(80.0, 2.0, 120.0)
    level_mesh.mesh = level_box
    level_mesh.position = Vector3(30.0, 0.0, 60.0)
    level_root.add_child(level_mesh)
    root.add_child(level_root)

    var target := Node3D.new()
    target.position = Vector3(30.0, 0.0, -50.0)
    var boundary := TestMinimapBoundary.new()
    boundary.bounds_size = Vector2(8.0, 8.0)
    boundary.position = Vector3.ZERO
    root.add_child(target)
    root.add_child(boundary)

    minimap.call("set_runtime_references", target, boundary, level_root)
    minimap.call("set_minimap_enabled", true)
    minimap.call("_process", 0.016)

    var level_center := level_mesh.global_position
    var expected_size := level_box.size.x / _get_minimap_render_aspect(minimap)
    var expected_clamped_z := level_center.z - level_box.size.z * 0.5 + minimap_camera.size * 0.5
    var passed := _expect(is_equal_approx(minimap_camera.size, expected_size), "tall minimap fits the level width to avoid horizontal empty space") \
        and _expect(is_equal_approx(minimap_camera.global_position.x, level_center.x), "tall minimap keeps the full level width visible") \
        and _expect(is_equal_approx(minimap_camera.global_position.z, expected_clamped_z), "tall minimap clamps vertically at the level edge")

    minimap.queue_free()
    level_root.queue_free()
    target.queue_free()
    boundary.queue_free()
    return passed


func _get_camera_visible_world_width(camera: Camera3D, minimap: Control) -> float:
    return camera.size * _get_minimap_render_aspect(minimap)


func _get_minimap_render_aspect(minimap: Control) -> float:
    var render_size := minimap.call("_get_minimap_render_size", MINIMAP_VIEW_SETTINGS) as Vector2i
    return float(render_size.x) / maxf(float(render_size.y), 0.001)


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
