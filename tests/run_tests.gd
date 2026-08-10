extends SceneTree

const BAT_NEST_SCRIPT := preload("res://enemies/bat_nest.gd")
const LEVEL_DEFINITION_SCRIPT := preload("res://levels/level_definition.gd")
const PLACEABLE_SCRIPT := preload("res://placeables/placeable.gd")
const TREASURE_DEPOSIT_COFFIN_SCENE := preload("res://placeables/treasure_deposit/treasure_deposit_coffin.tscn")
const DETERMINISTIC_SEED := preload("res://game/deterministic_seed.gd")
const CODEX_SESSION_OPTIONS := preload("res://game/codex_session_options.gd")
const CHARACTER_LOOK_SETTINGS := preload("res://game/character_look_settings.tres")
const RUN_RECORDER_SCRIPT := preload("res://game/run_recorder.gd")
const RUN_RECORDING_SCRIPT := preload("res://game/run_recording.gd")
const SCREEN_FADE_SCRIPT := preload("res://ui/screens/screen_fade.gd")
const AMETHYST_ITEM := preload("res://placeables/treasure/gems/amethyst_inventory.tres")
const AMETHYST_SCENE := preload("res://placeables/treasure/gems/amethyst.tscn")
const DIAMOND_ITEM := preload("res://placeables/treasure/gems/diamond_inventory.tres")
const DIAMOND_MATERIAL := preload("res://placeables/treasure/gems/diamond_material.tres")
const DIAMOND_SCENE := preload("res://placeables/treasure/gems/diamond.tscn")
const EMERALD_ITEM := preload("res://placeables/treasure/gems/emerald_inventory.tres")
const EMERALD_SCENE := preload("res://placeables/treasure/gems/emerald.tscn")
const GOLD_BAR_ITEM := preload("res://placeables/treasure/gold_bar_inventory.tres")
const GOLD_BAR_SCENE := preload("res://placeables/treasure/gold_bar.tscn")
const GOLD_BAR_SCRIPT := preload("res://placeables/treasure/gold_bar.gd")
const GOLD_COIN_ITEM := preload("res://placeables/treasure/gold_coin_inventory.tres")
const GOLD_COIN_SCENE := preload("res://placeables/treasure/gold_coin.tscn")
const GOLD_COIN_PILE_SCRIPT := preload("res://placeables/treasure/gold_coin_pile.gd")
const GOLD_TREASURE_MATERIAL := preload("res://placeables/treasure/gold_treasure_material.tres")
const TREASURE_OUTLINE_MATERIAL := preload(
    "res://placeables/treasure/treasure_outline_material.tres"
)
const KEY_SCENE := preload("res://inventory/key.tscn")
const KILL_BOUNDARY_SCENE := preload("res://placeables/kill_boundary/kill_boundary.tscn")
const LEVEL_SETTINGS_SCRIPT := preload("res://levels/level_settings.gd")
const LEVEL_SELECT_SCENE := preload("res://ui/screens/level_select_screen.tscn")
const LOW_HEALTH_VIGNETTE_SCRIPT := preload("res://ui/hud/low_health_vignette.gd")
const LOCKED_DOOR_SCENE := preload("res://placeables/lockables/locked_door.tscn")
const LOCKED_GATE_SCENE := preload("res://placeables/lockables/locked_gate.tscn")
const HEALTH_FLASK_SCENE := preload("res://placeables/collectibles/health_flask.tscn")
const NO_BOUNDARY_FLASK_SCENE := preload(
    "res://placeables/collectibles/flask_no_boundary.tscn"
)
const INDOOR_LIGHTING_SCENE := preload("res://lighting/gd_indoor_lighting.tscn")
const MINIMAP_VIEW_SCRIPT := preload("res://ui/hud/minimap/minimap_view.gd")
const MINIMAP_VIEW_SETTINGS := preload("res://ui/hud/minimap/minimap_view_settings.tres")
const VAMPIRE_MINIMAP_OVERLAY_SCRIPT := preload(
    "res://ui/hud/minimap/vampire_minimap_overlay.gd"
)
const PANEL_SCENE := preload("res://ui/hud/panel.tscn")
const BLOOD_SPLATTER_DECAL_SCRIPT := preload("res://player/blood_splatter_decal.gd")
const PLAYER_DEATH_EFFECTS_SCRIPT := preload("res://player/player_death_effects.gd")
const PLAYER_SCENE := preload("res://player/player.tscn")
const RUBY_ITEM := preload("res://placeables/treasure/gems/ruby_inventory.tres")
const RUBY_SCENE := preload("res://placeables/treasure/gems/ruby.tscn")
const SAPPHIRE_ITEM := preload("res://placeables/treasure/gems/sapphire_inventory.tres")
const SAPPHIRE_SCENE := preload("res://placeables/treasure/gems/sapphire.tscn")
const SHOP_SCENE := preload("res://ui/frontend/shop.tscn")
const SETTINGS_SCENE := preload("res://ui/frontend/settings.tscn")
const PROCEDURAL_STAIRCASE_SCRIPT := preload(
    "res://placeables/stairs/procedural_staircase.gd"
)
const PROCEDURAL_STAIRCASE_SCENE := preload(
    "res://placeables/stairs/procedural_staircase.tscn"
)
const FRONTEND_GALLERY_SCENE := preload("res://ui/frontend/frontend_gallery.tscn")
const WIN_SCREEN_SCENE := preload("res://ui/screens/win_screen.tscn")
const LOSE_SCREEN_SCENE := preload("res://ui/screens/lose_screen.tscn")
const PNG_TO_GRIDMAP_ALTERNATIVE := preload("res://addons/png_to_gridmap/png_to_gridmap_autotile_alternative.gd")
const PNG_TO_GRIDMAP_AUTOTILE := preload("res://addons/png_to_gridmap/png_to_gridmap_autotile.gd")
const PNG_TO_GRIDMAP_AUTO_REPAIR_WATCH := preload(
    "res://addons/png_to_gridmap/png_to_gridmap_auto_repair_watch.gd"
)
const PNG_TO_GRIDMAP_COLOR_MAPPING := preload("res://addons/png_to_gridmap/png_to_gridmap_color_mapping.gd")
const PNG_TO_GRIDMAP_FLOOR_BUILDER := preload("res://addons/png_to_gridmap/png_to_gridmap_floor_builder.gd")
const PNG_TO_GRIDMAP_IMPORTER := preload("res://addons/png_to_gridmap/png_to_gridmap_importer.gd")
const PNG_TO_GRIDMAP_MAPPING_CATALOG := preload(
    "res://addons/png_to_gridmap/png_to_gridmap_mapping_catalog.gd"
)
const PNG_TO_GRIDMAP_PROFILE_STORE := preload("res://addons/png_to_gridmap/png_to_gridmap_profile_store.gd")
const PNG_TO_GRIDMAP_REPAIRER := preload("res://addons/png_to_gridmap/png_to_gridmap_repairer.gd")
const PNG_TO_GRIDMAP_RESOURCE_CATALOG := preload(
    "res://addons/png_to_gridmap/png_to_gridmap_resource_catalog.gd"
)
const PNG_TO_GRIDMAP_SETTINGS := preload("res://addons/png_to_gridmap/png_to_gridmap_settings.gd")
const SKELETON_SCENE := preload("res://enemies/skeleton.tscn")
const SILVER_KEY_SCENE := preload("res://inventory/silver_key.tscn")
const TEST_BOUNDARY_BLOCKER_COLLISION_LAYER := 16
const TEST_TEXT_OVERLAY_VISUAL_LAYER := 1 << 19
const TEST_RUN_RECORDING_DIRECTORY := "res://.godot/test_run_playbacks"
const TORCH_SCENE := preload("res://placeables/torch/torch.tscn")
const TREASURE_PILE_SCENE := preload("res://placeables/treasure/treasure_pile.tscn")
const VAMPIRE_MINIMAP_ROUTE_SCENE := preload(
    "res://levels/vampire-maze/minimap_route_overlay.tscn"
)
const VAMPIRE_GENERATED_MAZE_SCENE := preload(
    "res://levels/vampire-maze/generated_maze/generated_maze.tscn"
)
const VAMPIRE_GENERATED_CONTENT_PLANNER := preload(
    "res://levels/vampire-maze/generated_maze/generated_content_planner.gd"
)
const VAMPIRE_DEBUG_HUD_SCENE := preload(
    "res://ui/hud/vampire_debug/vampire_debug_hud.tscn"
)
const VAMPIRE_SCENE := preload("res://enemies/vampire/vampire.tscn")
const ZOMBIE_SCENE := preload("res://enemies/zombie.tscn")
const TEST_MINIMAP_ROUTE_VISUAL_LAYER := 1 << 18

const MAP_PLACEABLE_SCENE_PATHS: Array[String] = [
    "res://placeables/collectibles/flask_base.tscn",
    "res://placeables/collectibles/flask_bigger_sack.tscn",
    "res://placeables/collectibles/flask_breathing_space.tscn",
    "res://placeables/collectibles/flask_no_boundary.tscn",
    "res://placeables/collectibles/flask_pause_boundary.tscn",
    "res://placeables/collectibles/flask_pickup_radius.tscn",
    "res://placeables/collectibles/flask_poison.tscn",
    "res://placeables/collectibles/health_flask.tscn",
    "res://placeables/kill_boundary/kill_boundary.tscn",
    "res://placeables/lockables/locked_door.tscn",
    "res://placeables/lockables/locked_gate.tscn",
    "res://placeables/pushables/hay_bale_pushable.tscn",
    "res://placeables/pushables/millstone.tscn",
    "res://placeables/pushables/rolling_rock_pushable.tscn",
    "res://placeables/spike_trap/spike_trap.tscn",
    "res://placeables/stairs/procedural_staircase.tscn",
    "res://placeables/text_trigger/text_trigger.tscn",
    "res://placeables/torch/torch.tscn",
    "res://placeables/treasure_deposit/treasure_deposit_coffin.tscn",
    "res://placeables/treasure/gems/amethyst.tscn",
    "res://placeables/treasure/gems/diamond.tscn",
    "res://placeables/treasure/gems/emerald.tscn",
    "res://placeables/treasure/gems/ruby.tscn",
    "res://placeables/treasure/gems/sapphire.tscn",
    "res://placeables/treasure/gold_bar.tscn",
    "res://placeables/treasure/gold_coin.tscn",
    "res://placeables/treasure/gold_coin_pile.tscn",
    "res://placeables/treasure/treasure_pile.tscn",
    "res://enemies/bat_nest.tscn",
    "res://enemies/skeleton.tscn",
    "res://enemies/vampire/vampire.tscn",
    "res://enemies/zombie.tscn",
    "res://inventory/key.tscn",
    "res://inventory/silver_key.tscn",
]

const PHYSICS_DROP_PLACEABLE_SCENE_PATHS: Array[String] = [
    "res://placeables/collectibles/flask_base.tscn",
    "res://placeables/collectibles/flask_bigger_sack.tscn",
    "res://placeables/collectibles/flask_breathing_space.tscn",
    "res://placeables/collectibles/flask_no_boundary.tscn",
    "res://placeables/collectibles/flask_pause_boundary.tscn",
    "res://placeables/collectibles/flask_pickup_radius.tscn",
    "res://placeables/collectibles/flask_poison.tscn",
    "res://placeables/collectibles/health_flask.tscn",
    "res://placeables/pushables/millstone.tscn",
    "res://placeables/pushables/rolling_rock_pushable.tscn",
    "res://placeables/treasure_deposit/treasure_deposit_coffin.tscn",
    "res://placeables/treasure/gems/amethyst.tscn",
    "res://placeables/treasure/gems/diamond.tscn",
    "res://placeables/treasure/gems/emerald.tscn",
    "res://placeables/treasure/gems/ruby.tscn",
    "res://placeables/treasure/gems/sapphire.tscn",
    "res://placeables/treasure/gold_bar.tscn",
    "res://placeables/treasure/gold_coin.tscn",
    "res://inventory/key.tscn",
    "res://inventory/silver_key.tscn",
]

enum TestAutotileItem {
    Base = 1,
    Solo = 2,
    End = 3,
    Corner = 4,
    Tee = 5,
    Cross = 6,
    FloorBase = 7,
    FloorSolo = 8,
    AltWallBase = 9,
    AltWallEnd = 10,
}

class TestGraveyard:
    extends GDGraveyard

    var win_requested := false


    func _store_result_stats() -> void:
        pass


    func _get_result_stats() -> Node:
        return null


    func _show_win_screen() -> void:
        win_requested = true


    func start_kill_boundary_for_test() -> void:
        _configure_kill_boundary_animation()


    func get_kill_boundary_for_test() -> Node:
        return _get_kill_boundary()


class TestKillBoundary:
    extends GDKillBoundary3D

    var sink_requested := false


    func _create_near_flame_audio() -> void:
        pass


    func _sink_removed_boundary(_seconds: float, _distance: float) -> void:
        sink_requested = true


class TestLevelSelection:
    extends GDLevelSelection


    func _save_results() -> void:
        pass


    func migrate_results_for_test(stored_results: Dictionary) -> Dictionary:
        return _migrate_legacy_results(stored_results)


    func resolve_highlighted_index_for_test(stored_results: Dictionary) -> int:
        return _resolve_saved_highlighted_level_index(stored_results)


class TestShutdownRecorder:
    extends Node

    var finish_called := false


    func _ready() -> void:
        add_to_group(GDRunRecorder.RUN_RECORDER_GROUP)


    func finish_recording() -> PackedByteArray:
        finish_called = true
        return PackedByteArray()


class TestGameSettings:
    extends GDGameSettings

    var save_count := 0


    func _load_settings() -> void:
        pass


    func _apply_audio_settings() -> void:
        pass


    func _save_settings() -> void:
        save_count += 1
        save_pending = false


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


class TestTorch:
    extends "res://placeables/torch/torch.gd"

    var level_selection: Node


    func _get_level_selection() -> Node:
        return level_selection


class TestVampireVictim:
    extends Node3D

    var killed := false


    func _ready() -> void:
        add_to_group(&"player")


    func is_dead() -> bool:
        return killed


    func die_from_vampire() -> void:
        killed = true


class TestSkeletonVictim:
    extends Node3D

    var killed_by_enemy := false
    var killed_by_fire := false


    func is_dead() -> bool:
        return killed_by_enemy or killed_by_fire


    func die_from_enemy() -> void:
        killed_by_enemy = true


    func die_from_flames() -> void:
        killed_by_fire = true


class TestGeneratedPlayer:
    extends CharacterBody3D


class TestVampireSearchBody:
    extends CharacterBody3D

    var selected_search_target := Vector3.ZERO


    func search_route(search_position: Vector3) -> void:
        selected_search_target = search_position


class TestVampireLayoutNavigation:
    extends Node


    func get_path_distance(origin: Vector3, destination: Vector3) -> float:
        var offset := destination - origin
        return Vector2(offset.x, offset.z).length()


    func get_path_departure_direction(
        origin: Vector3,
        destination: Vector3
    ) -> Vector3:
        var direction := destination - origin
        direction.y = 0.0
        return direction.normalized()


class TestVampirePositionSenses:
    extends Node


    func can_verify_position_is_empty(_position: Vector3) -> bool:
        return true


class TestKillBoundaryVictim:
    extends Node3D

    var immune_to_kill_boundary := true
    var received_damage := 0.0
    var last_damage_was_fire := false


    func is_immune_to_kill_boundary() -> bool:
        return immune_to_kill_boundary


    func apply_kill_boundary_damage(amount: float, causes_fire_death: bool) -> void:
        received_damage += amount
        last_damage_was_fire = causes_fire_death


func _init() -> void:
    _run_tests.call_deferred()


func _run_tests() -> void:
    var failed := false
    failed = not _test_deterministic_seed_helper_is_stable() or failed
    failed = not _test_environment_objects_keep_authored_collision() or failed
    failed = not _test_graveyard_mesh_library_references_use_stable_paths() or failed
    failed = not _test_map_placeables_share_spawn_time_and_physics_capabilities() or failed
    failed = not _test_millstone_rolls_on_one_axis_and_only_crushes_while_moving() or failed
    failed = not _test_debug_level_sequences_spawn_reviews_once_per_second() or failed
    failed = not _test_debug_level_enemy_patrols_ping_pong() or failed
    failed = not await _test_placeable_spawn_time_delays_and_drops_items() or failed
    failed = not await _test_static_placeable_spawn_presentations() or failed
    failed = not _test_codex_session_options_require_explicit_directed_test_data() or failed
    failed = not _test_run_recording_preserves_compact_frame_timing_and_controls() or failed
    failed = not _test_run_recorder_skips_freed_drift_nodes() or failed
    failed = not await _test_quick_exit_flushes_run_recording_tasks() or failed
    failed = not _test_coin_pile_derives_stable_seed_and_disables_camera_gate_by_default() or failed
    failed = not _test_treasure_pile_discovers_compatible_scenes_and_spawns_mixed_counts() \
        or failed
    failed = not _test_debug_level_total_includes_authored_loose_treasure() or failed
    failed = not _test_diamond_collectible_value_and_material() or failed
    failed = not _test_gem_variants_use_icon_cuts_and_scale_values() or failed
    failed = not _test_audio_fallback_is_deterministic() or failed
    failed = not _test_frontend_audio_uses_shared_support() or failed
    failed = not _test_letterbox_background_is_black() or failed
    failed = not await _test_screen_fade_finishes_while_paused() or failed
    failed = not await _test_feedback_pause_restores_prior_pause_state() or failed
    failed = not await _test_feedback_dialog_uses_large_game_font() or failed
    failed = not await _test_game_settings_batch_disk_writes() or failed
    failed = not _test_player_landing_uses_new_sample_after_a_meaningful_fall() or failed
    failed = not _test_player_fall_death_threshold() or failed
    failed = not await _test_pickup_radius_flasks_stack_and_expire_independently() or failed
    failed = not _test_pickup_radius_does_not_affect_treasure_deposit_range() or failed
    failed = not await _test_player_death_uses_face_blood_and_body_throes() or failed
    failed = not await _test_fire_boundary_death_blackens_and_burns_player() or failed
    failed = not _test_torch_scene_and_persistent_activation() or failed
    failed = not _test_indoor_lighting_strengthens_occlusion() or failed
    failed = not _test_held_drop_input_accelerates() or failed
    failed = not _test_drop_direction_variation_is_deterministic_and_compact() or failed
    failed = not _test_all_treasure_uses_indoor_lighting_and_coin_outline() or failed
    failed = not await _test_gold_bar_uses_inventory_capacity_and_physics_drop() or failed
    failed = not await _test_dense_coin_pile_collection_is_bounded() or failed
    failed = not _test_result_percentage_uses_mixed_treasure_value() or failed
    failed = not _test_typed_treasure_wallet_and_shop_purchases() or failed
    failed = not _test_treasure_absorption_does_not_complete_level() or failed
    failed = not _test_gate_completion_completes_level() or failed
    failed = not _test_optional_scene_node_paths_are_empty_or_valid() or failed
    failed = not _test_reusable_gate_and_treasure_deposit_coffin_scenes() or failed
    failed = not _test_coffin_deposit_jumps_move_two_extra_coins() or failed
    failed = not _test_stairwell_scopes_kill_boundary_immunity() or failed
    failed = not _test_kill_boundary_ignores_zombies_and_skeletons() or failed
    failed = not _test_key_scenes_have_authored_pickup_areas_and_landing_audio() or failed
    failed = not _test_graveyard_scene_does_not_embed_default_level() or failed
    failed = not _test_level_lookup_supports_debug_and_stable_ids() or failed
    failed = not _test_level_selection_tracks_outcomes_and_highlight() or failed
    failed = not _test_level_progress_uses_stable_mapping_ids() or failed
    failed = not await _test_level_select_scrolls_focused_cards_into_view() or failed
    failed = not _test_kill_boundary_loop_setting() or failed
    failed = not _test_kill_boundary_size_does_not_scale_center() or failed
    failed = not _test_kill_boundary_missing_scale_tracks_use_identity_scale() or failed
    failed = not _test_new_kill_boundary_animation_has_default_size_keys() or failed
    failed = not _test_new_kill_boundary_animation_uses_path_duration() or failed
    failed = not _test_existing_kill_boundary_animation_gains_size_tracks() or failed
    failed = not _test_rectangular_kill_boundary_keeps_square_corners_at_non_square_size() or failed
    failed = not _test_kill_boundary_animation_marks_path_point_times() or failed
    failed = not _test_kill_boundary_markers_extend_animation_to_path_end() or failed
    failed = not _test_kill_boundary_path_markers_wait_for_stable_curve() or failed
    failed = not _test_kill_boundary_speed_edit_ripple_retimes_other_keys() or failed
    failed = not _test_kill_boundary_speed_edit_retimes_incoming_linear_interval() or failed
    failed = not _test_graveyard_starts_refactored_kill_boundary_animation() or failed
    failed = not _test_production_kill_boundaries_use_equivalent_size_tracks() or failed
    failed = not _test_no_boundary_removal_keeps_current_pose() or failed
    failed = not _test_level_settings_control_minimap_visibility() or failed
    failed = not _test_low_health_vignette_maps_health_to_warning_intensity() or failed
    failed = not _test_hud_panel_sets_split_value_labels() or failed
    failed = not await _test_shop_uses_reusable_resizable_frames() or failed
    failed = not _test_frontend_gallery_instances_navigable_screens() or failed
    failed = not await _test_result_screens_and_settings_share_frontend_design() or failed
    failed = not _test_enemies_use_fake_shadows_without_warning_light_blobs() or failed
    failed = not _test_vampire_settings_prioritize_core_controls() or failed
    failed = not await _test_characters_glance_and_return_with_safe_head_turns() or failed
    failed = not _test_vampire_layout_knowledge_ages_and_filters_evidence() or failed
    failed = not _test_vampire_hunt_resets_and_scans_with_frame_delta() or failed
    failed = not await _test_vampire_boss_routes_to_noise_and_kills_on_contact() or failed
    failed = not _test_vampire_navigation_reports_scaled_search_contract() or failed
    failed = not _test_vampire_maze_owns_its_development_view() or failed
    failed = not _test_vampire_minimap_reports_live_belief_and_route_state() or failed
    failed = not _test_generated_maze_floor_settings() or failed
    failed = not _test_vampire_maze_generates_seeded_grid_maps() or failed
    failed = not _test_vampire_maze_exit_key_requires_exploration() or failed
    failed = not _test_vampire_maze_minimap_shows_all_shortest_routes() or failed
    failed = not _test_skeleton_contact_uses_non_fire_death() or failed
    failed = not _test_skeleton_facing_is_driven_by_movement() or failed
    failed = not _test_skeleton_uses_dedicated_movement_audio() or failed
    failed = not _test_zombie_spawn_uses_existing_enemy_landing_audio() or failed
    failed = not await _test_ground_enemies_block_each_other() or failed
    failed = not await _test_ground_enemies_fall_before_moving() or failed
    failed = not _test_minimap_disables_processing_and_rendering() or failed
    failed = not _test_minimap_left_trigger_expands_and_restores_layout() or failed
    failed = not _test_minimap_camera_scrolls_wide_level_without_empty_space() or failed
    failed = not _test_minimap_camera_scrolls_tall_level_without_empty_space() or failed
    failed = not _test_bat_nest_swarms_then_rises_away() or failed
    failed = not _test_bat_nest_camera_scare_grows_one_bat() or failed
    failed = not _test_gridmap_repair_uses_configured_connection_groups() or failed
    failed = not _test_gridmap_repair_merges_equivalent_configurations() or failed
    failed = not _test_gridmap_repair_preserves_only_matching_alternatives() or failed
    failed = not _test_gridmap_repair_matches_updated_wall_mesh_orientations() or failed
    failed = not _test_auto_repair_watches_mapping_configuration_changes() or failed
    failed = not _test_png_mapping_catalog_supports_manual_add_and_remove() or failed
    failed = not _test_graveyard_wall_profile_uses_updated_mesh_offsets() or failed
    failed = not _test_png_profile_store_only_accepts_level_subfolders() or failed
    failed = not _test_png_profile_store_resets_unsaved_level_state() or failed
    failed = not _test_png_resource_catalog_selects_only_gridmap() or failed
    failed = not _test_level_one_enables_gridmap_auto_repair() or failed
    failed = not _test_png_floor_gridmap_uses_non_transparent_pixels_and_safe_collision() or failed
    failed = not _test_png_gridmap_import_disables_y_cell_centering() or failed
    await process_frame
    quit(1 if failed else 0)


func _test_environment_objects_keep_authored_collision() -> bool:
    var expectations: Array[Dictionary] = [
        {
            "path": "res://placeables/environment/fence/fence.tscn",
            "position": Vector3(-0.001435, 0.449779, -0.00287),
            "size": Vector3(1.009926, 0.899558, 0.312569),
        },
        {
            "path": "res://placeables/environment/tombstone/tombstone.tscn",
            "position": Vector3(-0.05883, 0.582565, -0.020088),
            "size": Vector3(0.413012, 1.156285, 1.041493),
        },
    ]
    var passed := true
    for expectation in expectations:
        var scene_path := String(expectation["path"])
        var packed_scene := load(scene_path) as PackedScene
        var object: Node3D = null
        if packed_scene != null:
            object = packed_scene.instantiate() as Node3D
        var mesh: MeshInstance3D = null
        var body: StaticBody3D = null
        var collision: CollisionShape3D = null
        if object != null:
            mesh = object.get_node_or_null(^"Mesh") as MeshInstance3D
            body = object.get_node_or_null(^"StaticBody3D") as StaticBody3D
            collision = object.get_node_or_null(^"StaticBody3D/CollisionShape3D") \
                as CollisionShape3D
        var box: BoxShape3D = null
        if collision != null:
            box = collision.shape as BoxShape3D
        passed = _expect(
            mesh != null and mesh.mesh != null,
            "%s keeps its extracted Blender mesh" % scene_path
        ) and passed
        passed = _expect(
            body != null and body.collision_layer == 1,
            "%s provides world collision when placed outside a GridMap" % scene_path
        ) and passed
        passed = _expect(
            collision != null \
                and collision.position.is_equal_approx(expectation["position"] as Vector3) \
                and box != null \
                and box.size.is_equal_approx(expectation["size"] as Vector3),
            "%s keeps the Blender-authored collision bounds" % scene_path
        ) and passed
        if object != null:
            object.free()
    return passed


func _test_graveyard_mesh_library_references_use_stable_paths() -> bool:
    var level_scene_paths: Array[String] = [
        "res://levels/1/level.tscn",
        "res://levels/2/level.tscn",
        "res://levels/3/level.tscn",
        "res://levels/4/level.tscn",
        "res://levels/6/level.tscn",
        "res://levels/7/level.tscn",
        "res://levels/8/level.tscn",
        "res://levels/debug-level/level.tscn",
        "res://levels/graveyard/level.tscn",
    ]
    var passed := true
    for scene_path: String in level_scene_paths:
        var scene_source := FileAccess.get_file_as_string(scene_path)
        passed = _expect(
            scene_source.contains('path="res://Assets/environment/graveyard.res"') \
                and not scene_source.contains('uid="uid://c26i1gkgrxvs7"'),
            "%s references the rebuilt Graveyard MeshLibrary by its stable path" % scene_path
        ) and passed
    return passed


func _test_map_placeables_share_spawn_time_and_physics_capabilities() -> bool:
    var passed := true
    for scene_path in MAP_PLACEABLE_SCENE_PATHS:
        var packed_scene := load(scene_path) as PackedScene
        var placeable: Node3D
        if packed_scene != null:
            placeable = packed_scene.instantiate() as Node3D
        passed = _expect(
            placeable != null and _object_has_property(placeable, &"spawn_time"),
            "%s exposes Spawn Time on its placeable root" % scene_path
        ) and passed
        if PHYSICS_DROP_PLACEABLE_SCENE_PATHS.has(scene_path):
            passed = _expect(
                placeable is RigidBody3D and _object_has_property(placeable, &"spawn_drop_height"),
                "%s is marked as a gravity drop-capable placeable" % scene_path
            ) and passed
        if placeable != null:
            placeable.free()

    var pile := TREASURE_PILE_SCENE.instantiate()
    pile.set(&"trigger_time", 2.5)
    passed = _expect(
        is_equal_approx(float(pile.get(&"spawn_time")), 2.5),
        "legacy treasure-pile trigger time mirrors the shared Spawn Time field"
    ) and passed
    pile.free()

    var skeleton := SKELETON_SCENE.instantiate()
    skeleton.set(&"drop_in_time", 3.5)
    passed = _expect(
        is_equal_approx(float(skeleton.get(&"spawn_time")), 3.5),
        "legacy enemy drop-in time mirrors the shared Spawn Time field"
    ) and passed
    skeleton.free()
    return passed


func _test_millstone_rolls_on_one_axis_and_only_crushes_while_moving() -> bool:
    var millstone_scene := load(
        "res://placeables/pushables/millstone.tscn"
    ) as PackedScene
    var millstone := millstone_scene.instantiate() as Millstone
    var passed := _expect(
        millstone != null and is_equal_approx(millstone.mass, 1000.0),
        "the placeable millstone reuses the rolling rock's resistance"
    )
    if millstone == null:
        return false

    var millstone_level_paths: Array[String] = [
        "res://levels/1/level.tscn",
        "res://levels/debug-level/level.tscn",
    ]
    for level_path: String in millstone_level_paths:
        var level_source := FileAccess.get_file_as_string(level_path)
        passed = _expect(
            level_source.contains(
                'path="res://placeables/pushables/millstone.tscn"'
            ),
            "%s instances the physics millstone rather than its static art source" % level_path
        ) and passed

    var collision_shape := millstone.get_node_or_null(^"CollisionShape3D") as CollisionShape3D
    var cylinder: CylinderShape3D = null
    if collision_shape != null:
        cylinder = collision_shape.shape as CylinderShape3D
    passed = _expect(
        cylinder != null \
            and is_equal_approx(cylinder.radius, 0.5) \
            and is_equal_approx(cylinder.height, 0.5),
        "the millstone uses a cylinder physics shape matching its model"
    ) and passed
    passed = _expect(
        not millstone.constrain_to_starting_height \
            and not millstone.axis_lock_linear_y \
            and millstone.gravity_scale > 0.0,
        "the millstone falls when it rolls beyond supporting ground"
    ) and passed
    passed = _expect(
        millstone.audio_fade_out_seconds >= 0.15 \
            and millstone.trapped_audio_fade_seconds >= 0.1,
        "the millstone rolling sound fades quickly instead of cutting off"
    ) and passed
    millstone.has_rolling_audio_ground_contact = true
    passed = _expect(
        is_equal_approx(millstone._get_audible_rolling_speed(2.0), 2.0),
        "the millstone rolling sound follows movement while supported by ground"
    ) and passed
    millstone.has_rolling_audio_ground_contact = false
    passed = _expect(
        is_zero_approx(millstone._get_audible_rolling_speed(2.0)),
        "the millstone rolling sound fades out when movement continues in the air"
    ) and passed

    millstone.push_from_character(Vector3.RIGHT, Vector3.LEFT, 0.016)
    passed = _expect(
        millstone.recent_push_direction.is_equal_approx(Vector3.RIGHT),
        "the millstone accepts a push from either rolling end"
    ) and passed
    millstone.recent_push_direction = Vector3.ZERO
    millstone.recent_push_timer = 0.0
    millstone.push_from_character(Vector3.FORWARD, Vector3.BACK, 0.016)
    passed = _expect(
        millstone.recent_push_direction.is_zero_approx(),
        "the millstone rejects pushes against either axle face"
    ) and passed

    var sliding_velocity := Vector3.RIGHT + Vector3.FORWARD * 2.0
    var assisted_velocity := millstone.get_character_push_assist_velocity(
        Vector3.RIGHT * 5.0,
        sliding_velocity,
        Vector3.LEFT,
        0.1
    )
    passed = _expect(
        absf(assisted_velocity.z) < absf(sliding_velocity.z) \
            and absf(assisted_velocity.z) > 0.0,
        "the millstone gently reduces sideways sliding without locking the player"
    ) and passed
    var escape_velocity := Vector3.FORWARD * 2.0
    passed = _expect(
        millstone.get_character_push_assist_velocity(
            escape_velocity,
            escape_velocity,
            Vector3.LEFT,
            0.1
        ).is_equal_approx(escape_velocity),
        "the millstone releases alignment assistance as soon as the player steers away"
    ) and passed

    var skeleton := SKELETON_SCENE.instantiate() as GDSkeletonPath
    var zombie := ZOMBIE_SCENE.instantiate() as GDZombiePath
    millstone.linear_velocity = Vector3.ZERO
    passed = _expect(
        not skeleton._is_rolling_ball_body(millstone) \
            and not zombie._is_rolling_ball_body(millstone),
        "a stationary millstone cannot kill skeletons or zombies"
    ) and passed
    var enemy_crush_speed := float(millstone.get(&"enemy_crush_speed"))
    millstone.linear_velocity = Vector3.RIGHT * enemy_crush_speed
    passed = _expect(
        skeleton._is_rolling_ball_body(millstone) \
            and zombie._is_rolling_ball_body(millstone),
        "a rolling millstone can kill skeletons and zombies"
    ) and passed

    skeleton.free()
    zombie.free()
    millstone.free()
    return passed


func _test_debug_level_sequences_spawn_reviews_once_per_second() -> bool:
    var debug_level_scene := load("res://levels/debug-level/level.tscn") as PackedScene
    var debug_level := debug_level_scene.instantiate() as Node3D
    var spawn_review_paths: Array[NodePath] = [
        ^"GDFlaskNoBoundary2",
        ^"GDFlaskBiggerSack2",
        ^"Zombie/GDFlaskBreathingSpace",
        ^"Zombie/GDFlaskPauseBoundary",
        ^"Zombie/GDFlaskPickupRadius",
        ^"Zombie/GDFlaskPoison",
        ^"Zombie/GDHealthFlask",
        ^"Zombie/LockedDoor",
        ^"Zombie/SilverKey",
        ^"Zombie/LockedGate",
        ^"Zombie/Key",
        ^"Zombie/HayBalePushable",
        ^"Zombie/RollingRockPushable",
        ^"Zombie/SpikeTrap",
        ^"Zombie/GDTextTrigger",
        ^"Zombie/Torch",
        ^"Zombie/TreasureDepositCoffin",
        ^"Zombie/Amethyst",
        ^"Zombie/Diamond",
        ^"Zombie/Emerald",
        ^"Zombie/Ruby",
        ^"Zombie/Sapphire",
        ^"Zombie/GoldBar",
        ^"Zombie/GoldCoinPile",
        ^"Zombie/TreasurePile",
        ^"Zombie/BatNest",
        ^"Zombie/Skeleton",
        ^"Zombie/Zombie",
    ]
    var sequence_is_complete := debug_level != null
    for spawn_index in spawn_review_paths.size():
        var placeable: Node = null
        if debug_level != null:
            placeable = debug_level.get_node_or_null(spawn_review_paths[spawn_index])
        if placeable == null \
                or not _object_has_property(placeable, &"spawn_time") \
                or not is_equal_approx(float(placeable.get(&"spawn_time")), spawn_index + 1.0):
            sequence_is_complete = false
            break

    var popup_trigger: GDTextTrigger = null
    var pause_trigger: GDTextTrigger = null
    if debug_level != null:
        popup_trigger = debug_level.get_node_or_null(^"GDTextTriggerPopup") as GDTextTrigger
        pause_trigger = debug_level.get_node_or_null(^"GDTextTriggerPause") as GDTextTrigger
    var showcases_both_modes := popup_trigger != null \
        and not popup_trigger.pause_game_with_text \
        and pause_trigger != null \
        and pause_trigger.pause_game_with_text
    var continue_button: Button = null
    if pause_trigger != null:
        continue_button = pause_trigger.get_node_or_null(^"PauseLayer/ContinueButton") as Button
    var uses_large_primary_action := continue_button != null \
        and continue_button.custom_minimum_size == Vector2(440.0, 112.0) \
        and is_equal_approx(continue_button.offset_top, -332.0) \
        and is_equal_approx(continue_button.offset_bottom, -220.0) \
        and continue_button.theme.resource_path == "res://ui/frontend/frontend_theme.tres" \
        and continue_button.get_theme_font_size(&"font_size") == 64
    var primary_action := InputEventJoypadButton.new()
    primary_action.button_index = JOY_BUTTON_A
    primary_action.pressed = true
    var secondary_action := InputEventJoypadButton.new()
    secondary_action.button_index = JOY_BUTTON_B
    secondary_action.pressed = true
    uses_large_primary_action = uses_large_primary_action \
        and pause_trigger.call("_is_continue_input", primary_action) \
        and not pause_trigger.call("_is_continue_input", secondary_action)
    if debug_level != null:
        debug_level.free()
    return _expect(
        sequence_is_complete,
        "the debug-level spawn-review row runs once per second from 1 through 28"
    ) and _expect(
        showcases_both_modes,
        "the debug level extends the potion showcase with popup and pausing text triggers"
    ) and _expect(
        uses_large_primary_action,
        "pausing text uses a large Continue button above the HUD and only the primary action"
    )


func _test_debug_level_enemy_patrols_ping_pong() -> bool:
    var debug_level_scene := load("res://levels/debug-level/level.tscn") as PackedScene
    var debug_level := debug_level_scene.instantiate() as Node3D
    var enemy_paths: Array[NodePath] = [
        ^"Skeleton",
        ^"Zombie",
        ^"Zombie/Skeleton",
        ^"Zombie/Zombie",
    ]
    var patrols_ping_pong := debug_level != null
    for enemy_path in enemy_paths:
        var enemy: Node = null
        var path_follow: PathFollow3D = null
        var patrol_curve: Curve3D = null
        if debug_level != null:
            enemy = debug_level.get_node_or_null(enemy_path)
        if enemy != null:
            path_follow = enemy.get_node_or_null("PathFollow3D") as PathFollow3D
            patrol_curve = enemy.get("curve") as Curve3D
        if enemy == null \
                or bool(enemy.get("loop_patrol")) \
                or not bool(enemy.get("reverse_at_path_ends")) \
                or patrol_curve == null \
                or patrol_curve.closed \
                or path_follow == null \
                or path_follow.loop:
            patrols_ping_pong = false
            break

    if debug_level != null:
        debug_level.free()
    return _expect(
        patrols_ping_pong,
        "the debug level's original and timed enemy patrols reverse instead of wrapping"
    )


func _test_placeable_spawn_time_delays_and_drops_items() -> bool:
    var existing_key := KEY_SCENE.instantiate() as RigidBody3D
    root.add_child(existing_key)
    var passed := _expect(
        existing_key.visible \
            and not existing_key.freeze \
            and existing_key.get(&"placeable_spawn_controller") == null,
        "Spawn Time zero leaves an already-present physics item untouched"
    )
    existing_key.queue_free()

    var existing_flask := HEALTH_FLASK_SCENE.instantiate() as RigidBody3D
    root.add_child(existing_flask)
    passed = _expect(
        existing_flask.freeze \
            and existing_flask.get(&"placeable_spawn_controller") == null \
            and is_zero_approx(existing_flask.angular_velocity.length()),
        "Spawn Time zero keeps an authored flask fixed in place"
    ) and passed
    var flask_physics_material := existing_flask.physics_material_override
    var base_collision := existing_flask.get_node_or_null("BaseCollisionShape") \
        as CollisionShape3D
    var body_collision := existing_flask.get_node_or_null("BodyCollisionShape") \
        as CollisionShape3D
    var neck_collision := existing_flask.get_node_or_null("NeckCollisionShape") \
        as CollisionShape3D
    var rim_collision := existing_flask.get_node_or_null("RimCollisionShape") \
        as CollisionShape3D
    var stopper_collision := existing_flask.get_node_or_null("StopperCollisionShape") \
        as CollisionShape3D
    var base_shape: CylinderShape3D
    var body_shape: SphereShape3D
    var neck_shape: CylinderShape3D
    var rim_shape: CylinderShape3D
    var stopper_shape: CylinderShape3D
    if base_collision != null:
        base_shape = base_collision.shape as CylinderShape3D
    if body_collision != null:
        body_shape = body_collision.shape as SphereShape3D
    if neck_collision != null:
        neck_shape = neck_collision.shape as CylinderShape3D
    if rim_collision != null:
        rim_shape = rim_collision.shape as CylinderShape3D
    if stopper_collision != null:
        stopper_shape = stopper_collision.shape as CylinderShape3D
    passed = _expect(
        flask_physics_material != null \
            and is_equal_approx(flask_physics_material.bounce, 0.12) \
            and is_equal_approx(flask_physics_material.friction, 0.45) \
            and is_equal_approx(existing_flask.linear_damp, 0.25) \
            and is_equal_approx(existing_flask.angular_damp, 0.9) \
            and existing_flask.contact_monitor \
            and existing_flask.max_contacts_reported == 8 \
            and base_collision != null \
            and base_shape != null \
            and body_collision != null \
            and body_shape != null \
            and neck_collision != null \
            and neck_shape != null \
            and rim_collision != null \
            and rim_shape != null \
            and stopper_collision != null \
            and stopper_shape != null \
            and is_equal_approx(base_shape.radius, 0.061) \
            and is_equal_approx(body_shape.radius, 0.11) \
            and is_equal_approx(neck_shape.radius, 0.042) \
            and is_equal_approx(rim_shape.radius, 0.053) \
            and is_equal_approx(stopper_shape.radius, 0.027),
        "flasks use a measured, lightly bouncing bottle collider that settles after rolling"
    ) and passed
    existing_flask.set(&"previous_linear_velocity", Vector3.DOWN * 4.0)
    var impact_body := StaticBody3D.new()
    existing_flask.call("_on_physics_body_entered", impact_body)
    var impact_audio := existing_flask.get_node_or_null("FlaskImpactAudio") \
        as AudioStreamPlayer3D
    passed = _expect(
        impact_audio != null \
            and impact_audio.stream != null \
            and impact_audio.bus == &"SFX" \
            and is_equal_approx(impact_audio.volume_db, 6.0) \
            and is_equal_approx(impact_audio.max_distance, 64.0) \
            and is_equal_approx(impact_audio.unit_size, 16.0),
        "a substantial flask collision plays its shared sample through spatial SFX audio"
    ) and passed
    impact_body.free()
    existing_flask.queue_free()

    var static_placeable := PLACEABLE_SCRIPT.new() as Node3D
    var trigger_area := Area3D.new()
    trigger_area.collision_layer = 1
    trigger_area.collision_mask = 2
    static_placeable.add_child(trigger_area)
    static_placeable.set(&"spawn_time", 0.04)
    root.add_child(static_placeable)
    await physics_frame
    passed = _expect(
        not static_placeable.visible \
            and trigger_area.collision_layer == 0 \
            and trigger_area.collision_mask == 0,
        "a positive Spawn Time suspends a non-physics placeable while it waits"
    )
    await physics_frame
    await physics_frame
    await physics_frame
    passed = _expect(
        static_placeable.visible \
            and static_placeable.is_in_group(&"map_placeable") \
            and trigger_area.collision_layer == 1 \
            and trigger_area.collision_mask == 2,
        "a non-physics placeable and its collisions activate at Spawn Time"
    ) and passed
    static_placeable.queue_free()

    var delayed_keys: Array[RigidBody3D] = [
        KEY_SCENE.instantiate() as RigidBody3D,
        SILVER_KEY_SCENE.instantiate() as RigidBody3D,
    ]
    var authored_key_positions: Array[Vector3] = []
    var authored_key_bases: Array[Basis] = []
    for key_index in delayed_keys.size():
        var delayed_key := delayed_keys[key_index]
        delayed_key.set(&"spawn_time", 0.04)
        delayed_key.set(&"spawn_drop_height", 1.5)
        delayed_key.position.x = float(key_index) * 2.0
        authored_key_positions.append(delayed_key.position)
        authored_key_bases.append(delayed_key.basis)
        root.add_child(delayed_key)
    await physics_frame
    var keys_waiting := true
    for delayed_key in delayed_keys:
        keys_waiting = keys_waiting and not delayed_key.visible and delayed_key.freeze
    passed = _expect(
        keys_waiting,
        "delayed gold and silver keys stay hidden and frozen before spawning"
    ) and passed
    await physics_frame
    await physics_frame
    await physics_frame
    var keys_released_with_physics := true
    for key_index in delayed_keys.size():
        var delayed_key := delayed_keys[key_index]
        keys_released_with_physics = keys_released_with_physics \
            and delayed_key.visible \
            and delayed_key.global_position.y > authored_key_positions[key_index].y + 1.0 \
            and not delayed_key.freeze \
            and not delayed_key.basis.is_equal_approx(authored_key_bases[key_index]) \
            and delayed_key.angular_velocity.length() > 0.0
    passed = _expect(
        keys_released_with_physics,
        "timed gold and silver keys tumble into the level under rigid-body physics"
    ) and passed
    for delayed_key in delayed_keys:
        delayed_key.queue_free()

    var existing_coffin := TREASURE_DEPOSIT_COFFIN_SCENE.instantiate() as RigidBody3D
    root.add_child(existing_coffin)
    var coffin_collision := existing_coffin.get_node_or_null("CollisionShape3D") \
        as CollisionShape3D
    var coffin_shape: BoxShape3D
    if coffin_collision != null:
        coffin_shape = coffin_collision.shape as BoxShape3D
    var imported_coffin_body := existing_coffin.get_node_or_null(
        "CoffinVisual/coffin/StaticBody3D"
    ) as StaticBody3D
    passed = _expect(
        existing_coffin.freeze \
            and existing_coffin.get(&"placeable_spawn_controller") == null \
            and coffin_collision != null \
            and coffin_shape != null \
            and coffin_shape.size.is_equal_approx(Vector3(0.573807, 0.325, 0.837824)) \
            and imported_coffin_body != null \
            and imported_coffin_body.collision_layer == 0 \
            and imported_coffin_body.collision_mask == 0,
        "an already-present deposit coffin stays fixed with one measured physics collider"
    ) and passed
    existing_coffin.queue_free()

    var delayed_coffin := TREASURE_DEPOSIT_COFFIN_SCENE.instantiate() as RigidBody3D
    delayed_coffin.set(&"spawn_time", 0.04)
    delayed_coffin.set(&"spawn_drop_height", 1.5)
    delayed_coffin.position.x = 4.0
    var authored_coffin_position := delayed_coffin.position
    var authored_coffin_basis := delayed_coffin.basis
    root.add_child(delayed_coffin)
    await physics_frame
    passed = _expect(
        not delayed_coffin.visible and delayed_coffin.freeze,
        "a timed deposit coffin stays hidden and frozen before spawning"
    ) and passed
    await physics_frame
    await physics_frame
    await physics_frame
    passed = _expect(
        delayed_coffin.visible \
            and delayed_coffin.global_position.y > authored_coffin_position.y + 1.0 \
            and not delayed_coffin.freeze \
            and not delayed_coffin.basis.is_equal_approx(authored_coffin_basis) \
            and delayed_coffin.angular_velocity.length() > 2.5,
        "a positive Spawn Time drops and tumbles the deposit coffin under rigid-body physics"
    ) and passed
    delayed_coffin.set(&"previous_linear_velocity", Vector3.DOWN * 4.0)
    var coffin_impact_body := StaticBody3D.new()
    coffin_impact_body.collision_layer = 1
    delayed_coffin.call("_on_landing_body_entered", coffin_impact_body)
    var coffin_landing_audio := delayed_coffin.get_node_or_null("CoffinLandingAudio") \
        as AudioStreamPlayer3D
    passed = _expect(
        coffin_landing_audio != null \
            and coffin_landing_audio.stream != null \
            and coffin_landing_audio.stream.resource_path \
                == "res://Assets/audio/coffin-landing.mp3" \
            and coffin_landing_audio.bus == &"SFX" \
            and is_equal_approx(coffin_landing_audio.volume_db, 4.0),
        "the deposit coffin plays its supplied spatial impact sample on landing"
    ) and passed
    coffin_impact_body.free()
    delayed_coffin.queue_free()

    var flask := HEALTH_FLASK_SCENE.instantiate() as RigidBody3D
    flask.set(&"spawn_time", 0.04)
    flask.set(&"spawn_drop_height", 1.5)
    var authored_flask_position := flask.position
    var authored_flask_basis := flask.basis
    root.add_child(flask)
    var second_flask := HEALTH_FLASK_SCENE.instantiate() as RigidBody3D
    second_flask.set(&"spawn_time", 0.04)
    second_flask.set(&"spawn_drop_height", 1.5)
    second_flask.position.x = 2.0
    root.add_child(second_flask)
    await physics_frame
    passed = _expect(
        not flask.visible \
            and flask.freeze \
            and not second_flask.visible \
            and second_flask.freeze,
        "a delayed flask remains hidden and frozen before spawning"
    ) and passed
    await physics_frame
    await physics_frame
    await physics_frame
    var flask_visual := flask.get_node("Visual") as Node3D
    passed = _expect(
        flask.visible \
            and flask.global_position.y > authored_flask_position.y + 1.0 \
            and not flask.freeze \
            and not flask.basis.is_equal_approx(authored_flask_basis) \
            and is_zero_approx(flask_visual.position.y) \
            and flask.angular_velocity.length() > 8.0 \
            and second_flask.angular_velocity.length() > 8.0 \
            and not flask.angular_velocity.normalized().is_equal_approx(
                second_flask.angular_velocity.normalized()
            ) \
            and not flask.basis.is_equal_approx(second_flask.basis),
        "delayed flasks tumble on distinct axes while staying collider-aligned"
    ) and passed
    flask.queue_free()
    second_flask.queue_free()
    await process_frame
    return passed


func _test_static_placeable_spawn_presentations() -> bool:
    var spike_trap_scene := load(
        "res://placeables/spike_trap/spike_trap.tscn"
    ) as PackedScene
    var spike_trap := spike_trap_scene.instantiate() as GDSpikeTrap
    spike_trap.spawn_time = 0.04
    spike_trap.spawn_buried_depth = 0.4
    spike_trap.spawn_rise_seconds = 0.05
    spike_trap.position = Vector3(1.0, 0.6, 2.0)
    root.add_child(spike_trap)
    var spike_authored_position := spike_trap.global_position
    await physics_frame

    var trigger_area := spike_trap.get_node("TriggerArea") as Area3D
    var strike_area := spike_trap.get_node("StrikeArea") as Area3D
    var passed := _expect(
        not spike_trap.visible \
            and trigger_area.collision_mask == 0 \
            and strike_area.collision_mask == 0,
        "a delayed spike trap waits invisibly without triggering"
    )

    for _frame_index in range(3):
        await physics_frame
    var reset_audio := spike_trap.get_node_or_null("SpikeTrapResetAudio") \
        as AudioStreamPlayer3D
    passed = _expect(
        spike_trap.visible \
            and spike_trap.global_position.y < spike_authored_position.y \
            and reset_audio != null \
            and reset_audio.stream == spike_trap.reset_sound,
        "a delayed spike trap winds upward from below using its recharge sound"
    ) and passed

    for _frame_index in range(5):
        await physics_frame
    passed = _expect(
        spike_trap.is_placeable_spawned() \
            and spike_trap.global_position.is_equal_approx(spike_authored_position) \
            and trigger_area.collision_mask == spike_trap.target_collision_mask \
            and strike_area.collision_mask == spike_trap.target_collision_mask,
        "a spawned spike trap becomes active only at its authored position"
    ) and passed
    spike_trap.queue_free()

    var bat_nest_scene := load("res://enemies/bat_nest.tscn") as PackedScene
    var bat_nest := bat_nest_scene.instantiate() as GDBatNest
    bat_nest.spawn_time = 0.04
    bat_nest.position = Vector3(3.0, 0.5, 4.0)
    root.add_child(bat_nest)
    var bat_nest_authored_position := bat_nest.global_position
    await physics_frame
    var bats_hidden_while_waiting := not bat_nest.visible

    for _frame_index in range(3):
        await physics_frame
    var roosting_bats_remain_hidden := true
    for bat_state in bat_nest.bats:
        if bat_state.node == null or bat_state.node.visible:
            roosting_bats_remain_hidden = false
            break
    passed = _expect(
        bats_hidden_while_waiting \
            and bat_nest.visible \
            and bat_nest.is_placeable_spawned() \
            and bat_nest.global_position.is_equal_approx(bat_nest_authored_position) \
            and roosting_bats_remain_hidden,
        "a delayed bat nest activates in place without prematurely revealing its swarm"
    ) and passed
    bat_nest.queue_free()
    await process_frame
    return passed


func _object_has_property(object: Object, property_name: StringName) -> bool:
    for property in object.get_property_list():
        var found_name := property.get(&"name") as StringName
        if found_name == property_name:
            return true
    return false


func _test_deterministic_seed_helper_is_stable() -> bool:
    var first_seed := DETERMINISTIC_SEED.from_text("stable-source", 23)
    var second_seed := DETERMINISTIC_SEED.from_text("stable-source", 23)
    var different_seed := DETERMINISTIC_SEED.from_text("stable-source", 24)

    return _expect(first_seed == second_seed, "deterministic seed helper repeats the same seed") \
        and _expect(first_seed != different_seed, "deterministic seed helper changes with salt")


func _test_codex_session_options_require_explicit_directed_test_data() -> bool:
    var directed_test := CODEX_SESSION_OPTIONS.parse(PackedStringArray([
        "--codex-test",
        "Walk through the exit gate.",
        "--codex-level",
        "vampire_boss",
        "--codex-confirmed",
    ]))
    var replay := CODEX_SESSION_OPTIONS.parse(PackedStringArray([
        "--codex-replay",
        "--codex-level",
        "latest",
        "--codex-logs",
        "summary,position,buttons",
        "--codex-sample-seconds",
        "0.25",
    ]))
    var invalid := CODEX_SESSION_OPTIONS.parse(PackedStringArray([
        "--codex-replay",
        "--codex-logs",
        "summary,omniscience",
    ]))
    var feedback := CODEX_SESSION_OPTIONS.parse(PackedStringArray([
        "--codex-new-feedback",
        "--codex-logs",
        "feedback,position",
        "--codex-feedback-before",
        "1.5",
        "--codex-feedback-after",
        "2.5",
    ]))

    return _expect(
        int(directed_test.get("mode", CODEX_SESSION_OPTIONS.SessionMode.Disabled)) \
            == CODEX_SESSION_OPTIONS.SessionMode.DirectedTest \
            and String(directed_test.get("instruction", "")) \
                == "Walk through the exit gate." \
            and String(directed_test.get("level", "")) == "vampire_boss" \
            and bool(directed_test.get("confirmed", false)) \
            and String(directed_test.get("report_button", "")) == "square" \
            and String(directed_test.get("text_button", "")) == "disabled",
        "Codex directed tests preserve the request and use a conflict-free feedback button"
    ) and _expect(
        int(replay.get("mode", CODEX_SESSION_OPTIONS.SessionMode.Disabled)) \
            == CODEX_SESSION_OPTIONS.SessionMode.Replay \
            and is_equal_approx(float(replay.get("sample_seconds", 0.0)), 0.25) \
            and CODEX_SESSION_OPTIONS.has_log_channel(
                replay,
                CODEX_SESSION_OPTIONS.LogChannel.Position
            ) \
            and not CODEX_SESSION_OPTIONS.has_log_channel(
                replay,
                CODEX_SESSION_OPTIONS.LogChannel.Camera
            ),
        "Codex replay options select only the requested logging channels"
    ) and _expect(
        not (invalid.get("errors", []) as Array).is_empty(),
        "Codex replay options reject unknown logging channels"
    ) and _expect(
        int(feedback.get("mode", CODEX_SESSION_OPTIONS.SessionMode.Disabled)) \
            == CODEX_SESSION_OPTIONS.SessionMode.Feedback \
            and CODEX_SESSION_OPTIONS.has_log_channel(
                feedback,
                CODEX_SESSION_OPTIONS.LogChannel.Feedback
            ) \
            and is_equal_approx(
                float(feedback.get("feedback_before_seconds", 0.0)),
                1.5
            ) \
            and is_equal_approx(
                float(feedback.get("feedback_after_seconds", 0.0)),
                2.5
            ),
        "Codex feedback options select a bounded diagnostic window"
    )


func _test_run_recording_preserves_compact_frame_timing_and_controls() -> bool:
    var recorder := RUN_RECORDER_SCRIPT.new() as RUN_RECORDER_SCRIPT
    var save_task_owner := TestLevelSelection.new()
    var storage_level_id := "run_recording_round_trip_test"
    recorder.level_id = storage_level_id
    recorder.storage_directory = TEST_RUN_RECORDING_DIRECTORY
    var live_feedback_path := TEST_RUN_RECORDING_DIRECTORY.path_join(
        "latest_feedback.json"
    )
    recorder.live_feedback_path = live_feedback_path
    var repository_report_directory := TEST_RUN_RECORDING_DIRECTORY.path_join(
        "feedback_reports"
    )
    recorder.repository_report_directory = repository_report_directory
    recorder.repository_archive_directory = TEST_RUN_RECORDING_DIRECTORY.path_join(
        "feedback_archive"
    )
    recorder.level_scene_path = "res://levels/1/level.tscn"
    recorder.save_task_owner = save_task_owner
    recorder.run_settings = {
        "shop_purchases": {
            "ghost_sneakers": 1,
        },
    }
    recorder.session_context = {
        "source": "codex_directed_test",
        "instruction": "Walk through the gate.",
    }
    var recording_root := Node3D.new()
    recording_root.name = "RecordedLevel"
    var tracked_pushable := Node3D.new()
    tracked_pushable.name = "TrackedPushable"
    tracked_pushable.position = Vector3(2.0, 0.5, -4.0)
    tracked_pushable.add_to_group(&"pushable")
    recording_root.add_child(tracked_pushable)
    root.add_child(recording_root)
    recorder.recording_root = recording_root
    recorder._discover_drift_nodes()
    var first_player_position := Vector3(1.25, 0.4, -3.75)
    var first_camera_transform := Transform3D(
        Basis.from_euler(Vector3(-0.45, 0.2, 0.0)),
        Vector3(1.25, 6.2, 3.1)
    )
    recorder.capture_sample(
        1.0 / 60.0,
        Vector2(0.375, -0.8),
        Vector2(-0.25, 0.5),
        true,
        false,
        first_player_position,
        0.65,
        first_camera_transform
    )
    recorder.recording_enabled = true
    recorder.mark_feedback("Vampire stuck.", {
        "nodes": [{
            "path": "Vampire",
            "state": {"state": "Hunting"},
        }],
    })
    var repository_report_id := recorder.latest_repository_report_id
    recorder.update_latest_feedback_note("Vampire stuck beside the coffin.")
    recorder.capture_sample(
        1.0 / 30.0,
        Vector2(0.5, -0.25),
        Vector2.ZERO,
        false,
        true,
        first_player_position + Vector3(0.0014, 0.0, -0.0024),
        0.7,
        first_camera_transform.translated(Vector3(0.0034, 0.0, -0.0014))
    )
    var teleported_player_position := Vector3(80.0, 1.0, -90.0)
    recorder.capture_sample(
        0.02,
        Vector2.ZERO,
        Vector2.ZERO,
        false,
        false,
        teleported_player_position,
        -2.2,
        Transform3D(Basis.IDENTITY, Vector3(80.0, 7.0, -84.0))
    )
    var payload := recorder.frame_payload.slice(0, recorder.bytes_used)
    recorder.finish_recording()
    var decoded := RUN_RECORDING_SCRIPT.decode_payload(payload, recorder.frame_count, 41.0)
    var deltas := decoded.get("frame_deltas", PackedFloat32Array()) as PackedFloat32Array
    var movement := decoded.get("movement_inputs", PackedVector2Array()) as PackedVector2Array
    var button_states := decoded.get("button_states", PackedByteArray()) as PackedByteArray
    var positions := decoded.get("player_positions", PackedVector3Array()) \
        as PackedVector3Array
    var save_task_id := recorder.get_save_task_id()
    var pending_save_task_id := save_task_owner.take_run_recording_save_task(storage_level_id)
    var stored_recording := RUN_RECORDING_SCRIPT.load_for_level_after_task(
        storage_level_id,
        pending_save_task_id,
        TEST_RUN_RECORDING_DIRECTORY
    )
    var stored_metadata := stored_recording.get("run_metadata", {}) as Dictionary
    var live_feedback: Variant = JSON.parse_string(
        FileAccess.get_file_as_string(live_feedback_path)
    )
    var repository_report_path := repository_report_directory.path_join(
        "%s.json" % repository_report_id
    )
    var repository_report: Variant = JSON.parse_string(
        FileAccess.get_file_as_string(repository_report_path)
    )
    var repository_playback_path := RUN_RECORDING_SCRIPT.get_path_for_level(
        repository_report_id,
        repository_report_directory
    )
    var repository_playback_saved := FileAccess.file_exists(repository_playback_path)
    var repository_level_scene_path := repository_report_directory.path_join(
        "%s.tscn" % repository_report_id
    )
    var repository_level_scene_saved := FileAccess.file_exists(
        repository_level_scene_path
    )
    var repository_level_scene_source := FileAccess.get_file_as_string(
        repository_level_scene_path
    )
    var stored_settings := stored_metadata.get("settings", {}) as Dictionary
    var stored_session := stored_metadata.get("session", {}) as Dictionary
    var stored_purchases := stored_settings.get("shop_purchases", {}) as Dictionary
    var stored_checkpoints := stored_metadata.get("drift_checkpoints", []) as Array
    var stored_feedback_markers := stored_metadata.get("feedback_markers", []) as Array
    var stored_feedback := stored_feedback_markers[0] as Dictionary \
        if not stored_feedback_markers.is_empty() else {}
    var first_checkpoint := stored_checkpoints[0] as Dictionary \
        if not stored_checkpoints.is_empty() else {}
    var checkpoint_states := first_checkpoint.get("states", []) as Array
    var first_checkpoint_state := checkpoint_states[0] as Dictionary \
        if not checkpoint_states.is_empty() else {}
    var checkpoint_position_values := first_checkpoint_state.get("position", []) as Array
    var checkpoint_position := Vector3.ZERO
    if checkpoint_position_values.size() == 3:
        checkpoint_position = Vector3(
            float(checkpoint_position_values[0]),
            float(checkpoint_position_values[1]),
            float(checkpoint_position_values[2])
        )
    var saved := save_task_id == pending_save_task_id \
        and save_task_id != RUN_RECORDING_SCRIPT.INVALID_TASK_ID \
        and FileAccess.file_exists(RUN_RECORDING_SCRIPT.get_path_for_level(
            storage_level_id,
            TEST_RUN_RECORDING_DIRECTORY
        ))
    var listed_recordings := RUN_RECORDING_SCRIPT.list_recordings(
        TEST_RUN_RECORDING_DIRECTORY
    )
    var latest_recording_id := RUN_RECORDING_SCRIPT.get_latest_level_id(
        TEST_RUN_RECORDING_DIRECTORY
    )
    RUN_RECORDING_SCRIPT.remove_for_level(storage_level_id, TEST_RUN_RECORDING_DIRECTORY)
    DirAccess.remove_absolute(ProjectSettings.globalize_path(live_feedback_path))
    RUN_RECORDING_SCRIPT.remove_for_level(
        repository_report_id,
        repository_report_directory
    )
    DirAccess.remove_absolute(ProjectSettings.globalize_path(repository_level_scene_path))
    DirAccess.remove_absolute(ProjectSettings.globalize_path(repository_report_path))
    var passed := _expect(decoded.size() > 0, "run recording binary payload decodes") \
        and _expect(
            deltas.size() == 3 \
                and is_equal_approx(deltas[0], 1.0 / 60.0) \
                and is_equal_approx(deltas[1], 1.0 / 30.0) \
                and is_equal_approx(deltas[2], 0.02),
            "run recording preserves each physics-frame delta"
        ) \
        and _expect(
            movement[0].distance_to(Vector2(0.375, -0.8)) <= 2.0 / 32767.0 \
                and movement[1].distance_to(Vector2(0.5, -0.25)) <= 2.0 / 32767.0,
            "run recording preserves analogue joypad controls"
        ) \
        and _expect(
            bool(button_states[0] & RUN_RECORDING_SCRIPT.FrameFlags.JumpPressed) \
                and bool(button_states[1] & RUN_RECORDING_SCRIPT.FrameFlags.DropPressed),
            "run recording preserves per-frame joypad buttons"
        ) \
        and _expect(
            positions[1].is_equal_approx(first_player_position + Vector3(0.001, 0.0, -0.002)) \
                and positions[2].is_equal_approx(teleported_player_position),
            "run recording uses millimetre deltas and lossless teleport keyframes"
        ) \
        and _expect(
            payload.size() == RUN_RECORDER_SCRIPT.ABSOLUTE_FRAME_SIZE * 2 \
                + RUN_RECORDER_SCRIPT.NORMAL_FRAME_SIZE,
            "run recording keeps ordinary frames to a compact fixed binary size"
        ) \
        and _expect(
            RUN_RECORDER_SCRIPT.INITIAL_BUFFER_SIZE \
                >= RUN_RECORDER_SCRIPT.ABSOLUTE_FRAME_SIZE \
                    * Engine.physics_ticks_per_second * 300,
            "run recording avoids buffer reallocations during a typical five-minute level"
        ) \
        and _expect(
            saved and is_equal_approx(float(stored_recording.get("duration", 0.0)), 0.07),
            "run recording asynchronously stores a compressed file for each level"
        ) \
        and _expect(
            int(stored_purchases.get("ghost_sneakers", 0)) == 1,
            "run recording retains the shop upgrades active for the attempt"
        ) \
        and _expect(
            String(stored_session.get("instruction", "")) == "Walk through the gate.",
            "run recording retains the Codex-directed playtest instruction"
        ) \
        and _expect(
            String(stored_feedback.get("note", "")) \
                == "Vampire stuck beside the coffin." \
                and int(stored_feedback.get("frame", -1)) == 0,
            "run recording stores player feedback at one precise replay frame"
        ) \
        and _expect(
            live_feedback is Dictionary \
                and String((live_feedback as Dictionary).get("level_id", "")) \
                    == storage_level_id,
            "player feedback is available to Codex before the run finishes"
        ) \
        and _expect(
            repository_report is Dictionary \
                and String((repository_report as Dictionary).get(
                    "playback_status",
                    ""
                )) == "ready" \
                and repository_playback_saved \
                and String((repository_report as Dictionary).get(
                    "level_scene_status",
                    ""
                )) == "ready" \
                and repository_level_scene_saved \
                and not repository_level_scene_source.get_slice("\n", 0).contains(" uid="),
            "player feedback creates a UID-free immutable level snapshot and playback"
        ) \
        and _expect(
            listed_recordings.size() == 1 and latest_recording_id == storage_level_id,
            "run recording lookup identifies the newest player session"
        ) \
        and _expect(
            String(first_checkpoint_state.get("path", "")) == "TrackedPushable" \
                and checkpoint_position.is_equal_approx(tracked_pushable.global_position),
            "run recording stores periodic world checkpoints for playback drift diagnostics"
        )
    save_task_owner.free()
    recorder.free()
    recording_root.free()
    return passed


func _test_quick_exit_flushes_run_recording_tasks() -> bool:
    var quick_exit := root.get_node_or_null("quick_exit") as GDQuickExit
    var level_selection := root.get_node_or_null("LevelSelection") as GDLevelSelection
    if not _expect(
        quick_exit != null and level_selection != null,
        "shutdown recording test has its persistent services"
    ):
        return false

    var shutdown_recorder := TestShutdownRecorder.new()
    root.add_child(shutdown_recorder)
    var delayed_level_id := "test_shutdown_recording"
    var delayed_task_id := WorkerThreadPool.add_task(
        func() -> void:
            OS.delay_msec(75),
        false,
        "Test shutdown recording save"
    )
    level_selection.register_run_recording_save_task(delayed_level_id, delayed_task_id)
    var wait_started_at := Time.get_ticks_msec()
    quick_exit.call("_finish_pending_run_recordings")
    var wait_duration := Time.get_ticks_msec() - wait_started_at
    var remaining_task_id := level_selection.take_run_recording_save_task(
        delayed_level_id
    )
    if remaining_task_id != GDRunRecording.INVALID_TASK_ID:
        WorkerThreadPool.wait_for_task_completion(remaining_task_id)
    var passed := _expect(
        not auto_accept_quit \
            and shutdown_recorder.finish_called \
            and wait_duration >= 50 \
            and remaining_task_id == GDRunRecording.INVALID_TASK_ID,
        "quitting finalizes active recorders and joins every playback save before teardown"
    )
    shutdown_recorder.queue_free()
    await process_frame
    return passed


func _test_run_recorder_skips_freed_drift_nodes() -> bool:
    var recorder := RUN_RECORDER_SCRIPT.new() as RUN_RECORDER_SCRIPT
    var removed_boundary_center := Node3D.new()
    var stored_path := "KillBoundary/BoundaryCenter"
    recorder.drift_nodes[stored_path] = removed_boundary_center
    recorder.drift_node_paths.append(stored_path)
    removed_boundary_center.free()

    recorder._capture_drift_checkpoint(60, 1.0)
    var checkpoint := recorder.drift_checkpoints[0] as Dictionary
    var states := checkpoint.get("states", []) as Array
    var passed := _expect(
        states.is_empty(),
        "run recorder skips a kill boundary removed during an active recording"
    )
    recorder.free()
    return passed


func _test_coin_pile_derives_stable_seed_and_disables_camera_gate_by_default() -> bool:
    var parent := Node3D.new()
    parent.name = "DeterministicSeedParent"
    root.add_child(parent)

    var pile: Node = GOLD_COIN_PILE_SCRIPT.new()
    pile.name = "GoldCoinPile"
    parent.add_child(pile)

    var expected_seed := DETERMINISTIC_SEED.from_node(pile, 0, &"gold_coin_pile")
    var runtime_seed := int(pile.get_runtime_random_seed())
    var coin_pile_preview := pile.call("_create_preview_item", 0) as Node3D
    var coin_pile_preview_meshes := coin_pile_preview.find_children(
        "*", "MeshInstance3D", true, false
    )
    var coin_pile_preview_mesh := coin_pile_preview_meshes[0] as MeshInstance3D \
        if not coin_pile_preview_meshes.is_empty() else null
    var editor_preview_pile := TREASURE_PILE_SCENE.instantiate() as GDTreasurePile
    editor_preview_pile.pile_radius = 0.75
    editor_preview_pile.call("_configure_editor_selection_placeholder")
    var selection_placeholder := editor_preview_pile.get_node(
        "EditorSelectionPlaceholder"
    ) as MeshInstance3D
    var selection_mesh := selection_placeholder.mesh as CylinderMesh
    var gold_pile_scene_text := FileAccess.get_file_as_string(
        "res://placeables/treasure/gold_coin_pile.tscn"
    )
    var treasure_pile_scene_text := FileAccess.get_file_as_string(
        "res://placeables/treasure/treasure_pile.tscn"
    )
    var both_pile_scenes_author_placeholder := gold_pile_scene_text.contains(
        "[node name=\"EditorSelectionPlaceholder\""
    ) and treasure_pile_scene_text.contains("[node name=\"EditorSelectionPlaceholder\"")
    parent.add_child(editor_preview_pile)
    var passed := _expect(runtime_seed == expected_seed, "coin pile derives a stable fallback seed") \
        and _expect(
            pile.get_max_coin_count() == 200 and pile.get_max_item_count() == 200,
            "coin pile keeps its existing quantity API and default"
        ) \
        and _expect(
            not bool(pile.get("spawn_when_near_camera")),
            "coin pile does not camera-gate spawn timing by default"
        ) \
        and _expect(
            coin_pile_preview_mesh != null \
                and coin_pile_preview_mesh.get_aabb().size.is_equal_approx(
                    Vector3(0.1280421, 0.0160053, 0.1280421)
                ) \
                and coin_pile_preview_mesh.material_overlay \
                    == TREASURE_OUTLINE_MATERIAL,
            "coin pile previews use the textured skull coin at its authored size"
        ) \
        and _expect(
            both_pile_scenes_author_placeholder \
                and selection_mesh != null \
                and is_equal_approx(selection_mesh.top_radius, 0.75) \
                and selection_placeholder.position.y > 0.0,
            "gold coin and mixed treasure piles author selectable placeholder geometry"
        ) \
        and _expect(
            not selection_placeholder.visible,
            "pile selection placeholder geometry is hidden during gameplay"
        )

    coin_pile_preview.free()
    parent.free()
    return passed


func _test_treasure_pile_discovers_compatible_scenes_and_spawns_mixed_counts() -> bool:
    var parent := Node3D.new()
    parent.name = "TreasurePileTestParent"
    root.add_child(parent)
    var pile := TREASURE_PILE_SCENE.instantiate() as GDTreasurePile

    var inspector_properties: Array[StringName] = []
    for property in pile.get_property_list():
        inspector_properties.append(property["name"] as StringName)
    var compatible_types := pile.get_compatible_treasure_types()
    var diamond_preview := pile._create_preview_item(0)
    var gold_bar_preview := pile._create_preview_item(3)
    var gold_coin_preview := pile._create_preview_item(6)
    var diamond_preview_meshes := diamond_preview.find_children(
        "*", "MeshInstance3D", true, false
    )
    var gold_bar_preview_meshes := gold_bar_preview.find_children(
        "*", "MeshInstance3D", true, false
    )
    var gold_coin_preview_meshes := gold_coin_preview.find_children(
        "*", "MeshInstance3D", true, false
    )
    parent.add_child(pile)
    var passed := _expect(
        compatible_types == [
            &"amethyst",
            &"diamond",
            &"emerald",
            &"gold_bar",
            &"gold_coin",
            &"ruby",
            &"sapphire",
        ] \
            and not compatible_types.has(&"key"),
        "treasure pile discovers marked treasure scenes and excludes unmarked collectibles"
    ) and _expect(
        pile.get_treasure_count(&"gold_coin") == 5 \
            and pile.get_treasure_count(&"diamond") == 3 \
            and pile.get_treasure_count(&"gold_bar") == 3 \
            and pile.get_max_item_count() == 11,
        "treasure pile defaults to five coins, three diamonds, and three bars"
    ) and _expect(
        inspector_properties.has(&"gold_coin_count") \
            and inspector_properties.has(&"diamond_count") \
            and inspector_properties.has(&"ruby_count") \
            and inspector_properties.has(&"sapphire_count") \
            and inspector_properties.has(&"emerald_count") \
            and inspector_properties.has(&"amethyst_count") \
            and inspector_properties.has(&"gold_bar_count"),
        "treasure pile exposes every built-in gem count as an ordinary editor property"
    ) and _expect(
        not diamond_preview_meshes.is_empty() \
            and not gold_bar_preview_meshes.is_empty() \
            and not gold_coin_preview_meshes.is_empty() \
            and diamond_preview.find_children(
                "*", "CollisionObject3D", true, false
            ).is_empty() \
            and gold_bar_preview.find_children(
                "*", "CollisionObject3D", true, false
            ).is_empty(),
        "mixed pile editor previews contain visible meshes without physics bodies"
    ) and _expect(
        not diamond_preview_meshes.is_empty() \
            and not gold_bar_preview_meshes.is_empty() \
            and not gold_coin_preview_meshes.is_empty() \
            and (diamond_preview_meshes[0] as MeshInstance3D).material_overlay \
                == TREASURE_OUTLINE_MATERIAL \
            and (gold_bar_preview_meshes[0] as MeshInstance3D).material_overlay \
                == TREASURE_OUTLINE_MATERIAL \
            and (gold_coin_preview_meshes[0] as MeshInstance3D).material_overlay \
                == TREASURE_OUTLINE_MATERIAL,
        "mixed pile editor previews retain the shared treasure outline"
    )

    diamond_preview.free()
    gold_bar_preview.free()
    gold_coin_preview.free()

    pile.set_treasure_count(&"gold_coin", 2)
    pile.set_treasure_count(&"diamond", 1)
    pile.set_treasure_count(&"ruby", 1)
    pile.set_treasure_count(&"sapphire", 1)
    pile.set_treasure_count(&"emerald", 1)
    pile.set_treasure_count(&"amethyst", 1)
    pile.set_treasure_count(&"gold_bar", 2)
    pile.set("spawn_interval", 0.0)
    pile._advance_spawn_schedule()
    pile._spawn_scheduled_items()

    var spawned_coins := 0
    var spawned_gems: Dictionary = {}
    var spawned_bars: Array[GDGoldBar] = []
    for child in parent.get_children():
        if child is GDGoldCoin:
            spawned_coins += 1
        elif child is GDGoldBar:
            spawned_bars.append(child as GDGoldBar)
        elif child is GDInventoryPickup:
            var gem := child as GDInventoryPickup
            var gem_type: StringName = gem.carried_item.get("item_type")
            if gem_type in [&"diamond", &"ruby", &"sapphire", &"emerald", &"amethyst"]:
                spawned_gems[gem_type] = int(spawned_gems.get(gem_type, 0)) + 1

    passed = _expect(
        pile.get_max_item_count() == 9 \
            and pile.get_max_treasure_value() == 124 \
            and spawned_coins == 2 \
            and spawned_gems == {
                &"amethyst": 1,
                &"diamond": 1,
                &"emerald": 1,
                &"ruby": 1,
                &"sapphire": 1,
            } \
            and spawned_bars.size() == 2,
        "treasure pile spawns each configured gem count and reports their combined value"
    ) and _expect(
        not spawned_bars.is_empty() and not spawned_bars[0].freeze,
        "mixed treasure pile uses the working rigid collectible scenes"
    ) and passed

    parent.free()
    return passed


func _test_debug_level_total_includes_authored_loose_treasure() -> bool:
    var debug_level_scene := load("res://levels/debug-level/level.tscn") as PackedScene
    var debug_level := debug_level_scene.instantiate() as Node3D
    var treasure_pile := debug_level.get_node("TreasurePile") as GDTreasurePile
    treasure_pile.call("_load_treasure_catalog")
    var graveyard := TestGraveyard.new()
    graveyard.current_level = debug_level
    var authored_total := graveyard._calculate_max_treasure_value()
    var loose_treasure_value := AMETHYST_ITEM.treasure_value \
        + DIAMOND_ITEM.treasure_value \
        + EMERALD_ITEM.treasure_value \
        + RUBY_ITEM.treasure_value \
        + SAPPHIRE_ITEM.treasure_value \
        + GOLD_BAR_ITEM.treasure_value
    var runtime_pickup := DIAMOND_SCENE.instantiate() as GDInventoryPickup
    debug_level.add_child(runtime_pickup)
    var total_with_runtime_pickup := graveyard._calculate_max_treasure_value()
    var passed := _expect(
        authored_total == 867 + loose_treasure_value and authored_total == 944,
        "debug level total includes every authored loose treasure pickup (got %d)" \
            % authored_total
    ) and _expect(
        total_with_runtime_pickup == authored_total,
        "runtime-spawned treasure does not duplicate its source pile value"
    )

    graveyard.free()
    debug_level.free()
    return passed


func _test_diamond_collectible_value_and_material() -> bool:
    var diamond := DIAMOND_SCENE.instantiate() as GDDiamond
    root.add_child(diamond)
    var diamond_collision := diamond.get_node_or_null("CollisionShape3D") as CollisionShape3D
    var diamond_shape := (
        diamond_collision.shape as ConvexPolygonShape3D if diamond_collision != null else null
    )
    var diamond_visual := diamond.get_node_or_null("GemVisual") as Node3D
    var diamond_cut := diamond_visual.get_node_or_null("DiamondCut") as Node3D
    var diamond_mesh := diamond_cut.get_node_or_null("Crown") as MeshInstance3D
    var surface_material: Material = (
        diamond_mesh.material_override if diamond_mesh != null else null
    )
    var diamond_material := DIAMOND_MATERIAL as ShaderMaterial
    var inventory := GDPlayerInventory.new()
    inventory._add_item(GOLD_COIN_ITEM)
    inventory._add_item(DIAMOND_ITEM)
    var deposited_item := inventory.take_highest_value_carried_treasure()

    var passed := _expect(
        diamond is RigidBody3D \
            and diamond_shape != null \
            and diamond_shape.points.size() == 17,
        "diamond uses an authored faceted convex collider instead of a rolling sphere"
    ) and _expect(
        diamond.physics_material_override != null \
            and is_equal_approx(diamond.physics_material_override.friction, 0.9) \
            and is_equal_approx(diamond.physics_material_override.bounce, 0.02) \
            and diamond.angular_damp >= 2.5,
        "diamond friction, bounce, and angular damping help it settle on a face"
    ) and _expect(
        surface_material == DIAMOND_MATERIAL,
        "diamond mesh receives the authored stylized material"
    ) and _expect(
        diamond_mesh != null \
            and diamond_mesh.mesh is CylinderMesh \
            and (diamond_mesh.mesh as CylinderMesh).radial_segments == 8 \
            and diamond_cut.get_node_or_null("Pavilion") is MeshInstance3D,
        "diamond uses an authored eight-sided crown and pointed pavilion matching its icon"
    ) and _expect(
        diamond_material.shader.resource_path \
            == "res://placeables/treasure/gems/gem_stylized.gdshader" \
            and (diamond_material.get_shader_parameter(&"body_color") as Color).a == 1.0 \
            and float(diamond_material.get_shader_parameter(&"rim_energy")) > 0.0 \
            and diamond_material.shader.code.contains("dFdx") \
            and diamond_mesh.material_overlay == TREASURE_OUTLINE_MATERIAL,
        "diamond keeps its opaque facet material beneath the shared treasure outline"
    ) and _expect(
        is_equal_approx(DIAMOND_ITEM.weight, GOLD_COIN_ITEM.weight) \
            and DIAMOND_ITEM.treasure_value == 10 \
            and GOLD_COIN_ITEM.treasure_value == 1,
        "a diamond uses one sack unit and carries ten treasure value"
    ) and _expect(
        DIAMOND_ITEM.pickup_sound == GOLD_COIN_ITEM.pickup_sound \
            and DIAMOND_ITEM.drop_sound == GOLD_COIN_ITEM.drop_sound,
        "diamond pickup and drop temporarily reuse coin sounds"
    ) and _expect(
        deposited_item == DIAMOND_ITEM \
            and inventory.get_used_inventory_units() == 1 \
            and inventory.get_carried_treasure_value() == 1,
        "deposit selection removes the highest-value treasure while preserving sack accounting"
    )

    inventory.free()
    diamond.free()
    return passed


func _test_gem_variants_use_icon_cuts_and_scale_values() -> bool:
    var gem_items: Array[Resource] = [
        DIAMOND_ITEM,
        RUBY_ITEM,
        SAPPHIRE_ITEM,
        EMERALD_ITEM,
        AMETHYST_ITEM,
    ]
    var gem_scenes: Array[PackedScene] = [
        DIAMOND_SCENE,
        RUBY_SCENE,
        SAPPHIRE_SCENE,
        EMERALD_SCENE,
        AMETHYST_SCENE,
    ]
    var expected_values := [10, 9, 5, 6, 2]
    var expected_cuts := [0, 1, 2, 3, 1]
    var expected_cut_nodes := ["DiamondCut", "RubyCut", "SapphireCut", "EmeraldCut", "RubyCut"]
    var body_colors: Array[Color] = []
    var passed := true

    for index in gem_items.size():
        var gem := gem_scenes[index].instantiate() as GDInventoryPickup
        root.add_child(gem)
        var gem_visual := gem.get_node_or_null("GemVisual") as Node3D
        var cut_node := gem_visual.get_node_or_null(expected_cut_nodes[index]) as Node3D
        var cut_meshes := cut_node.find_children("*", "MeshInstance3D", true, false) \
            if cut_node != null else []
        var gem_mesh := cut_meshes[0] as MeshInstance3D if not cut_meshes.is_empty() else null
        var gem_material := (
            gem_mesh.material_override as ShaderMaterial if gem_mesh != null else null
        )
        if gem_material != null:
            body_colors.append(gem_material.get_shader_parameter(&"body_color") as Color)

        passed = _expect(
            gem != null \
                and gem.carried_item == gem_items[index] \
                and is_equal_approx(float(gem_items[index].get("weight")), 1.0) \
                and int(gem_items[index].get("treasure_value")) == expected_values[index],
            "%s uses one sack unit and its scaled gem value" \
                % String(gem_items[index].get("display_name"))
        ) and _expect(
            gem_visual != null \
                and int(gem_visual.get("cut")) == expected_cuts[index] \
                and cut_node != null \
                and cut_node.visible \
                and gem_mesh != null \
                and gem_material != null \
                and gem_material.shader.resource_path \
                    == "res://placeables/treasure/gems/gem_stylized.gdshader" \
                and gem_mesh.material_overlay == TREASURE_OUTLINE_MATERIAL,
            "%s uses its icon-matched cut, stylized shader, and treasure outline" \
                % String(gem_items[index].get("display_name"))
        ) and passed
        gem.free()

    passed = _expect(
        body_colors.size() == gem_items.size() \
            and body_colors[0].r > 0.7 \
            and body_colors[1].r > body_colors[1].g * 10.0 \
            and body_colors[2].b > body_colors[2].r * 8.0 \
            and body_colors[3].g > body_colors[3].r * 10.0 \
            and body_colors[4].b > body_colors[4].g * 5.0,
        "gem palettes read as white, red, blue, green, and purple"
    ) and passed
    return passed


func _test_audio_fallback_is_deterministic() -> bool:
    var first_stream := AudioStreamMP3.new()
    var second_stream := AudioStreamMP3.new()
    var streams: Array[AudioStream] = [first_stream, second_stream]
    var picked_stream := GDAudio._pick_stream(streams, null)
    var midpoint := GDAudio._randf_range(0.25, 0.75, null)

    return _expect(picked_stream == first_stream, "audio fallback picks the first stream deterministically") \
        and _expect(is_equal_approx(midpoint, 0.5), "audio fallback uses deterministic midpoint variation")


func _test_frontend_audio_uses_shared_support() -> bool:
    var frontend_audio: Node = root.get_node_or_null("FrontendAudio")
    if not _expect(frontend_audio != null, "frontend audio is available to every menu scene"):
        return false

    var sound_streams := frontend_audio.get("sound_streams") as Dictionary
    var all_streams_loaded := sound_streams.size() == 3
    for stream: AudioStream in sound_streams.values():
        all_streams_loaded = all_streams_loaded and stream != null
    frontend_audio.call("play_select")
    var select_player := frontend_audio.get_node_or_null("FrontendSelect") as AudioStreamPlayer
    var passed := _expect(
        all_streams_loaded,
        "frontend audio loads the supplied select, movement, and purchase sounds"
    ) and _expect(
        select_player != null and select_player.bus == GDAudio.SFX_BUS,
        "frontend audio one-shots use the shared audio support and SFX bus"
    )
    if select_player != null:
        select_player.stop()
        select_player.queue_free()
    return passed


func _test_letterbox_background_is_black() -> bool:
    var clear_color: Color = ProjectSettings.get_setting(
        "rendering/environment/defaults/default_clear_color",
        Color(0.3, 0.3, 0.3, 1.0)
    )
    return _expect(
        clear_color.is_equal_approx(Color.BLACK),
        "unused screen space renders as black letterboxing on non-16:9 displays"
    )


func _test_screen_fade_finishes_while_paused() -> bool:
    var fade_owner := Control.new()
    root.add_child(fade_owner)
    paused = true
    var fade_tween := SCREEN_FADE_SCRIPT.fade_in(fade_owner, "PausedTreeFade", 0.01)
    await create_timer(0.05, true).timeout
    await process_frame
    var fade := fade_owner.get_node_or_null("PausedTreeFade") as ColorRect
    var fade_finished := not fade_tween.is_running() \
        and (fade == null or is_zero_approx(fade.color.a))
    paused = false
    fade_owner.queue_free()
    return _expect(
        fade_finished,
        "screen fades finish even when gameplay leaves the scene tree paused"
    )


func _test_feedback_pause_restores_prior_pause_state() -> bool:
    var pause_scene := load("res://ui/screens/pause_screen.tscn") as PackedScene
    var pause_screen := pause_scene.instantiate() as GDPauseScreen
    root.add_child(pause_screen)
    await process_frame

    pause_screen.begin_feedback_pause()
    var newly_paused_without_overlay := paused and not pause_screen.visible
    pause_screen.end_feedback_pause()
    var resumed_after_feedback := not paused and not pause_screen.visible

    paused = true
    pause_screen.begin_feedback_pause()
    pause_screen.end_feedback_pause()
    var prior_pause_restored := paused and pause_screen.visible
    paused = false
    pause_screen.queue_free()
    await process_frame
    return _expect(
        newly_paused_without_overlay and resumed_after_feedback and prior_pause_restored,
        "feedback pauses gameplay without covering its dialog and restores prior pause state"
    )


func _test_feedback_dialog_uses_large_game_font() -> bool:
    var feedback_scene := load(
        "res://ui/hud/player_feedback/player_feedback.tscn"
    ) as PackedScene
    var feedback := feedback_scene.instantiate() as GDPlayerFeedback
    root.add_child(feedback)
    await process_frame
    var note_panel := feedback.get_node_or_null("NotePanel") as Control
    var prompt := feedback.get_node_or_null(
        "NotePanel/Center/Panel/Margin/VBox/Prompt"
    ) as Label
    var instructions := feedback.get_node_or_null(
        "NotePanel/Center/Panel/Margin/VBox/Instructions"
    ) as Label
    var note_field := feedback.get_node_or_null(
        "NotePanel/Center/Panel/Margin/VBox/NoteField"
    ) as TextEdit
    var cancel_button := feedback.get_node_or_null(
        "NotePanel/Center/Panel/Margin/VBox/Actions/CancelButton"
    ) as Button
    var proceed_button := feedback.get_node_or_null(
        "NotePanel/Center/Panel/Margin/VBox/Actions/ProceedButton"
    ) as Button
    var submitted_note := {"value": ""}
    feedback.feedback_note_submitted.connect(
        func(note: String) -> void:
            submitted_note["value"] = note
    )
    feedback.call("_show_note_field")
    var keyboard_starts_on_controller_action := proceed_button.has_focus() \
        and note_field.focus_mode == Control.FOCUS_CLICK
    var first_key := InputEventKey.new()
    first_key.keycode = KEY_A
    first_key.unicode = "a".unicode_at(0)
    first_key.pressed = true
    feedback.call("_input", first_key)
    var newline_key := InputEventKey.new()
    newline_key.keycode = KEY_ENTER
    newline_key.pressed = true
    feedback.call("_input", newline_key)
    var second_key := InputEventKey.new()
    second_key.keycode = KEY_B
    second_key.unicode = "b".unicode_at(0)
    second_key.pressed = true
    feedback.call("_input", second_key)
    var keyboard_routes_to_note_without_activating := note_field.text == "a\nb" \
        and note_panel.visible \
        and proceed_button.has_focus()

    var dpad_left := InputEventJoypadButton.new()
    dpad_left.button_index = JOY_BUTTON_DPAD_LEFT
    dpad_left.pressed = true
    feedback.call("_input", dpad_left)
    var dpad_selects_cancel := cancel_button.has_focus()
    dpad_left.pressed = false
    feedback.call("_input", dpad_left)
    var stick_motion := InputEventJoypadMotion.new()
    stick_motion.axis = JOY_AXIS_LEFT_X
    stick_motion.axis_value = 1.0
    feedback.call("_input", stick_motion)
    var stick_selects_proceed := proceed_button.has_focus()
    var joypad_accept := InputEventJoypadButton.new()
    joypad_accept.button_index = JOY_BUTTON_A
    joypad_accept.pressed = true
    feedback.call("_input", joypad_accept)
    var controller_submits_keyboard_note := String(submitted_note["value"]) == "a\nb" \
        and not note_panel.visible
    joypad_accept.pressed = false
    feedback.call("_input", joypad_accept)

    feedback.call("_show_note_field")
    note_field.text = "Discard this note."
    var joypad_cancel := InputEventJoypadButton.new()
    joypad_cancel.button_index = JOY_BUTTON_B
    joypad_cancel.pressed = true
    feedback.call("_input", joypad_cancel)
    var controller_cancel_discarded_note := String(submitted_note["value"]) == "a\nb" \
        and not note_panel.visible
    var passed := _expect(
        prompt != null \
            and prompt.get_theme_font_size("font_size") >= 64 \
            and prompt.has_theme_font_override("font"),
        "feedback title uses the large shared game font"
    ) and _expect(
        instructions != null \
            and instructions.get_theme_font_size("font_size") >= 40 \
            and instructions.has_theme_font_override("font") \
            and note_field != null \
            and note_field.get_theme_font_size("font_size") >= 48 \
            and note_field.has_theme_font_override("font"),
        "feedback instructions and entry field more than double their original font sizes"
    ) and _expect(
        keyboard_starts_on_controller_action \
            and keyboard_routes_to_note_without_activating \
            and dpad_selects_cancel \
            and stick_selects_proceed \
            and controller_submits_keyboard_note \
            and controller_cancel_discarded_note \
            and proceed_button != null \
            and proceed_button.focus_mode == Control.FOCUS_ALL \
            and proceed_button.has_theme_font_override("font") \
            and cancel_button != null \
            and cancel_button.focus_mode == Control.FOCUS_ALL \
            and cancel_button.has_theme_font_override("font") \
            and not proceed_button.focus_neighbor_left.is_empty() \
            and not cancel_button.focus_neighbor_right.is_empty(),
        "feedback routes keyboard notes separately from controller navigation and actions"
    )
    feedback.queue_free()
    await process_frame
    return passed


func _test_game_settings_batch_disk_writes() -> bool:
    var game_settings := TestGameSettings.new()
    root.add_child(game_settings)
    game_settings.call("_queue_settings_save")
    game_settings.call("_queue_settings_save")
    var saves_immediately := game_settings.save_count
    await create_timer(GDGameSettings.SETTINGS_SAVE_DELAY + 0.05).timeout
    var passed := _expect(
        saves_immediately == 0 and game_settings.save_count == 1 \
            and not game_settings.save_pending,
        "rapid audio-setting changes are persisted in one delayed disk write"
    )
    game_settings.queue_free()
    await process_frame
    return passed


func _test_png_profile_store_only_accepts_level_subfolders() -> bool:
    var profile_store := PNG_TO_GRIDMAP_PROFILE_STORE.new(null, PNG_TO_GRIDMAP_SETTINGS)
    var rejected_save_result: Error = profile_store.save(
        PNG_TO_GRIDMAP_SETTINGS.new(),
        "res://player/player.tscn"
    )
    return _expect(
        profile_store.path_for_mesh_library("res://Assets/environment/graveyard.res") \
        == "res://addons/png_to_gridmap/settings/png_to_gridmap_configuration_for_graveyard.tres",
        "PNG project configuration names the MeshLibrary it configures"
    ) and _expect(
        profile_store.path_for_scene("res://levels/7/level.tscn") \
        == "res://levels/7/png_to_gridmap_settings.tres",
        "PNG profile settings resolve beside scenes in a level subfolder"
    ) and _expect(
        profile_store.path_for_scene("res://player/player.tscn") == "",
        "PNG profile settings do not resolve a file beside non-level scenes"
    ) and _expect(
        profile_store.path_for_scene("res://placeables/torch/torch.tscn") == "",
        "PNG profile settings do not resolve a file beside reusable placeables"
    ) and _expect(
        rejected_save_result == ERR_INVALID_PARAMETER,
        "PNG profile saves reject non-level scenes before writing any settings"
    ) and _expect(
        PNG_TO_GRIDMAP_PROFILE_STORE.is_scene_in_levels_subfolder(
            "res://levels/7/level.tscn"
        ),
        "PNG profile settings accept scenes in a level subfolder"
    ) and _expect(
        PNG_TO_GRIDMAP_PROFILE_STORE.is_scene_in_levels_subfolder(
            "res://levels/tutorial/rooms/entrance.tscn"
        ),
        "PNG profile settings accept scenes nested below a level subfolder"
    ) and _expect(
        not PNG_TO_GRIDMAP_PROFILE_STORE.is_scene_in_levels_subfolder(
            "res://levels/level.tscn"
        ),
        "PNG profile settings reject scenes directly inside the levels root"
    ) and _expect(
        not PNG_TO_GRIDMAP_PROFILE_STORE.is_scene_in_levels_subfolder(
            "res://placeables/torch/torch.tscn"
        ),
        "PNG profile settings reject reusable placeable scenes"
    ) and _expect(
        not PNG_TO_GRIDMAP_PROFILE_STORE.is_scene_in_levels_subfolder(
            "res://player/player.tscn"
        ),
        "PNG profile settings reject non-level scenes"
    ) and _expect(
        not PNG_TO_GRIDMAP_PROFILE_STORE.is_scene_in_levels_subfolder(
            "res://levels_backup/7/level.tscn"
        ),
        "PNG profile settings reject similarly named folders"
    ) and _expect(
        not PNG_TO_GRIDMAP_PROFILE_STORE.is_scene_in_levels_subfolder(
            "res://levels/../player/player.tscn"
        ),
        "PNG profile settings reject paths that traverse out of levels"
    )


func _test_png_profile_store_resets_unsaved_level_state() -> bool:
    var profile_store := PNG_TO_GRIDMAP_PROFILE_STORE.new(null, PNG_TO_GRIDMAP_SETTINGS)
    var previous_settings: Resource = PNG_TO_GRIDMAP_SETTINGS.new()
    previous_settings.mesh_library_path = "res://Assets/environment/graveyard.res"
    previous_settings.target_gridmap_path = NodePath("PNGGridMap")
    previous_settings.auto_repair = true
    var level_settings: Resource = profile_store.load_for_scene(
        previous_settings,
        "res://levels/profile_without_saved_settings/level.tscn"
    )
    return _expect(
        level_settings != previous_settings
            and level_settings.mesh_library_path == previous_settings.mesh_library_path
            and level_settings.target_gridmap_path.is_empty()
            and not level_settings.auto_repair,
        "profile-less levels retain shared mappings without inheriting another level's repair target"
    )


func _test_png_resource_catalog_selects_only_gridmap() -> bool:
    var level_root := Node3D.new()
    var grid_map := GridMap.new()
    grid_map.name = "GridMap"
    level_root.add_child(grid_map)
    var selected_path: NodePath = PNG_TO_GRIDMAP_RESOURCE_CATALOG.preferred_grid_map_path(
        level_root,
        NodePath("MissingGridMap")
    )
    level_root.free()
    return _expect(
        selected_path == NodePath("GridMap"),
        "PNG-to-GridMap selects a level's only GridMap when saved selection is missing"
    )


func _test_level_one_enables_gridmap_auto_repair() -> bool:
    var settings := ResourceLoader.load("res://levels/1/png_to_gridmap_settings.tres")
    return _expect(
        settings != null
            and settings.target_gridmap_path == NodePath("GridMap")
            and settings.auto_repair,
        "Level 1 targets its authored GridMap with automatic repair enabled"
    )


func _test_torch_scene_and_persistent_activation() -> bool:
    var torch_scene := TORCH_SCENE.instantiate()
    var mount := torch_scene.get_node("RaisedWallMount") as Node3D
    var particles := torch_scene.get_node(
        "RaisedWallMount/FabricFlameAttachment/FlameParticles"
    ) as GPUParticles3D
    var embers := torch_scene.get_node(
        "RaisedWallMount/FabricFlameAttachment/EmberParticles"
    ) as CPUParticles3D
    var light := torch_scene.get_node(
        "RaisedWallMount/FabricFlameAttachment/FlameLight"
    ) as OmniLight3D
    var outline_mesh := torch_scene.get_node(
        "RaisedWallMount/Model/RootNode/Torch1"
    ) as MeshInstance3D
    var editor_light_range := light.omni_range
    root.add_child(torch_scene)
    var passed := _expect(
        mount.rotation.is_zero_approx(),
        "torch model stands upright at its wall-placement origin"
    ) and _expect(
        is_equal_approx(mount.position.z, 0.22) and mount.scale.is_equal_approx(Vector3.ONE * 1.5),
        "torch model remains visible outside the wall when placed at a wall section origin"
    ) and _expect(
        particles.get_parent().name == "FabricFlameAttachment",
        "torch flame particles are attached at the model's fabric"
    ) and _expect(
        particles.draw_pass_1.material is ShaderMaterial \
        and (particles.draw_pass_1.material as ShaderMaterial).shader.resource_path \
        == "res://placeables/torch/torch_flame.gdshader",
        "torch flame uses the animated procedural flame material"
    ) and _expect(
        embers != null and embers.get_parent() == particles.get_parent(),
        "torch flame includes rising embers at the fabric attachment"
    ) and _expect(
        particles.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_OFF \
        and embers.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_OFF,
        "transparent torch particles do not project card-shaped shadows"
    ) and _expect(
        (mount.basis * (particles.process_material as ParticleProcessMaterial).direction) \
        .normalized().is_equal_approx(Vector3.UP),
        "upright torch flame rises vertically"
    ) and _expect(
        light != null and not light.visible and not particles.emitting and not embers.emitting,
        "torch light and flame begin unlit"
    ) and _expect(
        light.shadow_enabled,
        "torch omni illumination retains dungeon shadow casting"
    ) and _expect(
        light.is_in_group(GDIndoorLighting.AUTHORED_SHADOW_SETTINGS_GROUP) \
        and is_equal_approx(light.shadow_bias, 0.03) \
        and is_equal_approx(light.shadow_normal_bias, 0.6),
        "torch retains authored anti-acne shadow bias in indoor levels"
    ) and _expect(
        outline_mesh.layers == GDTorch.TORCH_GEOMETRY_VISUAL_LAYER \
        and light.light_cull_mask & outline_mesh.layers == outline_mesh.layers \
        and light.shadow_caster_mask & outline_mesh.layers == 0 \
        and light.shadow_caster_mask & 1 == 1 \
        and light.light_cull_mask & 1 == 1,
        "torch light illuminates its model but excludes it only from shadow casting"
    ) and _expect(
        is_equal_approx(editor_light_range, 0.1) and is_equal_approx(light.omni_range, 7.0),
        "torch keeps light bounds small for editor placement and restores gameplay range at runtime"
    )

    var outline_player := Node3D.new()
    outline_player.position = Vector3(0.0, 0.0, -2.0)
    root.add_child(outline_player)
    torch_scene.update_outline_for_player(outline_player)
    var outline_material := outline_mesh.material_overlay as ShaderMaterial
    passed = _expect(
        outline_material.shader.resource_path \
        == "res://placeables/torch/torch_outline.gdshader" \
        and float(
            outline_mesh.get_instance_shader_parameter(&"outline_intensity")
        ) > 0.0,
        "an unlit torch gains a subtle shader outline when the player approaches"
    ) and _expect(
        torch_scene.find_children("*", "MeshInstance3D", true, false).size() == 1,
        "torch guidance reuses the original model without duplicate shadow geometry"
    ) and passed
    torch_scene._set_lit(false)
    passed = _expect(
        is_zero_approx(float(
            outline_mesh.get_instance_shader_parameter(&"outline_intensity")
        )),
        "lighting a torch immediately removes its proximity outline"
    ) and passed
    outline_player.queue_free()
    torch_scene.queue_free()

    var level_selection := TestLevelSelection.new()
    var torch := TestTorch.new()
    torch.level_selection = level_selection
    torch.torch_id = &"test_wall_torch"
    torch.torch_activation_time = 100.0
    torch.activation_distance = 2.0
    root.add_child(torch)
    var player := CharacterBody3D.new()
    player.position = Vector3(0.0, 0.0, -1.0)
    root.add_child(player)
    var pivot := Node3D.new()
    pivot.name = "Pivot"
    player.add_child(pivot)

    player.velocity = Vector3(0.5, 0.0, 0.0)
    torch.update_activation_for_player(player, 0.06)
    passed = _expect(
        is_zero_approx(torch.activation_elapsed_ms),
        "torch activation does not begin while the player is moving"
    ) and passed
    player.velocity = Vector3.ZERO
    torch.update_activation_for_player(player, 0.06)
    pivot.rotation.y = PI
    torch.update_activation_for_player(player, 0.06)
    passed = _expect(
        is_zero_approx(torch.activation_elapsed_ms),
        "looking away resets partial torch activation"
    ) and passed
    pivot.rotation.y = 0.0
    torch.update_activation_for_player(player, 0.1)
    passed = _expect(torch.is_lit, "facing a torch for its activation time lights it") and passed
    passed = _expect(
        level_selection.is_torch_lit(&"test_wall_torch"),
        "lighting a torch stores it in the selected level's user progress"
    ) and passed

    var restored_torch := TestTorch.new()
    restored_torch.level_selection = level_selection
    restored_torch.torch_id = &"test_wall_torch"
    root.add_child(restored_torch)
    passed = _expect(
        restored_torch.is_lit,
        "a previously lit torch restores its lit state when the level restarts"
    ) and passed

    player.queue_free()
    torch.queue_free()
    restored_torch.queue_free()
    level_selection.free()
    return passed


func _test_indoor_lighting_strengthens_occlusion() -> bool:
    var level := Node3D.new()
    root.add_child(level)
    var grid_map := GridMap.new()
    var mesh_library := MeshLibrary.new()
    var wall_mesh_source := load("res://Assets/environment/wall.res") as ArrayMesh
    var wall_mesh := wall_mesh_source.duplicate(true) as ArrayMesh
    mesh_library.create_item(0)
    mesh_library.set_item_name(0, "Wall")
    mesh_library.set_item_mesh(0, wall_mesh)
    mesh_library.set_item_mesh_cast_shadow(
        0,
        RenderingServer.SHADOW_CASTING_SETTING_ON
    )
    mesh_library.create_item(1)
    mesh_library.set_item_name(1, "Road")
    mesh_library.set_item_mesh(1, BoxMesh.new())
    grid_map.mesh_library = mesh_library
    grid_map.set_cell_item(Vector3i.ZERO, 0)
    grid_map.set_cell_item(Vector3i.RIGHT, 1)
    level.add_child(grid_map)
    var headlamp := SpotLight3D.new()
    headlamp.shadow_enabled = true
    headlamp.position.y = 1.05
    headlamp.shadow_bias = 0.03
    headlamp.shadow_normal_bias = 0.6
    headlamp.spot_angle = 82.0
    headlamp.spot_range = 60.0
    headlamp.spot_attenuation = 1.25
    headlamp.name = "PlayerHeadlampLight"
    level.add_child(headlamp)
    var light := OmniLight3D.new()
    light.shadow_enabled = true
    light.shadow_bias = 0.03
    light.shadow_normal_bias = 0.6
    light.name = "PlayerLight"
    light.position = headlamp.position
    level.add_child(light)
    var room_light := OmniLight3D.new()
    room_light.shadow_enabled = true
    room_light.shadow_opacity = 0.25
    room_light.shadow_bias = 0.1
    room_light.shadow_normal_bias = 2.0
    level.add_child(room_light)
    var effect_light := OmniLight3D.new()
    effect_light.shadow_enabled = false
    effect_light.shadow_opacity = 0.25
    level.add_child(effect_light)
    var indoor_lighting := INDOOR_LIGHTING_SCENE.instantiate() as GDIndoorLighting
    level.add_child(indoor_lighting)
    indoor_lighting.strengthen_level_shadows()

    var passed := _expect(light.shadow_enabled, "indoor lights cast shadows") \
        and _expect(light.visible, "indoor levels enable the player's omni fill light") \
        and _expect(
            light.global_position.is_equal_approx(headlamp.global_position),
            "indoor omni fill originates at the headlamp"
        ) \
        and _expect(
            is_equal_approx(headlamp.position.y, 1.05),
            "indoor headlamps retain their authored height"
        ) \
        and _expect(
            is_equal_approx(headlamp.spot_angle, 82.0),
            "indoor headlamps retain their editor-authored cone"
        ) \
        and _expect(
            is_equal_approx(headlamp.spot_range, 60.0),
            "indoor headlamps retain their editor-authored range"
        ) \
        and _expect(
            is_equal_approx(headlamp.spot_attenuation, 1.25),
            "indoor headlamps retain their editor-authored falloff"
        ) \
        and _expect(is_equal_approx(room_light.shadow_opacity, 1.0), \
            "indoor room-light shadows are fully opaque") \
        and _expect(is_equal_approx(room_light.shadow_bias, 0.03), \
            "indoor room-light shadows avoid surface acne") \
        and _expect(
            is_equal_approx(room_light.shadow_normal_bias, 0.6),
            "indoor room-light wall faces avoid self-shadowing"
        ) \
        and _expect(_player_scene_owns_light_tuning(), \
            "player light tuning is authored in the player scene") \
        and _expect(
            is_equal_approx(effect_light.shadow_opacity, 0.25),
            "indoor effect lights remain free of shadow overrides"
        ) \
        and _expect(not headlamp.shadow_reverse_cull_face, \
            "indoor lights keep normal shadow-face culling") \
        and _expect(_grid_map_has_dedicated_shadow_caster(grid_map), \
            "indoor GridMaps use dedicated wall-only geometry for reliable shadows")

    level.queue_free()
    return passed


func _player_scene_owns_light_tuning() -> bool:
    var player := PLAYER_SCENE.instantiate()
    var headlamp := player.get_node_or_null("Pivot/PlayerHeadlampLight") as SpotLight3D
    var fill_light := player.get_node_or_null("Pivot/PlayerLight") as OmniLight3D
    var passed := headlamp != null \
        and fill_light != null \
        and headlamp.visible \
        and fill_light.visible \
        and headlamp.position.is_equal_approx(fill_light.position) \
        and is_equal_approx(headlamp.spot_angle, 82.0) \
        and is_equal_approx(headlamp.spot_range, 60.0) \
        and is_equal_approx(headlamp.spot_attenuation, 1.25) \
        and is_equal_approx(headlamp.shadow_bias, 0.03) \
        and is_equal_approx(headlamp.shadow_normal_bias, 0.6) \
        and is_equal_approx(fill_light.shadow_bias, 0.03) \
        and is_equal_approx(fill_light.shadow_normal_bias, 0.6)
    player.free()
    return passed


func _grid_map_has_dedicated_shadow_caster(grid_map: GridMap) -> bool:
    var shadow_casters := grid_map.get_node_or_null("GridMapShadowCasters")
    if shadow_casters == null or shadow_casters.get_child_count() != 1:
        return false

    var caster := shadow_casters.get_child(0) as MultiMeshInstance3D
    if caster == null or caster.multimesh == null:
        return false

    var wall_mesh := grid_map.mesh_library.get_item_mesh(0)
    var caster_mesh := caster.multimesh.mesh as BoxMesh
    var caster_material := caster.material_override as BaseMaterial3D
    return caster.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY \
        and caster.multimesh.instance_count == 1 \
        and caster_mesh != null \
        and caster_mesh.size.x < wall_mesh.get_aabb().size.x \
        and is_equal_approx(caster_mesh.size.y, wall_mesh.get_aabb().size.y) \
        and caster_mesh.size.z < wall_mesh.get_aabb().size.z \
        and caster_material != null \
        and caster_material.cull_mode == BaseMaterial3D.CULL_DISABLED


func _test_player_landing_uses_new_sample_after_a_meaningful_fall() -> bool:
    var player := PLAYER_SCENE.instantiate() as GDPlayer
    if not _expect(player != null, "player scene instantiates for landing audio test"):
        return false

    root.add_child(player)
    player.set_physics_process(false)
    var movement := player.get_node("PlayerMovement") as GDPlayerMovement
    movement.call("_process_landing_state", true, 0.0)
    var suppresses_initial_floor_contact := player.get_node_or_null("LandingAudio") == null

    movement.call("_process_landing_state", false, 0.5)
    movement.call("_process_landing_state", true, 0.0)
    var suppresses_small_floor_step := player.get_node_or_null("LandingAudio") == null

    movement.call("_process_landing_state", false, 3.0)
    movement.call("_process_landing_state", true, 0.0)
    var landing_audio := player.get_node_or_null("LandingAudio") as AudioStreamPlayer3D
    var loaded_landing_sound := movement.get("landing_sound") as AudioStream
    var settings := GDPlayerMovement.JUMP_SETTINGS as GDPlayerJumpSettings
    var uses_new_landing_sample := landing_audio != null \
        and landing_audio.stream == loaded_landing_sound \
        and settings.landing_sound_path == "res://Assets/audio/player-landing.mp3" \
        and is_equal_approx(landing_audio.volume_db, settings.landing_volume_db) \
        and landing_audio.pitch_scale >= settings.landing_pitch_min \
        and landing_audio.pitch_scale <= settings.landing_pitch_max
    player.free()

    return _expect(
        suppresses_initial_floor_contact,
        "player landing audio does not play merely because the scene starts on the floor"
    ) and _expect(
        suppresses_small_floor_step,
        "player landing audio ignores tiny floor steps"
    ) and _expect(
        uses_new_landing_sample,
        "a meaningful player fall plays the configured new landing sample"
    )


func _test_player_fall_death_threshold() -> bool:
    if not _expect(PLAYER_SCENE != null, "player scene loads for fall-death threshold test"):
        return false

    var player := PLAYER_SCENE.instantiate() as GDPlayer
    if not _expect(player != null, "player scene instantiates for fall-death threshold test"):
        return false

    root.add_child(player)
    player.global_position.y = GDPlayer.FLOOR_LEVEL_Y - GDPlayer.FALL_DEATH_DEPTH
    var survives_at_threshold := not player.is_below_fall_death_height()

    player.global_position.y -= 0.01
    var dies_below_threshold := player.is_below_fall_death_height()
    player.free()

    return _expect(survives_at_threshold, "player survives exactly four metres below the floor") \
        and _expect(dies_below_threshold, "player dies below four metres under the floor")


func _test_pickup_radius_flasks_stack_and_expire_independently() -> bool:
    var properties := load(
        "res://placeables/collectibles/global_flask_properties.tres"
    ) as GDGlobalFlaskProperties
    var player := PLAYER_SCENE.instantiate() as GDPlayer
    root.add_child(player)
    player.set_physics_process(false)

    var first_stack_applied := player.increase_pickup_radius_percent_for(50.0, 0.2)
    var one_stack_multiplier := player.get_pickup_radius_multiplier()
    await create_timer(0.11).timeout
    var second_stack_applied := player.increase_pickup_radius_percent_for(50.0, 0.2)
    var two_stack_multiplier := player.get_pickup_radius_multiplier()
    await create_timer(0.11).timeout
    var first_stack_expired_multiplier := player.get_pickup_radius_multiplier()
    await create_timer(0.11).timeout
    var all_stacks_expired_multiplier := player.get_pickup_radius_multiplier()
    player.free()

    return _expect(
        properties != null and is_equal_approx(properties.pickup_radius_seconds, 15.0),
        "pickup radius flasks display and apply a fifteen-second timer"
    ) and _expect(
        first_stack_applied \
            and second_stack_applied \
            and is_equal_approx(one_stack_multiplier, 1.5) \
            and is_equal_approx(two_stack_multiplier, 2.25),
        "collecting a second pickup radius flask increases the active pickup radius again"
    ) and _expect(
        is_equal_approx(first_stack_expired_multiplier, 1.5) \
            and is_equal_approx(all_stacks_expired_multiplier, 1.0),
        "each pickup radius flask stack expires on its own timer"
    )


func _test_pickup_radius_does_not_affect_treasure_deposit_range() -> bool:
    var player := PLAYER_SCENE.instantiate() as GDPlayer
    root.add_child(player)
    player.set_physics_process(false)
    player.increase_pickup_radius_percent_for(50.0, 5.0)

    var coin := GOLD_COIN_SCENE.instantiate() as GDGoldCoin
    root.add_child(coin)
    coin.set_physics_process(false)
    var coin_pickup_shape := coin.get_node(
        "PickupArea/CollisionShape3D"
    ) as CollisionShape3D
    var base_pickup_scale := coin_pickup_shape.get_meta(
        "base_pickup_scale"
    ) as Vector3
    var one_stack_pickup_scale := coin_pickup_shape.scale

    var coffin := TREASURE_DEPOSIT_COFFIN_SCENE.instantiate() as Node3D
    root.add_child(coffin)
    var deposit := coffin.get_node("TreasureDeposit") as GDTreasureDeposit
    var deposit_shape := deposit.get_node(
        "DepositArea/CollisionShape3D"
    ) as CollisionShape3D
    var initial_deposit_scale := deposit_shape.scale

    player.increase_pickup_radius_percent_for(50.0, 5.0)
    var two_stack_pickup_scale := coin_pickup_shape.scale
    var boosted_deposit_scale := deposit_shape.scale
    var deposit_radius := (deposit_shape.shape as SphereShape3D).radius
    var deposit_ignores_pickup_radius := not deposit.is_in_group(
        &"pickup_radius_scalable"
    ) \
        and initial_deposit_scale.is_equal_approx(Vector3.ONE) \
        and boosted_deposit_scale.is_equal_approx(Vector3.ONE) \
        and is_equal_approx(deposit_radius, deposit.detection_radius)

    coin.free()
    coffin.free()
    player.free()
    var passed := _expect(
        deposit_ignores_pickup_radius,
        "pickup radius flask stacks leave the coffin drop-off radius unchanged"
    )
    return _expect(
        one_stack_pickup_scale.is_equal_approx(base_pickup_scale * 1.5) \
            and two_stack_pickup_scale.is_equal_approx(base_pickup_scale * 2.25),
        "pickup radius flask stacks continue to expand loose treasure pickup areas"
    ) and passed


func _test_player_death_uses_face_blood_and_body_throes() -> bool:
    var floor := StaticBody3D.new()
    floor.collision_layer = 1
    var floor_collision := CollisionShape3D.new()
    var floor_shape := BoxShape3D.new()
    floor_shape.size = Vector3(4.0, 0.1, 4.0)
    floor_collision.shape = floor_shape
    floor.add_child(floor_collision)
    floor.position.y = -0.05
    root.add_child(floor)
    var player := PLAYER_SCENE.instantiate() as GDPlayer
    root.add_child(player)
    player.set_physics_process(false)
    await physics_frame

    var death_controller := player.get_node("PlayerDeath") as GDPlayerDeath
    var death_effects := player.get_node("PlayerDeathEffects") as Node3D
    var attention := player.get_node("PlayerAttention") as GDPlayerAttention
    var head := player.get_node(
        "Pivot/Character/character-keeper/root/torso/head"
    ) as Node3D
    var visual_pivot := player.get_node("Pivot") as Node3D
    var blood_emitters: Array[GPUParticles3D] = [
        player.get_node("PlayerDeathEffects/MouthBlood") as GPUParticles3D,
        player.get_node("PlayerDeathEffects/NoseBlood") as GPUParticles3D,
        player.get_node("PlayerDeathEffects/LeftEyeBlood") as GPUParticles3D,
        player.get_node("PlayerDeathEffects/RightEyeBlood") as GPUParticles3D,
    ]
    death_controller.return_delay = 60.0
    var base_pivot_rotation := visual_pivot.rotation
    player.die_from_fall()

    var all_face_sources_keep_emitting := true
    for emitter in blood_emitters:
        all_face_sources_keep_emitting = all_face_sources_keep_emitting \
            and emitter.visible \
            and emitter.emitting \
            and not emitter.one_shot \
            and not emitter.local_coords \
            and emitter.process_material is ParticleProcessMaterial
    var head_inverse := head.global_transform.affine_inverse()
    var face_sources_are_placed := (
        head_inverse * blood_emitters[0].global_transform
    ).origin.is_equal_approx(PLAYER_DEATH_EFFECTS_SCRIPT.MOUTH_FACE_OFFSET) \
        and (
            head_inverse * blood_emitters[1].global_transform
        ).origin.is_equal_approx(PLAYER_DEATH_EFFECTS_SCRIPT.NOSE_FACE_OFFSET) \
        and (
            head_inverse * blood_emitters[2].global_transform
        ).origin.is_equal_approx(PLAYER_DEATH_EFFECTS_SCRIPT.LEFT_EYE_FACE_OFFSET) \
        and (
            head_inverse * blood_emitters[3].global_transform
        ).origin.is_equal_approx(PLAYER_DEATH_EFFECTS_SCRIPT.RIGHT_EYE_FACE_OFFSET)
    await create_timer(0.04).timeout
    var body_has_started_twitching := not visual_pivot.rotation.is_equal_approx(
        base_pivot_rotation
    )
    await create_timer(
        float(death_effects.get("environment_splatter_delay")) + 0.08
    ).timeout
    var player_splatter := death_effects.call("get_player_splatter") as Node3D
    var environment_splatter := death_effects.call("get_environment_splatter") as Node3D
    var player_decal := player_splatter.get_node_or_null("Decal") as Decal \
        if player_splatter != null else null
    var environment_decal := environment_splatter.get_node_or_null("Decal") as Decal \
        if environment_splatter != null else null
    var player_surface_mark := player_splatter.get_node_or_null(
        "SurfaceMark"
    ) as MeshInstance3D if player_splatter != null else null
    var environment_surface_mark := environment_splatter.get_node_or_null(
        "SurfaceMark"
    ) as MeshInstance3D if environment_splatter != null else null
    var player_impact := player_splatter.get_node_or_null(
        "ImpactBlood"
    ) as GPUParticles3D if player_splatter != null else null
    var environment_impact := environment_splatter.get_node_or_null(
        "ImpactBlood"
    ) as GPUParticles3D if environment_splatter != null else null
    var head_mesh := head as MeshInstance3D
    var head_bounds := head_mesh.get_aabb()
    var current_head_inverse := head.global_transform.affine_inverse()
    var sources_are_below_hat := true
    for emitter in blood_emitters:
        var source_offset := (current_head_inverse * emitter.global_transform).origin
        sources_are_below_hat = sources_are_below_hat \
            and source_offset.y < head_bounds.position.y + head_bounds.size.y * 0.5 \
            and source_offset.z > 0.16 \
            and source_offset.z < 0.21
    var player_projector_reaches_face := player_splatter != null \
        and player_decal != null \
        and absf(player_splatter.position.z - 0.174) < player_decal.size.y * 0.5
    var splatters_attach_to_their_receivers := player_splatter != null \
        and environment_splatter != null \
        and player_splatter.get_parent() == head \
        and environment_splatter.get_parent() == floor \
        and player_decal != null \
        and environment_decal != null \
        and player_decal.cull_mask == BLOOD_SPLATTER_DECAL_SCRIPT.PLAYER_VISUAL_LAYER \
        and environment_decal.cull_mask \
            == BLOOD_SPLATTER_DECAL_SCRIPT.ENVIRONMENT_VISUAL_LAYER \
        and player_decal.texture_albedo != null \
        and environment_decal.texture_albedo == player_decal.texture_albedo \
        and player_decal.texture_emission == player_decal.texture_albedo \
        and environment_decal.texture_emission == environment_decal.texture_albedo \
        and player_surface_mark != null \
        and player_surface_mark.mesh != null \
        and environment_surface_mark != null \
        and environment_surface_mark.mesh != null \
        and player_impact != null \
        and player_impact.one_shot \
        and player_impact.amount == 8 \
        and environment_impact != null \
        and environment_impact.one_shot \
        and environment_impact.amount == 18

    var passed := _expect(
        death_controller.is_dead \
            and bool(death_effects.get("is_playing")) \
            and not attention.is_processing() \
            and body_has_started_twitching,
        "player death overlays diminishing body throes without live attention movement"
    ) and _expect(
        all_face_sources_keep_emitting \
            and face_sources_are_placed \
            and sources_are_below_hat,
        "player death keeps spraying blood from facial features below the hat"
    ) and _expect(
        splatters_attach_to_their_receivers and player_projector_reaches_face,
        "blood impacts visibly mark and overlap the corpse and contacted environment"
    )
    player.queue_free()
    floor.queue_free()
    await process_frame
    return passed


func _test_fire_boundary_death_blackens_and_burns_player() -> bool:
    var player := PLAYER_SCENE.instantiate() as GDPlayer
    root.add_child(player)
    player.set_physics_process(false)
    var death_controller := player.get_node("PlayerDeath") as GDPlayerDeath
    var death_effects := player.get_node("PlayerDeathEffects") as GDPlayerDeathEffects
    var fire_particles := player.get_node(
        "PlayerDeathEffects/FireParticles"
    ) as GPUParticles3D
    var fire_light := player.get_node("PlayerDeathEffects/FireLight") as OmniLight3D
    var blood_emitters: Array[GPUParticles3D] = [
        player.get_node("PlayerDeathEffects/MouthBlood") as GPUParticles3D,
        player.get_node("PlayerDeathEffects/NoseBlood") as GPUParticles3D,
        player.get_node("PlayerDeathEffects/LeftEyeBlood") as GPUParticles3D,
        player.get_node("PlayerDeathEffects/RightEyeBlood") as GPUParticles3D,
    ]
    var character := player.get_node("Pivot/Character") as Node3D
    var torso := player.get_node(
        "Pivot/Character/character-keeper/root/torso"
    ) as MeshInstance3D
    var head := player.get_node(
        "Pivot/Character/character-keeper/root/torso/head"
    ) as MeshInstance3D
    var visual_pivot := player.get_node("Pivot") as Node3D
    var base_pivot_rotation := visual_pivot.rotation
    death_controller.return_delay = 60.0

    player.apply_kill_boundary_damage(death_controller.max_flame_energy, true)
    await create_timer(0.045).timeout
    var pronounced_fire_throe_started := visual_pivot.rotation.distance_to(
        base_pivot_rotation
    ) > deg_to_rad(10.0)
    await create_timer(0.305).timeout

    var character_meshes := character.find_children("*", "MeshInstance3D", true, false)
    var every_character_mesh_is_blackened := not character_meshes.is_empty()
    for descendant in character_meshes:
        var character_mesh := descendant as MeshInstance3D
        every_character_mesh_is_blackened = every_character_mesh_is_blackened \
            and character_mesh.material_overlay == death_effects.blackened_material
    var blood_was_suppressed := true
    for emitter in blood_emitters:
        blood_was_suppressed = blood_was_suppressed \
            and not emitter.visible \
            and not emitter.emitting
    var fire_process_material := fire_particles.process_material as ParticleProcessMaterial
    var head_fire_position := fire_particles.global_transform.affine_inverse() \
        * head.global_position
    var torso_fire_position := fire_particles.global_transform.affine_inverse() \
        * torso.global_position
    var fire_extents := fire_process_material.emission_box_extents
    var upper_body_stays_inside_fire_volume := (
        absf(head_fire_position.x) <= fire_extents.x \
        and absf(head_fire_position.y) <= fire_extents.y \
        and absf(head_fire_position.z) <= fire_extents.z \
        and absf(torso_fire_position.x) <= fire_extents.x \
        and absf(torso_fire_position.y) <= fire_extents.y \
        and absf(torso_fire_position.z) <= fire_extents.z
    )
    var fire_mesh := fire_particles.draw_pass_1 as QuadMesh
    var fire_shader_material := fire_mesh.material as ShaderMaterial
    var fire_shader_code := fire_shader_material.shader.code
    var particles_keep_individual_positions := fire_shader_code.contains(
        "particle_position = MODELVIEW_MATRIX[3]"
    ) and not fire_shader_code.contains("MODEL_MATRIX[3]")

    var passed := _expect(
        death_controller.is_dead \
            and every_character_mesh_is_blackened \
            and fire_particles.visible \
            and fire_particles.emitting \
            and fire_particles.amount >= 80 \
            and fire_particles.process_material is ParticleProcessMaterial \
            and fire_light.visible,
        "fire kill-boundary death blackens the player under flames covering the body"
    ) and _expect(
        upper_body_stays_inside_fire_volume and particles_keep_individual_positions,
        "fire particles remain distributed over the fallen player's torso and head"
    ) and _expect(
        pronounced_fire_throe_started and death_effects.throe_tween.is_running(),
        "burning player begins pronounced sustained death throes"
    ) and _expect(
        blood_was_suppressed,
        "fire kill-boundary death replaces the ordinary blood presentation"
    )
    player.queue_free()
    await process_frame
    return passed


func _test_held_drop_input_accelerates() -> bool:
    var inventory := GDPlayerInventory.new()
    var starting_interval := inventory._get_drop_repeat_interval(0.0)
    var middle_interval := inventory._get_drop_repeat_interval(
        GDPlayerInventory.DROP_REPEAT_ACCELERATION_TIME * 0.5
    )
    var minimum_interval := inventory._get_drop_repeat_interval(
        GDPlayerInventory.DROP_REPEAT_ACCELERATION_TIME
    )
    var interval_after_ramp := inventory._get_drop_repeat_interval(
        GDPlayerInventory.DROP_REPEAT_ACCELERATION_TIME * 2.0
    )
    var linear_middle_interval := lerpf(
        GDPlayerInventory.DROP_REPEAT_START_INTERVAL,
        GDPlayerInventory.DROP_REPEAT_MIN_INTERVAL,
        0.5
    )

    var passed := _expect(middle_interval < starting_interval, "held drop input accelerates over time") \
        and _expect(minimum_interval < middle_interval, "held drop input reaches a faster final cadence") \
        and _expect(
            middle_interval > linear_middle_interval,
            "held drop input gathers speed more strongly near the end of the ramp"
        ) \
        and _expect(
            is_equal_approx(interval_after_ramp, minimum_interval),
            "held drop input acceleration stops at its minimum interval"
        )
    inventory.free()
    return passed


func _test_drop_direction_variation_is_deterministic_and_compact() -> bool:
    var first_inventory := GDPlayerInventory.new()
    var second_inventory := GDPlayerInventory.new()
    first_inventory.drop_position_rng.seed = 12345
    second_inventory.drop_position_rng.seed = 12345
    var back := Vector3.BACK
    var has_sideways_variation := false
    var passed := true

    for drop_index in range(12):
        var first_direction := first_inventory._get_varied_drop_direction(back)
        var second_direction := second_inventory._get_varied_drop_direction(back)
        var angle := back.angle_to(first_direction)
        has_sideways_variation = has_sideways_variation or not is_zero_approx(first_direction.x)
        passed = _expect(
            first_direction.is_equal_approx(second_direction),
            "drop direction variation repeats for the same deterministic seed"
        ) and passed
        passed = _expect(
            angle <= GDPlayerInventory.DROP_DIRECTION_VARIANCE_RADIANS + 0.0001,
            "drop direction variation stays within the compact spread"
        ) and passed

    passed = _expect(has_sideways_variation, "drop direction variation breaks up straight coin lines") and passed
    first_inventory.free()
    second_inventory.free()
    return passed


func _test_all_treasure_uses_indoor_lighting_and_coin_outline() -> bool:
    var coin := GOLD_COIN_SCENE.instantiate() as GDGoldCoin
    root.add_child(coin)
    var coin_meshes := coin.find_children("*", "MeshInstance3D", true, false)
    var coin_mesh := coin_meshes[0] as MeshInstance3D \
        if not coin_meshes.is_empty() else null
    var coin_model_root := coin.get_node_or_null("CoinMesh") as Node3D
    var coin_collision := coin.get_node_or_null("CollisionShape3D") as CollisionShape3D
    var coin_convex_shape := coin_collision.shape as ConvexPolygonShape3D \
        if coin_collision != null else null
    var coin_material: Material = (
        coin_mesh.get_active_material(0) if coin_mesh != null else null
    )
    var coin_outline: ShaderMaterial = (
        coin_mesh.material_overlay as ShaderMaterial if coin_mesh != null else null
    )
    var shared_shape_coin := GOLD_COIN_SCENE.instantiate() as GDGoldCoin
    root.add_child(shared_shape_coin)
    var shared_shape_collision := shared_shape_coin.get_node(
        "CollisionShape3D"
    ) as CollisionShape3D
    var bar := GOLD_BAR_SCENE.instantiate() as GDGoldBar
    root.add_child(bar)
    var bar_meshes := bar.find_children("*", "MeshInstance3D", true, false)
    var bar_mesh := bar_meshes[0] as MeshInstance3D if not bar_meshes.is_empty() else null
    var bar_material: Material = (
        bar_mesh.get_surface_override_material(0) if bar_mesh != null else null
    )
    var bar_outline: Material = bar_mesh.material_overlay if bar_mesh != null else null
    var gem := DIAMOND_SCENE.instantiate() as GDDiamond
    root.add_child(gem)
    var gem_meshes := gem.find_children("*", "MeshInstance3D", true, false)
    var gem_mesh := gem_meshes[0] as MeshInstance3D if not gem_meshes.is_empty() else null
    var gem_outline: Material = gem_mesh.material_overlay if gem_mesh != null else null
    var indoor_lighting := INDOOR_LIGHTING_SCENE.instantiate() as GDIndoorLighting
    var world_environment := (
        indoor_lighting.get_node_or_null("WorldEnvironment") as WorldEnvironment
    )
    var environment: Environment = (
        world_environment.environment if world_environment != null else null
    )
    var gold_material := GOLD_TREASURE_MATERIAL as StandardMaterial3D
    var incoming_coin := GOLD_COIN_SCENE.instantiate() as GDGoldCoin
    var incoming_mesh_root := incoming_coin.get_node("CoinMesh") as Node3D
    var incoming_meshes := incoming_mesh_root.find_children(
        "*", "MeshInstance3D", true, false
    )
    var incoming_nested_mesh := incoming_meshes[0] as MeshInstance3D
    var incoming_mesh_width := incoming_nested_mesh.get_aabb().size.x
    incoming_nested_mesh.position = Vector3(0.25, 0.0, 0.0)
    incoming_nested_mesh.scale = Vector3(2.0, 1.0, 1.0)
    root.add_child(incoming_coin)
    var incoming_collision := incoming_coin.get_node("CollisionShape3D") as CollisionShape3D
    var incoming_shape := incoming_collision.shape as ConvexPolygonShape3D
    var incoming_bounds := AABB()
    var has_incoming_bounds := incoming_shape != null and not incoming_shape.points.is_empty()
    if has_incoming_bounds:
        incoming_bounds = AABB(incoming_shape.points[0], Vector3.ZERO)
        for point in incoming_shape.points:
            incoming_bounds = incoming_bounds.expand(point)

    var passed := _expect(
        coin_material is StandardMaterial3D \
            and (coin_material as StandardMaterial3D).metallic > 0.0 \
            and (coin_material as StandardMaterial3D).normal_texture != null \
            and (coin_material as StandardMaterial3D).normal_texture.resource_path \
                == "res://Assets/environment/skull-coin_skulldugger.png",
        "coins use the textured metallic skull model"
    ) and _expect(
        coin_model_root != null \
            and coin_model_root.scene_file_path \
                == "res://Assets/environment/skull-coin.glb" \
            and coin_mesh != null \
            and coin_mesh.get_aabb().size.is_equal_approx(
                Vector3(0.1280421, 0.0160053, 0.1280421)
            ),
        "coins retain the skull model's authored hierarchy and dimensions"
    ) and _expect(
        coin_convex_shape != null and coin_convex_shape.points.size() >= 4,
        "coin physics builds a convex hull from its visual mesh"
    ) and _expect(
        shared_shape_collision.shape == coin_convex_shape,
        "identical coins share one cached convex physics hull"
    ) and _expect(
        has_incoming_bounds \
            and absf(incoming_bounds.size.x - incoming_mesh_width * 2.0) <= 0.001 \
            and is_equal_approx(incoming_bounds.get_center().x, 0.25),
        (
            "coin physics follows transformed meshes inside an incoming model hierarchy "
            + "(width %.6f/%.6f, centre %.6f/0.250000)"
        ) % [
            incoming_bounds.size.x,
            incoming_mesh_width * 2.0,
            incoming_bounds.get_center().x,
        ]
    ) and _expect(
        bar_material == GOLD_TREASURE_MATERIAL,
        "the imported gold-bar model receives the shared material override"
    ) and _expect(
        gold_material.metallic > 0.0 and gold_material.roughness > 0.0,
        "gold treasure retains reflective lighting and visible surface shape"
    ) and _expect(
        gold_material.emission_enabled \
            and is_zero_approx(gold_material.emission_energy_multiplier),
        "gold treasure depends on scene lighting instead of flat fill emission"
    ) and _expect(
        coin_outline != null \
            and coin_outline == TREASURE_OUTLINE_MATERIAL \
            and coin_outline.shader.resource_path \
            == "res://placeables/treasure/coin_outline.gdshader" \
            and (coin_outline.get_shader_parameter(&"outline_color") as Color) \
            == Color(1.0, 0.72, 0.12, 0.45) \
            and float(coin_outline.get_shader_parameter(&"outline_emission")) \
            * (coin_outline.get_shader_parameter(&"outline_color") as Color).a > 1.0 \
            and float(coin_outline.get_shader_parameter(&"outline_width")) > 0.0 \
            and coin_outline.shader.code.contains("unshaded") \
            and coin_outline.shader.code.contains("blend_add") \
            and coin_outline.shader.code.contains("cull_front") \
            and not coin_outline.shader.code.contains("shadow_to_opacity"),
        "the shared treasure outline remains visible and bloom-capable under every light condition"
    ) and _expect(
        bar_outline == TREASURE_OUTLINE_MATERIAL \
            and gem_outline == TREASURE_OUTLINE_MATERIAL,
        "gold bars and gems use the same outline material as coins"
    ) and _expect(
        coin.find_children("*", "MeshInstance3D", true, false).size() == 1,
        "coin guidance reuses the existing mesh instead of adding duplicate geometry"
    ) and _expect(
        environment != null and environment.glow_enabled and environment.glow_bloom > 0.0,
        "indoor lighting enables a modest bloom for emissive treasure"
    )

    indoor_lighting.free()
    incoming_coin.free()
    shared_shape_coin.free()
    gem.free()
    bar.free()
    coin.free()
    return passed


func _test_gold_bar_uses_inventory_capacity_and_physics_drop() -> bool:
    var authored_bar := GOLD_BAR_SCENE.instantiate() as GDGoldBar
    root.add_child(authored_bar)
    var authored_collision := authored_bar.get_node_or_null("CollisionShape3D") as CollisionShape3D
    var authored_shape: Shape3D = authored_collision.shape if authored_collision != null else null
    var world_body := StaticBody3D.new()
    world_body.collision_layer = 1
    root.add_child(world_body)
    authored_bar.call("_on_body_entered", world_body)
    var landing_audio := authored_bar.get_node_or_null("GoldBarLandingAudio") as AudioStreamPlayer3D
    var inventory := GDPlayerInventory.new()
    inventory._add_item(GOLD_BAR_ITEM)
    var bar_uses_45_units := is_equal_approx(inventory.get_carried_weight(), 45.0) \
        and inventory.get_used_inventory_units() == 45
    inventory._add_item(GOLD_COIN_ITEM)
    var capacity_updates: Array[int] = []
    inventory.inventory_capacity_changed.connect(
        func(max_units: int) -> void:
            capacity_updates.append(max_units)
    )
    inventory.increase_inventory_space(12)

    var passed := _expect(
        authored_bar is RigidBody3D and not authored_bar.freeze,
        "gold bar is an active physics body"
    ) and _expect(
        authored_shape is BoxShape3D,
        "gold bar physics body has an authored box collider"
    ) and _expect(
        authored_bar.get_node_or_null("GoldBarModel") != null,
        "gold bar scene uses the supplied model"
    ) and _expect(
        GOLD_BAR_ITEM.pickup_sound.resource_path == "res://Assets/audio/gold-bar-pickup.mp3",
        "gold bar item uses its dedicated pickup sound"
    ) and _expect(
        landing_audio != null \
            and landing_audio.stream.resource_path == "res://Assets/audio/gold-hits-floor.mp3",
        "gold bar plays its dedicated sound on first contact with level geometry"
    ) and _expect(
        is_equal_approx(float(GOLD_BAR_ITEM.weight), 45.0),
        "gold bar consumes exactly 45 inventory units"
    ) and _expect(
        bar_uses_45_units,
        "carrying a gold bar occupies 45 sack units"
    ) and _expect(
        is_equal_approx(inventory.get_carried_weight(), 46.0) \
            and inventory.get_used_inventory_units() == 46,
        "inventory capacity combines gold-bar and coin weight"
    ) and _expect(
        inventory._item_type(inventory._get_next_drop_item()) == &"gold_bar",
        "carried-item drop prioritizes the 45-unit gold bar over individual coins"
    ) and _expect(
        inventory.get_max_inventory_units() == 112 and capacity_updates == [112],
        "inventory capacity upgrades report the new treasure sack capacity"
    )

    var player := PLAYER_SCENE.instantiate() as GDPlayer
    root.add_child(player)
    var player_inventory := player.get_node("PlayerInventory") as GDPlayerInventory
    authored_bar.global_position = player.global_position
    var collected := player_inventory.try_collect_item_pickup(authored_bar)
    var pickup_audio := player.get_node_or_null("PickupItemAudio") as AudioStreamPlayer
    var dropped := player_inventory.drop_item_of_type(&"gold_bar")
    var dropped_bar: RigidBody3D
    for node in get_nodes_in_group("gold_bar"):
        if node != authored_bar and node is RigidBody3D and node.get_script() == GOLD_BAR_SCRIPT:
            dropped_bar = node as RigidBody3D
            break

    passed = _expect(
        collected and pickup_audio != null and pickup_audio.stream == GOLD_BAR_ITEM.pickup_sound,
        "collecting a gold bar plays the dedicated pickup sound"
    ) and _expect(dropped, "gold bar can be dropped through the carried-item flow") \
        and _expect(
            dropped_bar != null and dropped_bar is RigidBody3D and not dropped_bar.freeze,
            "dropping a gold bar spawns an active rigid body"
        ) \
        and _expect(
            player_inventory.get_item_count(&"gold_bar") == 0 \
                and player_inventory.get_used_inventory_units() == 0,
            "dropping a gold bar releases its 45 inventory units"
        ) \
        and passed

    if dropped_bar != null:
        var drop_start_y := dropped_bar.global_position.y
        await physics_frame
        await physics_frame
        passed = _expect(
            dropped_bar.global_position.y < drop_start_y,
            "dropped gold bar falls under rigid-body physics"
        ) and passed

    if dropped_bar != null:
        dropped_bar.free()
    player.free()
    world_body.free()
    inventory.free()
    authored_bar.free()
    return passed


func _test_dense_coin_pile_collection_is_bounded() -> bool:
    var player := PLAYER_SCENE.instantiate() as GDPlayer
    root.add_child(player)
    var inventory := player.get_node("PlayerInventory") as GDPlayerInventory
    var coins: Array[GDGoldCoin] = []
    var attempted_coin_count := GDPlayerInventory.MAX_PICKUPS_PER_PHYSICS_FRAME + 4
    var collected_count := 0
    var pickup_noise_events: Array[Vector3] = []
    player.pickup_noise_emitted.connect(
        func(noise_position: Vector3) -> void:
            pickup_noise_events.append(noise_position)
    )
    for _coin_index in attempted_coin_count:
        var coin := GOLD_COIN_SCENE.instantiate() as GDGoldCoin
        coin.position = player.position
        root.add_child(coin)
        coin.can_be_collected = true
        coins.append(coin)
        if coin._try_collect(player):
            collected_count += 1

    var pickup_audio_count := 0
    for child in player.get_children():
        if child is AudioStreamPlayer \
                and String(child.name).begins_with("PickupItemAudio"):
            pickup_audio_count += 1
    var passed := _expect(
        collected_count == GDPlayerInventory.MAX_PICKUPS_PER_PHYSICS_FRAME \
            and inventory.get_item_count(&"gold_coin") == collected_count,
        "dense coin overlaps collect through a bounded per-physics-frame budget " \
            + "(collected %d, carried %d)" % [
                collected_count,
                inventory.get_item_count(&"gold_coin"),
            ]
    ) and _expect(
        pickup_audio_count == 1,
        "a dense coin pickup batch reuses one inventory audio voice"
    ) and _expect(
        pickup_noise_events.size() == 1,
        "a dense coin pickup batch emits one shared enemy-alert event"
    ) and _expect(
        not coins[0].continuous_cd and not coins[0].contact_monitor,
        "dense coin piles avoid unused continuous collision and contact monitoring"
    )

    while inventory.get_item_count(&"gold_coin") < GOLD_COIN_ITEM.max_count:
        inventory._add_item(GOLD_COIN_ITEM)
    await process_frame
    var remaining_original_coins := 0
    for coin in coins:
        if is_instance_valid(coin):
            remaining_original_coins += 1
    var live_gold_coins := get_nodes_in_group("gold_coin").size()
    passed = _expect(
        remaining_original_coins == attempted_coin_count - collected_count \
            and live_gold_coins == remaining_original_coins,
        "a full sack leaves overflow coins in place without spawning replacements"
    ) and passed

    for coin in coins:
        if is_instance_valid(coin):
            coin.free()
    player.free()
    return passed


func _test_treasure_absorption_does_not_complete_level() -> bool:
    var graveyard := TestGraveyard.new()
    graveyard.max_treasure_value = 3
    graveyard.treasure_collected = 2
    graveyard._on_treasure_absorbed(1)

    var passed := _expect(
        graveyard.treasure_collected == 3,
        "treasure absorption updates the deposited treasure value"
    ) and _expect(
        not graveyard.win_requested,
        "banking the last treasure does not complete the level"
    )
    graveyard.free()
    return passed


func _test_result_percentage_uses_mixed_treasure_value() -> bool:
    var available_treasure := GOLD_COIN_ITEM.treasure_value * 2 \
        + DIAMOND_ITEM.treasure_value \
        + GOLD_BAR_ITEM.treasure_value * 2
    var recovered_treasure := DIAMOND_ITEM.treasure_value + GOLD_BAR_ITEM.treasure_value
    var expected_percentage := roundi(
        float(recovered_treasure) / float(available_treasure) * 100.0
    )
    var result_stats := GDResultStats.new()
    result_stats.set_result(recovered_treasure, available_treasure)

    var level_selection := TestLevelSelection.new()
    level_selection.record_level_result(
        0,
        recovered_treasure,
        result_stats.get_completion_percentage(),
        true
    )
    var stored_result := level_selection.get_level_result(0)
    var passed := _expect(
        available_treasure == 102 \
            and recovered_treasure == 55 \
            and result_stats.get_completion_percentage() == expected_percentage,
        "result percentage compares recovered mixed treasure value with all available value"
    ) and _expect(
        int(stored_result.get("best_percentage", 0)) == expected_percentage,
        "level selection stores the mixed-treasure completion percentage"
    )

    level_selection.free()
    result_stats.free()
    return passed


func _test_typed_treasure_wallet_and_shop_purchases() -> bool:
    var result_stats := GDResultStats.new()
    result_stats.begin_attempt(100)
    result_stats.add_treasure(&"diamond", DIAMOND_ITEM.treasure_value)
    result_stats.add_treasure(&"diamond", DIAMOND_ITEM.treasure_value)
    result_stats.add_treasure(&"gold_coin", GOLD_COIN_ITEM.treasure_value)
    var banked_treasure := result_stats.take_unbanked_treasure()

    var level_selection := TestLevelSelection.new()
    var initial_credit := level_selection.record_selected_level_result(
        21,
        21,
        true,
        banked_treasure
    )
    var loss_credit := level_selection.record_selected_level_result(
        40,
        40,
        false,
        {"diamond": 4, "gold_coin": 5, "ruby": 3}
    )
    var incompatible_credit := level_selection.record_selected_level_result(
        32,
        32,
        true,
        {"diamond": 1, "gold_coin": 5, "ruby": 2}
    )
    var wallet_after_incompatible_replay := level_selection.treasure_wallet.duplicate(true)
    var counts_after_incompatible_replay: Dictionary = level_selection.get_level_result(0).get(
        "banked_treasure_counts",
        {}
    )
    var superset_credit := level_selection.record_selected_level_result(
        42,
        42,
        true,
        {"diamond": 3, "gold_coin": 5, "ruby": 2}
    )
    level_selection.record_selected_level_result(
        22,
        22,
        true,
        {"diamond": 2, "gold_coin": 1, "ruby": 1}
    )
    var purchased := level_selection.purchase_shop_item(&"bone_charm", &"diamond", 2, 5)
    var repeated_without_funds := level_selection.purchase_shop_item(
        &"bone_charm",
        &"diamond",
        2,
        5
    )
    var passed := _expect(
        banked_treasure == {"diamond": 2, "gold_coin": 1},
        "result stats retain deposited object counts for every treasure type"
    ) and _expect(
        initial_credit == {"diamond": 2, "gold_coin": 1} \
            and loss_credit.is_empty() \
            and incompatible_credit.is_empty() \
            and superset_credit == {"diamond": 1, "gold_coin": 4, "ruby": 2},
        "level results report only treasure newly credited by each qualifying win"
    ) and _expect(
        result_stats.take_unbanked_treasure().is_empty(),
        "an attempt's treasure can only be banked once"
    ) and _expect(
        wallet_after_incompatible_replay == {"diamond": 2, "gold_coin": 1} \
            and counts_after_incompatible_replay == {"diamond": 2, "gold_coin": 1},
        "a different partial haul cannot combine currencies across successful runs"
    ) and _expect(
        level_selection.get_level_result(0).get("banked_treasure_counts") \
            == {"diamond": 3, "gold_coin": 5, "ruby": 2},
        "reward-bearing replays must contain the level's complete previously banked haul"
    ) and _expect(
        purchased and not repeated_without_funds,
        "shop purchases atomically validate and deduct their authored treasure currency"
    ) and _expect(
        level_selection.get_treasure_count(&"diamond") == 1 \
            and level_selection.get_treasure_count(&"gold_coin") == 5 \
            and level_selection.get_treasure_count(&"ruby") == 2 \
            and level_selection.get_shop_item_purchase_count(&"bone_charm") == 1,
        "losses and incompatible replay hauls add nothing while a superset run funds purchases"
    ) and _expect(
        level_selection.player_progress.get_script().resource_path \
            == "res://autoload/player_progress.gd",
        "level navigation delegates persisted results, treasure, and shop stock"
    )

    level_selection.free()
    result_stats.free()
    return passed


func _test_gate_completion_completes_level() -> bool:
    var graveyard := TestGraveyard.new()
    graveyard._on_level_completed()

    var passed := _expect(graveyard.win_requested, "gate completion completes the level")
    graveyard.free()
    return passed


func _test_optional_scene_node_paths_are_empty_or_valid() -> bool:
    var door := LOCKED_DOOR_SCENE.instantiate() as Node3D
    var gate := LOCKED_GATE_SCENE.instantiate() as Node3D
    var vampire_level_scene := load("res://levels/vampire-maze/level.tscn") as PackedScene
    var vampire_level := vampire_level_scene.instantiate() as Node3D
    var generated_maze := vampire_level.get_node("GeneratedMaze") as Node3D
    var graveyard_level_scene := load("res://levels/graveyard/level.tscn") as PackedScene
    var graveyard_level := graveyard_level_scene.instantiate() as Node3D
    var graveyard_camera := graveyard_level.get_node("Camera3D") as Camera3D
    var path_expectations: Array[Dictionary] = [
        {"node": door, "property": &"leaf_root_path"},
        {"node": door, "property": &"unlock_area_path"},
        {"node": door, "property": &"completion_area_path"},
        {"node": door, "property": &"unlock_audio_player_path"},
        {"node": gate, "property": &"leaf_root_path"},
        {"node": gate, "property": &"unlock_area_path"},
        {"node": gate, "property": &"completion_area_path"},
        {"node": gate, "property": &"unlock_audio_player_path"},
        {"node": generated_maze, "property": &"authored_content_path"},
        {"node": graveyard_camera, "property": &"kill_boundary_path"},
    ]
    var passed := true
    for expectation: Dictionary in path_expectations:
        var node := expectation["node"] as Node
        var property_name := expectation["property"] as StringName
        var configured_path := node.get(property_name) as NodePath
        passed = _expect(
            String(configured_path).is_empty() or node.get_node_or_null(configured_path) != null,
            "%s.%s is empty or resolves to an authored node" \
                % [node.name, property_name]
        ) and passed

    door.free()
    gate.free()
    vampire_level.free()
    graveyard_level.free()
    return passed


func _test_reusable_gate_and_treasure_deposit_coffin_scenes() -> bool:
    var gate := LOCKED_GATE_SCENE.instantiate() as GDLockableHingedPassage
    var coffin := TREASURE_DEPOSIT_COFFIN_SCENE.instantiate() as Node3D
    if not _expect(gate != null, "locked gate scene instantiates with passage behavior") \
        or not _expect(coffin != null, "treasure deposit coffin scene instantiates"):
        if gate != null:
            gate.free()
        if coffin != null:
            coffin.free()
        return false

    root.add_child(gate)
    root.add_child(coffin)
    var level_one_scene := load("res://levels/1/level.tscn") as PackedScene
    var level_one := level_one_scene.instantiate() as Node3D
    var level_one_gate := level_one.get_node_or_null("LockedGate") as Node3D
    var level_one_staircase := level_one.get_node_or_null(
        "LockedGate/ProceduralStaircase"
    ) as Node3D
    if level_one_staircase != null:
        level_one_staircase.call(&"rebuild")
    var level_one_stair_mesh := level_one.get_node_or_null(
        "LockedGate/ProceduralStaircase/GeneratedStairMesh"
    ) as MeshInstance3D
    var configurable_staircase := PROCEDURAL_STAIRCASE_SCENE.instantiate() as Node3D
    var authored_editor_preview := configurable_staircase.get_node_or_null(
        "EditorPreview"
    ) as CSGPolygon3D
    var editor_preview_is_serialized_and_visible := authored_editor_preview != null \
        and authored_editor_preview.visible \
        and authored_editor_preview.polygon.size() >= 8 \
        and is_equal_approx(authored_editor_preview.polygon[0].x, 1.25) \
        and is_equal_approx(authored_editor_preview.position.z, 1.5) \
        and is_equal_approx(authored_editor_preview.depth, 3.0) \
        and authored_editor_preview.material != null
    configurable_staircase.set(&"step_count", 5)
    configurable_staircase.set(&"steepness_degrees", 15.0)
    configurable_staircase.set(&"step_depth", 0.6)
    root.add_child(configurable_staircase)
    var configured_mesh_instance := configurable_staircase.get_node_or_null(
        "GeneratedStairMesh"
    ) as MeshInstance3D
    var configured_mesh := configured_mesh_instance.mesh as ArrayMesh \
        if configured_mesh_instance != null else null
    var configured_top_marker := configurable_staircase.get_node_or_null(
        "TopMarker"
    ) as Marker3D
    var configured_completion_area := configurable_staircase.get_node_or_null(
        "CompletionArea"
    ) as Area3D
    var configured_approach_floor := configurable_staircase.get_node_or_null(
        "ApproachFloor"
    ) as MeshInstance3D
    var configured_approach_mesh := configured_approach_floor.mesh as BoxMesh \
        if configured_approach_floor != null else null
    var configured_approach_collision := configurable_staircase.get_node_or_null(
        "StairCollision/ApproachFloorShape"
    ) as CollisionShape3D
    var configured_approach_shape := configured_approach_collision.shape as BoxShape3D \
        if configured_approach_collision != null else null
    var configured_faces_use_clockwise_winding := configured_mesh != null
    var configured_lowest_walkable_surface_y := INF
    if configured_mesh != null:
        var configured_arrays := configured_mesh.surface_get_arrays(0)
        var configured_vertices := configured_arrays[Mesh.ARRAY_VERTEX] \
            as PackedVector3Array
        var configured_normals := configured_arrays[Mesh.ARRAY_NORMAL] \
            as PackedVector3Array
        configured_faces_use_clockwise_winding = configured_vertices.size() >= 3 \
            and configured_vertices.size() == configured_normals.size() \
            and configured_vertices.size() % 3 == 0
        for vertex_index in configured_vertices.size():
            if configured_normals[vertex_index].dot(Vector3.UP) >= 0.99:
                configured_lowest_walkable_surface_y = minf(
                    configured_lowest_walkable_surface_y,
                    configured_vertices[vertex_index].y
                )
        for triangle_start in range(0, configured_vertices.size(), 3):
            var conventional_normal := (
                configured_vertices[triangle_start + 1] \
                    - configured_vertices[triangle_start]
            ).cross(
                configured_vertices[triangle_start + 2] \
                    - configured_vertices[triangle_start]
            )
            if conventional_normal.dot(configured_normals[triangle_start]) >= 0.0:
                configured_faces_use_clockwise_winding = false
                break
    var deposit := coffin.get_node_or_null("TreasureDeposit") as GDTreasureDeposit
    var deposit_coin: Node3D = (
        deposit._create_visual_treasure(GOLD_COIN_ITEM) if deposit != null else null
    )
    var deposit_diamond: Node3D = (
        deposit._create_visual_treasure(DIAMOND_ITEM) if deposit != null else null
    )
    var deposit_gold_bar: Node3D = (
        deposit._create_visual_treasure(GOLD_BAR_ITEM) if deposit != null else null
    )
    var deposit_inventory := GDPlayerInventory.new()
    deposit_inventory._add_item(GOLD_COIN_ITEM)
    deposit_inventory._add_item(DIAMOND_ITEM)
    deposit_inventory._add_item(GOLD_BAR_ITEM)
    var selected_deposit_item := deposit_inventory.take_highest_value_carried_treasure()
    var absorbed_values: Array[int] = []
    var absorbed_types: Array[StringName] = []
    if deposit != null:
        deposit.treasure_absorbed.connect(
            func(value: int) -> void:
                absorbed_values.append(value)
        )
        deposit.treasure_item_absorbed.connect(
            func(item_type: StringName, _value: int) -> void:
                absorbed_types.append(item_type)
        )
        deposit._absorb_treasure(DIAMOND_ITEM.treasure_value, DIAMOND_ITEM)
    var world_coin := GOLD_COIN_SCENE.instantiate() as GDGoldCoin
    var world_coin_meshes := world_coin.find_children(
        "*", "MeshInstance3D", true, false
    )
    var world_coin_mesh := world_coin_meshes[0] as MeshInstance3D \
        if not world_coin_meshes.is_empty() else null
    var gate_exit_staircase := gate.get_node_or_null("ProceduralStaircase") as Node3D
    var gate_exit_completion := gate.get_node_or_null(
        "ProceduralStaircase/CompletionArea"
    ) as Area3D
    var gate_exit_left_guard := gate.get_node_or_null(
        "ProceduralStaircase/StairCollision/LeftSideGuardShape"
    ) as CollisionShape3D
    var gate_exit_top_landing := gate.get_node_or_null(
        "ProceduralStaircase/StairCollision/TopLandingShape"
    ) as CollisionShape3D
    var gate_exit_mesh := gate.get_node_or_null(
        "ProceduralStaircase/GeneratedStairMesh"
    ) as MeshInstance3D
    var passed := _expect(gate.completes_level, "locked gate scene completes the level") \
        and _expect(gate.get_node_or_null("Leaves/LeftGateLeaf") != null, "locked gate includes its left leaf") \
        and _expect(gate.get_node_or_null("Leaves/RightGateLeaf") != null, "locked gate includes its right leaf") \
        and _expect(
            gate_exit_staircase != null \
                and gate_exit_completion != null \
                and gate_exit_left_guard != null \
                and gate_exit_top_landing != null \
                and gate.completion_area == gate_exit_completion \
                and gate_exit_completion.position.x \
                    < gate_exit_top_landing.position.x \
                and gate.to_local(gate_exit_completion.global_position).x < 0.0 \
                and gate.to_local(gate_exit_top_landing.global_position).x \
                    < gate.to_local(gate_exit_completion.global_position).x,
            "every reusable locked gate owns the guarded staircase and its runoff trigger"
        ) \
        and _expect(
            gate_exit_staircase.get_script() == PROCEDURAL_STAIRCASE_SCRIPT \
                and (gate_exit_staircase.get_script() as Script).is_tool() \
                and gate_exit_staircase.position.is_equal_approx(
                    Vector3(-0.16, 0.0, 0.0)
                ) \
                and gate_exit_staircase.scene_file_path \
                    == "res://placeables/stairs/procedural_staircase.tscn" \
                and gate_exit_mesh != null \
                and gate_exit_mesh.mesh is ArrayMesh \
                and gate_exit_mesh.mesh.get_surface_count() == 1 \
                and gate_exit_staircase.get_node_or_null("Steps") == null,
            "LockedGate instances one procedural mesh with no authored staircase remnants"
        ) \
        and _expect(
            configured_mesh != null \
                and configured_mesh.get_surface_count() == 1 \
                and configured_top_marker != null \
                and configured_completion_area != null \
                and is_equal_approx(configured_mesh.get_aabb().size.x, 4.2) \
                and is_equal_approx(configured_mesh.get_aabb().size.z, 3.0) \
                and configured_top_marker.position.is_equal_approx(
                    Vector3(
                        5.45,
                        tan(deg_to_rad(15.0)) * 0.6 * 5.0,
                        0.0
                    )
                ),
            "the procedural staircase rebuilds from count, steepness, and tread depth"
        ) \
        and _expect(
            configured_lowest_walkable_surface_y > 0.1 \
                and configurable_staircase.get_node_or_null(
                    "StairCollision/GateThresholdShape"
                ) == null,
            "procedural staircase begins at its first tread without a floor-level threshold"
        ) \
        and _expect(
            configured_approach_floor != null \
                and configured_approach_mesh != null \
                and configured_approach_collision != null \
                and configured_approach_shape != null \
                and configured_approach_mesh.size.is_equal_approx(
                    Vector3(1.25, 0.1, 3.0)
                ) \
                and is_equal_approx(
                    configured_approach_floor.position.y \
                        + configured_approach_mesh.size.y * 0.5,
                    0.01
                ) \
                and is_equal_approx(
                    configured_approach_collision.position.y \
                        + configured_approach_shape.size.y * 0.5,
                    0.0
                ),
            "gate approach floor renders above ground while its collision stays flush"
        ) \
        and _expect(
            configured_faces_use_clockwise_winding,
            "procedural staircase faces use Godot's visible clockwise winding"
        ) \
        and _expect(
            editor_preview_is_serialized_and_visible \
                and authored_editor_preview.polygon.size() == 2 * 5 + 4 \
                and is_equal_approx(
                    authored_editor_preview.position.z,
                    authored_editor_preview.depth * 0.5
                ) \
                and not authored_editor_preview.visible,
            "procedural staircase editor preview stays centred and hides at runtime"
        ) \
        and _expect(
            level_one_gate != null \
                and level_one_gate.scene_file_path \
                    == "res://placeables/lockables/locked_gate.tscn" \
                and level_one_staircase != null \
                and level_one_staircase.visible \
                and level_one_stair_mesh != null \
                and level_one_stair_mesh.visible \
                and level_one_stair_mesh.mesh != null,
            "Level 1 inherits the visible staircase from its LockedGate instance"
        ) \
        and _expect(deposit != null, "treasure deposit coffin includes deposit behavior") \
        and _expect(
            deposit != null and is_equal_approx(deposit.position.y, 0.42),
            "treasure deposit coffin keeps the working Level 1 deposit offset"
        ) \
        and _expect(
            deposit != null and deposit.get_node_or_null("DepositArea/CollisionShape3D") != null,
            "treasure deposit coffin creates its player detection area"
        ) \
        and _expect(
            deposit_coin is GDGoldCoin \
                and _all_geometry_has_shadow_mode(
                    deposit_coin,
                    GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
                ),
            "coins retain their visual without casting distracting deposit-flight shadows"
        ) \
        and _expect(
            deposit_diamond is GDDiamond \
                and absorbed_values == [DIAMOND_ITEM.treasure_value] \
                and absorbed_types == [&"diamond"],
            "diamonds retain their visual and report exact type and value when deposited"
        ) \
        and _expect(
            deposit_gold_bar is GDGoldBar \
                and GOLD_BAR_ITEM.treasure_value == 45 \
                and _all_geometry_has_shadow_mode(
                    deposit_gold_bar,
                    GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
                ),
            "gold bars use their real visual and carry 45 treasure value into the coffin"
        ) \
        and _expect(
            selected_deposit_item == GOLD_BAR_ITEM \
                and deposit_inventory.get_carried_treasure_value() \
                    == DIAMOND_ITEM.treasure_value + GOLD_COIN_ITEM.treasure_value,
            "the coffin deposit flow selects a carried gold bar before lower-value treasure"
        ) \
        and _expect(
            world_coin_mesh != null \
                and world_coin_mesh.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_ON,
            "ordinary world coins continue to cast shadows"
        )
    if deposit_coin != null:
        deposit_coin.free()
    if deposit_diamond != null:
        deposit_diamond.free()
    if deposit_gold_bar != null:
        deposit_gold_bar.free()
    deposit_inventory.free()
    world_coin.free()
    level_one.free()
    configurable_staircase.free()
    gate.queue_free()
    coffin.queue_free()
    return passed


func _test_coffin_deposit_jumps_move_two_extra_coins() -> bool:
    var prior_coin_instance_ids: Array[int] = []
    for coin_node in get_nodes_in_group(&"gold_coin"):
        prior_coin_instance_ids.append(coin_node.get_instance_id())
    var coffin := TREASURE_DEPOSIT_COFFIN_SCENE.instantiate() as Node3D
    var player := PLAYER_SCENE.instantiate() as GDPlayer
    root.add_child(coffin)
    root.add_child(player)
    var deposit := coffin.get_node("TreasureDeposit") as GDTreasureDeposit
    var inventory := player.get_node("PlayerInventory") as GDPlayerInventory
    for _coin_index in 5:
        inventory._add_item(GOLD_COIN_ITEM)
    inventory._add_item(GOLD_BAR_ITEM)
    deposit._on_body_entered(player)

    deposit.deposit_cooldown = deposit.deposit_interval
    player.notify_jump_started()
    var coins_after_first_jump := inventory.get_item_count(&"gold_coin")
    var gold_bars_after_first_jump := inventory.get_item_count(&"gold_bar")
    var cooldown_after_first_jump := deposit.deposit_cooldown
    player.notify_jump_started()
    var coins_after_second_jump := inventory.get_item_count(&"gold_coin")
    player.notify_jump_started()
    var coins_after_third_jump := inventory.get_item_count(&"gold_coin")
    deposit._on_body_exited(player)
    inventory._add_item(GOLD_COIN_ITEM)
    inventory._add_item(GOLD_COIN_ITEM)
    player.notify_jump_started()
    var coins_after_out_of_range_jump := inventory.get_item_count(&"gold_coin")

    var passed := _expect(
        coins_after_first_jump == 3 \
            and coins_after_second_jump == 1 \
            and coins_after_third_jump == 0,
        "each nearby jump moves exactly two extra carried coins when available"
    ) and _expect(
        gold_bars_after_first_jump == 1,
        "jump bonus transfers leave non-coin treasure to the ordinary coffin flow"
    ) and _expect(
        is_equal_approx(cooldown_after_first_jump, deposit.deposit_interval),
        "jump bonus coins do not alter the coffin's ordinary timed deposit cadence"
    ) and _expect(
        coins_after_out_of_range_jump == 2,
        "jumping outside coffin range does not transfer bonus coins"
    )

    for coin_node in get_nodes_in_group(&"gold_coin"):
        var coin := coin_node as Node
        if coin != null and not prior_coin_instance_ids.has(coin.get_instance_id()):
            coin.free()
    player.free()
    coffin.free()
    return passed


func _test_stairwell_scopes_kill_boundary_immunity() -> bool:
    var staircase := PROCEDURAL_STAIRCASE_SCENE.instantiate() as Node3D
    var player := PLAYER_SCENE.instantiate() as GDPlayer
    root.add_child(staircase)
    root.add_child(player)
    var safety_area := staircase.get_node_or_null("StairwellSafetyArea") as Area3D
    var safety_collision := staircase.get_node_or_null(
        "StairwellSafetyArea/CollisionShape3D"
    ) as CollisionShape3D
    var safety_box := safety_collision.shape as BoxShape3D \
        if safety_collision != null else null
    var no_boundary_was_present := get_nodes_in_group(&"kill_boundary").is_empty()
    staircase.call("_on_safety_area_body_entered", player)
    var boundary_free_level_keeps_normal_player_state := \
        not bool(player.call("is_immune_to_kill_boundary")) \
        and (player.collision_mask & TEST_BOUNDARY_BLOCKER_COLLISION_LAYER) != 0

    var boundary := KILL_BOUNDARY_SCENE.instantiate() as GDKillBoundary3D
    boundary.autoplay_boundary_animation = false
    root.add_child(boundary)
    staircase.call("_on_safety_area_body_entered", player)
    var stairs_grant_damage_and_blocker_immunity := \
        bool(player.call("is_immune_to_kill_boundary")) \
        and (player.collision_mask & TEST_BOUNDARY_BLOCKER_COLLISION_LAYER) == 0
    staircase.call("_on_safety_area_body_exited", player)
    var leaving_stairs_restores_boundary := \
        not bool(player.call("is_immune_to_kill_boundary")) \
        and (player.collision_mask & TEST_BOUNDARY_BLOCKER_COLLISION_LAYER) != 0
    staircase.call("_on_safety_area_body_entered", player)
    staircase.call("_on_safety_area_body_exited", player)
    var doubling_back_restores_boundary := \
        not bool(player.call("is_immune_to_kill_boundary")) \
        and (player.collision_mask & TEST_BOUNDARY_BLOCKER_COLLISION_LAYER) != 0

    var victim := TestKillBoundaryVictim.new()
    victim.add_to_group(&"flame_vulnerable")
    victim.position = Vector3(50.0, 0.0, 0.0)
    root.add_child(victim)
    boundary.call("_apply_flame_heat", 1.0)
    var immune_victim_ignored_damage := is_zero_approx(victim.received_damage)
    victim.immune_to_kill_boundary = false
    boundary.call("_apply_flame_heat", 1.0)
    var ordinary_victim_received_damage := victim.received_damage > 0.0
    var flame_boundary_reports_fire_death := victim.last_damage_was_fire
    victim.received_damage = 0.0
    boundary.render_effect = boundary.EFFECT_GHOST
    boundary.call("_apply_flame_heat", 1.0)
    var ghost_boundary_reports_non_fire_death := victim.received_damage > 0.0 \
        and not victim.last_damage_was_fire

    var passed := _expect(
        safety_area != null \
            and safety_area.collision_mask == 2 \
            and safety_box != null \
            and safety_area.position.x - safety_box.size.x * 0.5 <= -0.4 \
            and safety_area.position.x + safety_box.size.x * 0.5 \
                >= float(staircase.call("get_end_distance")) - 0.01 \
            and safety_box.size.z >= 2.9,
        "procedural staircase owns a player-only safety area covering its full run"
    ) and _expect(
        no_boundary_was_present and boundary_free_level_keeps_normal_player_state,
        "stairwells do not grant immunity in levels without a kill boundary"
    ) and _expect(
        stairs_grant_damage_and_blocker_immunity,
        "entering gate stairs ignores kill-boundary damage and blocker collision"
    ) and _expect(
        leaving_stairs_restores_boundary and doubling_back_restores_boundary,
        "leaving or doubling back from the stairs restores boundary damage and collision"
    ) and _expect(
        immune_victim_ignored_damage \
            and ordinary_victim_received_damage \
            and flame_boundary_reports_fire_death \
            and ghost_boundary_reports_non_fire_death,
        "boundary damage resumes after immunity and only active flames report a fire death"
    )
    victim.free()
    player.free()
    boundary.free()
    staircase.free()
    return passed


func _test_kill_boundary_ignores_zombies_and_skeletons() -> bool:
    var boundary := KILL_BOUNDARY_SCENE.instantiate() as GDKillBoundary3D
    boundary.autoplay_boundary_animation = false
    boundary.boundary_segments = 8
    root.add_child(boundary)
    boundary.set_physics_process(false)

    var zombie := ZOMBIE_SCENE.instantiate() as GDZombiePath
    var skeleton := SKELETON_SCENE.instantiate() as GDSkeletonPath
    var zombie_body := zombie.get_node("ZombieBody") as CharacterBody3D
    var skeleton_body := skeleton.get_node(
        "PathFollow3D/DropPivot/SkeletonBody"
    ) as AnimatableBody3D
    var authored_enemy_bodies_ignore_boundary := (
        zombie_body.collision_mask & TEST_BOUNDARY_BLOCKER_COLLISION_LAYER
    ) == 0 and (
        skeleton_body.collision_mask & TEST_BOUNDARY_BLOCKER_COLLISION_LAYER
    ) == 0
    zombie.ai_enabled_on_ready = false
    root.add_child(zombie)
    root.add_child(skeleton)
    zombie.set_physics_process(false)
    skeleton.set_physics_process(false)

    var player := PLAYER_SCENE.instantiate() as GDPlayer
    root.add_child(player)
    player.set_physics_process(false)
    var runtime_enemy_bodies_ignore_boundary := (
        zombie_body.collision_mask & TEST_BOUNDARY_BLOCKER_COLLISION_LAYER
    ) == 0 and (
        skeleton_body.collision_mask & TEST_BOUNDARY_BLOCKER_COLLISION_LAYER
    ) == 0
    var enemy_probes_ignore_boundary := (
        zombie.map_collision_mask & TEST_BOUNDARY_BLOCKER_COLLISION_LAYER
    ) == 0 and (
        zombie.vision_collision_mask & TEST_BOUNDARY_BLOCKER_COLLISION_LAYER
    ) == 0 and (
        skeleton.map_collision_mask & TEST_BOUNDARY_BLOCKER_COLLISION_LAYER
    ) == 0 and (
        skeleton.enemy_collision_mask & TEST_BOUNDARY_BLOCKER_COLLISION_LAYER
    ) == 0

    var flame_areas := boundary.get("strip_areas") as Array
    var flame_areas_only_monitor_player := not flame_areas.is_empty()
    for area_value in flame_areas:
        var area := area_value as Area3D
        flame_areas_only_monitor_player = flame_areas_only_monitor_player \
            and area != null \
            and area.collision_mask == 2
    var blocker_bodies := boundary.get("blocker_bodies") as Array
    var blockers_use_player_only_layer := not blocker_bodies.is_empty()
    for body_value in blocker_bodies:
        var blocker := body_value as StaticBody3D
        blockers_use_player_only_layer = blockers_use_player_only_layer \
            and blocker != null \
            and blocker.collision_layer == TEST_BOUNDARY_BLOCKER_COLLISION_LAYER

    var passed := _expect(
        authored_enemy_bodies_ignore_boundary \
            and runtime_enemy_bodies_ignore_boundary \
            and enemy_probes_ignore_boundary,
        "zombies and skeletons ignore the moving player-only boundary blockers"
    ) and _expect(
        flame_areas_only_monitor_player,
        "kill-boundary damage areas monitor the player layer without monitoring enemies"
    ) and _expect(
        blockers_use_player_only_layer \
            and (player.collision_mask & TEST_BOUNDARY_BLOCKER_COLLISION_LAYER) != 0,
        "kill-boundary blocker collision remains active for the player"
    )

    player.free()
    skeleton.free()
    zombie.free()
    boundary.free()
    return passed


func _test_key_scenes_have_authored_pickup_areas_and_landing_audio() -> bool:
    var gold_key := KEY_SCENE.instantiate() as GDKey
    var silver_key := SILVER_KEY_SCENE.instantiate() as GDKey
    var keys: Array[GDKey] = [gold_key, silver_key]
    var key_inventory := GDPlayerInventory.new()
    var world_body := StaticBody3D.new()
    world_body.collision_layer = 1
    root.add_child(world_body)
    var passed := true
    for key in keys:
        root.add_child(key)
        var item := key.carried_item as GDCarriedItem
        key.previous_linear_velocity = Vector3.DOWN * 0.5
        key.call("_on_body_entered", world_body)
        var tiny_contact_is_silent := key.get_node_or_null("KeyLandingAudio") == null
        key.previous_linear_velocity = Vector3.DOWN * 4.0
        key.call("_on_body_entered", world_body)
        var landing_audio := key.get_node_or_null("KeyLandingAudio") as AudioStreamPlayer3D
        passed = _expect(
            _key_has_valid_pickup_area(key),
            "%s scene has a valid pickup area" % key.name
        ) and _expect(
            key.contact_monitor \
                and key.max_contacts_reported > 0 \
                and item != null \
                and item.landing_sound != null \
                and item.landing_sound.resource_path == "res://Assets/audio/key-landing.mp3" \
                and tiny_contact_is_silent \
                and landing_audio != null \
                and landing_audio.stream == item.landing_sound \
                and landing_audio.bus == &"SFX",
            "%s ignores tiny contacts and plays the shared spatial landing sample after a fall" \
                % key.name
        ) and passed
        key_inventory._add_item(item)

    passed = _expect(
        key_inventory.get_used_inventory_units() == 0 \
            and key_inventory.get_carried_treasure_value() == 0 \
            and key_inventory.take_highest_value_carried_treasure() == null,
        "carried keys remain available for locks without appearing as depositable sack treasure"
    ) and passed

    world_body.free()
    for key in keys:
        key.free()
    key_inventory.free()
    return passed


func _key_has_valid_pickup_area(key: GDKey) -> bool:
    if key == null:
        return false

    var pickup_area := key.get_node_or_null(key.pickup_area_path) as Area3D
    if pickup_area == null or pickup_area.collision_mask != 2:
        return false

    var collision_shape := pickup_area.get_node_or_null("CollisionShape3D") as CollisionShape3D
    var sphere := collision_shape.shape as SphereShape3D if collision_shape != null else null
    return sphere != null and is_equal_approx(sphere.radius, key.generated_pickup_radius)


func _test_graveyard_scene_does_not_embed_default_level() -> bool:
    var scene := load("res://game/graveyard.tscn") as PackedScene
    if not _expect(scene != null, "graveyard scene loads"):
        return false

    var graveyard := scene.instantiate()
    var pause_screen := graveyard.get_node_or_null("PauseScreen") as CanvasLayer
    var feedback := graveyard.get_node_or_null("PlayerFeedback") as CanvasLayer
    var note_panel := graveyard.get_node_or_null("PlayerFeedback/NotePanel") as Control
    var feedback_settings := feedback.get("settings") as GDPlayerFeedbackSettings \
        if feedback != null else null
    var passed := _expect(
        graveyard.get_node_or_null("CurrentLevel") == null,
        "graveyard editor scene does not embed level 1"
    ) and _expect(
        graveyard.get_node_or_null("CodexTestInstruction") != null,
        "gameplay owns a hidden Codex-directed test instruction panel"
    ) and _expect(
        feedback != null \
            and pause_screen != null \
            and feedback.layer > pause_screen.layer \
            and feedback.process_mode == Node.PROCESS_MODE_ALWAYS \
            and note_panel != null \
            and is_equal_approx(note_panel.anchor_right, 1.0) \
            and is_equal_approx(note_panel.anchor_bottom, 1.0),
        "gameplay feedback owns a full-screen centered modal above the pause layer"
    ) and _expect(
        feedback_settings != null \
            and feedback_settings.report_button \
                == GDPlayerFeedbackSettings.FeedbackButton.FaceLeft \
            and feedback_settings.text_button \
                == GDPlayerFeedbackSettings.FeedbackButton.Disabled,
        "gameplay feedback defaults to the unclaimed Square face button"
    )
    graveyard.queue_free()
    return passed


func _test_level_select_scrolls_focused_cards_into_view() -> bool:
    var level_selection := root.get_node_or_null("LevelSelection") as GDLevelSelection
    if not _expect(level_selection != null, "level selection autoload exists for menu test"):
        return false

    var original_mapping = level_selection.level_mapping
    var original_highlighted_index := level_selection.last_highlighted_level_index
    var original_results := level_selection.level_results.duplicate(true)
    var original_persistence_enabled := level_selection.persistence_enabled
    level_selection.persistence_enabled = false
    var test_mapping := GDLevelMapping.new()
    for index in range(16):
        test_mapping.level_entries.append(_create_level_definition(
            "test_level_%02d" % (index + 1),
            "Test Level %d" % (index + 1),
            str(index + 1),
            true,
            index == 0
        ))
    level_selection.level_mapping = test_mapping
    level_selection.last_highlighted_level_index = 12
    level_selection.level_results = {
        "test_level_01": {"best_percentage": 40, "escaped": false, "play_count": 2, "played": true},
        "test_level_02": {
            "banked_treasure_counts": {"diamond": 2, "gold_coin": 7},
            "best_percentage": 70,
            "escaped": true,
            "play_count": 3,
            "played": true,
        },
        "test_level_03": {"best_percentage": 100, "escaped": true, "play_count": 1, "played": true},
    }
    var replay_state_before := level_selection.level_results.duplicate(true)
    var replay_wallet_before := level_selection.treasure_wallet.duplicate(true)
    var replay_purchases_before := level_selection.shop_purchases.duplicate(true)

    var screen := LEVEL_SELECT_SCENE.instantiate() as GDLevelSelectScreen
    root.add_child(screen)
    await process_frame
    await process_frame

    var scroll := screen.scroll_container
    var shop_button := screen.shop_button
    var settings_button := screen.settings_button
    var back_button := screen.back_button
    var screen_container := screen.get_node("ScreenContainer") as Control
    var background := screen.get_node("ScreenContainer/Background") as TextureRect
    var background_shade := screen.get_node("ScreenContainer/Shade") as ColorRect
    var level_select_frame := screen.get_node(
        "ScreenContainer/LevelListFrame"
    ) as NinePatchRect
    var loot_frame := screen.get_node("ScreenContainer/LootFrame") as NinePatchRect
    var level_run_playback := screen.get_node(
        "ScreenContainer/LootFrame/Content/LevelRunPlayback"
    ) as SubViewportContainer
    var playback_viewport := level_run_playback.get_node("PlaybackViewport") as SubViewport
    var preview_root := Node3D.new()
    var preview_world_body := StaticBody3D.new()
    var preview_player := PLAYER_SCENE.instantiate() as GDPlayer
    var preview_camera := Camera3D.new()
    var preview_coin_pile := GOLD_COIN_PILE_SCRIPT.new() as GDGoldCoinPile
    var preview_coin := GOLD_COIN_SCENE.instantiate() as GDInventoryPickup
    var preview_gate := LOCKED_GATE_SCENE.instantiate() as GDLockableHingedPassage
    var preview_boundary := KILL_BOUNDARY_SCENE.instantiate() as GDKillBoundary3D
    var preview_no_boundary_flask := NO_BOUNDARY_FLASK_SCENE.instantiate() \
        as GDFlaskNoBoundary
    var preview_audio := AudioStreamPlayer.new()
    var preview_tutorial_area := Area3D.new()
    preview_world_body.collision_layer = 1
    preview_player.name = "Player"
    preview_coin_pile.coin_count = 1
    preview_coin_pile.spawn_interval = 0.0
    preview_coin_pile.position = Vector3(3.0, 0.0, 0.0)
    preview_coin.pickup_delay = 0.0
    preview_coin.freeze = true
    preview_coin.position = Vector3(0.0, 0.4, 0.0)
    preview_no_boundary_flask.position = Vector3(20.0, 0.0, 0.0)
    preview_root.add_child(preview_world_body)
    preview_root.add_child(preview_player)
    preview_root.add_child(preview_camera)
    preview_root.add_child(preview_coin_pile)
    preview_root.add_child(preview_coin)
    preview_root.add_child(preview_gate)
    preview_root.add_child(preview_boundary)
    preview_root.add_child(preview_no_boundary_flask)
    preview_root.add_child(preview_tutorial_area)
    level_run_playback.call("_prepare_preview_tree", preview_root)
    level_run_playback.call("_configure_playback_player", preview_player)
    root.add_child(preview_root)
    level_run_playback.call("_configure_playback_player", preview_player)
    level_run_playback.call("_isolate_preview_state", preview_root)
    level_run_playback.call("_start_preview_runtime", preview_root)
    level_run_playback.playback_level = preview_root
    preview_root.add_child(preview_audio)
    level_run_playback.playback_level = null
    level_run_playback.call("_disable_preview_area", preview_tutorial_area, false)
    var level_select_title := screen.get_node("ScreenContainer/ScreenTitleLabel") as Label
    var liberated_heading := screen.get_node(
        "ScreenContainer/LootFrame/Content/SelectedTombPanel/LiberatedLootHeadingLabel"
    ) as Label
    var level_loot_tiles := screen.get_node(
        "ScreenContainer/LootFrame/Content/SelectedTombPanel/LootTiles"
    ) as GridContainer
    var level_diamond_tile := level_loot_tiles.get_node("DiamondTile") as Control
    var level_coin_tile := level_loot_tiles.get_node("GoldCoinTile") as Control
    var level_ruby_tile := level_loot_tiles.get_node("RubyTile") as Control
    var diamond_loot_quantity := screen.get_node(
        "ScreenContainer/LootFrame/Content/SelectedTombPanel/LootTiles/DiamondTile/TreasureQuantityLabel"
    ) as Label
    var gold_coin_loot_quantity := screen.get_node(
        "ScreenContainer/LootFrame/Content/SelectedTombPanel/LootTiles/GoldCoinTile/TreasureQuantityLabel"
    ) as Label
    var level_focus_style := screen.level_buttons[0].get_theme_stylebox(&"focus") as StyleBoxFlat
    var initial_button_rect := screen.level_buttons[12].get_global_rect()
    var initial_viewport_rect := scroll.get_global_rect()
    var scaled_focus_margin := GDLevelSelectScreen.FOCUS_SCROLL_MARGIN * screen_container.scale.y
    var passed := _expect(scroll != null, "level selection places rows in a scrolling viewport") \
        and _expect(
            background.texture.resource_path == "res://Assets/frontend/level-select.png" \
            and background_shade.color == Color(0.015, 0.01, 0.015, 0.68),
            "level selection shares the illustrated frontend background and shade"
        ) \
        and _expect(
            level_select_title.text == "CHOOSE YOUR TOMB" \
            and level_select_title.get_global_rect().end.y \
                <= level_select_frame.get_global_rect().position.y,
            "level selection carries its title above and outside the surrounds"
        ) \
        and _expect(
            level_select_frame.axis_stretch_horizontal == NinePatchRect.AXIS_STRETCH_MODE_TILE \
            and level_select_frame.axis_stretch_vertical == NinePatchRect.AXIS_STRETCH_MODE_TILE \
            and level_select_frame.texture.resource_path \
            == "res://Assets/frontend/panel-surround.png",
            "level selection shares the shop's tiled nine-slice surround"
        ) \
        and _expect(
            loot_frame.axis_stretch_horizontal == NinePatchRect.AXIS_STRETCH_MODE_TILE \
            and loot_frame.axis_stretch_vertical == NinePatchRect.AXIS_STRETCH_MODE_TILE \
            and loot_frame.texture == level_select_frame.texture \
            and loot_frame.position.x > level_select_frame.position.x,
            "level selection mirrors the shop's separate list and detail surrounds"
        ) \
        and _expect(
            is_equal_approx(level_run_playback.modulate.a, 0.65) \
                and level_run_playback.stretch_shrink == 2 \
                and playback_viewport.render_target_update_mode == SubViewport.UPDATE_DISABLED \
                and level_run_playback.pending_level_id.is_empty() \
                and not level_run_playback.is_processing(),
            "last-run playback is readable, low resolution, and idle until asynchronously loaded"
        ) \
        and _expect(
            bool(screen.call(
                "_should_show_level_run_playback",
                {"run_playback_enabled": true},
                {"played": true}
            )) \
                and not bool(screen.call(
                    "_should_show_level_run_playback",
                    {"run_playback_enabled": false},
                    {"played": true}
                )),
            "individual procedural levels can disable replay previews without affecting other levels"
        ) \
        and _expect(
            preview_root.process_mode != Node.PROCESS_MODE_DISABLED \
                and preview_world_body.process_mode != Node.PROCESS_MODE_DISABLED \
                and preview_world_body.collision_layer == 1 \
                and preview_player.process_mode != Node.PROCESS_MODE_DISABLED \
                and preview_player.collision_layer == 2 \
                and preview_player.collision_mask == 0,
            "last-run playback simulates world logic with a pickup-capable recorded player"
        ) \
        and _expect(
            preview_audio.bus == GDLevelRunPlayback.MUTED_AUDIO_BUS \
                and AudioServer.is_bus_mute(
                    AudioServer.get_bus_index(GDLevelRunPlayback.MUTED_AUDIO_BUS)
                ),
            "last-run playback routes dynamically created sounds to a muted bus"
        ) \
        and _expect(
            preview_gate.completion_area != null \
                and preview_gate.completion_area.collision_mask == 0,
            "last-run playback disables level completion triggers"
        ) \
        and _expect(
            preview_tutorial_area.monitoring \
                and preview_tutorial_area.collision_mask == 0,
            "replay tutorial triggers remain queryable while unable to detect the player"
        ) \
        and _expect(
            preview_boundary.strip_meshes.any(
                func(mesh: MeshInstance3D) -> bool: return mesh.visible
            ) \
                and preview_boundary.get_node("BoundaryAnimationPlayer").is_playing(),
            "last-run playback keeps the kill boundary visible and moving"
        ) \
        and _expect(
            liberated_heading.text == "LIBERATED LOOT" \
            and not liberated_heading.visible \
            and not level_loot_tiles.visible \
            and not screen.liberated_summary_label.visible,
            "unplayed tombs hide the complete liberated-loot section"
        ) \
        and _expect(
            is_equal_approx(screen_container.scale.x, screen_container.scale.y),
            "level selection scales its shop-style reference canvas uniformly"
        ) \
        and _expect(
            screen.level_buttons[0].get_node("LevelIconTexture").texture.resource_path \
            == "res://Assets/frontend/health-icon.png",
            "level rows expose a replaceable placeholder icon"
        ) \
        and _expect(
            screen.level_buttons[1].position.y > screen.level_buttons[0].position.y \
            and is_equal_approx(
                screen.level_buttons[1].position.x,
                screen.level_buttons[0].position.x
            ) \
            and screen.level_buttons[0].size.y < 150.0,
            "level selection replaces the old card grid with one compact vertical list"
        ) \
        and _expect(
            level_focus_style != null and level_focus_style.border_width_left == 5 \
            and level_focus_style.border_color == Color(1, 0.86, 0.08, 1),
            "level rows share the shop's five-pixel yellow selection surround"
        ) \
        and _expect(
            screen.level_buttons[0].get_node("Title").label_settings.font.resource_path \
            == "res://Assets/fonts/Almendra-Bold.ttf",
            "level rows use the bold Almendra game font"
        ) \
        and _expect(
            screen.selected_button_index == 12,
            "level selection initially highlights the remembered level"
        ) \
        and _expect(
            scroll.vertical_scroll_mode != ScrollContainer.SCROLL_MODE_DISABLED,
            "level selection supports mouse-wheel scrolling"
        ) \
        and _expect(
            scroll.get_v_scroll_bar().visible,
            "additional level rows extend beyond the viewport"
        ) \
        and _expect(
            initial_button_rect.position.y \
            >= initial_viewport_rect.position.y + scaled_focus_margin \
            and initial_button_rect.end.y \
            <= initial_viewport_rect.end.y - scaled_focus_margin,
            "the remembered level row and its focus surround start fully visible"
        ) \
        and _expect(
            screen.level_buttons[0].get_node("LevelStatus").text.begins_with("TUTORIAL"),
            "tutorial levels are identified on their rows"
        ) \
        and _expect(
            screen.level_buttons[0].get_node("LevelStatus").text == "TUTORIAL  •  FAILED" \
            and screen.level_buttons[0].get_node("Percentage").text == "40%" \
            and screen.level_buttons[0].get_node("Plays").text == "2 PLAYS",
            "failed level rows separate status, treasure percentage, and play count"
        ) \
        and _expect(
            screen.level_buttons[1].get_node("LevelStatus").text == "COMPLETE" \
            and screen.level_buttons[1].get_node("Percentage").text == "70%",
            "escaped levels show completion and treasure percentage"
        ) \
        and _expect(
            screen.level_buttons[2].get_node("LevelStatus").text == "SUCCESS" \
            and screen.level_buttons[2].get_node("Percentage").text == "100%",
            "full treasure completion has a distinct success status"
        ) \
        and _expect(
            back_button != null and back_button.text == "BACK" \
            and settings_button != null and settings_button.text == "SETTINGS" \
            and shop_button != null and shop_button.text == "SHOP" \
            and screen.shop_scene_path == "res://ui/frontend/shop.tscn",
            "level selection provides Back, Settings, and Shop actions beneath the list"
        ) \
        and _expect(
            back_button.get_global_rect().position.y >= level_select_frame.get_global_rect().end.y \
            and shop_button.get_global_rect().position.y \
                >= level_select_frame.get_global_rect().end.y \
            and back_button.size.is_equal_approx(Vector2(260.0, 72.0)) \
            and shop_button.size.is_equal_approx(Vector2(260.0, 72.0)),
            "level-select actions sit outside the surround and match the compact shop buttons"
        ) \
        and _expect(
            screen.level_buttons[0].get_node(screen.level_buttons[0].focus_neighbor_left) \
            == back_button \
            and screen.level_buttons[0].get_node(
                screen.level_buttons[0].focus_neighbor_right
            ) == shop_button,
            "left and right move directly from a level row to the bottom actions"
        )

    level_run_playback.playback_level = preview_root
    level_run_playback.playback_player = preview_player
    preview_no_boundary_flask.global_position = preview_player.global_position
    level_run_playback.call("_collect_preview_flasks")
    passed = _expect(
        preview_no_boundary_flask.is_being_collected \
            and preview_boundary.boundary_removed_for_level,
        "last-run playback applies the no-boundary flask effect before consuming it"
    ) and passed
    level_run_playback.playback_level = null
    level_run_playback.playback_player = null

    await physics_frame
    await physics_frame
    var preview_coin_spawned := false
    for preview_child in preview_root.get_children():
        if preview_child.is_in_group(&"gold_coin"):
            preview_coin_spawned = true
            break
    passed = _expect(
        preview_coin_spawned,
        "last-run playback advances level physics such as coin-pile spawning"
    ) and passed
    passed = _expect(
        preview_coin.is_being_collected \
            and preview_player.inventory.get_item_count(&"gold_coin") >= 1,
        "the recorded player collects nearby items into its replay-only inventory"
    ) and passed
    passed = _expect(
        level_selection.level_results == replay_state_before \
            and level_selection.treasure_wallet == replay_wallet_before \
            and level_selection.shop_purchases == replay_purchases_before,
        "replay collection and completion isolation leave saved player progress unchanged"
    ) and passed
    var preview_animation_player := level_run_playback.call(
        "_find_animation_player",
        preview_player
    ) as AnimationPlayer
    level_run_playback.playback_player = preview_player
    level_run_playback.animation_player = preview_animation_player
    level_run_playback.death_animation = level_run_playback.call(
        "_find_animation",
        preview_animation_player,
        GDLevelRunPlayback.DEATH_ANIMATION_CANDIDATES
    ) as String
    level_run_playback.recording = {
        "movement_inputs": PackedVector2Array([Vector2.ONE]),
    }
    preview_player.die_from_flames()
    level_run_playback.call("_update_animation", 1.0 / 60.0, 0)
    passed = _expect(
        preview_player.is_dead() \
            and not level_run_playback.death_animation.is_empty() \
            and level_run_playback.current_animation == level_run_playback.death_animation \
            and preview_animation_player.current_animation == level_run_playback.death_animation \
            and is_equal_approx(preview_animation_player.speed_scale, 0.5),
        "replay hazards play the local death animation without a recorded death flag"
    ) and passed
    var final_pose_camera := Camera3D.new()
    playback_viewport.add_child(final_pose_camera)
    level_run_playback.playback_camera = final_pose_camera
    level_run_playback.recording = {
        "player_positions": PackedVector3Array([Vector3.ZERO, Vector3(9.0, 1.0, -3.0)]),
        "player_yaws": PackedFloat32Array([0.0, 1.0]),
        "camera_positions": PackedVector3Array([Vector3.ZERO, Vector3(8.0, 6.0, 2.0)]),
        "camera_rotations": PackedVector4Array([
            Vector4(0.0, 0.0, 0.0, 1.0),
            Vector4(0.0, 0.0, 0.0, 1.0),
        ]),
    }
    level_run_playback.call("_apply_frame", 1, 0.5)
    passed = _expect(
        preview_player.global_position.is_equal_approx(Vector3(9.0, 1.0, -3.0)) \
            and final_pose_camera.global_position.is_equal_approx(Vector3(8.0, 6.0, 2.0)),
        "the replay final frame holds its last player and camera pose"
    ) and passed
    playback_viewport.remove_child(final_pose_camera)
    final_pose_camera.free()
    level_run_playback.playback_camera = null
    var delayed_save_level_id := "test_delayed_preview_save"
    var delayed_save_task_id := WorkerThreadPool.add_task(
        func() -> void:
            OS.delay_msec(1000),
        false,
        "Test delayed preview save"
    )
    level_selection.register_run_recording_save_task(
        delayed_save_level_id,
        delayed_save_task_id
    )
    level_run_playback.pending_level_id = delayed_save_level_id
    level_run_playback.pending_scene_path = "res://levels/1/level.tscn"
    level_run_playback.call("_start_recording_read")
    var delayed_stop_started_at := Time.get_ticks_msec()
    await level_run_playback.stop_for_scene_change()
    var delayed_stop_duration := Time.get_ticks_msec() - delayed_stop_started_at
    var returned_save_task_id := level_selection.take_run_recording_save_task(
        delayed_save_level_id
    )
    var delayed_save_still_running := not WorkerThreadPool.is_task_completed(
        returned_save_task_id
    )
    WorkerThreadPool.wait_for_task_completion(returned_save_task_id)
    passed = _expect(
        delayed_save_task_id == returned_save_task_id \
            and delayed_save_still_running \
            and delayed_stop_duration < 500,
        "leaving level selection does not wait for a run recording still saving"
    ) and passed
    var shutdown_scene_path := "res://levels/vampire-maze/level.tscn"
    level_run_playback.active_scene_path = shutdown_scene_path
    level_run_playback.recording = {"camera_fov": 34.0}
    var constructed_preview_started_at := Time.get_ticks_msec()
    var constructed_preview_loaded := bool(
        level_run_playback.call("_load_active_level_scene")
    )
    var constructed_preview_load_duration := Time.get_ticks_msec() \
        - constructed_preview_started_at
    level_run_playback.pending_level_id = "queued_preview"
    level_run_playback.pending_scene_path = shutdown_scene_path
    await level_run_playback.stop_for_scene_change()
    passed = _expect(
        constructed_preview_loaded \
            and constructed_preview_load_duration < 2000 \
            and level_run_playback.pending_level_id.is_empty() \
            and level_run_playback.pending_scene_path.is_empty() \
            and level_run_playback.load_state == GDLevelRunPlayback.LoadState.Idle \
            and not level_run_playback.is_processing() \
            and playback_viewport.render_target_update_mode == SubViewport.UPDATE_DISABLED,
        "the shared loader starts and cleanly stops a constructed-level replay"
    ) and passed

    var loop_level_source := Node3D.new()
    var loop_player := PLAYER_SCENE.instantiate() as GDPlayer
    var loop_coin := GOLD_COIN_SCENE.instantiate() as GDInventoryPickup
    var loop_particles := GPUParticles3D.new()
    loop_player.name = "Player"
    loop_coin.name = "LoopCoin"
    loop_particles.name = "LoopParticles"
    loop_particles.emitting = true
    loop_coin.position = Vector3(20.0, 0.0, 0.0)
    loop_level_source.add_child(loop_player)
    loop_level_source.add_child(loop_coin)
    loop_level_source.add_child(loop_particles)
    loop_player.owner = loop_level_source
    loop_coin.owner = loop_level_source
    loop_particles.owner = loop_level_source
    var loop_level_scene := PackedScene.new()
    var loop_pack_error := loop_level_scene.pack(loop_level_source)
    loop_level_source.free()
    level_run_playback.recording = {
        "camera_fov": 34.0,
        "duration": 0.1,
        "frame_times": PackedFloat32Array([0.0]),
        "frame_deltas": PackedFloat32Array([0.1]),
        "player_positions": PackedVector3Array([Vector3.ZERO]),
        "player_yaws": PackedFloat32Array([0.0]),
        "camera_positions": PackedVector3Array([Vector3(0.0, 6.0, 8.0)]),
        "camera_rotations": PackedVector4Array([Vector4(0.0, 0.0, 0.0, 1.0)]),
        "movement_inputs": PackedVector2Array([Vector2.ZERO]),
    }
    level_run_playback.call("_create_preview", loop_level_scene)
    level_run_playback.load_state = GDLevelRunPlayback.LoadState.Idle
    var first_loop_instance := level_run_playback.playback_level as Node3D
    var first_loop_player := first_loop_instance.get_node("Player") as GDLevelRunPlaybackPlayer
    var first_loop_inventory := first_loop_player.inventory as GDPlayerInventory
    var collected_loop_coin := first_loop_instance.get_node("LoopCoin") as GDInventoryPickup
    first_loop_inventory.call("_add_item", collected_loop_coin.get_carried_item())
    collected_loop_coin.visible = false
    collected_loop_coin.queue_free()
    level_run_playback.playback_time = 0.09
    level_run_playback.call("_advance_playback", 0.02)
    var reset_loop_instance := level_run_playback.playback_level as Node3D
    var reset_loop_coin := reset_loop_instance.get_node_or_null("LoopCoin") as GDInventoryPickup
    var reset_loop_player := reset_loop_instance.get_node("Player") as GDLevelRunPlaybackPlayer
    var reset_loop_inventory := reset_loop_player.inventory as GDPlayerInventory
    var reset_loop_particles := reset_loop_instance.get_node(
        "LoopParticles"
    ) as GPUParticles3D
    passed = _expect(
        loop_pack_error == OK \
            and not is_instance_valid(first_loop_instance) \
            and reset_loop_instance != first_loop_instance \
            and playback_viewport.own_world_3d \
            and reset_loop_coin != null \
            and reset_loop_coin.visible \
            and reset_loop_inventory.get_used_inventory_units() == 0 \
            and reset_loop_inventory.get_item_count(&"gold_coin") == 0,
        "looping a last-run playback replaces its isolated session and replay inventory"
    ) and passed
    passed = _expect(
        reset_loop_particles.emitting,
        "last-run playback preserves authored particle emitters across loops"
    ) and passed
    await level_run_playback.stop_for_scene_change()

    screen.level_buttons[6].grab_focus()
    await create_timer(GDLevelSelectScreen.FOCUS_SCROLL_DURATION + 0.05).timeout
    screen._move_focus(Vector2i.DOWN)
    screen._move_focus(Vector2i.DOWN)
    passed = _expect(
        screen.selected_button_index == 8,
        "a double down tap moves focus twice without waiting for scrolling"
    ) and passed
    passed = _expect(
        screen.scroll_tween != null,
        "the shared level list owns the eased focus-scroll tween"
    ) and passed

    screen.level_buttons[0].grab_focus()
    await process_frame
    passed = _expect(
        not liberated_heading.visible \
        and not level_loot_tiles.visible \
        and not screen.liberated_summary_label.visible,
        "played tombs without liberated loot keep the liberated-loot section hidden"
    ) and passed

    screen.level_buttons[1].grab_focus()
    await process_frame
    passed = _expect(
        liberated_heading.visible \
        and diamond_loot_quantity.text == "x2" \
        and gold_coin_loot_quantity.text == "x7" \
        and level_diamond_tile.visible \
        and level_coin_tile.visible \
        and not level_ruby_tile.visible \
        and level_loot_tiles.visible \
        and screen.liberated_summary_label.text == "9 PIECES LIBERATED  •  70% RECOVERED",
        "played tombs show the liberated-loot section only when it contains treasure"
    ) and passed
    screen.level_buttons[8].grab_focus()
    await create_timer(GDLevelSelectScreen.FOCUS_SCROLL_DURATION + 0.05).timeout
    passed = _expect(
        screen.selected_button_index == 8,
        "joypad-style list navigation reaches later level rows"
    ) and passed
    passed = _expect(
        scroll.scroll_vertical > 0,
        "focused joypad selections automatically scroll into view"
    ) and passed

    screen.level_buttons[8].grab_focus()
    var first_up_flick := InputEventJoypadMotion.new()
    first_up_flick.axis = JOY_AXIS_LEFT_Y
    first_up_flick.axis_value = -1.0
    screen._input(first_up_flick)
    var frontend_move_player := root.get_node_or_null(
        "FrontendAudio/FrontendMoveCursor"
    ) as AudioStreamPlayer
    passed = _expect(
        frontend_move_player != null and frontend_move_player.bus == GDAudio.SFX_BUS,
        "level and shop list movement plays cursor audio through shared SFX support"
    ) and passed
    screen._input(first_up_flick)
    var partial_up_release := InputEventJoypadMotion.new()
    partial_up_release.axis = JOY_AXIS_LEFT_Y
    partial_up_release.axis_value = -0.45
    screen._input(partial_up_release)
    var second_up_flick := InputEventJoypadMotion.new()
    second_up_flick.axis = JOY_AXIS_LEFT_Y
    second_up_flick.axis_value = -0.9
    screen._input(second_up_flick)
    passed = _expect(
        screen.selected_button_index == 6,
        "two analog flicks move twice after a partial release without unwanted hold repeat"
    ) and passed
    scroll._process(scroll.navigation_repeat_delay + 0.01)
    passed = _expect(
        screen.selected_button_index == 5,
        "holding the level-select stick repeats movement after the configured delay"
    ) and passed
    var full_up_release := InputEventJoypadMotion.new()
    full_up_release.axis = JOY_AXIS_LEFT_Y
    full_up_release.axis_value = 0.0
    screen._input(full_up_release)

    screen.level_buttons[15].grab_focus()
    screen._move_focus(Vector2i.LEFT)
    passed = _expect(
        back_button.has_focus(),
        "left from the level list moves to Back"
    ) and passed
    screen._move_focus(Vector2i.RIGHT)
    passed = _expect(
        settings_button.has_focus(),
        "right moves across the bottom actions to Settings"
    ) and passed
    screen._move_focus(Vector2i.RIGHT)
    passed = _expect(
        shop_button.has_focus(),
        "a second right movement reaches Shop"
    ) and passed
    screen._move_focus(Vector2i.UP)
    passed = _expect(
        screen.level_buttons[15].has_focus(),
        "up returns from a bottom action to the previously selected level row"
    ) and passed

    screen._on_button_gui_input(InputEventMouseMotion.new(), 3)
    passed = _expect(
        screen.selected_button_index == 3 \
        and level_selection.get_last_highlighted_level_index() == 3,
        "moving the mouse over a level remembers that highlighted card"
    ) and passed

    level_selection.last_highlighted_level_index = 99
    screen._focus_initial_level()
    passed = _expect(
        screen.selected_button_index == 0,
        "an invalid remembered level falls back to the first available level"
    ) and passed

    level_selection.level_mapping = original_mapping
    level_selection.last_highlighted_level_index = original_highlighted_index
    level_selection.level_results = original_results
    level_selection.persistence_enabled = original_persistence_enabled
    screen.queue_free()
    preview_root.queue_free()
    return passed


func _test_level_lookup_supports_debug_and_stable_ids() -> bool:
    var mapping := load("res://levels/level_mapping.tres") as GDLevelMapping
    return _expect(mapping.get_level_count() == 17, "level lookup exposes the debug level and sixteen slots") \
        and _expect(mapping.get_level_id(0) == "debug_level", "debug level has a stable mapping ID") \
        and _expect(mapping.get_level_id(1) == "level_01", "level 1 has a stable mapping ID") \
        and _expect(
            mapping.find_level_index("Vampire Boss") == 9 \
                and mapping.find_level_index("vampire-maze") == 9,
            "level lookup resolves Codex CLI references by name and folder"
        ) \
        and _expect(
            bool(mapping.get_level_data(9).get("run_playback_enabled", true)) \
                and not mapping.get_level_data(9).has(
                    "run_playback_background_load_enabled"
                ),
            "Vampire Boss recordings use the shared safe preview loader"
        ) \
        and _expect(
            mapping.get_level_scene_path(9) == "res://levels/1/level.tscn",
            "dummy level slots can reuse an existing level scene"
        )


func _test_level_selection_tracks_outcomes_and_highlight() -> bool:
    var level_selection := TestLevelSelection.new()
    level_selection.select_level(0)
    level_selection.select_level(0)
    level_selection.record_level_result(0, 3, 50, false)
    var failed_result := level_selection.get_level_result(0)
    var passed := _expect(
        bool(failed_result.get("played", false)) and not bool(failed_result.get("escaped", false)),
        "a failed attempt is stored separately from an escape"
    ) and _expect(
        int(failed_result.get("play_count", 0)) == 2,
        "launching a level increments its persistent play count"
    )

    level_selection.record_level_result(0, 4, 65, true)
    var complete_result := level_selection.get_level_result(0)
    passed = _expect(
        bool(complete_result.get("escaped", false))
        and int(complete_result.get("best_percentage", 0)) == 65,
        "an escape stores its best treasure percentage"
    ) and passed

    level_selection.record_level_result(0, 6, 100, false)
    var failed_after_escape_result := level_selection.get_level_result(0)
    passed = _expect(
        int(failed_after_escape_result.get("best_percentage", 0)) == 65,
        "a later failed attempt cannot turn an earlier partial escape into full success"
    ) and passed

    passed = _expect(level_selection.select_level(16), "the final dummy level can be selected") and passed
    passed = _expect(
        level_selection.get_last_highlighted_level_index() == 16,
        "selecting a level remembers it for the next menu visit"
    ) and passed
    passed = _expect(
        level_selection.remember_highlighted_level(3) \
        and level_selection.get_last_highlighted_level_index() == 3,
        "moving focus remembers the highlighted level without launching it"
    ) and passed
    level_selection.free()
    return passed


func _test_level_progress_uses_stable_mapping_ids() -> bool:
    var level_selection := TestLevelSelection.new()
    var mapping := GDLevelMapping.new()
    mapping.level_entries = [
        _create_level_definition("alpha", "Alpha", "alpha", true, false, "01"),
        _create_level_definition("bravo", "Bravo", "bravo", true, false, "02"),
    ]
    level_selection.level_mapping = mapping
    level_selection.level_results = level_selection.migrate_results_for_test({
        "02": {
            "best_percentage": 73,
            "escaped": true,
            "play_count": 4,
            "played": true,
        },
    })

    mapping.level_entries.insert(
        0,
        _create_level_definition("new_level", "New Level", "new")
    )
    var moved_result := level_selection.get_level_result(2)
    var new_result := level_selection.get_level_result(0)
    var passed := _expect(
        int(moved_result.get("best_percentage", 0)) == 73,
        "saved progress follows a stable level ID after mappings are inserted"
    ) and _expect(
        not bool(new_result.get("played", false)),
        "a newly inserted mapping does not inherit another level's progress"
    ) and _expect(
        level_selection.resolve_highlighted_index_for_test({
            "last_highlighted_level_index": 1,
        }) == 2,
        "legacy highlighted indices migrate through legacy level keys"
    )

    level_selection.free()
    return passed


func _create_level_definition(
    level_id: String,
    level_name: String,
    level_folder_name: String,
    is_available: bool = true,
    is_tutorial: bool = false,
    legacy_key: String = ""
) -> Resource:
    var definition := LEVEL_DEFINITION_SCRIPT.new()
    definition.id = level_id
    definition.display_name = level_name
    definition.folder_name = level_folder_name
    definition.available = is_available
    definition.tutorial = is_tutorial
    definition.legacy_result_key = legacy_key
    return definition


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


func _test_kill_boundary_size_does_not_scale_center() -> bool:
    var boundary := TestKillBoundary.new()
    root.add_child(boundary)
    boundary._ensure_boundary_nodes()
    boundary.boundary_size_x = 12.0
    boundary.boundary_size_y = 6.0

    var center := boundary.get_node("BoundaryCenter") as PathFollow3D
    var passed := _expect(
        boundary.get_bounds_size().is_equal_approx(Vector2(12.0, 6.0)),
        "kill boundary exposes its animated geometry size"
    ) and _expect(
        center.scale.is_equal_approx(Vector3.ONE),
        "kill boundary size does not stretch BoundaryCenter"
    )
    boundary.queue_free()
    return passed


func _test_kill_boundary_missing_scale_tracks_use_identity_scale() -> bool:
    var boundary := TestKillBoundary.new()
    root.add_child(boundary)
    boundary._ensure_boundary_nodes()
    boundary.boundary_scale_x = 2.0
    boundary.boundary_scale_z = 3.0
    var size_only_animation := Animation.new()
    size_only_animation.length = 4.0
    var size_x_track := size_only_animation.add_track(Animation.TYPE_VALUE)
    size_only_animation.track_set_path(size_x_track, NodePath(".:boundary_size_x"))
    size_only_animation.track_insert_key(size_x_track, 0.0, 16.0)
    var size_y_track := size_only_animation.add_track(Animation.TYPE_VALUE)
    size_only_animation.track_set_path(size_y_track, NodePath(".:boundary_size_y"))
    size_only_animation.track_insert_key(size_y_track, 0.0, 16.0)
    var empty_scale_x_track := size_only_animation.add_track(Animation.TYPE_VALUE)
    size_only_animation.track_set_path(empty_scale_x_track, NodePath(".:boundary_scale_x"))
    var empty_scale_z_track := size_only_animation.add_track(Animation.TYPE_VALUE)
    size_only_animation.track_set_path(empty_scale_z_track, NodePath(".:boundary_scale_z"))
    var empty_rotation_track := size_only_animation.add_track(Animation.TYPE_VALUE)
    size_only_animation.track_set_path(empty_rotation_track, NodePath(".:boundary_rotation_z_radians"))

    boundary._sync_boundary_scale_rotation_to_animation(size_only_animation, 0.0)
    var center := boundary.get_node("BoundaryCenter") as PathFollow3D
    var passed := _expect(
        is_equal_approx(boundary.boundary_scale_x, 1.0)
        and is_equal_approx(boundary.boundary_scale_z, 1.0),
        "missing or empty kill boundary scale tracks reset legacy scale values"
    ) and _expect(
        center.scale.is_equal_approx(Vector3.ONE),
        "missing kill boundary scale tracks apply identity center scale"
    )
    boundary.queue_free()
    return passed


func _test_new_kill_boundary_animation_has_default_size_keys() -> bool:
    var boundary := TestKillBoundary.new()
    var animation := boundary._create_default_animation()
    var size_x_track := animation.find_track(NodePath(".:boundary_size_x"), Animation.TYPE_VALUE)
    var size_y_track := animation.find_track(NodePath(".:boundary_size_y"), Animation.TYPE_VALUE)
    var passed := _expect(
        _animation_track_has_default_boundary_size_keys(animation, size_x_track),
        "new kill boundary animation has 16m start and end width keys"
    ) and _expect(
        _animation_track_has_default_boundary_size_keys(animation, size_y_track),
        "new kill boundary animation has 16m start and end depth keys"
    )
    boundary.free()
    return passed


func _test_new_kill_boundary_animation_uses_path_duration() -> bool:
    var boundary := TestKillBoundary.new()
    var path_curve := Curve3D.new()
    path_curve.add_point(Vector3.ZERO)
    path_curve.add_point(Vector3(10.0, 0.0, 0.0))
    boundary.curve = path_curve
    boundary.movement_speed = 2.0

    var animation := boundary._create_default_animation()
    var passed := _expect(
        is_equal_approx(animation.length, 5.0),
        "new kill boundary animation derives duration from path length and movement speed"
    )
    boundary.free()
    return passed


func _animation_track_has_default_boundary_size_keys(animation: Animation, track: int) -> bool:
    return (
        track >= 0
        and animation.track_get_key_count(track) == 2
        and is_zero_approx(animation.track_get_key_time(track, 0))
        and is_equal_approx(animation.track_get_key_time(track, 1), animation.length)
        and is_equal_approx(float(animation.track_get_key_value(track, 0)), 16.0)
        and is_equal_approx(float(animation.track_get_key_value(track, 1)), 16.0)
    )


func _test_existing_kill_boundary_animation_gains_size_tracks() -> bool:
    var boundary := TestKillBoundary.new()
    boundary.boundary_size_x = 24.0
    boundary.boundary_size_y = 18.0
    var animation := _create_pose_test_boundary_animation()
    boundary._upgrade_boundary_animation_tracks(animation)

    var size_x_track := animation.find_track(NodePath(".:boundary_size_x"), Animation.TYPE_VALUE)
    var size_y_track := animation.find_track(NodePath(".:boundary_size_y"), Animation.TYPE_VALUE)
    var passed := _expect(
        _animation_track_has_size_keys(animation, size_x_track, 24.0),
        "existing kill boundary animation gains current width keys"
    ) and _expect(
        _animation_track_has_size_keys(animation, size_y_track, 18.0),
        "existing kill boundary animation gains current depth keys"
    )
    boundary.free()
    return passed


func _animation_track_has_size_keys(animation: Animation, track: int, expected_size: float) -> bool:
    return (
        track >= 0
        and animation.track_get_key_count(track) == 2
        and is_zero_approx(animation.track_get_key_time(track, 0))
        and is_equal_approx(animation.track_get_key_time(track, 1), animation.length)
        and is_equal_approx(float(animation.track_get_key_value(track, 0)), expected_size)
        and is_equal_approx(float(animation.track_get_key_value(track, 1)), expected_size)
    )


func _test_rectangular_kill_boundary_keeps_square_corners_at_non_square_size() -> bool:
    var boundary := TestKillBoundary.new()
    boundary.boundary_size_x = 20.0
    boundary.boundary_size_y = 16.0
    boundary.shape_morph = 0.0
    boundary.boundary_segments = 32
    var points := boundary._get_boundary_points()
    var passed := _expect(
        points.has(Vector2(10.0, 8.0))
        and points.has(Vector2(-10.0, 8.0))
        and points.has(Vector2(-10.0, -8.0))
        and points.has(Vector2(10.0, -8.0)),
        "20x16 rectangular kill boundary includes all exact corners"
    )
    var all_points_are_on_straight_edges := true
    for point in points:
        if not is_equal_approx(absf(point.x), 10.0) and not is_equal_approx(absf(point.y), 8.0):
            all_points_are_on_straight_edges = false
            break
    passed = _expect(
        all_points_are_on_straight_edges,
        "20x16 rectangular kill boundary points stay on straight edges"
    ) and passed
    boundary.free()
    return passed


func _test_kill_boundary_animation_marks_path_point_times() -> bool:
    var boundary := TestKillBoundary.new()
    var path_curve := Curve3D.new()
    path_curve.add_point(Vector3.ZERO)
    path_curve.add_point(Vector3(2.0, 0.0, 0.0))
    path_curve.add_point(Vector3(4.0, 0.0, 0.0))
    boundary.curve = path_curve
    boundary.boundary_animation = _create_pose_test_boundary_animation()
    boundary._sync_path_point_animation_markers()

    var animation := boundary.boundary_animation
    var passed := _expect(
        animation.has_marker(&"Path Point 1")
        and is_zero_approx(animation.get_marker_time(&"Path Point 1")),
        "kill boundary animation marks the first path point at the start"
    ) and _expect(
        animation.has_marker(&"Path Point 2")
        and is_equal_approx(animation.get_marker_time(&"Path Point 2"), 2.0),
        "kill boundary animation marks an intermediate path point at its arrival time"
    ) and _expect(
        animation.has_marker(&"Path Point 3")
        and is_equal_approx(animation.get_marker_time(&"Path Point 3"), 4.0),
        "kill boundary animation marks the final path point at its arrival time"
    )
    boundary.free()
    return passed


func _test_kill_boundary_markers_extend_animation_to_path_end() -> bool:
    var boundary := TestKillBoundary.new()
    var path_curve := Curve3D.new()
    path_curve.add_point(Vector3.ZERO)
    path_curve.add_point(Vector3(10.0, 0.0, 0.0))
    boundary.curve = path_curve
    var animation := Animation.new()
    animation.length = 4.0
    var speed_track := animation.add_track(Animation.TYPE_VALUE)
    animation.track_set_path(speed_track, NodePath(".:movement_speed"))
    animation.track_insert_key(speed_track, 0.0, 1.0)
    boundary.boundary_animation = animation

    boundary._sync_path_point_animation_markers()
    var passed := _expect(
        is_equal_approx(animation.length, 10.0),
        "path markers extend animation duration using the final speed"
    ) and _expect(
        animation.has_marker(&"Path Point 2")
        and is_equal_approx(animation.get_marker_time(&"Path Point 2"), 10.0),
        "extended animation includes the final path point marker"
    ) and _expect(
        animation.track_get_key_count(speed_track) == 1
        and is_zero_approx(animation.track_get_key_time(speed_track, 0)),
        "path marker extension leaves existing animation keys unchanged"
    )
    boundary.free()
    return passed


func _test_kill_boundary_path_markers_wait_for_stable_curve() -> bool:
    var boundary := TestKillBoundary.new()
    var path_curve := Curve3D.new()
    path_curve.add_point(Vector3.ZERO)
    path_curve.add_point(Vector3(4.0, 0.0, 0.0))
    boundary.curve = path_curve
    boundary.boundary_animation = _create_pose_test_boundary_animation()

    boundary._update_path_point_animation_markers(1.0)
    var animation := boundary.boundary_animation
    var passed := _expect(
        not animation.has_marker(&"Path Point 1"),
        "path marker refresh waits after observing a curve edit"
    )
    boundary._update_path_point_animation_markers(1.0)
    passed = _expect(
        animation.has_marker(&"Path Point 1") and animation.has_marker(&"Path Point 2"),
        "path marker refresh runs after the curve remains stable"
    ) and passed
    boundary.free()
    return passed


func _test_kill_boundary_speed_edit_ripple_retimes_other_keys() -> bool:
    var boundary := TestKillBoundary.new()
    var animation := Animation.new()
    animation.length = 10.0
    var speed_track := animation.add_track(Animation.TYPE_VALUE)
    animation.track_set_path(speed_track, NodePath(".:movement_speed"))
    animation.track_insert_key(speed_track, 0.0, 1.0)
    animation.track_insert_key(speed_track, 5.0, 1.0)
    var size_track := animation.add_track(Animation.TYPE_VALUE)
    animation.track_set_path(size_track, NodePath(".:boundary_size_x"))
    animation.track_insert_key(size_track, 0.0, 16.0)
    animation.track_insert_key(size_track, 2.5, 18.0)
    animation.track_insert_key(size_track, 5.0, 20.0)
    animation.track_insert_key(size_track, 8.0, 22.0)
    animation.add_marker(&"Test Marker", 8.0)
    boundary.boundary_animation = animation

    var old_animation := animation.duplicate(true) as Animation
    animation.track_set_key_value(speed_track, 0, 2.0)
    var retimed := boundary._ripple_retime_tracks_after_speed_change(old_animation, animation)
    var expected_interval_end := 10.0 / 3.0
    var expected_time_delta := expected_interval_end - 5.0
    var passed := _expect(retimed, "single kill boundary speed edit triggers ripple retiming") \
        and _expect(
            is_zero_approx(animation.track_get_key_time(size_track, 0)),
            "ripple retiming leaves keys before the edited speed key unchanged"
        ) \
        and _expect(
            is_equal_approx(animation.track_get_key_time(size_track, 1), 5.0 / 3.0),
            "ripple retiming scales keys inside the changed speed interval"
        ) \
        and _expect(
            is_equal_approx(animation.track_get_key_time(size_track, 2), expected_interval_end),
            "ripple retiming moves the next interval anchor"
        ) \
        and _expect(
            is_equal_approx(animation.track_get_key_time(size_track, 3), 8.0 + expected_time_delta),
            "ripple retiming translates keys after the next speed key"
        ) \
        and _expect(
            is_equal_approx(animation.get_marker_time(&"Test Marker"), 8.0 + expected_time_delta),
            "ripple retiming translates animation markers after the interval"
        ) \
        and _expect(
            is_equal_approx(animation.length, 10.0 + expected_time_delta),
            "ripple retiming adjusts the animation duration"
        )
    boundary.free()
    return passed


func _test_kill_boundary_speed_edit_retimes_incoming_linear_interval() -> bool:
    var boundary := TestKillBoundary.new()
    var animation := Animation.new()
    animation.length = 15.0
    var speed_track := animation.add_track(Animation.TYPE_VALUE)
    animation.track_set_path(speed_track, NodePath(".:movement_speed"))
    animation.track_insert_key(speed_track, 0.0, 1.0)
    animation.track_insert_key(speed_track, 5.0, 1.0)
    animation.track_insert_key(speed_track, 10.0, 1.0)
    var size_track := animation.add_track(Animation.TYPE_VALUE)
    animation.track_set_path(size_track, NodePath(".:boundary_size_x"))
    animation.track_insert_key(size_track, 0.0, 16.0)
    animation.track_insert_key(size_track, 2.5, 17.0)
    animation.track_insert_key(size_track, 5.0, 18.0)
    animation.track_insert_key(size_track, 7.5, 19.0)
    animation.track_insert_key(size_track, 10.0, 20.0)
    animation.track_insert_key(size_track, 12.0, 21.0)
    boundary.boundary_animation = animation

    var old_animation := animation.duplicate(true) as Animation
    animation.track_set_key_value(speed_track, 1, 2.0)
    var retimed := boundary._ripple_retime_tracks_after_speed_change(old_animation, animation)
    var passed := _expect(retimed, "interior linear speed edit triggers two-sided ripple retiming") \
        and _expect(
            is_zero_approx(animation.track_get_key_time(size_track, 0)),
            "two-sided ripple keeps the previous speed key anchor fixed"
        ) \
        and _expect(
            is_equal_approx(animation.track_get_key_time(size_track, 1), 5.0 / 3.0),
            "two-sided ripple scales keys in the incoming linear interval"
        ) \
        and _expect(
            is_equal_approx(animation.track_get_key_time(size_track, 2), 10.0 / 3.0),
            "two-sided ripple moves the edited speed key to preserve incoming distance"
        ) \
        and _expect(
            is_equal_approx(animation.track_get_key_time(size_track, 3), 5.0),
            "two-sided ripple scales keys in the outgoing linear interval"
        ) \
        and _expect(
            is_equal_approx(animation.track_get_key_time(size_track, 4), 20.0 / 3.0),
            "two-sided ripple moves the next speed key after both interval changes"
        ) \
        and _expect(
            is_equal_approx(animation.track_get_key_time(size_track, 5), 26.0 / 3.0),
            "two-sided ripple translates later keys by the combined interval delta"
        )
    boundary.free()
    return passed


func _test_graveyard_starts_refactored_kill_boundary_animation() -> bool:
    var graveyard := TestGraveyard.new()
    var passed := true
    for level_path in ["res://levels/1/level.tscn", "res://levels/2/level.tscn"]:
        var level_scene := load(level_path) as PackedScene
        var level := level_scene.instantiate() as Node3D
        root.add_child(level)
        graveyard.current_level = level

        var boundary := level.get_node("KillBoundary3D") as GDKillBoundary3D
        var animation_player := boundary.get_node("BoundaryAnimationPlayer") as AnimationPlayer
        animation_player.stop()
        graveyard.start_kill_boundary_for_test()

        passed = _expect(
            graveyard.get_kill_boundary_for_test() == boundary,
            "%s finds the concrete refactored kill-boundary script" % level_path
        ) and passed
        passed = _expect(
            animation_player.is_playing(),
            "%s starts the refactored kill-boundary animation" % level_path
        ) and passed

        root.remove_child(level)
        level.free()
    graveyard.free()
    return passed


func _test_production_kill_boundaries_use_equivalent_size_tracks() -> bool:
    var level_expectations: Array[Dictionary] = [
        {
            "path": "res://levels/1/level.tscn",
            "length": 475.27316,
            "speed": 1.0,
            "times": [0.0, 10.0, 20.0, 30.0],
            "widths": [8.0, 14.0, 5.0, 8.0],
            "depths": [8.0, 12.0, 7.0, 8.0],
        },
        {
            "path": "res://levels/2/level.tscn",
            "length": 480.0,
            "speed": 2.0,
            "times": [0.0, 10.099455, 20.19891, 30.298367],
            "widths": [8.0, 14.0, 5.0, 8.0],
            "depths": [8.0, 12.0, 7.0, 8.0],
        },
        {
            "path": "res://levels/3/level.tscn",
            "length": 60.033333,
            "speed": 3.25,
            "times": [0.0],
            "widths": [17.6],
            "depths": [17.6],
        },
        {
            "path": "res://levels/6/level.tscn",
            "length": 475.27316,
            "speed": 1.0,
            "times": [0.0, 10.0, 20.0, 30.0],
            "widths": [8.0, 14.0, 5.0, 8.0],
            "depths": [8.0, 12.0, 7.0, 8.0],
        },
    ]
    var passed := true
    for expectation in level_expectations:
        var level_scene := load(expectation["path"] as String) as PackedScene
        var level := level_scene.instantiate() as Node3D
        var boundary := level.get_node("KillBoundary3D") as GDKillBoundary3D
        var animation := boundary.boundary_animation
        var speed_track := animation.find_track(NodePath(".:movement_speed"), Animation.TYPE_VALUE)
        var width_track := animation.find_track(NodePath(".:boundary_size_x"), Animation.TYPE_VALUE)
        var depth_track := animation.find_track(NodePath(".:boundary_size_y"), Animation.TYPE_VALUE)
        passed = _expect(
            is_equal_approx(animation.length, expectation["length"] as float),
            "%s preserves its production kill-boundary timeline length" % expectation["path"]
        ) and passed
        passed = _expect(
            _animation_track_matches(animation, speed_track, [0.0], [expectation["speed"]]),
            "%s preserves its production kill-boundary movement speed" % expectation["path"]
        ) and passed
        passed = _expect(
            animation.find_track(NodePath(".:boundary_scale_x"), Animation.TYPE_VALUE) < 0
            and animation.find_track(NodePath(".:boundary_scale_z"), Animation.TYPE_VALUE) < 0,
            "%s no longer animates legacy center scale" % expectation["path"]
        ) and passed
        passed = _expect(
            _animation_track_matches(animation, width_track, expectation["times"], expectation["widths"])
            and _animation_track_matches(animation, depth_track, expectation["times"], expectation["depths"]),
            "%s preserves kill-boundary key timing and equivalent world sizes" % expectation["path"]
        ) and passed
        var center := boundary.get_node("BoundaryCenter") as PathFollow3D
        passed = _expect(
            center.scale.is_equal_approx(Vector3.ONE),
            "%s keeps BoundaryCenter at identity scale" % expectation["path"]
        ) and passed
        level.free()
    return passed


func _animation_track_matches(
    animation: Animation,
    track: int,
    expected_times: Array,
    expected_values: Array
) -> bool:
    if track < 0 or animation.track_get_key_count(track) != expected_times.size():
        return false
    for key_index in expected_times.size():
        if not is_equal_approx(animation.track_get_key_time(track, key_index), expected_times[key_index] as float):
            return false
        if not is_equal_approx(animation.track_get_key_value(track, key_index) as float, expected_values[key_index] as float):
            return false
    return true


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
        and _expect(
            center.global_position.is_equal_approx(center_position),
            "no-boundary removal keeps current center pose"
        ) \
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
    passed = _expect(
        not bool(graveyard.call("_should_show_minimap")),
        "level settings can disable the minimap"
    ) and passed

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
    var passed := _expect(
        is_equal_approx(float(vignette.call("get_target_intensity")), 0.0),
        "healthy player hides low-health vignette"
    )
    passed = _expect(
        vignette.layer == 30,
        "low-health vignette renders above gameplay and under gameplay HUD layers"
    ) and passed

    vignette.call("set_health_ratio", 0.50, false)
    passed = _expect(
        is_equal_approx(float(vignette.call("get_target_intensity")), 0.0),
        "vignette starts below configured health threshold"
    ) and passed

    vignette.call("set_health_ratio", 2.0 / 6.0, false)
    passed = _expect(
        float(vignette.call("get_target_intensity")) > 0.4,
        "vignette is visible when two health bars remain"
    ) and passed

    vignette.call("set_health_ratio", 1.0 / 6.0, false)
    passed = _expect(
        float(vignette.call("get_target_intensity")) > 0.99,
        "vignette is full strength when one health bar remains"
    ) and passed

    vignette.call("set_health_ratio", 0.20, false)
    passed = _expect(
        is_equal_approx(float(vignette.call("get_target_intensity")), 1.0),
        "vignette reaches full strength at critical health"
    ) and passed

    vignette.call("set_health_ratio", 1.0, true)
    passed = _expect(
        is_equal_approx(float(vignette.call("get_target_intensity")), 1.0),
        "dead player keeps warning vignette visible"
    ) and passed

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
        and _expect(
            panel.get_node_or_null("ScreenContainer") != null,
            "HUD panel has a full-screen editor container"
        ) \
        and _expect(
            panel.get_node_or_null("ScreenContainer/PanelPlacement") != null,
            "HUD panel has an editor-owned placement node"
        ) \
        and _expect(
            not panel.get_node("ScreenContainer/PanelPlacement/PlacementGuide").visible,
            "HUD panel hides placement guide at runtime"
        ) \
        and _expect(
            is_equal_approx(screen_container.scale.x, screen_container.scale.y),
            "HUD panel scales reference screen uniformly"
        ) \
        and _expect(
            is_equal_approx(screen_container.position.x, 320.0),
            "HUD panel centers reference screen on wide viewports"
        )

    panel.queue_free()
    return passed


func _test_shop_uses_reusable_resizable_frames() -> bool:
    var level_selection := root.get_node_or_null("LevelSelection") as GDLevelSelection
    if not _expect(level_selection != null, "level selection autoload supplies the shop wallet"):
        return false
    var original_wallet := level_selection.treasure_wallet.duplicate(true)
    var original_purchases := level_selection.shop_purchases.duplicate(true)
    var original_persistence_enabled := level_selection.persistence_enabled
    level_selection.persistence_enabled = false
    level_selection.treasure_wallet = {"diamond": 2, "gold_coin": 60}
    level_selection.shop_purchases = {}

    var shop := SHOP_SCENE.instantiate() as Control
    root.add_child(shop)
    shop.set_anchors_preset(Control.PRESET_TOP_LEFT)
    shop.size = Vector2(2560.0, 1080.0)
    shop.call("_sync_screen_container")
    await process_frame

    var screen_container := shop.get_node("ScreenContainer") as Control
    var shop_title := shop.get_node("ScreenContainer/ScreenTitleLabel") as Label
    var inventory_frame := shop.get_node("ScreenContainer/InventoryFrame") as NinePatchRect
    var details_frame := shop.get_node("ScreenContainer/DetailsFrame") as NinePatchRect
    var scroll := shop.get_node(
        "ScreenContainer/InventoryFrame/Content/ShopItemsPanel/AvailableItemsScroll"
    ) as ScrollContainer
    var item_rows := shop.get("item_rows") as Array
    var available_items := shop.get("available_items") as Array
    var item_name_label := shop.get_node(
        "ScreenContainer/DetailsFrame/Content/SelectedItemPanel/ItemNameLabel"
    ) as Label
    var selected_item_panel := shop.get_node(
        "ScreenContainer/DetailsFrame/Content/SelectedItemPanel"
    ) as Panel
    var bottom_actions := shop.get_node("ScreenContainer/BottomActions") as HBoxContainer
    var back_button := shop.get_node("ScreenContainer/BottomActions/BackButton") as Button
    var wallet_tiles := shop.get_node("ScreenContainer/WalletTiles") as HBoxContainer
    var gold_coin_tile := shop.get_node(
        "ScreenContainer/WalletTiles/GoldCoinTile"
    ) as Control
    var diamond_tile := shop.get_node(
        "ScreenContainer/WalletTiles/DiamondTile"
    ) as Control
    var ruby_tile := shop.get_node(
        "ScreenContainer/WalletTiles/RubyTile"
    ) as Control
    var gold_coin_quantity := gold_coin_tile.get_node("TreasureQuantityLabel") as Label
    var diamond_quantity := diamond_tile.get_node("TreasureQuantityLabel") as Label
    var diamond_icon := diamond_tile.get_node("TreasureIconTexture") as TextureRect
    var compact_surround := diamond_tile.get_node("ScaledSurround") as NinePatchRect
    var unavailable_item_was_filtered := true
    for row: Button in item_rows:
        if StringName(row.get_meta(&"shop_item_id", &"")) == &"royal_coffin_lining":
            unavailable_item_was_filtered = false
            break

    var focus_style := item_rows[0].get_theme_stylebox(&"focus") as StyleBoxFlat
    var moth_cloak_row := item_rows[3] as Button
    var cursed_lantern_row := item_rows[4] as Button
    var bone_charm_row := item_rows[5] as Button
    var stock_count_label := item_rows[0].get_node("StockCountLabel") as Label
    var passed := _expect(
        inventory_frame.patch_margin_left > 0,
        "shop inventory frame preserves nine-slice corners"
    ) and _expect(
        shop_title.text == "SHOP",
        "shop carries the unified screen title"
    ) and _expect(
        inventory_frame.axis_stretch_horizontal == NinePatchRect.AXIS_STRETCH_MODE_TILE
            and inventory_frame.axis_stretch_vertical == NinePatchRect.AXIS_STRETCH_MODE_TILE,
        "shop frame tiles its edge artwork instead of stretching it"
    ) and _expect(
        details_frame.patch_margin_right == inventory_frame.patch_margin_right,
        "shop frames share the reusable panel surround"
    ) and _expect(
        inventory_frame.get_node_or_null("Content") != null
            and details_frame.get_node_or_null("Content") != null,
        "shop frames expose inset content areas"
    ) and _expect(
        not is_equal_approx(inventory_frame.size.x, details_frame.size.x),
        "shop demonstrates that panel surrounds can be resized independently"
    ) and _expect(
        is_equal_approx(screen_container.scale.x, screen_container.scale.y),
        "shop scales its reference screen uniformly"
    ) and _expect(
        is_equal_approx(screen_container.position.x, 320.0),
        "shop centres its reference screen on wide viewports"
    ) and _expect(
        available_items.size() == 12 and item_rows.size() == 12,
        "shop catalog supplies enough available items to exercise scrolling"
    ) and _expect(
        unavailable_item_was_filtered,
        "shop filters unavailable catalog items before building the list"
    ) and _expect(
        focus_style != null and focus_style.border_width_left == 5 \
            and focus_style.border_width_top == 5 \
            and focus_style.border_width_right == 5 \
            and focus_style.border_width_bottom == 5,
        "shop selection uses a five-pixel focus rectangle"
    ) and _expect(
        item_name_label.text == "BONE CHARM",
        "shop starts on the catalog's configured initial item"
    ) and _expect(
        stock_count_label.text == "x5",
        "shop rows show their authored stock count"
    ) and _expect(
        not cursed_lantern_row.disabled \
            and cursed_lantern_row.focus_mode == Control.FOCUS_ALL \
            and cursed_lantern_row.modulate.is_equal_approx(Color(0.43, 0.43, 0.43, 1.0)),
        "items without enough matching treasure stay grey but remain focusable"
    ) and _expect(
        not bone_charm_row.disabled,
        "an item priced at the current balance remains selectable"
    ) and _expect(
        moth_cloak_row.get_node(moth_cloak_row.focus_neighbor_bottom) == cursed_lantern_row,
        "joypad navigation can move onto greyed-out shop rows"
    ) and _expect(
        bone_charm_row.get_node(bone_charm_row.focus_neighbor_left) == back_button \
            and bone_charm_row.get_node(bone_charm_row.focus_neighbor_right) == back_button,
        "shop rows route left and right to the sole Level Select action"
    ) and _expect(
        gold_coin_quantity.text == "x60" \
            and diamond_quantity.text == "x2" \
            and gold_coin_tile.visible \
            and diamond_tile.visible \
            and not ruby_tile.visible \
            and diamond_icon.texture.resource_path \
            == "res://Assets/frontend/diamond-icon.png",
        "the shop displays owned balances and hides empty resource boxes"
    ) and _expect(
        compact_surround.axis_stretch_horizontal == NinePatchRect.AXIS_STRETCH_MODE_TILE \
            and compact_surround.axis_stretch_vertical == NinePatchRect.AXIS_STRETCH_MODE_TILE \
            and compact_surround.scale.is_equal_approx(Vector2(0.5, 0.5)) \
            and inventory_frame.position.y > diamond_tile.get_global_rect().end.y,
        "compact balance borders tile at half scale above the shifted shop panels"
    ) and _expect(
        gold_coin_tile.get_global_rect().position.y >= 48.0 \
            and bottom_actions.get_child_count() == 1 \
            and back_button.text == "LEVEL SELECT" \
            and back_button.size.is_equal_approx(Vector2(260.0, 72.0)),
        "shop balances have top breathing room and Level Select is the only bottom action"
    ) and _expect(
        scroll.get_v_scroll_bar().max_value > scroll.get_v_scroll_bar().page,
        "shop item placeholders extend beyond the visible scrolling area"
    )

    bone_charm_row.grab_focus()
    var shop_first_up_flick := InputEventJoypadMotion.new()
    shop_first_up_flick.axis = JOY_AXIS_LEFT_Y
    shop_first_up_flick.axis_value = -1.0
    shop._input(shop_first_up_flick)
    var shop_partial_up_release := InputEventJoypadMotion.new()
    shop_partial_up_release.axis = JOY_AXIS_LEFT_Y
    shop_partial_up_release.axis_value = -0.45
    shop._input(shop_partial_up_release)
    var shop_second_up_flick := InputEventJoypadMotion.new()
    shop_second_up_flick.axis = JOY_AXIS_LEFT_Y
    shop_second_up_flick.axis_value = -0.9
    shop._input(shop_second_up_flick)
    var shop_up_release := InputEventJoypadMotion.new()
    shop_up_release.axis = JOY_AXIS_LEFT_Y
    shop_up_release.axis_value = 0.0
    shop._input(shop_up_release)
    passed = _expect(
        int(shop.get("selected_item_index")) == 3 and item_name_label.text == "MOTH CLOAK",
        "shop navigation shares partial-release analog flick handling"
    ) and passed

    cursed_lantern_row.grab_focus()
    await process_frame
    passed = _expect(
        item_name_label.text == "CURSED LANTERN",
        "selecting an unaffordable item still populates its details"
    ) and _expect(
        selected_item_panel.modulate.is_equal_approx(Color(0.43, 0.43, 0.43, 1.0)),
        "unaffordable selected-item artwork and details use the grey treatment"
    ) and passed

    bone_charm_row.grab_focus()
    await process_frame
    passed = _expect(
        selected_item_panel.modulate.is_equal_approx(Color.WHITE),
        "affordable selected-item details return to full colour"
    ) and passed

    bone_charm_row.button_down.emit()
    await process_frame
    var bone_stock_label := bone_charm_row.get_node("StockCountLabel") as Label
    passed = _expect(
        level_selection.get_treasure_count(&"diamond") == 0 \
            and level_selection.get_shop_item_purchase_count(&"bone_charm") == 1,
        "clicking an item buys it, deducts its currency, and saves the purchase"
    ) and _expect(
        bone_stock_label.text == "x4" \
            and selected_item_panel.modulate.is_equal_approx(Color(0.43, 0.43, 0.43, 1.0)),
        "direct purchases immediately refresh remaining stock and affordability"
    ) and _expect(
        diamond_quantity.text == "x0" and not diamond_tile.visible,
        "spending the final resource immediately removes its empty balance box"
    ) and passed

    level_selection.treasure_wallet.clear()
    shop.call("_update_wallet_tiles")
    passed = _expect(
        not wallet_tiles.visible,
        "the shop hides the complete balance row when every resource count is empty"
    ) and passed

    scroll.scroll_vertical = 0
    (item_rows[item_rows.size() - 1] as Button).grab_focus()
    await process_frame
    var scroll_tween := scroll.get("scroll_tween") as Tween
    passed = _expect(
        scroll_tween != null and scroll_tween.is_running(),
        "joypad-style focus changes start eased shop scrolling"
    ) and passed
    await create_timer(0.25).timeout
    passed = _expect(
        scroll.scroll_vertical > 0,
        "focused shop items scroll smoothly into view"
    ) and _expect(
        item_name_label.text == "BLACK CANDLE",
        "focused shop rows update the selected-item details"
    ) and passed

    shop.queue_free()
    level_selection.treasure_wallet = original_wallet
    level_selection.shop_purchases = original_purchases
    level_selection.persistence_enabled = original_persistence_enabled
    return passed


func _test_frontend_gallery_instances_navigable_screens() -> bool:
    var gallery := FRONTEND_GALLERY_SCENE.instantiate() as Control
    var preview_paths := [
        ^"TitleCard/TitleScreenPreview",
        ^"ShopCard/ShopPreview",
        ^"SettingsCard/SettingsPreview",
        ^"WinCard/WinPreview",
        ^"LoseCard/LosePreview",
    ]
    var all_previews_are_linked_and_scaled := true
    for preview_path: NodePath in preview_paths:
        var preview := gallery.get_node_or_null(preview_path) as Control
        if preview == null or not preview.scale.is_equal_approx(Vector2(0.27, 0.27)):
            all_previews_are_linked_and_scaled = false
            break

    var title_card := gallery.get_node("TitleCard") as Panel
    var level_preview_viewport := gallery.get_node(
        "LevelSelectCard/PreviewViewportContainer/PreviewViewport"
    ) as SubViewport
    var level_preview_container := level_preview_viewport.get_parent() as SubViewportContainer
    var level_preview := level_preview_viewport.get_node_or_null(
        "LevelSelectPreview"
    ) as Control
    var settings_card := gallery.get_node("SettingsCard") as Panel
    var lose_card := gallery.get_node("LoseCard") as Panel
    var win_preview := gallery.get_node("WinCard/WinPreview") as Control
    var lose_preview := gallery.get_node("LoseCard/LosePreview") as Control
    var win_title := win_preview.get_node("ScreenContainer/ScreenTitleLabel") as Label
    var lose_title := lose_preview.get_node("ScreenContainer/ScreenTitleLabel") as Label
    var win_actions := win_preview.get_node("ScreenContainer/BottomActions") as HBoxContainer
    var lose_actions := lose_preview.get_node("ScreenContainer/BottomActions") as HBoxContainer
    var passed := _expect(
        all_previews_are_linked_and_scaled \
            and level_preview != null \
            and level_preview_viewport.size == Vector2i(1920, 1080) \
            and not level_preview_container.stretch \
            and level_preview_container.size.is_equal_approx(Vector2(1920, 1080)) \
            and level_preview_container.scale.is_equal_approx(Vector2(0.27, 0.27)),
        "frontend gallery links and consistently frames all six navigable screens"
    ) and _expect(
        level_preview_viewport.get_parent().clip_contents \
            and level_preview_viewport.render_target_update_mode \
                == SubViewport.UPDATE_ALWAYS,
        "level-select preview is isolated so its own screen scaler cannot escape its card"
    ) and _expect(
        settings_card.position.y > title_card.position.y \
            and lose_card.position.x > settings_card.position.x,
        "frontend gallery arranges its screen previews side by side in two rows"
    ) and _expect(
        lose_title.text == "YOU DIED!" \
            and lose_title.position.is_equal_approx(win_title.position) \
            and lose_title.size.is_equal_approx(win_title.size),
        "lose title is editor-authored at the shared result title position"
    ) and _expect(
        lose_actions.position.is_equal_approx(win_actions.position) \
            and lose_actions.size.is_equal_approx(win_actions.size),
        "lose buttons retain the shared result-screen action placement"
    )
    gallery.free()
    return passed


func _test_result_screens_and_settings_share_frontend_design() -> bool:
    var level_selection := root.get_node_or_null("LevelSelection") as GDLevelSelection
    var result_stats := root.get_node_or_null("ResultStats") as GDResultStats
    var game_settings := root.get_node_or_null("GameSettings")
    if not _expect(
        level_selection != null and result_stats != null and game_settings != null,
        "frontend result and settings test has its persistent services"
    ):
        return false

    var original_results := level_selection.level_results.duplicate(true)
    var original_wallet := level_selection.treasure_wallet.duplicate(true)
    var original_purchases := level_selection.shop_purchases.duplicate(true)
    var original_highlight := level_selection.last_highlighted_level_index
    var original_persistence := level_selection.persistence_enabled
    var original_music := float(game_settings.get("music_volume_percent"))
    var original_sound_effects := float(game_settings.get("sound_effect_volume_percent"))
    var original_settings_persistence := bool(game_settings.get("persistence_enabled"))
    level_selection.persistence_enabled = false
    level_selection.level_results = {}
    level_selection.treasure_wallet = {}
    level_selection.shop_purchases = {}
    game_settings.set("persistence_enabled", false)

    result_stats.begin_attempt(100)
    result_stats.add_treasure(&"gold_coin", 1)
    var win_screen := WIN_SCREEN_SCENE.instantiate() as GDResultScreen
    root.add_child(win_screen)
    await process_frame
    var win_title := win_screen.get_node("ScreenContainer/ScreenTitleLabel") as Label
    var win_percentage := win_screen.get_node(
        "ScreenContainer/ResultFrame/Content/ResultContentCenter/ResultContent/PercentageValueLabel"
    ) as Label
    var win_tiles := win_screen.get_node(
        "ScreenContainer/ResultFrame/Content/ResultContentCenter/ResultContent/TreasureTiles"
    ) as HFlowContainer
    var win_coin_tile := win_tiles.get_node("GoldCoinTile") as Control
    var win_coin_count := win_coin_tile.get_node(
        "TreasureQuantityLabel"
    ) as Label
    var win_diamond_tile := win_tiles.get_node("DiamondTile") as Control
    var result_frame := win_screen.get_node("ScreenContainer/ResultFrame") as NinePatchRect
    var win_back := win_screen.get_node(
        "ScreenContainer/BottomActions/BackButton"
    ) as Button
    var win_retry := win_screen.get_node(
        "ScreenContainer/BottomActions/SecondaryButton"
    ) as Button
    var result_primary := InputEventJoypadButton.new()
    result_primary.button_index = JOY_BUTTON_A
    result_primary.pressed = true
    var passed := _expect(
        win_title.text == "ESCAPED THE GRAVE" \
            and win_title.get_global_rect().end.y <= result_frame.get_global_rect().position.y \
            and win_screen.get_node_or_null(
                "ScreenContainer/ResultFrame/Content/OutcomeHeadingLabel"
            ) == null \
            and win_screen.get_node_or_null(
                "ScreenContainer/ResultFrame/Content/OutcomeMessageLabel"
            ) == null,
        "the result title sits outside the surround without duplicate internal copy"
    ) and _expect(
        win_coin_tile.visible \
            and win_coin_count.text == "x1" \
            and not win_diamond_tile.visible \
            and win_percentage.text == "1%",
        "a coin-only win shows only the newly liberated coin tile and percentage"
    ) and _expect(
        win_coin_tile.custom_minimum_size.x == 340.0 \
            and win_coin_tile.custom_minimum_size.y == 176.0,
        "result resource tiles use the larger presentation"
    ) and _expect(
        result_frame.axis_stretch_horizontal == NinePatchRect.AXIS_STRETCH_MODE_TILE \
            and result_frame.axis_stretch_vertical == NinePatchRect.AXIS_STRETCH_MODE_TILE,
        "result screens use the shared tiled stone surround"
    ) and _expect(
        win_screen.get_script().get_base_script().resource_path \
            == "res://ui/frontend/frontend_screen.gd",
        "frontend screens inherit shared scaling and primary-input support"
    ) and _expect(
        win_back.text == "LEVEL SELECT" \
            and win_back.has_focus() \
            and win_retry.text == "RETRY" \
            and not win_retry.has_focus(),
        "successful results initially highlight Back while retaining Retry"
    )
    win_screen.size = Vector2(1280.0, 720.0)
    win_screen.call("_sync_screen_container")
    var win_container := win_screen.get_node("ScreenContainer") as Control
    passed = _expect(
        win_container.scale.is_equal_approx(Vector2(2.0 / 3.0, 2.0 / 3.0)) \
            and win_container.position.is_equal_approx(Vector2.ZERO),
        "win results scale their complete reference canvas to the viewport"
    ) and _expect(
        win_back.button_down.get_connections().size() == 1 \
            and win_retry.button_down.get_connections().size() == 1,
        "win result actions respond immediately to mouse and joypad button presses"
    ) and passed
    win_screen.call("_unhandled_input", result_primary)
    passed = _expect(
        win_screen.transitioning,
        "joypad primary activates the focused Level Select action on a win"
    ) and passed
    win_screen.queue_free()
    await process_frame

    result_stats.begin_attempt(100)
    result_stats.add_treasure(&"gold_coin", 1)
    var replay_screen := WIN_SCREEN_SCENE.instantiate() as GDResultScreen
    root.add_child(replay_screen)
    await process_frame
    var replay_tiles := replay_screen.get_node(
        "ScreenContainer/ResultFrame/Content/ResultContentCenter/ResultContent/TreasureTiles"
    ) as HFlowContainer
    passed = _expect(
        not replay_tiles.visible,
        "a successful replay with no additional treasure shows no resource tiles"
    ) and passed
    var replay_retry := replay_screen.get_node(
        "ScreenContainer/BottomActions/SecondaryButton"
    ) as Button
    replay_retry.grab_focus()
    replay_screen.call("_unhandled_input", result_primary)
    passed = _expect(
        replay_screen.transitioning,
        "joypad primary activates the focused Retry action on a win"
    ) and passed
    replay_screen.queue_free()
    await process_frame

    result_stats.begin_attempt(100)
    result_stats.add_treasure(&"gold_coin", 1)
    result_stats.add_treasure(&"gold_bar", 45)
    result_stats.add_treasure(&"diamond", 10)
    result_stats.add_treasure(&"ruby", 9)
    result_stats.add_treasure(&"sapphire", 5)
    result_stats.add_treasure(&"emerald", 6)
    result_stats.add_treasure(&"amethyst", 2)
    var multi_loot_screen := WIN_SCREEN_SCENE.instantiate() as GDResultScreen
    root.add_child(multi_loot_screen)
    await process_frame
    await process_frame
    var multi_loot_tiles := multi_loot_screen.get_node(
        "ScreenContainer/ResultFrame/Content/ResultContentCenter/ResultContent/TreasureTiles"
    ) as HFlowContainer
    var multi_gold_bar := multi_loot_tiles.get_node("GoldBarTile") as Control
    var multi_amethyst := multi_loot_tiles.get_node("AmethystTile") as Control
    passed = _expect(
        multi_gold_bar.visible \
            and multi_amethyst.visible \
            and multi_amethyst.position.y > multi_gold_bar.position.y,
        "larger newly liberated resource tiles wrap into two centred rows"
    ) and passed
    multi_loot_screen.queue_free()
    await process_frame

    level_selection.level_results.erase(level_selection.get_selected_level_id())
    result_stats.begin_attempt(0)
    var treasure_free_win_screen := WIN_SCREEN_SCENE.instantiate() as GDResultScreen
    root.add_child(treasure_free_win_screen)
    await process_frame
    var treasure_free_result := level_selection.get_level_result(
        level_selection.selected_level_index
    )
    passed = _expect(
        bool(treasure_free_result.get("escaped", false)),
        "treasure-free levels still record a successful escape"
    ) and passed
    treasure_free_win_screen.queue_free()
    await process_frame

    result_stats.begin_attempt(100)
    result_stats.add_treasure(&"ruby", 9)
    var lose_screen := LOSE_SCREEN_SCENE.instantiate() as GDResultScreen
    root.add_child(lose_screen)
    await process_frame
    var lose_title := lose_screen.get_node("ScreenContainer/ScreenTitleLabel") as Label
    var lose_ruby_tile := lose_screen.get_node(
        "ScreenContainer/ResultFrame/Content/ResultContentCenter/ResultContent/TreasureTiles/RubyTile"
    ) as Control
    var lose_coin_tile := lose_screen.get_node(
        "ScreenContainer/ResultFrame/Content/ResultContentCenter/ResultContent/TreasureTiles/GoldCoinTile"
    ) as Control
    var lose_ruby_count := lose_ruby_tile.get_node("TreasureQuantityLabel") as Label
    var lose_secondary := lose_screen.get_node(
        "ScreenContainer/BottomActions/SecondaryButton"
    ) as Button
    var lose_back := lose_screen.get_node(
        "ScreenContainer/BottomActions/BackButton"
    ) as Button
    passed = _expect(
        lose_screen is GDLoseScreen \
            and lose_screen.outcome == GDResultScreen.ResultOutcome.Lose \
            and lose_title.text == "YOU DIED!" \
            and lose_ruby_count.text == "x1" \
            and lose_ruby_tile.visible \
            and not lose_coin_tile.visible \
            and lose_ruby_tile.modulate.r < 0.5 \
            and lose_secondary.text == "RETRY" \
            and lose_secondary.has_focus() \
            and not lose_back.has_focus(),
        "death shows the exact lost haul and initially highlights Retry"
    ) and passed
    lose_screen.size = Vector2(2560.0, 1080.0)
    lose_screen.call("_sync_screen_container")
    var lose_container := lose_screen.get_node("ScreenContainer") as Control
    passed = _expect(
        lose_container.scale.is_equal_approx(Vector2.ONE) \
            and lose_container.position.is_equal_approx(Vector2(320.0, 0.0)),
        "lose results centre their complete reference canvas on wide viewports"
    ) and _expect(
        lose_back.button_down.get_connections().size() == 1 \
            and lose_secondary.button_down.get_connections().size() == 1,
        "lose result actions respond immediately to mouse and joypad button presses"
    ) and passed
    lose_screen.call("_unhandled_input", result_primary)
    passed = _expect(
        lose_screen.transitioning,
        "joypad primary activates the focused Retry action on a loss"
    ) and passed
    lose_screen.queue_free()
    await process_frame

    level_selection.level_results = {"test": {"played": true}}
    level_selection.treasure_wallet = {"diamond": 4}
    level_selection.shop_purchases = {"bone_charm": 1}
    var settings_screen := SETTINGS_SCENE.instantiate() as Control
    root.add_child(settings_screen)
    await process_frame
    var settings_title := settings_screen.get_node(
        "ScreenContainer/ScreenTitleLabel"
    ) as Label
    var music_slider := settings_screen.get_node(
        "ScreenContainer/SettingsFrame/Content/SettingsPanel/MusicRow/MusicContent/MusicSlider"
    ) as HSlider
    var sound_slider := settings_screen.get_node(
        "ScreenContainer/SettingsFrame/Content/SettingsPanel/SoundEffectRow/SoundEffectContent/SoundEffectSlider"
    ) as HSlider
    var music_icon := settings_screen.get_node(
        "ScreenContainer/SettingsFrame/Content/SettingsPanel/MusicRow/MusicContent/MusicIcon"
    ) as TextureRect
    var sound_icon := settings_screen.get_node(
        "ScreenContainer/SettingsFrame/Content/SettingsPanel/SoundEffectRow/SoundEffectContent/SoundEffectIcon"
    ) as TextureRect
    var confirmation_frame := settings_screen.get_node(
        "ScreenContainer/ResetConfirmationFrame"
    ) as NinePatchRect
    var settings_frame := settings_screen.get_node(
        "ScreenContainer/SettingsFrame"
    ) as NinePatchRect
    var settings_back := settings_screen.get_node(
        "ScreenContainer/BottomActions/BackButton"
    ) as Button
    var reset_button := settings_screen.get_node(
        "ScreenContainer/SettingsFrame/Content/SettingsPanel/ResetProgressButton"
    ) as Button
    var confirmation_no := settings_screen.get_node(
        "ScreenContainer/ResetConfirmationFrame/Content/ConfirmationActions/NoButton"
    ) as Button
    var confirmation_yes := settings_screen.get_node(
        "ScreenContainer/ResetConfirmationFrame/Content/ConfirmationActions/YesButton"
    ) as Button
    var music_focus_border := settings_screen.get_node(
        "ScreenContainer/SettingsFrame/Content/SettingsPanel/MusicRow/FocusBorder"
    ) as Panel
    var sound_focus_border := settings_screen.get_node(
        "ScreenContainer/SettingsFrame/Content/SettingsPanel/SoundEffectRow/FocusBorder"
    ) as Panel
    var volume_focus_style := music_focus_border.get_theme_stylebox(&"panel") as StyleBoxFlat
    var volume_track_style := music_slider.get_theme_stylebox(&"slider") as StyleBoxFlat
    var music_was_highlighted := music_focus_border.visible
    sound_slider.grab_focus()
    await process_frame
    var sound_was_highlighted := sound_focus_border.visible and not music_focus_border.visible
    settings_screen.size = Vector2(1280.0, 720.0)
    settings_screen.call("_sync_screen_container")
    var settings_container := settings_screen.get_node("ScreenContainer") as Control
    var settings_fits_viewport := settings_container.scale.is_equal_approx(
        Vector2(2.0 / 3.0, 2.0 / 3.0)
    ) and settings_container.position.is_equal_approx(Vector2.ZERO)
    var joypad_primary := InputEventJoypadButton.new()
    joypad_primary.button_index = JOY_BUTTON_A
    joypad_primary.pressed = true
    reset_button.grab_focus()
    settings_screen.call("_unhandled_input", joypad_primary)
    var confirmation_shade := settings_screen.get_node(
        "ScreenContainer/ResetConfirmationShade"
    ) as ColorRect
    var confirmation_was_shown := confirmation_frame.visible \
        and confirmation_shade.visible \
        and confirmation_frame.z_index > confirmation_shade.z_index
    settings_screen.call("_unhandled_input", joypad_primary)
    var confirmation_was_cancelled := not confirmation_frame.visible
    reset_button.grab_focus()
    settings_screen.call("_unhandled_input", joypad_primary)
    confirmation_yes.grab_focus()
    settings_screen.call("_unhandled_input", joypad_primary)
    passed = _expect(
        settings_title.text == "SETTINGS" \
            and music_slider != null and sound_slider != null \
            and AudioServer.get_bus_index(&"Music") >= 0 \
            and AudioServer.get_bus_index(&"SFX") >= 0,
        "settings provides separate persistent music and sound-effect controls"
    ) and _expect(
        volume_track_style != null \
            and volume_track_style.content_margin_top == 20.0 \
            and volume_track_style.content_margin_bottom == 20.0 \
            and music_slider.size_flags_vertical == Control.SIZE_SHRINK_CENTER \
            and sound_slider.size_flags_vertical == Control.SIZE_SHRINK_CENTER \
            and is_equal_approx(
                music_slider.get_global_rect().get_center().y,
                music_icon.get_global_rect().get_center().y
            ) \
            and is_equal_approx(
                sound_slider.get_global_rect().get_center().y,
                sound_icon.get_global_rect().get_center().y
            ),
        "volume sliders use double-thickness tracks centred beside their icons and labels"
    ) and _expect(
        settings_frame.size.x >= 1000.0 \
            and settings_back.visible \
            and settings_back.get_global_rect().position.y \
                >= settings_frame.get_global_rect().end.y,
        "settings uses a substantial surround with a clear external Back action"
    ) and _expect(
        settings_fits_viewport \
            and reset_button.button_down.get_connections().size() == 1 \
            and settings_back.button_down.get_connections().size() == 1 \
            and GDSettingsScreen.LEVEL_SELECT_SCENE_PATH \
                == "res://ui/screens/level_select_screen.tscn" \
            and LEVEL_SELECT_SCENE.can_instantiate(),
        "settings fills the viewport and wires its Reset Progress and Back actions"
    ) and _expect(
        music_was_highlighted \
            and sound_was_highlighted \
            and volume_focus_style != null \
            and volume_focus_style.border_width_left == 5 \
            and volume_focus_style.border_color == Color(1, 0.86, 0.08, 1),
        "music and sound controls share the reset button's yellow focus treatment"
    ) and _expect(
        confirmation_was_shown \
            and confirmation_was_cancelled \
            and not confirmation_frame.visible \
            and level_selection.level_results.is_empty() \
            and level_selection.treasure_wallet.is_empty() \
            and level_selection.shop_purchases.is_empty(),
        "styled confirmation guards a complete progress reset " \
            + "(shown=%s, cancelled=%s, results=%s, wallet=%s, purchases=%s)" % [
                confirmation_was_shown,
                confirmation_was_cancelled,
                level_selection.level_results.is_empty(),
                level_selection.treasure_wallet.is_empty(),
                level_selection.shop_purchases.is_empty(),
            ]
    ) and passed
    settings_screen.queue_free()

    level_selection.level_results = original_results
    level_selection.treasure_wallet = original_wallet
    level_selection.shop_purchases = original_purchases
    level_selection.last_highlighted_level_index = original_highlight
    level_selection.persistence_enabled = original_persistence
    game_settings.set("persistence_enabled", false)
    game_settings.call("set_music_volume_percent", original_music)
    game_settings.call("set_sound_effect_volume_percent", original_sound_effects)
    game_settings.set("persistence_enabled", original_settings_persistence)

    await process_frame
    var navigation_settings := SETTINGS_SCENE.instantiate() as GDSettingsScreen
    root.add_child(navigation_settings)
    current_scene = navigation_settings
    await process_frame
    var navigation_back := navigation_settings.get_node(
        "ScreenContainer/BottomActions/BackButton"
    ) as Button
    navigation_back.grab_focus()
    navigation_settings.call("_unhandled_input", joypad_primary)
    await process_frame
    await process_frame
    var returned_to_level_select := current_scene is GDLevelSelectScreen
    passed = _expect(
        returned_to_level_select,
        "settings Back performs a real transition to the level-select scene"
    ) and passed
    if current_scene != null:
        var loaded_scene := current_scene
        current_scene = null
        loaded_scene.queue_free()
        await process_frame
    return passed


func _test_vampire_settings_prioritize_core_controls() -> bool:
    var settings := load(
        "res://enemies/vampire/vampire_settings.tres"
    ) as Resource
    var advanced_group_index := -1
    var core_property_indices: Array[int] = []
    var advanced_property_indices: Array[int] = []
    var advanced_subgroups: Array[StringName] = []
    var core_property_names: Array[StringName] = [
        &"model_scale",
        &"max_speed",
        &"acceleration",
        &"deceleration",
        &"turn_speed",
        &"sight_distance",
        &"sight_field_of_view_degrees",
        &"sight_loss_grace_seconds",
        &"instant_kill_contact_radius",
        &"proximity_fog_distance",
        &"proximity_fog_max_intensity",
    ]
    var advanced_property_names: Array[StringName] = [
        &"waypoint_reached_distance",
        &"wall_stall_recovery_seconds",
        &"sight_clearance_radius",
        &"last_seen_prediction_seconds",
        &"junction_scan_seconds_per_direction",
        &"noise_retarget_distance",
        &"layout_landmark_noise_match_distance",
        &"proximity_fog_response_speed",
    ]
    var property_list := settings.get_property_list()
    for property_index in property_list.size():
        var property := property_list[property_index] as Dictionary
        var property_name := property.get("name", &"") as StringName
        var property_usage := int(property.get("usage", PROPERTY_USAGE_NONE))
        if (property_usage & PROPERTY_USAGE_GROUP) != 0 \
                and property_name == &"Advanced":
            advanced_group_index = property_index
        elif (property_usage & PROPERTY_USAGE_SUBGROUP) != 0:
            advanced_subgroups.append(property_name)
        elif core_property_names.has(property_name):
            core_property_indices.append(property_index)
        elif advanced_property_names.has(property_name):
            advanced_property_indices.append(property_index)

    var core_controls_are_before_advanced := advanced_group_index >= 0 \
        and core_property_indices.size() == core_property_names.size()
    for property_index in core_property_indices:
        core_controls_are_before_advanced = core_controls_are_before_advanced \
            and property_index < advanced_group_index
    var complex_controls_are_inside_advanced := advanced_property_indices.size() \
        == advanced_property_names.size()
    for property_index in advanced_property_indices:
        complex_controls_are_inside_advanced = complex_controls_are_inside_advanced \
            and property_index > advanced_group_index
    return _expect(
        core_controls_are_before_advanced \
            and complex_controls_are_inside_advanced \
            and advanced_subgroups.has(&"Movement") \
            and advanced_subgroups.has(&"Sight") \
            and advanced_subgroups.has(&"Noise Search") \
            and advanced_subgroups.has(&"Proximity Fog"),
        "Vampire settings keep core controls above grouped advanced tuning"
    )


func _test_characters_glance_and_return_with_safe_head_turns() -> bool:
    var holder := Node3D.new()
    root.add_child(holder)

    var player := PLAYER_SCENE.instantiate() as GDPlayer
    var coin := GOLD_COIN_SCENE.instantiate() as GDInventoryPickup
    holder.add_child(player)
    holder.add_child(coin)
    player.set_physics_process(false)
    coin.set_physics_process(false)
    coin.freeze = true
    coin.position = Vector3(1.5, 0.0, 2.0)
    await physics_frame

    var player_attention: Node = player.get_node("PlayerAttention")
    var player_pivot := player.get_node("Pivot") as Node3D
    var player_look_direction := player.get_node("Pivot/LookDirection") as Node3D
    var player_head := player.get_node(
        "Pivot/Character/character-keeper/root/torso/head"
    ) as Node3D
    var player_torso := player_head.get_parent() as Node3D
    var player_torso_rest_yaw := player_torso.rotation.y
    var player_headlamp := player.get_node("Pivot/PlayerHeadlampLight") as SpotLight3D
    var player_headlamp_offset := player_head.global_transform.affine_inverse() \
        * player_headlamp.global_transform
    var player_travel_yaw := player_pivot.rotation.y
    player_attention.update_attention(0.2)
    player_attention.call("_process", 0.0)
    var player_glances_at_visible_coin: bool = player_attention.get_target_collectible() == coin \
        and player_attention.get_current_head_yaw() > 0.0 \
        and player_attention.get_current_head_yaw() \
            <= float(player_attention.get_maximum_head_turn_radians()) \
        and is_equal_approx(player_pivot.rotation.y, player_travel_yaw) \
        and not is_zero_approx(player_look_direction.rotation.y)
    var player_headlamp_follows_head := (
        player_head.global_transform.affine_inverse() * player_headlamp.global_transform
    ).is_equal_approx(player_headlamp_offset)
    var player_upper_body_supports_look := not is_equal_approx(
        player_torso.rotation.y,
        player_torso_rest_yaw
    )
    coin.queue_free()
    await process_frame
    player_attention.update_attention(0.1)
    player_attention.update_attention(0.8)
    var player_returns_to_travel: bool = is_zero_approx(
        player_attention.get_current_head_yaw()
    ) and is_equal_approx(player_pivot.rotation.y, player_travel_yaw) \
        and player_attention.get_target_collectible() == null
    player_attention.update_attention(0.0, 0.0)
    player_attention.set("next_glance_seconds", 0.0)
    player_attention.update_attention(0.2, 0.0)
    var player_idle_glance := absf(float(player_attention.get_current_head_yaw()))
    var player_first_idle_direction := float(player_attention.get_current_head_yaw())
    player_attention.update_attention(2.0, 0.0)
    var player_second_idle_direction := float(player_attention.get_current_head_yaw())
    var player_continuously_scans_at_rest := player_first_idle_direction \
        * player_second_idle_direction < 0.0
    player_attention.update_attention(0.0, 1.0)
    player_attention.set("next_glance_seconds", 0.0)
    player_attention.update_attention(0.2, 1.0)
    var player_full_pace_glance := absf(float(player_attention.get_current_head_yaw()))

    var vampire := VAMPIRE_SCENE.instantiate() as GDVampire
    vampire.position = Vector3(4.3, 0.0, 1.2)
    holder.add_child(vampire)
    vampire.set_physics_process(false)
    var threat_coin := GOLD_COIN_SCENE.instantiate() as GDInventoryPickup
    threat_coin.position = Vector3(0.0, 0.0, 3.0)
    holder.add_child(threat_coin)
    threat_coin.set_physics_process(false)
    threat_coin.freeze = true
    await physics_frame
    player_attention.update_attention(0.2, 1.0)
    var player_tracks_close_enemy: bool = player_attention.get_target_enemy() == vampire \
        and player_attention.get_target_collectible() == null \
        and is_equal_approx(
            player_attention.get_current_head_yaw(),
            player_attention.get_maximum_head_turn_radians()
        )
    vampire.position = Vector3(-4.3, 0.0, 1.2)
    player_attention.update_attention(0.4, 1.0)
    var player_follows_moving_enemy: bool = player_attention.get_target_enemy() == vampire \
        and player_attention.get_current_head_yaw() < 0.0
    vampire.position = Vector3(0.0, 0.0, -2.0)
    player_attention.update_attention(0.1, 1.0)
    var player_rejects_enemy_behind := player_attention.get_target_enemy() == null
    vampire.position = Vector3(0.0, 0.0, 5.1)
    player_attention.update_attention(0.1, 1.0)
    var player_rejects_enemy_beyond_close_range := player_attention.get_target_enemy() == null
    var vampire_look: Node = vampire.get_node("VampireLook")
    var vampire_pivot := vampire.get_node("Pivot") as Node3D
    var vampire_head := vampire.get_node(
        "Pivot/Character/character-vampire/root/torso/head"
    ) as Node3D
    var vampire_torso := vampire_head.get_parent() as Node3D
    var vampire_torso_rest_yaw := vampire_torso.rotation.y
    var vampire_headlamp := vampire.get_node("Pivot/VampireHeadlampLight") as SpotLight3D
    var vampire_headlamp_offset := vampire_head.global_transform.affine_inverse() \
        * vampire_headlamp.global_transform
    var vampire_travel_yaw := vampire_pivot.rotation.y
    vampire_look.return_to_travel_direction()
    vampire_look.update_look(1.0, Vector3.ZERO, false, false)
    vampire_look.update_look(0.0, Vector3.ZERO, false, true)
    vampire_look.set("next_glance_seconds", 0.0)
    vampire_look.update_look(0.2, Vector3.ZERO, false, true)
    vampire_look.call("_process", 0.0)
    var vampire_idle_glance := absf(float(vampire_look.get_current_head_yaw()))
    var vampire_headlamp_follows_head := (
        vampire_head.global_transform.affine_inverse() * vampire_headlamp.global_transform
    ).is_equal_approx(vampire_headlamp_offset)
    var vampire_upper_body_supports_look := not is_equal_approx(
        vampire_torso.rotation.y,
        vampire_torso_rest_yaw
    )
    var vampire_first_idle_direction := float(vampire_look.get_current_head_yaw())
    vampire_look.update_look(2.0, Vector3.ZERO, false, true, 0.0)
    var vampire_second_idle_direction := float(vampire_look.get_current_head_yaw())
    var vampire_continuously_scans_at_rest := vampire_first_idle_direction \
        * vampire_second_idle_direction < 0.0
    vampire_look.update_look(0.0, Vector3.ZERO, false, true, 1.0)
    vampire_look.set("next_glance_seconds", 0.0)
    vampire_look.update_look(0.2, Vector3.ZERO, false, true, 1.0)
    var vampire_full_pace_glance := absf(float(vampire_look.get_current_head_yaw()))
    var vampire_searches_while_stationary: bool = vampire_idle_glance \
        > vampire_full_pace_glance \
        and is_equal_approx(vampire_pivot.rotation.y, vampire_travel_yaw)
    vampire_look.return_to_travel_direction()
    vampire_look.update_look(1.0, Vector3.ZERO, false, false)
    vampire_look.look_in_world_direction(Vector3.RIGHT)
    vampire_look.update_look(1.0)
    var vampire_turn_is_clamped: bool = is_equal_approx(
        vampire_look.get_current_head_yaw(),
        float(vampire_look.get_maximum_head_turn_radians())
    ) and is_equal_approx(vampire_pivot.rotation.y, vampire_travel_yaw)
    vampire_look.return_to_travel_direction()
    vampire_look.update_look(1.0, Vector3.ZERO, false, false)
    var vampire_returns_to_travel: bool = is_zero_approx(
        vampire_look.get_current_head_yaw()
    ) and is_equal_approx(vampire_pivot.rotation.y, vampire_travel_yaw)

    var snapshot := vampire.get_minimap_debug_snapshot()
    var senses := vampire.get_node("VampireSenses") as GDVampireSenses
    var minimap_and_sight_share_look_direction := (
        senses.get("facing_node") as Node3D
    ) == vampire.get_node("Pivot/LookDirection") \
        and float(snapshot.get("sight_distance", 0.0)) > 0.0 \
        and float(snapshot.get("sight_field_of_view_degrees", 0.0)) > 0.0
    var stationary_attention_is_stronger := float(
        CHARACTER_LOOK_SETTINGS.get_wandering_head_turn_radians(0.0)
    ) > float(CHARACTER_LOOK_SETTINGS.get_wandering_head_turn_radians(0.5)) \
        and float(CHARACTER_LOOK_SETTINGS.get_wandering_head_turn_radians(0.5)) \
            > float(CHARACTER_LOOK_SETTINGS.get_wandering_head_turn_radians(1.0)) \
        and float(CHARACTER_LOOK_SETTINGS.get_wandering_hold_seconds(0.0)) \
            > float(CHARACTER_LOOK_SETTINGS.get_wandering_hold_seconds(1.0)) \
        and float(CHARACTER_LOOK_SETTINGS.get_wandering_interval_max_seconds(0.0)) \
            < float(CHARACTER_LOOK_SETTINGS.get_wandering_interval_min_seconds(1.0))

    var passed := _expect(
        player_glances_at_visible_coin \
            and player_returns_to_travel \
            and player_idle_glance > player_full_pace_glance \
            and player_continuously_scans_at_rest,
        "player continuously scans at rest and focuses toward full-pace travel"
    ) and _expect(
        player_tracks_close_enemy \
            and player_follows_moving_enemy \
            and player_rejects_enemy_behind \
            and player_rejects_enemy_beyond_close_range,
        "player follows close forward enemies as far as its safe head turn permits"
    ) and _expect(
        vampire_searches_while_stationary \
            and vampire_turn_is_clamped \
            and vampire_returns_to_travel \
            and vampire_continuously_scans_at_rest,
        "vampire continuously searches at rest without exceeding a safe head turn"
    ) and _expect(
        player_headlamp_follows_head \
            and vampire_headlamp_follows_head \
            and player_upper_body_supports_look \
            and vampire_upper_body_supports_look,
        "readable head turns include the upper body and keep headlamps attached"
    ) and _expect(
        minimap_and_sight_share_look_direction and stationary_attention_is_stronger,
        "Vampire sight and the shared attention ramp use the live look direction"
    )
    holder.queue_free()
    await process_frame
    return passed


func _test_vampire_layout_knowledge_ages_and_filters_evidence() -> bool:
    var navigation := TestVampireLayoutNavigation.new()
    var evidence_position := Vector3.ZERO
    var visible_end_gate_position := Vector3(10.0, 0.0, 0.0)
    var alternative_key_position := Vector3(-10.0, 0.0, 0.0)
    var landmarks: Array[Dictionary] = [
        {
            "id": &"heard_gold_key",
            "kind": &"gold_key",
            "position": evidence_position,
        },
        {
            "id": &"likely_end_gate",
            "kind": &"end_gate",
            "position": visible_end_gate_position,
        },
        {
            "id": &"alternative_gold_key",
            "kind": &"gold_key",
            "position": alternative_key_position,
        },
        {
            "id": &"unreachable_gold_key",
            "kind": &"gold_key",
            "position": Vector3(30.0, 0.0, 0.0),
        },
    ]

    var fresh_knowledge := GDVampireLayoutKnowledge.new()
    fresh_knowledge.configure(landmarks)
    fresh_knowledge.record_noise_evidence(evidence_position, 0.5)
    var fresh_destination := fresh_knowledge.select_likely_destination(
        evidence_position,
        15.0,
        Vector3.ZERO,
        -1.0,
        navigation,
        1.0
    ) as Dictionary

    var old_knowledge := GDVampireLayoutKnowledge.new()
    old_knowledge.configure(landmarks)
    old_knowledge.record_noise_evidence(evidence_position, 0.5)
    var old_destination := old_knowledge.select_likely_destination(
        evidence_position,
        15.0,
        Vector3.ZERO,
        -1.0,
        navigation,
        0.0
    ) as Dictionary

    var filtered_knowledge := GDVampireLayoutKnowledge.new()
    filtered_knowledge.configure(landmarks)
    filtered_knowledge.record_noise_evidence(evidence_position, 0.5)
    var rule_out_visible_end_gate := func(candidate: Vector3) -> bool:
        return candidate.is_equal_approx(visible_end_gate_position)
    var filtered_destination := filtered_knowledge.select_likely_destination(
        evidence_position,
        15.0,
        Vector3.ZERO,
        -1.0,
        navigation,
        1.0,
        rule_out_visible_end_gate
    ) as Dictionary

    var settings := load(
        "res://enemies/vampire/vampire_settings.tres"
    ).duplicate(true) as Resource
    var hunt := GDVampireHunt.new()
    hunt.settings = settings
    var half_life_seconds := float(settings.get("noise_evidence_half_life_seconds"))
    hunt.noise_elapsed_seconds = half_life_seconds
    var half_life_relevance := hunt.get_noise_evidence_relevance()
    var half_life_radius := hunt.get_noise_uncertainty_radius()
    hunt.noise_elapsed_seconds = half_life_seconds * 2.0
    var two_half_life_relevance := hunt.get_noise_evidence_relevance()
    var two_half_life_radius := hunt.get_noise_uncertainty_radius()

    var observed_player := Node3D.new()
    observed_player.position = visible_end_gate_position
    var position_senses := TestVampirePositionSenses.new()
    root.add_child(observed_player)
    root.add_child(position_senses)
    hunt.player = observed_player
    hunt.senses = position_senses
    hunt.player_is_visible = true
    var confirmed_player_remains_possible := not bool(hunt.call(
        "_is_possible_player_position_ruled_out",
        visible_end_gate_position
    ))
    var visible_empty_position_is_ruled_out := bool(hunt.call(
        "_is_possible_player_position_ruled_out",
        alternative_key_position
    ))

    var fresh_landmark_uses_sound_context := not fresh_destination.is_empty() \
        and (fresh_destination["position"] as Vector3).is_equal_approx(
            visible_end_gate_position
        )
    var old_landmark_returns_to_general_knowledge := not old_destination.is_empty() \
        and (old_destination["position"] as Vector3).is_equal_approx(
            alternative_key_position
        )
    var visible_landmark_is_filtered := not filtered_destination.is_empty() \
        and (filtered_destination["position"] as Vector3).is_equal_approx(
            alternative_key_position
        )
    var passed := _expect(
        fresh_landmark_uses_sound_context \
            and old_landmark_returns_to_general_knowledge,
        "vampire layout clues lose influence as their reachable noise circle grows"
    ) and _expect(
        is_equal_approx(half_life_relevance, 0.5) \
            and is_equal_approx(two_half_life_relevance, 0.25) \
            and two_half_life_radius > half_life_radius,
        "vampire noise age expands possible movement while decaying clue confidence"
    ) and _expect(
        visible_landmark_is_filtered \
            and confirmed_player_remains_possible \
            and visible_empty_position_is_ruled_out,
        "vampire excludes visibly empty predictions but retains a confirmed player tile"
    )
    navigation.free()
    fresh_knowledge.free()
    old_knowledge.free()
    filtered_knowledge.free()
    hunt.free()
    observed_player.free()
    position_senses.free()
    return passed


func _test_vampire_hunt_resets_and_scans_with_frame_delta() -> bool:
    var holder := Node3D.new()
    root.add_child(holder)
    var player := Node3D.new()
    player.position = Vector3(1000.0, 0.0, 1000.0)
    holder.add_child(player)
    var end_gate := Node3D.new()
    end_gate.position = Vector3(8.0, 0.0, 8.0)
    holder.add_child(end_gate)
    var wall_grid_map := GridMap.new()
    holder.add_child(wall_grid_map)
    var vampire := VAMPIRE_SCENE.instantiate() as GDVampire
    vampire.set_physics_process(false)
    holder.add_child(vampire)
    vampire.configure_navigation(wall_grid_map)

    var hunt := vampire.get_node("VampireHunt") as GDVampireHunt
    var navigation := vampire.get_node("VampireNavigation") as GDVampireNavigation
    var senses := vampire.get_node("VampireSenses") as GDVampireSenses
    var layout_knowledge := vampire.get_node(
        "VampireLayoutKnowledge"
    ) as GDVampireLayoutKnowledge
    var settings := vampire.get("settings") as Resource
    hunt.configure(
        vampire,
        navigation,
        senses,
        layout_knowledge,
        player,
        end_gate,
        settings
    )

    hunt.set("noise_target_active", true)
    hunt.set("player_was_visible", true)
    hunt.set("player_is_visible", true)
    hunt.set("searching", true)
    hunt.set("pursuing_last_seen_position", true)
    hunt.set("junction_scan_active", true)
    hunt.set("has_visible_observation", true)
    hunt.set("has_noise_position", true)
    hunt.set("last_seen_player_velocity", Vector3(3.0, 0.0, 1.0))
    hunt.set("last_confirmed_player_position", Vector3(7.0, 0.0, 2.0))
    hunt.set("noise_elapsed_seconds", 9.0)
    hunt.set("sight_loss_elapsed", 2.0)
    hunt.set("awareness_source", GDVampireHunt.AwarenessSource.Sight)
    (hunt.get("noise_search_rng") as RandomNumberGenerator).randi()
    navigation.set("has_target", true)
    navigation.set("route_points", [Vector3.ONE] as Array[Vector3])
    navigation.set(
        "route_traversal_status",
        GDVampireNavigation.RouteTraversalStatus.Following
    )
    layout_knowledge.set("investigation_counts", {&"stale_landmark": 3})
    layout_knowledge.set(
        "last_evidence_kind",
        GDVampireLayoutKnowledge.LandmarkKind.GoldKey
    )
    vampire.velocity = Vector3(4.0, 0.0, 2.0)

    hunt.reset_runtime_state()
    var expected_rng := RandomNumberGenerator.new()
    expected_rng.seed = int(settings.get("noise_search_seed"))
    var reset_rng_matches_seed := (
        hunt.get("noise_search_rng") as RandomNumberGenerator
    ).randi() == expected_rng.randi()
    var stale_observations_are_cleared := \
        not bool(hunt.get("noise_target_active")) \
        and not bool(hunt.get("player_was_visible")) \
        and not bool(hunt.get("player_is_visible")) \
        and not bool(hunt.get("searching")) \
        and not bool(hunt.get("pursuing_last_seen_position")) \
        and not bool(hunt.get("junction_scan_active")) \
        and not bool(hunt.get("has_visible_observation")) \
        and not bool(hunt.get("has_noise_position")) \
        and (hunt.get("last_seen_player_velocity") as Vector3).is_zero_approx() \
        and (hunt.get("last_confirmed_player_position") as Vector3).is_zero_approx() \
        and is_zero_approx(float(hunt.get("noise_elapsed_seconds"))) \
        and is_zero_approx(float(hunt.get("sight_loss_elapsed"))) \
        and int(hunt.get_awareness_source()) == GDVampireHunt.AwarenessSource.None \
        and not bool(navigation.get("has_target")) \
        and navigation.get_route_points().is_empty() \
        and navigation.get_route_traversal_status() \
            == GDVampireNavigation.RouteTraversalStatus.Idle \
        and (layout_knowledge.get("investigation_counts") as Dictionary).is_empty() \
        and int(layout_knowledge.get("last_evidence_kind")) \
            == GDVampireLayoutKnowledge.LandmarkKind.Unknown \
        and vampire.velocity.is_zero_approx() \
        and reset_rng_matches_seed

    var pivot := vampire.get_node("Pivot") as Node3D
    var vampire_look: Node = vampire.get_node("VampireLook")
    pivot.rotation.y = 0.0
    var scan_delta := 1.0 / 60.0
    var travel_yaw_before_scan := pivot.rotation.y
    vampire.set("state", GDVampire.VampireState.SearchingRoute)
    vampire.velocity = Vector3(0.0, 0.0, 2.0)
    navigation.set("has_target", true)
    navigation.set("route_points", [Vector3(0.0, 0.0, 4.0)] as Array[Vector3])
    var velocity_before_corridor_look := vampire.velocity
    vampire.call("_update_look", scan_delta)
    var expected_first_head_yaw := minf(
        float(CHARACTER_LOOK_SETTINGS.head_turn_speed) * scan_delta,
        float(vampire_look.get_maximum_head_turn_radians())
    )
    var side_corridor_directions := senses.get_clear_side_corridor_directions(
        float(settings.get("junction_scan_probe_distance"))
    ) as Array[Vector3]
    var scan_right := pivot.global_basis.x.normalized()
    var corridor_snapshot := vampire.get_minimap_debug_snapshot()
    var moving_search_checks_side_corridors := is_equal_approx(
        pivot.rotation.y,
        travel_yaw_before_scan
    ) and is_equal_approx(
        float(vampire_look.get_current_head_yaw()),
        expected_first_head_yaw
    ) and bool(vampire.call("is_corridor_look_active")) \
        and side_corridor_directions.has(scan_right) \
        and side_corridor_directions.has(-scan_right) \
        and bool(navigation.get("has_target")) \
        and vampire.velocity.is_equal_approx(velocity_before_corridor_look) \
        and bool(corridor_snapshot.get("corridor_look_active", false)) \
        and absf(float(corridor_snapshot.get("head_yaw_degrees", 0.0))) > 0.0
    vampire.call(
        "_update_look",
        float(settings.get("junction_scan_seconds_per_direction")) + 0.01
    )
    var corridor_look_returns_head_to_travel := is_zero_approx(
        float(vampire_look.get_current_head_yaw())
    ) and not bool(vampire.call("is_corridor_look_active"))
    var human_scaled_gameplay_sight := is_equal_approx(
        float(settings.get("sight_field_of_view_degrees")),
        110.0
    )
    var complete_configuration_has_no_errors := vampire.get_configuration_errors(
        player,
        end_gate,
        wall_grid_map
    ).is_empty()
    var missing_dependencies_are_named := vampire.get_configuration_errors(
        null,
        null,
        null
    ) == PackedStringArray(["player", "wall GridMap", "end gate"])

    var passed := _expect(
        moving_search_checks_side_corridors \
            and corridor_look_returns_head_to_travel,
        "vampire checks side corridors with its head while route movement continues"
    ) and _expect(
        human_scaled_gameplay_sight,
        "vampire gameplay sight uses a focused human-scale field of view"
    ) and _expect(
        stale_observations_are_cleared,
        "vampire reuse clears perception, prediction, search, movement, and RNG state"
    ) and _expect(
        complete_configuration_has_no_errors and missing_dependencies_are_named,
        "vampire startup validation reports all missing gameplay dependencies together"
    )
    holder.free()
    return passed


func _test_vampire_boss_routes_to_noise_and_kills_on_contact() -> bool:
    var level_controller := load(
        "res://levels/vampire-maze/vampire_maze.gd"
    ).new() as Node3D
    level_controller.set(&"end_gate_path", NodePath("LockedGate"))
    level_controller.set(&"wall_grid_map_path", NodePath("NavigationWalls"))
    var grid_map := GridMap.new()
    grid_map.name = "NavigationWalls"
    var mesh_library := MeshLibrary.new()
    mesh_library.create_item(0)
    mesh_library.set_item_name(0, "Wall Test")
    grid_map.mesh_library = mesh_library
    for coordinate in range(5):
        grid_map.set_cell_item(Vector3i(coordinate, 0, 0), 0)
        grid_map.set_cell_item(Vector3i(coordinate, 0, 4), 0)
        grid_map.set_cell_item(Vector3i(0, 0, coordinate), 0)
        grid_map.set_cell_item(Vector3i(4, 0, coordinate), 0)
    grid_map.set_cell_item(Vector3i(2, 0, 1), 0)
    grid_map.set_cell_item(Vector3i(2, 0, 2), 0)

    var vampire := VAMPIRE_SCENE.instantiate() as CharacterBody3D
    vampire.name = "Vampire"
    vampire.set_physics_process(false)
    var player := PLAYER_SCENE.instantiate() as GDPlayer
    player.name = "Player"
    player.set_physics_process(false)
    vampire.position = grid_map.map_to_local(Vector3i(1, 0, 1))
    player.position = grid_map.map_to_local(Vector3i(3, 0, 1))
    var authored_player_entrance := player.position
    var coffin := TREASURE_DEPOSIT_COFFIN_SCENE.instantiate() as Node3D
    coffin.position = Vector3(1.0, 0.0, 3.0)
    var gate := Node3D.new()
    gate.name = "LockedGate"
    gate.position = grid_map.map_to_local(Vector3i(3, 0, 3))
    var sight_wall := StaticBody3D.new()
    sight_wall.collision_layer = 1
    sight_wall.position = (
        vampire.position + player.position
    ) * 0.5 + Vector3.UP * 0.8
    var sight_wall_shape := CollisionShape3D.new()
    var sight_wall_box := BoxShape3D.new()
    sight_wall_box.size = Vector3(0.8, 1.6, 0.8)
    sight_wall_shape.shape = sight_wall_box
    sight_wall.add_child(sight_wall_shape)
    var sight_floor := StaticBody3D.new()
    sight_floor.collision_layer = 1
    sight_floor.position = Vector3(2.0, -0.25, 2.0)
    var sight_floor_shape := CollisionShape3D.new()
    var sight_floor_box := BoxShape3D.new()
    sight_floor_box.size = Vector3(8.0, 0.5, 8.0)
    sight_floor_shape.shape = sight_floor_box
    sight_floor.add_child(sight_floor_shape)
    level_controller.add_child(grid_map)
    level_controller.add_child(vampire)
    level_controller.add_child(player)
    level_controller.add_child(coffin)
    level_controller.add_child(gate)
    level_controller.add_child(sight_wall)
    level_controller.add_child(sight_floor)
    var debug_hud := VAMPIRE_DEBUG_HUD_SCENE.instantiate() as CanvasLayer
    level_controller.add_child(debug_hud)

    var selected_targets: Array[Vector3] = []
    vampire.target_selected.connect(
        func(noise_position: Vector3) -> void:
            selected_targets.append(noise_position)
    )
    root.add_child(level_controller)
    await process_frame
    var hunt := vampire.get_node("VampireHunt")
    var starts_hunting_entrance: bool = selected_targets.size() == 1 \
        and selected_targets[0].is_equal_approx(authored_player_entrance) \
        and vampire.get_vampire_state() == GDVampire.VampireState.Hunting \
        and int(hunt.call("get_awareness_source")) \
            == GDVampireHunt.AwarenessSource.Entrance
    var placed_coffin_bodies: Array[PhysicsBody3D] = []
    var coffin_root_body := coffin as PhysicsBody3D
    if coffin_root_body != null \
            and (player.collision_mask & coffin_root_body.collision_layer) != 0:
        placed_coffin_bodies.append(coffin_root_body)
    for coffin_body_node in coffin.find_children("*", "PhysicsBody3D", true, false):
        var coffin_body := coffin_body_node as PhysicsBody3D
        if coffin_body != null \
                and (player.collision_mask & coffin_body.collision_layer) != 0:
            placed_coffin_bodies.append(coffin_body)
    var placed_coffin_blocks_only_player := not placed_coffin_bodies.is_empty()
    for coffin_body in placed_coffin_bodies:
        placed_coffin_blocks_only_player = placed_coffin_blocks_only_player \
            and vampire.get_collision_exceptions().has(coffin_body) \
            and coffin_body.get_collision_exceptions().has(vampire) \
            and not player.get_collision_exceptions().has(coffin_body)
    await physics_frame
    for _settle_step in 3:
        vampire.velocity = Vector3.DOWN * 10.0
        vampire.move_and_slide()
        await physics_frame
    var stride_pivot := vampire.get_node("Pivot") as Node3D
    var stride_rest_position := stride_pivot.position
    var stride_test_position := vampire.global_position
    var stride_sample_position := coffin.global_position
    for coffin_body in placed_coffin_bodies:
        var body_shapes := coffin_body.find_children(
            "*",
            "CollisionShape3D",
            true,
            false
        )
        if body_shapes.is_empty():
            continue
        var coffin_shape := body_shapes[0] as CollisionShape3D
        var debug_mesh := coffin_shape.shape.get_debug_mesh()
        var world_bounds := coffin_shape.global_transform * debug_mesh.get_aabb()
        stride_sample_position = world_bounds.get_center()
        break
    stride_sample_position.y = stride_test_position.y
    vampire.global_position = stride_sample_position
    vampire.velocity = Vector3.ZERO
    vampire.call("_update_passthrough_obstacle_stride", 1.0)
    var coffin_stride_lifts_model := stride_pivot.position.y \
        > stride_rest_position.y + 0.05
    vampire.global_position = stride_test_position
    vampire.velocity = Vector3.ZERO
    vampire.call("_update_passthrough_obstacle_stride", 1.0)
    var coffin_stride_returns_to_floor := stride_pivot.position.is_equal_approx(
        stride_rest_position
    )
    var settings := vampire.get("settings") as Resource
    var navigation := vampire.get_node("VampireNavigation")
    var wall_side_search_body := TestVampireSearchBody.new()
    level_controller.add_child(wall_side_search_body)
    wall_side_search_body.global_position = grid_map.to_global(
        grid_map.map_to_local(Vector3i(3, 0, 1))
    )
    var wall_side_navigation := GDVampireNavigation.new()
    level_controller.add_child(wall_side_navigation)
    wall_side_navigation.configure(
        wall_side_search_body,
        vampire.get_node("Pivot") as Node3D,
        settings
    )
    wall_side_navigation.set_wall_grid_map(grid_map)
    var wall_cell_centre := grid_map.to_global(
        grid_map.map_to_local(Vector3i(2, 0, 1))
    )
    var player_side_wall_target := wall_cell_centre + Vector3(-0.49, 0.0, 0.0)
    var wall_side_route := wall_side_navigation.build_route_to(
        player_side_wall_target
    ) as Array[Vector3]
    var resolved_wall_side_cell := Vector3i(3, 0, 1)
    if not wall_side_route.is_empty():
        resolved_wall_side_cell = grid_map.local_to_map(
            grid_map.to_local(wall_side_route.back())
        )
        resolved_wall_side_cell.y = 0
    var wall_adjacent_target_uses_player_side: bool = not wall_side_route.is_empty() \
        and resolved_wall_side_cell == Vector3i(1, 0, 1)
    var noise_search_rng := hunt.get("noise_search_rng") as RandomNumberGenerator
    var expected_noise_search_rng := RandomNumberGenerator.new()
    expected_noise_search_rng.seed = int(settings.get("noise_search_seed"))
    var noise_search_is_replay_stable: bool = noise_search_rng != null \
        and noise_search_rng.seed == expected_noise_search_rng.seed \
        and noise_search_rng.state == expected_noise_search_rng.state \
        and player.process_physics_priority < vampire.process_physics_priority \
        and vampire.process_physics_priority \
            < (vampire.get_node("VampireSenses") as Node).process_physics_priority
    var ordered_search_points := navigation.get_reachable_search_points(
        vampire.global_position,
        float(settings.get("assumed_player_max_speed")) * 5.0,
        0.0
    ) as Array[Vector3]
    var search_candidates_are_stably_ordered := true
    for point_index in range(1, ordered_search_points.size()):
        var previous_point := ordered_search_points[point_index - 1]
        var current_point := ordered_search_points[point_index]
        if previous_point.x > current_point.x \
                or (previous_point.x == current_point.x \
                and previous_point.z > current_point.z):
            search_candidates_are_stably_ordered = false
            break
    var target_position := grid_map.to_global(grid_map.map_to_local(Vector3i(3, 0, 1)))
    vampire.hear_noise(target_position)
    var route_points := navigation.get_route_points() as Array[Vector3]
    var simplified_route := navigation.build_route_to(target_position) as Array[Vector3]
    var active_route_keeps_safe_cell_steps := route_points.size() > simplified_route.size()
    var routes_around_wall := false
    for route_point in route_points:
        var cell := grid_map.local_to_map(grid_map.to_local(route_point))
        if cell.z >= 3:
            routes_around_wall = true
            break
    navigation.call(
        "_update_wall_stall_recovery",
        float(settings.get("wall_stall_recovery_seconds")),
        true,
        0.0,
        float(settings.get("max_speed"))
    )
    var recovers_after_wall_stall: bool = int(
        navigation.call("get_wall_stall_recovery_count")
    ) == 1 and not (navigation.get_route_points() as Array[Vector3]).is_empty()
    navigation.call(
        "_update_wall_stall_recovery",
        float(settings.get("wall_stall_recovery_seconds")),
        false,
        0.0,
        float(settings.get("max_speed"))
    )
    var recovers_after_collisionless_stall: bool = int(
        navigation.call("get_wall_stall_recovery_count")
    ) == 2 and not (navigation.get_route_points() as Array[Vector3]).is_empty()
    navigation.call(
        "select_visible_target",
        target_position,
        vampire.global_position,
        true
    )
    var safe_tile_direction := navigation.call("get_active_route_direction") as Vector3
    var crossing_direction := Vector3(
        -safe_tile_direction.z,
        0.0,
        safe_tile_direction.x
    ).normalized()
    navigation.call(
        "update_visible_player_position",
        vampire.global_position + crossing_direction * 0.1,
        true
    )
    navigation.call("update_velocity", 0.016)
    var pursues_closer_visible_player := bool(
        navigation.call("is_using_visible_player_shortcut")
    ) and Vector2(
        vampire.velocity.x,
        vampire.velocity.z
    ).normalized().dot(Vector2(crossing_direction.x, crossing_direction.z)) > 0.999
    var route_rebuilds_before_direct_recovery := int(
        navigation.call("get_route_rebuild_count")
    )
    navigation.call("_abandon_blocked_visible_shortcut")
    var blocked_direct_shortcut_recovers_immediately: bool = not bool(
        navigation.call("is_using_visible_player_shortcut")
    ) and not bool(navigation.get("visible_player_direct_path_clear")) \
        and int(navigation.call("get_direct_shortcut_recovery_count")) == 1 \
        and int(navigation.call("get_route_rebuild_count")) \
            == route_rebuilds_before_direct_recovery + 1 \
        and not (navigation.get_route_points() as Array[Vector3]).is_empty()
    navigation.set(
        "current_horizontal_velocity",
        crossing_direction * float(settings.get("max_speed"))
    )
    navigation.call(
        "update_visible_player_position",
        vampire.global_position + crossing_direction * 10.0,
        true
    )
    navigation.call("update_velocity", 0.016)
    var follows_tile_route_without_lateral_drift := not bool(
        navigation.call("is_using_visible_player_shortcut")
    ) and Vector2(
        vampire.velocity.x,
        vampire.velocity.z
    ).normalized().dot(Vector2(safe_tile_direction.x, safe_tile_direction.z)) > 0.999
    navigation.set(
        "route_index",
        (navigation.get_route_points() as Array[Vector3]).size()
    )
    navigation.set("has_target", true)
    navigation.set("current_horizontal_velocity", Vector3.ZERO)
    navigation.call(
        "update_visible_player_position",
        vampire.global_position + crossing_direction * 0.8,
        true
    )
    navigation.call("update_velocity", 0.016)
    var completed_tile_route_keeps_chasing_visible_player: bool = bool(
        navigation.get("has_target")
    ) and bool(navigation.call("is_using_visible_player_shortcut")) \
        and Vector2(vampire.velocity.x, vampire.velocity.z).length() > 0.0
    navigation.call("select_target", target_position)
    navigation.set("current_horizontal_velocity", Vector3.ZERO)
    vampire.velocity.x = 0.0
    vampire.velocity.z = 0.0

    var senses := vampire.get_node("VampireSenses") as ShapeCast3D
    var vampire_process_mode := vampire.process_mode
    vampire.process_mode = Node.PROCESS_MODE_DISABLED
    player.position.y = vampire.position.y
    var current_sight_direction := player.position - vampire.position
    current_sight_direction.y = 0.0
    current_sight_direction = current_sight_direction.normalized()
    var vampire_pivot := vampire.get_node("Pivot") as Node3D
    vampire_pivot.rotation.y = atan2(
        current_sight_direction.x,
        current_sight_direction.z
    )
    var sight_edge_direction := Vector3(
        -current_sight_direction.z,
        0.0,
        current_sight_direction.x
    )
    var sight_wall_centre := (
        vampire.position + player.position
    ) * 0.5 + Vector3.UP * 0.8
    var sight_wall_clear_offset := sight_edge_direction * 8.0
    sight_wall.position = sight_wall_centre
    await physics_frame
    var blocked_by_body_height_wall := not bool(senses.call("can_see_player"))
    sight_wall.position = sight_wall_centre + sight_wall_clear_offset
    await physics_frame
    var blocked_by_grid_wall := not bool(senses.call("can_see_player"))
    grid_map.set_cell_item(Vector3i(2, 0, 1), GridMap.INVALID_CELL_ITEM)
    grid_map.set_cell_item(Vector3i(2, 0, 2), GridMap.INVALID_CELL_ITEM)
    await physics_frame
    var sees_clear_player := bool(senses.call("can_see_player"))
    var clear_sight_allows_direct_chase := bool(
        senses.call("is_player_direct_path_clear")
    )
    var visible_empty_position := vampire.global_position.lerp(
        player.global_position,
        0.5
    )
    var clear_empty_tile_is_verified := bool(senses.call(
        "can_verify_position_is_empty",
        visible_empty_position
    ))
    var visible_player_tile_is_not_empty := not bool(senses.call(
        "can_verify_position_is_empty",
        player.global_position
    ))
    sight_wall.position = sight_wall_centre + sight_edge_direction * 0.9
    await physics_frame
    var edge_sight_target := Vector3(
        player.global_position.x,
        senses.global_position.y,
        player.global_position.z
    )
    var sees_past_body_width_wall_edge := bool(senses.call("can_see_player")) \
        and bool(senses.call("_sight_ray_hits_player", edge_sight_target)) \
        and not bool(senses.call("is_player_direct_path_clear"))
    sight_wall_box.size = Vector3(0.08, 1.6, 0.08)
    sight_wall.position = sight_wall_centre
    await physics_frame
    var centre_ray_blocked_by_thin_wall := not bool(
        senses.call("_sight_ray_hits_player", edge_sight_target)
    )
    var body_samples_see_around_thin_wall := bool(senses.call("can_see_player"))
    sight_wall_box.size = Vector3(0.8, 1.6, 0.8)
    sight_wall.position = sight_wall_centre
    await physics_frame
    var offset_sight_still_respects_full_wall := not bool(
        senses.call("can_see_player")
    )
    senses.call("sample_player_visibility")
    var ordinary_player_position := player.global_position
    vampire_pivot.rotation.y = atan2(
        sight_edge_direction.x,
        sight_edge_direction.z
    )
    player.global_position = vampire.global_position + sight_edge_direction * 1.25
    await physics_frame
    var notices_player_passing_close := bool(senses.call("sample_player_visibility"))
    var close_pass_target := navigation.get("target_position") as Vector3
    var close_pass_is_chasing: bool = vampire.get_vampire_state() \
        == GDVampire.VampireState.ChasingPlayer
    var close_pass_targets_player := close_pass_target.is_equal_approx(
        player.global_position
    )
    var close_pass_retains_visible_position := bool(
        navigation.get("has_visible_player_position")
    )
    sight_wall.position = sight_wall_centre + sight_wall_clear_offset
    var wall_pressed_player_position := grid_map.to_global(
        grid_map.map_to_local(Vector3i(3, 0, 1))
    ) + Vector3(0.0, 0.0, -0.51)
    wall_pressed_player_position.y = vampire.global_position.y
    var wall_pressed_direction := (
        wall_pressed_player_position - vampire.global_position
    )
    vampire_pivot.rotation.y = atan2(
        wall_pressed_direction.x,
        wall_pressed_direction.z
    )
    player.global_position = wall_pressed_player_position
    await physics_frame
    var wall_pressed_player_cell := grid_map.local_to_map(
        grid_map.to_local(player.global_position)
    )
    wall_pressed_player_cell.y = 0
    grid_map.set_cell_item(wall_pressed_player_cell, 0)
    await physics_frame
    var player_endpoint_is_logical_wall := bool(
        senses.call("_world_position_is_wall", player.global_position)
    )
    var sees_player_pressed_into_wall_cell := player_endpoint_is_logical_wall \
        and bool(senses.call("can_see_player"))
    grid_map.set_cell_item(wall_pressed_player_cell, GridMap.INVALID_CELL_ITEM)
    player.global_position = ordinary_player_position
    sight_wall.position = sight_wall_centre + sight_wall_clear_offset
    vampire_pivot.rotation.y = atan2(
        current_sight_direction.x,
        current_sight_direction.z
    )
    vampire.process_mode = vampire_process_mode
    await physics_frame
    senses.call("set_wall_grid_map", null)
    var visual_headlamp := vampire.get_node(
        "Pivot/VampireHeadlampLight"
    ) as SpotLight3D
    var vampire_look_component: Node = vampire.get_node("VampireLook")
    vampire_look_component.look_in_world_direction(vampire_pivot.global_basis.z)
    vampire_look_component.update_look(1.0)
    var visibility_cone_forward := vampire_look_component.get_look_direction() as Vector3
    visibility_cone_forward.y = 0.0
    visibility_cone_forward = visibility_cone_forward.normalized()
    var visibility_cone_test_direction := visibility_cone_forward.rotated(
        Vector3.UP,
        deg_to_rad(60.0)
    )
    var authored_field_of_view := float(
        settings.get("sight_field_of_view_degrees")
    )
    var authored_headlamp_angle := visual_headlamp.spot_angle
    settings.set("sight_field_of_view_degrees", 90.0)
    visual_headlamp.spot_angle = 179.0
    player.global_position = vampire.global_position \
        + visibility_cone_test_direction * 1.25
    await physics_frame
    var narrow_gameplay_cone_excludes_player := not bool(
        senses.call("can_see_player")
    )
    settings.set("sight_field_of_view_degrees", 150.0)
    visual_headlamp.spot_angle = 1.0
    await physics_frame
    var wide_gameplay_cone_includes_player := bool(senses.call("can_see_player"))
    var behind_vampire_direction := -vampire_pivot.global_basis.z.normalized()
    player.global_position = vampire.global_position + behind_vampire_direction * 1.25
    await physics_frame
    var visibility_cone_rejects_player_behind := not bool(
        senses.call("can_see_player")
    )
    settings.set("sight_field_of_view_degrees", authored_field_of_view)
    visual_headlamp.spot_angle = authored_headlamp_angle
    var configured_sight_distance := float(settings.get("sight_distance"))
    player.global_position = vampire.global_position \
        + visibility_cone_forward * configured_sight_distance
    await physics_frame
    var sees_player_at_configured_distance := bool(senses.call("can_see_player"))
    player.global_position = vampire.global_position \
        + visibility_cone_forward * (configured_sight_distance + 0.5)
    await physics_frame
    var cannot_see_player_beyond_configured_distance := not bool(
        senses.call("can_see_player")
    )
    vampire_look_component.return_to_travel_direction()
    player.global_position = ordinary_player_position
    vampire_pivot.rotation.y = atan2(
        current_sight_direction.x,
        current_sight_direction.z
    )
    senses.call("set_wall_grid_map", grid_map)
    await physics_frame
    var sight_samples_before := int(senses.call("get_visibility_sample_count"))
    await physics_frame
    await physics_frame
    var sight_samples_continuously := senses.is_physics_processing() \
        and int(senses.call("get_visibility_sample_count")) \
            >= sight_samples_before + 2
    var corner_cell_centre := grid_map.to_global(
        grid_map.map_to_local(Vector3i(1, 0, 1))
    )
    var corner_player_target := corner_cell_centre + Vector3(-0.2, 0.0, 0.32)
    navigation.call("select_target", corner_player_target)
    var corner_route := navigation.get_route_points() as Array[Vector3]
    var corner_target_is_within_contact_reach := not corner_route.is_empty() \
        and Vector2(
            corner_route.back().x - corner_player_target.x,
            corner_route.back().z - corner_player_target.z
        ).length() <= float(settings.get("visible_route_contact_distance"))
    var wall_safe_target_tracks_open_lane := not corner_route.is_empty() \
        and is_equal_approx(corner_route.back().z, corner_player_target.z)

    vampire.finish_search()
    grid_map.set_cell_item(Vector3i(2, 0, 1), 0)
    await physics_frame
    var pickup := GOLD_COIN_SCENE.instantiate() as RigidBody3D
    level_controller.add_child(pickup)
    pickup.global_position = player.global_position
    pickup.set("can_be_collected", true)
    vampire.hear_noise(gate.global_position)
    var targets_before_pickup := selected_targets.size()
    var collected := bool(pickup.call("_try_collect", player))
    var pickup_route := navigation.get_route_points() as Array[Vector3]
    var pickup_has_active_player_route: bool = vampire.get_vampire_state() \
        == GDVampire.VampireState.Hunting \
        and bool(navigation.get("has_target")) \
        and not pickup_route.is_empty() \
        and (navigation.get("target_position") as Vector3).is_equal_approx(
            player.global_position
        )
    var deposit := coffin.get_node("TreasureDeposit") as GDTreasureDeposit
    var targets_before_deposit := selected_targets.size()
    deposit._absorb_treasure(GOLD_COIN_ITEM.treasure_value, GOLD_COIN_ITEM)
    var route_rebuilds_after_first_deposit := int(
        navigation.call("get_route_rebuild_count")
    )
    for _additional_coin in 19:
        deposit._absorb_treasure(GOLD_COIN_ITEM.treasure_value, GOLD_COIN_ITEM)
    vampire.hear_noise(deposit.global_position + Vector3(0.25, 0.0, 0.25))
    var repeated_deposits_reuse_route: bool = selected_targets.size() \
        == targets_before_deposit + 1 \
        and int(navigation.call("get_route_rebuild_count")) \
            == route_rebuilds_after_first_deposit

    var victim := TestVampireVictim.new()
    root.add_child(victim)
    var contact := vampire.get_node("VampireContact")
    var contact_collision_shape := contact.get_node("CollisionShape3D") as CollisionShape3D
    var contact_capsule := contact_collision_shape.shape as CapsuleShape3D
    var contact_matches_doubled_model := contact_capsule != null \
        and is_equal_approx(
            contact_capsule.radius,
            float(settings.get("instant_kill_contact_radius"))
        ) \
        and contact_capsule.radius > 0.52
    victim.global_position = vampire.global_position
    contact._on_body_entered(victim)

    var character := vampire.get_node("Pivot/Character") as Node3D
    var headlamp := vampire.get_node("Pivot/VampireHeadlampLight") as SpotLight3D
    var fill_light := vampire.get_node("Pivot/VampireLight") as OmniLight3D
    var debug_state_label := debug_hud.get_node("Screen/StateLabel") as Label
    var passed := _expect(
        starts_hunting_entrance,
        "vampire immediately hunts the player's level entrance"
    ) and _expect(
        settings != null and is_equal_approx(float(settings.get("model_scale")), 2.0) \
            and character.scale.is_equal_approx(Vector3.ONE * 2.0),
        "vampire model is authored at double scale"
    ) and _expect(
        float(settings.get("max_speed")) > 0.0 \
            and navigation.get("settings") == settings,
        "vampire navigation uses its positive editor-configured maximum speed"
    ) and _expect(
        noise_search_is_replay_stable and search_candidates_are_stably_ordered,
        "vampire search decisions use replay-stable seeds, candidates, and physics ordering"
    ) and _expect(
        routes_around_wall,
        "vampire routes around maze walls to its selected noise target"
    ) and _expect(
        placed_coffin_blocks_only_player \
            and coffin_stride_lifts_model \
            and coffin_stride_returns_to_floor,
        "editor-placed coffins block the player while the larger vampire strides over them"
    ) and _expect(
        wall_adjacent_target_uses_player_side,
        "wall-adjacent sightings resolve to the player's side instead of fixed neighbour order"
    ) and _expect(
        active_route_keeps_safe_cell_steps,
        "vampire active routes retain safe cell-by-cell turns instead of cutting wall corners"
    ) and _expect(
        follows_tile_route_without_lateral_drift,
        "vampire movement stays aligned with its next safe tile waypoint"
    ) and _expect(
        pursues_closer_visible_player,
        "vampire only leaves its tile route when the visible player is closer than its waypoint"
    ) and _expect(
        blocked_direct_shortcut_recovers_immediately,
        "a colliding direct shortcut immediately returns to the safe tile route"
    ) and _expect(
        completed_tile_route_keeps_chasing_visible_player,
        "vampire keeps moving toward a body-clear player after exhausting its tile waypoints"
    ) and _expect(
        recovers_after_wall_stall and recovers_after_collisionless_stall,
        "vampire rebuilds a detailed route after any sustained movement stall"
    ) and _expect(
        corner_target_is_within_contact_reach,
        "vampire final chase waypoint reaches a player pressed into a reachable corner"
    ) and _expect(
        wall_safe_target_tracks_open_lane,
        "vampire final chase waypoint follows a wall-side player along the open lane"
    ) and _expect(
        headlamp.light_color.b > headlamp.light_color.r \
            and fill_light.light_color.b > fill_light.light_color.r \
            and is_equal_approx(headlamp.spot_range, 60.0),
        "vampire carries a purple version of the player's headlamp"
    ) and _expect(
        contact_matches_doubled_model,
        "vampire instant-kill contact covers its doubled visible body"
    ) and _expect(victim.killed, "touching the vampire kills the player immediately")
    var pickup_passed := _expect(
        collected \
            and pickup_has_active_player_route \
            and targets_before_deposit == targets_before_pickup + 1 \
            and selected_targets[targets_before_pickup] == player.global_position,
        "successful player pickups retarget the Vampire Maze boss"
    )
    var landmark_sound_uses_event_evidence := pickup_passed \
        and int(hunt.call("get_awareness_source")) \
            == GDVampireHunt.AwarenessSource.Noise
    var deposit_passed := _expect(
        selected_targets.size() == targets_before_deposit + 1 \
            and selected_targets[targets_before_deposit] == deposit.global_position \
            and repeated_deposits_reuse_route,
        "multi-item coffin deposits reuse one nearby Vampire route without stuttering"
    )
    var targets_before_footstep := selected_targets.size()
    var movement := player.get_node("PlayerMovement")
    movement.call("_play_footstep", GDPlayerMovement.SPEED)
    var footstep_passed := _expect(
        selected_targets.size() == targets_before_footstep,
        "player footsteps do not alert the Vampire Maze boss"
    )
    var targets_before_bats := selected_targets.size()
    level_controller.call("_on_bat_noise", player.global_position)
    var bat_noise_passed := _expect(
        selected_targets.size() == targets_before_bats + 1 \
            and selected_targets[targets_before_bats] == player.global_position,
        "disturbed bats retarget the Vampire Maze boss to the player's position"
    )
    var ordinary_sound_uses_only_event_position := bat_noise_passed \
        and int(hunt.call("get_awareness_source")) \
            == GDVampireHunt.AwarenessSource.Noise

    grid_map.set_cell_item(Vector3i(2, 0, 1), GridMap.INVALID_CELL_ITEM)
    sight_wall.position = sight_wall_centre + sight_wall_clear_offset
    await physics_frame
    hunt.update_hunt(0.016)
    var ruthlessly_chases_visible_player: bool = vampire.get_vampire_state() \
        == GDVampire.VampireState.ChasingPlayer \
        and bool(hunt.call("is_player_visible")) \
        and int(hunt.call("get_awareness_source")) \
            == GDVampireHunt.AwarenessSource.Sight
    debug_hud.call("_process", 0.0)
    var debug_reports_visible_chase: bool = debug_state_label.text.contains("ChasingPlayer") \
        and debug_state_label.text.contains("LOS: YES")
    var visible_chase_route := navigation.get_route_points() as Array[Vector3]
    var visible_chase_target := navigation.get("target_position") as Vector3
    var visible_chase_uses_navigation: bool = bool(navigation.get("has_target")) \
        and not visible_chase_route.is_empty() \
        and Vector2(visible_chase_target.x, visible_chase_target.z).is_equal_approx(
            Vector2(player.global_position.x, player.global_position.z)
        )
    var targets_before_visible_noise := selected_targets.size()
    vampire.hear_noise(gate.global_position)
    var search_started_during_sight := bool(hunt.call("begin_search"))
    var priority_target := navigation.get("target_position") as Vector3
    var visible_player_overrides_other_modes: bool = not search_started_during_sight \
        and selected_targets.size() == targets_before_visible_noise \
        and vampire.get_vampire_state() == GDVampire.VampireState.ChasingPlayer \
        and Vector2(priority_target.x, priority_target.z).is_equal_approx(
            Vector2(player.global_position.x, player.global_position.z)
        )
    var visible_player_position_before_brief_loss := player.global_position
    player.global_position = vampire.global_position + Vector3(
        float(settings.get("sight_distance")) + 1.0,
        0.0,
        0.0
    )
    await physics_frame
    var targets_before_brief_loss_noise := selected_targets.size()
    vampire.hear_noise(gate.global_position)
    var brief_loss_target := navigation.get("target_position") as Vector3
    var sound_does_not_interrupt_confirmed_chase: bool = \
        not bool(senses.call("can_see_player")) \
        and selected_targets.size() == targets_before_brief_loss_noise \
        and vampire.get_vampire_state() == GDVampire.VampireState.ChasingPlayer \
        and brief_loss_target.is_equal_approx(priority_target) \
        and bool(hunt.get("player_was_visible")) \
        and not bool(hunt.get("noise_target_active")) \
        and not bool(hunt.get("has_noise_position")) \
        and int(hunt.call("get_awareness_source")) \
            == GDVampireHunt.AwarenessSource.Sight
    player.global_position = visible_player_position_before_brief_loss
    await physics_frame
    hunt.update_hunt(0.0)
    var sight_memory_survives_chase_refresh: bool = \
        not bool(hunt.get("noise_target_active")) \
        and not bool(hunt.get("has_noise_position")) \
        and int(hunt.call("get_awareness_source")) \
            == GDVampireHunt.AwarenessSource.Sight
    vampire.begin_junction_scan()
    hunt.set("junction_scan_active", true)
    var targets_before_visible_scan_repair := selected_targets.size()
    hunt.update_hunt(0.0)
    var visible_sight_cancels_junction_scan: bool = vampire.get_vampire_state() \
        == GDVampire.VampireState.ChasingPlayer \
        and not bool(hunt.get("junction_scan_active")) \
        and bool(navigation.get("has_target")) \
        and selected_targets.size() == targets_before_visible_scan_repair + 1
    player.global_position = target_position + Vector3(0.0, 0.0, 2.0)
    navigation.set("has_target", false)
    hunt.set("last_chase_target", player.global_position)
    var targets_before_completed_visible_route := selected_targets.size()
    hunt.call("_update_visible_chase", player.global_position)
    var completed_visible_route_retries: bool = selected_targets.size() \
        == targets_before_completed_visible_route + 1 \
        and bool(navigation.get("has_target")) \
        and vampire.get_vampire_state() == GDVampire.VampireState.ChasingPlayer \
        and (navigation.get("target_position") as Vector3).is_equal_approx(
            player.global_position
        )
    var straight_corridor_vampire_position := grid_map.to_global(
        grid_map.map_to_local(Vector3i(1, 0, 3))
    )
    straight_corridor_vampire_position.y = vampire.global_position.y
    var straight_corridor_player_position := grid_map.to_global(
        grid_map.map_to_local(Vector3i(3, 0, 3))
    )
    straight_corridor_player_position.y = straight_corridor_vampire_position.y
    vampire_process_mode = vampire.process_mode
    vampire.process_mode = Node.PROCESS_MODE_DISABLED
    vampire.global_position = straight_corridor_vampire_position
    player.global_position = straight_corridor_player_position
    sight_wall.position = sight_wall_centre + sight_wall_clear_offset
    await physics_frame
    vampire.process_mode = vampire_process_mode
    var visible_chase_state_stays_stable := true
    for _completed_corridor_route in 3:
        navigation.set("has_target", false)
        hunt.update_hunt(0.016)
        if vampire.get_vampire_state() != GDVampire.VampireState.ChasingPlayer \
                or not bool(hunt.call("is_player_visible")) \
                or bool(hunt.get("junction_scan_active")) \
                or not bool(navigation.get("has_target")):
            visible_chase_state_stays_stable = false
            break
    var junction_position := grid_map.to_global(grid_map.map_to_local(Vector3i(2, 0, 3)))
    var stale_left_target := grid_map.to_global(grid_map.map_to_local(Vector3i(1, 0, 3)))
    var visible_right_target := grid_map.to_global(grid_map.map_to_local(Vector3i(3, 0, 3)))
    vampire.global_position = junction_position
    vampire.chase_visible_player(stale_left_target, stale_left_target, false)
    hunt.set("has_chase_target", true)
    hunt.set("last_chase_target", stale_left_target)
    player.global_position = visible_right_target
    var targets_before_visible_branch_change := selected_targets.size()
    hunt.call("_update_visible_chase", player.global_position)
    var visible_branch_change_repaths_immediately: bool = selected_targets.size() \
        == targets_before_visible_branch_change + 1 \
        and (navigation.get("target_position") as Vector3).is_equal_approx(
            visible_right_target
        )
    var straight_chase_start := grid_map.to_global(
        grid_map.map_to_local(Vector3i(1, 0, 3))
    )
    var straight_chase_first_target := grid_map.to_global(
        grid_map.map_to_local(Vector3i(2, 0, 3))
    )
    vampire.global_position = straight_chase_start
    player.global_position = straight_chase_first_target
    hunt.set("has_chase_target", false)
    hunt.call("_update_visible_chase", player.global_position)
    navigation.call("update_velocity", 0.016)
    var initial_straight_route := navigation.get_route_points() as Array[Vector3]
    var straight_route_omits_current_cell := initial_straight_route.size() == 1 \
        and initial_straight_route[0].distance_to(straight_chase_start) > 0.5
    var rebuilds_before_route_refresh := int(navigation.call("get_route_rebuild_count"))
    var shifted_same_cell_target := straight_chase_first_target + Vector3(0.0, 0.0, 0.2)
    player.global_position = shifted_same_cell_target
    navigation.call("update_visible_player_position", player.global_position, false)
    hunt.call("_update_visible_chase", player.global_position)
    var same_cell_target_moves_without_rebuild := int(
        navigation.call("get_route_rebuild_count")
    ) == rebuilds_before_route_refresh \
        and (navigation.get_route_points() as Array[Vector3])[-1].is_equal_approx(
            shifted_same_cell_target
        )
    var straight_chase_second_target := grid_map.to_global(
        grid_map.map_to_local(Vector3i(3, 0, 3))
    ) + Vector3(0.0, 0.0, 0.2)
    var route_size_before_extension := (
        navigation.get_route_points() as Array[Vector3]
    ).size()
    player.global_position = straight_chase_second_target
    navigation.call("update_visible_player_position", player.global_position, false)
    hunt.call("_update_visible_chase", player.global_position)
    var straight_route_extends_without_rebuild := int(
        navigation.call("get_route_rebuild_count")
    ) == rebuilds_before_route_refresh \
        and (navigation.get_route_points() as Array[Vector3]).size() \
            == route_size_before_extension + 1 \
        and (navigation.get("target_position") as Vector3).is_equal_approx(
            straight_chase_second_target
        )
    var stopped_player_position := grid_map.to_global(grid_map.map_to_local(Vector3i(1, 0, 2)))
    var visible_velocity := Vector3.RIGHT * float(settings.get("assumed_player_max_speed"))
    vampire.global_position = grid_map.to_global(grid_map.map_to_local(Vector3i(1, 0, 3)))
    player.global_position = stopped_player_position
    hunt.set("last_seen_player_velocity", visible_velocity)
    hunt.set("has_chase_target", false)
    var stale_visible_intercept := navigation.predict_reachable_target(
        stopped_player_position,
        visible_velocity,
        0.75,
        4.0,
        float(settings.get("last_seen_prediction_alignment")),
        true
    ) as Vector3
    vampire.chase_visible_player(
        stale_visible_intercept,
        stopped_player_position,
        false
    )
    hunt.set("has_chase_target", true)
    hunt.set("last_chase_observed_player_position", stopped_player_position)
    var stale_endpoint_misses_contact := not bool(
        navigation.call(
            "is_route_endpoint_within_distance",
            stopped_player_position,
            float(settings.get("visible_route_contact_distance"))
        )
    )
    var targets_before_contact_repath := selected_targets.size()
    hunt.call(
        "_update_visible_chase",
        player.global_position
    )
    var visible_chase_does_not_overshoot_stopped_player: bool = \
        stale_endpoint_misses_contact \
        and selected_targets.size() == targets_before_contact_repath + 1 \
        and (navigation.get("target_position") as Vector3).is_equal_approx(
            stopped_player_position
        )
    var prediction_origin := grid_map.to_global(
        grid_map.map_to_local(Vector3i(1, 0, 2))
    )
    var confirmed_velocity := Vector3.RIGHT * float(settings.get("assumed_player_max_speed"))
    hunt.set("last_confirmed_player_position", prediction_origin)
    hunt.set("previous_visible_player_position", prediction_origin)
    hunt.set("last_seen_player_velocity", confirmed_velocity)
    hunt.set("has_visible_observation", true)
    var expected_predicted_target := navigation.predict_reachable_target(
        prediction_origin,
        confirmed_velocity,
        float(settings.get("last_seen_prediction_seconds")),
        float(settings.get("last_seen_prediction_max_distance")),
        float(settings.get("last_seen_prediction_alignment"))
    ) as Vector3
    sight_wall.position = (
        vampire.position + player.position
    ) * 0.5 + Vector3.UP * 0.8
    await physics_frame
    expected_predicted_target = navigation.predict_reachable_target(
        prediction_origin,
        confirmed_velocity,
        float(settings.get("last_seen_prediction_seconds")),
        float(settings.get("last_seen_prediction_max_distance")),
        float(settings.get("last_seen_prediction_alignment")),
        false,
        Callable(hunt, &"_is_possible_player_position_ruled_out")
    ) as Vector3
    var predicted_target_is_not_visibly_empty := not bool(hunt.call(
        "_is_possible_player_position_ruled_out",
        expected_predicted_target
    ))
    var sight_loss_grace := float(settings.get("sight_loss_grace_seconds"))
    hunt.update_hunt(sight_loss_grace * 0.5)
    var brief_sight_loss_keeps_chasing: bool = vampire.get_vampire_state() \
        == GDVampire.VampireState.ChasingPlayer \
        and not bool(hunt.call("is_player_visible"))
    hunt.update_hunt(sight_loss_grace * 0.5 + 0.001)
    var pursues_last_seen_after_losing_player: bool = vampire.get_vampire_state() \
        == GDVampire.VampireState.PursuingLastSeen \
        and (navigation.get("target_position") as Vector3).is_equal_approx(
            expected_predicted_target
        )
    debug_hud.call("_process", 0.0)
    var debug_reports_last_seen_pursuit: bool = debug_state_label.text.contains(
        "PursuingLastSeen"
    ) and debug_state_label.text.contains("LOS: NO") \
        and debug_state_label.text.contains("Target: Last Seen")
    var vampire_position_before_prediction_completion := vampire.global_position
    vampire.global_position = grid_map.to_global(
        grid_map.map_to_local(Vector3i(2, 0, 2))
    )
    senses.set("player", null)
    sight_wall.position = (
        vampire.position + player.position
    ) * 0.5 + Vector3.UP * 0.8
    await physics_frame
    hunt.set("player_was_visible", false)
    hunt.set("player_is_visible", false)
    navigation.set("last_completed_route_direction", confirmed_velocity.normalized())
    navigation.set("has_target", false)
    hunt.update_hunt(0.0)
    var scans_after_last_seen_position: bool = vampire.get_vampire_state() \
        == GDVampire.VampireState.ScanningJunction \
        and vampire.velocity.is_zero_approx()
    var scan_direction_count := maxi(
        (hunt.get("junction_scan_directions") as Array[Vector3]).size(),
        1
    )
    var scan_duration := float(settings.get("junction_scan_seconds_per_direction")) \
        * scan_direction_count + 0.001
    var uncertainty_expansion_duration := float(
        settings.get("prediction_followup_distance")
    ) / maxf(float(settings.get("assumed_player_max_speed")), 0.001) + 0.001
    hunt.update_hunt(maxf(scan_duration, uncertainty_expansion_duration))
    var followup_distance := float(hunt.call("get_last_seen_uncertainty_radius"))
    var followup_prediction_origin := vampire.global_position
    var expected_followup_target := navigation.predict_reachable_target(
        followup_prediction_origin,
        confirmed_velocity,
        followup_distance / confirmed_velocity.length(),
        followup_distance,
        float(settings.get("last_seen_prediction_alignment")),
        false,
        Callable(hunt, &"_is_possible_player_position_ruled_out")
    ) as Vector3
    var last_seen_uncertainty_expands_during_pursuit: bool = followup_distance \
        > float(settings.get("prediction_followup_distance"))
    var followup_target := navigation.get("target_position") as Vector3
    var followup_target_is_not_visibly_empty := not bool(hunt.call(
        "_is_possible_player_position_ruled_out",
        followup_target
    ))
    var followup_plan := int(hunt.get("active_search_plan"))
    var has_followup_target := bool(navigation.get("has_target"))
    var search_after_junction_scan_respects_visibility: bool = \
        not has_followup_target \
        or (
            vampire.get_vampire_state() == GDVampire.VampireState.SearchingRoute \
            and followup_target_is_not_visibly_empty \
            and (
            (
                followup_plan == GDVampireHunt.SearchPlan.LastSeenDirection \
                and followup_target.is_equal_approx(expected_followup_target)
            ) \
            or followup_plan == GDVampireHunt.SearchPlan.StrategicRoute
            )
        )
    if not scans_after_last_seen_position:
        vampire.begin_junction_scan()
    debug_hud.call("_process", 0.0)
    var debug_reports_junction_scan: bool = debug_state_label.text.contains(
        "ScanningJunction"
    ) and debug_state_label.text.contains("Target: Junction Scan")
    vampire.global_position = vampire_position_before_prediction_completion

    var preceding_noise_position := grid_map.to_global(
        grid_map.map_to_local(Vector3i(1, 0, 1))
    )
    var branch_noise_position := grid_map.to_global(
        grid_map.map_to_local(Vector3i(2, 0, 1))
    )
    var known_key_position := grid_map.to_global(
        grid_map.map_to_local(Vector3i(3, 0, 1))
    )
    var known_layout_landmarks: Array[Dictionary] = [
        {
            "id": &"known_branch_treasure",
            "kind": &"treasure_pile",
            "position": branch_noise_position,
        },
        {
            "id": &"known_branch_key",
            "kind": &"silver_key",
            "position": known_key_position,
        },
    ]
    vampire.configure_layout_knowledge(known_layout_landmarks)
    hunt.set("has_noise_position", false)
    hunt.set("noise_path_direction_hint", Vector3.ZERO)
    hunt.call("refresh_noise_origin", preceding_noise_position)
    var single_noise_uses_last_spotted_direction: bool = (
        hunt.get("noise_path_direction_hint") as Vector3
    ).dot(confirmed_velocity.normalized()) > 0.9
    hunt.set("noise_elapsed_seconds", 1.0)
    var one_second_noise_radius := float(hunt.call("get_noise_uncertainty_radius"))
    hunt.set("noise_elapsed_seconds", 5.0)
    var five_second_noise_radius := float(hunt.call("get_noise_uncertainty_radius"))
    var noise_uncertainty_radius_grows_over_time := is_equal_approx(
        one_second_noise_radius,
        float(settings.get("assumed_player_max_speed"))
    ) and is_equal_approx(
        five_second_noise_radius,
        float(settings.get("assumed_player_max_speed")) * 5.0
    ) and five_second_noise_radius > one_second_noise_radius
    hunt.call("refresh_noise_origin", preceding_noise_position)
    navigation.call("select_target", gate.global_position)
    vampire.hear_landmark_noise(branch_noise_position)
    var consecutive_sounds_infer_path_direction: bool = (
        hunt.get("noise_path_direction_hint") as Vector3
    ).dot(Vector3.RIGHT) > 0.9
    player.global_position += Vector3(0.23, 0.0, 0.37)
    sight_wall.position = (
        vampire.position + player.position
    ) * 0.5 + Vector3.UP * 0.8
    await physics_frame
    hunt.update_hunt(2.5)
    navigation.set("has_target", false)
    hunt.update_hunt(0.0)
    var noise_search_uses_layout_without_cheating: bool = vampire.get_vampire_state() \
        == GDVampire.VampireState.SearchingRoute \
        and bool(navigation.get("has_target")) \
        and (navigation.get("target_position") as Vector3).is_equal_approx(
            known_key_position
        ) \
        and not (navigation.get("target_position") as Vector3).is_equal_approx(
            player.global_position
        )

    var dead_end_grid_map := GridMap.new()
    dead_end_grid_map.mesh_library = mesh_library
    for x_coordinate in 9:
        for z_coordinate in 7:
            dead_end_grid_map.set_cell_item(Vector3i(x_coordinate, 0, z_coordinate), 0)
    var dead_end_origin_cell := Vector3i(4, 0, 3)
    var dead_end_walkable_cells: Array[Vector3i] = [
        dead_end_origin_cell,
        Vector3i(5, 0, 3),
        Vector3i(6, 0, 3),
        Vector3i(3, 0, 3),
        Vector3i(2, 0, 3),
        Vector3i(1, 0, 3),
        Vector3i(1, 0, 2),
        Vector3i(1, 0, 1),
        Vector3i(2, 0, 1),
        Vector3i(3, 0, 1),
        Vector3i(4, 0, 1),
        Vector3i(5, 0, 1),
        Vector3i(6, 0, 1),
    ]
    for walkable_cell in dead_end_walkable_cells:
        dead_end_grid_map.set_cell_item(walkable_cell, GridMap.INVALID_CELL_ITEM)
    level_controller.add_child(dead_end_grid_map)
    var dead_end_navigation := GDVampireNavigation.new()
    level_controller.add_child(dead_end_navigation)
    dead_end_navigation.configure(
        wall_side_search_body,
        vampire.get_node("Pivot") as Node3D,
        settings
    )
    dead_end_navigation.set_wall_grid_map(dead_end_grid_map)
    var dead_end_origin := dead_end_grid_map.to_global(
        dead_end_grid_map.map_to_local(dead_end_origin_cell)
    )
    var dead_end_search_points := dead_end_navigation.get_reachable_search_points(
        dead_end_origin,
        10.0,
        float(settings.get("noise_search_minimum_distance_fraction")),
        Vector3.RIGHT,
        float(settings.get("noise_path_hint_minimum_alignment"))
    ) as Array[Vector3]
    var short_dead_end_is_investigated := not dead_end_search_points.is_empty() \
        and dead_end_navigation.get_last_search_direction_match() \
            == GDVampireNavigation.SearchDirectionMatch.Forward
    for dead_end_search_point in dead_end_search_points:
        if dead_end_search_point.x <= dead_end_origin.x:
            short_dead_end_is_investigated = false
            break
    var sub_tile_uncertainty_points := dead_end_navigation.get_reachable_search_points(
        dead_end_origin,
        dead_end_grid_map.cell_size.x * 0.5,
        0.0,
        Vector3.RIGHT,
        float(settings.get("noise_path_hint_minimum_alignment"))
    ) as Array[Vector3]
    var uncertainty_radius_never_selects_an_unreachable_tile := (
        sub_tile_uncertainty_points.is_empty()
    )
    var dead_end_tip := dead_end_grid_map.to_global(
        dead_end_grid_map.map_to_local(Vector3i(6, 0, 3))
    )
    wall_side_search_body.global_position = dead_end_tip
    wall_side_search_body.selected_search_target = Vector3.ZERO
    var dead_end_hunt := GDVampireHunt.new()
    level_controller.add_child(dead_end_hunt)
    dead_end_hunt.set("body", wall_side_search_body)
    dead_end_hunt.set("navigation", dead_end_navigation)
    dead_end_hunt.set("settings", settings)
    dead_end_hunt.set(
        "prediction_search_direction",
        Vector3.RIGHT * float(settings.get("assumed_player_max_speed"))
    )
    dead_end_hunt.set(
        "last_seen_player_velocity",
        Vector3.RIGHT * float(settings.get("assumed_player_max_speed"))
    )
    dead_end_hunt.set("has_visible_observation", true)
    dead_end_hunt.set("last_confirmed_player_position", dead_end_origin)
    dead_end_hunt.set("prediction_followup_searches_remaining", 1)
    var continues_search_from_dead_end := bool(
        dead_end_hunt.call("begin_last_seen_direction_search")
    )
    var dead_end_followup_target := wall_side_search_body.selected_search_target
    var dead_end_departure_direction := dead_end_navigation.get_path_departure_direction(
        dead_end_tip,
        dead_end_followup_target
    ) as Vector3
    var exhausted_dead_end_is_not_reselected: bool = continues_search_from_dead_end \
        and not dead_end_followup_target.is_equal_approx(dead_end_tip) \
        and dead_end_departure_direction.dot(Vector3.LEFT) > 0.9

    senses.set("player", null)
    vampire.configure_layout_knowledge([] as Array[Dictionary])
    vampire.hear_noise(gate.global_position)
    var hidden_route_target := navigation.get("target_position") as Vector3
    var hidden_player_position := hidden_route_target + Vector3(0.37, 0.0, 1.41)
    player.global_position = hidden_player_position
    var targets_before_hidden_timeout := selected_targets.size()
    var grounded_vampire_height := vampire.global_position.y
    hunt.update_hunt(300.0)
    var hidden_player_is_never_revealed_by_timeout: bool = vampire.get_node_or_null(
        "VampireAerialScan"
    ) == null and is_equal_approx(vampire.global_position.y, grounded_vampire_height) \
        and selected_targets.size() == targets_before_hidden_timeout \
        and (navigation.get("target_position") as Vector3).is_equal_approx(
            hidden_route_target
        ) \
        and not (navigation.get("target_position") as Vector3).is_equal_approx(
            hidden_player_position
        ) \
        and int(hunt.call("get_awareness_source")) \
            == GDVampireHunt.AwarenessSource.Noise

    var strategic_search_started := bool(hunt.call("begin_search"))
    var strategic_target := navigation.get("target_position") as Vector3
    var strategic_search_avoids_visible_empty_tiles: bool = strategic_search_started \
        and vampire.get_vampire_state() == GDVampire.VampireState.SearchingRoute \
        and not bool(hunt.call(
            "_is_possible_player_position_ruled_out",
            strategic_target
        )) \
        and not strategic_target.is_equal_approx(hidden_player_position)

    var noise_interrupt_position := preceding_noise_position
    vampire.hear_noise(noise_interrupt_position)
    var sound_becomes_route_without_revealing_player: bool = vampire.get_vampire_state() \
        == GDVampire.VampireState.Hunting \
        and (navigation.get("target_position") as Vector3).is_equal_approx(
            noise_interrupt_position
        ) \
        and not (navigation.get("target_position") as Vector3).is_equal_approx(
            hidden_player_position
        ) \
        and int(hunt.call("get_awareness_source")) \
            == GDVampireHunt.AwarenessSource.Noise

    var fog := vampire.get_node("VampireProximityFog")
    var fog_distance := float(settings.get("proximity_fog_distance"))
    var fog_full_distance := float(settings.get("proximity_fog_full_distance"))
    var disabled_victim := TestVampireVictim.new()
    root.add_child(disabled_victim)
    var enabled_visibility := vampire.visible
    var enabled_process_mode := vampire.process_mode
    var enabled_collision_layer := vampire.collision_layer
    var enabled_collision_mask := vampire.collision_mask
    var enabled_contact_monitoring := bool(contact.get("monitoring"))
    var enabled_contact_mask := int(contact.get("collision_mask"))
    var enabled_senses := bool(senses.get("enabled"))
    var targets_before_development_disable := selected_targets.size()
    vampire.set("disable_vampire_for_testing", true)
    vampire.hear_noise(player.global_position)
    contact._on_body_entered(disabled_victim)
    debug_hud.call("_process", 0.0)
    var development_toggle_disables_vampire: bool = bool(
        vampire.call("is_disabled_for_testing")
    ) and vampire.get_vampire_state() == GDVampire.VampireState.Disabled \
        and vampire.process_mode == Node.PROCESS_MODE_DISABLED \
        and not vampire.visible \
        and vampire.collision_layer == 0 \
        and vampire.collision_mask == 0 \
        and not bool(contact.get("monitoring")) \
        and int(contact.get("collision_mask")) == 0 \
        and not bool(senses.get("enabled")) \
        and bool(fog.call("is_suppressed")) \
        and not disabled_victim.killed \
        and selected_targets.size() == targets_before_development_disable \
        and debug_state_label.text.contains("Disabled")
    vampire.set("disable_vampire_for_testing", false)
    var development_toggle_restores_vampire: bool = not bool(
        vampire.call("is_disabled_for_testing")
    ) and vampire.get_vampire_state() == GDVampire.VampireState.Idle \
        and vampire.process_mode == enabled_process_mode \
        and vampire.visible == enabled_visibility \
        and vampire.collision_layer == enabled_collision_layer \
        and vampire.collision_mask == enabled_collision_mask \
        and bool(contact.get("monitoring")) == enabled_contact_monitoring \
        and int(contact.get("collision_mask")) == enabled_contact_mask \
        and bool(senses.get("enabled")) == enabled_senses \
        and not bool(fog.call("is_suppressed"))
    var fog_passed := _expect(
        is_zero_approx(float(fog.call("calculate_intensity", fog_distance + 1.0))) \
            and is_equal_approx(
                float(fog.call("calculate_intensity", fog_full_distance)),
                float(settings.get("proximity_fog_max_intensity"))
            ),
        "vampire proximity fog uses its configured distance and maximum purple intensity"
    )
    var senses_passed := _expect(
        is_equal_approx(senses.position.y, float(settings.get("sight_origin_height"))) \
            and senses.shape is SphereShape3D \
            and is_equal_approx(
                (senses.shape as SphereShape3D).radius,
                float(settings.get("sight_clearance_radius")) \
                    + float(settings.get("direct_path_clearance_margin"))
            ) \
            and senses.position.y < headlamp.position.y,
        "vampire sight cast is margin-expanded and authored low on the doubled model"
    ) and _expect(
        blocked_by_body_height_wall,
        "maze walls block the vampire's low floor-level sight cast"
    ) and _expect(
        blocked_by_grid_wall,
        "occupied maze wall tiles block sight even when their physics has a seam"
    ) and _expect(
        sees_past_body_width_wall_edge,
        "low sight acquires around a block edge without authorizing a direct body shortcut"
    ) and _expect(
        centre_ray_blocked_by_thin_wall,
        "thin sightline scenery blocks the vampire's centre sight ray"
    ) and _expect(
        body_samples_see_around_thin_wall,
        "vampire sees visible player body edges around thin sightline scenery"
    ) and _expect(
        offset_sight_still_respects_full_wall,
        "low sight remains occluded by a complete wall"
    ) and _expect(
        sees_clear_player and clear_sight_allows_direct_chase,
        "vampire's floor-level clearance cast permits a direct unobstructed chase"
    ) and _expect(
        clear_empty_tile_is_verified and visible_player_tile_is_not_empty,
        "vampire sight distinguishes an empty visible tile from the observed player tile"
    ) and _expect(
        sees_player_at_configured_distance \
            and cannot_see_player_beyond_configured_distance,
        "vampire sight reaches but does not exceed its configured range"
    ) and _expect(
        notices_player_passing_close,
        "vampire notices a nearby player even when wide sight brushes a wall edge"
    ) and _expect(
        sees_player_pressed_into_wall_cell,
        "coarse wall-cell occupancy cannot hide a physically visible wall-side player"
    ) and _expect(
        narrow_gameplay_cone_excludes_player \
            and wide_gameplay_cone_includes_player \
            and visibility_cone_rejects_player_behind,
        "vampire sight uses its gameplay FOV independently of the headlamp cone"
    ) and _expect(
        close_pass_is_chasing,
        "vampire immediately enters its chase state after reacquiring a nearby player"
    ) and _expect(
        close_pass_targets_player,
        "vampire immediately routes to the nearby player's confirmed position"
    ) and _expect(
        close_pass_retains_visible_position,
        "vampire navigation immediately retains the nearby visible player position"
    ) and _expect(
        sight_samples_continuously,
        "vampire sight samples continuously during every physics frame"
    ) and _expect(
        ruthlessly_chases_visible_player \
            and visible_chase_uses_navigation \
            and visible_player_overrides_other_modes \
            and sound_does_not_interrupt_confirmed_chase \
            and sight_memory_survives_chase_refresh,
        "confirmed sight overrides every other mode and routes directly after the player"
    ) and _expect(
        visible_sight_cancels_junction_scan,
        "confirmed sight immediately cancels an invalid junction-scan state"
    ) and _expect(
        completed_visible_route_retries,
        "vampire immediately refreshes a completed visible route to the confirmed player"
    ) and _expect(
        visible_chase_state_stays_stable,
        "vampire remains in one continuous chase state down a clear corridor"
    ) and _expect(
        straight_route_omits_current_cell \
            and same_cell_target_moves_without_rebuild \
            and straight_route_extends_without_rebuild,
        "visible straight-corridor pursuit advances without route rebuild stop-starts"
    ) and _expect(
        visible_branch_change_repaths_immediately,
        "visible players changing junction branches immediately replace the stale chase route"
    ) and _expect(
        visible_chase_does_not_overshoot_stopped_player,
        "visible chase immediately replaces a route that could miss a player beside a wall"
    ) and _expect(
        brief_sight_loss_keeps_chasing,
        "vampire tolerates brief corner occlusion without abandoning its chase route"
    ) and _expect(
        pursues_last_seen_after_losing_player \
            and predicted_target_is_not_visibly_empty,
        "vampire predicts a reachable non-visible pursuit target from last-seen movement"
    ) and _expect(
        search_after_junction_scan_respects_visibility \
            and last_seen_uncertainty_expands_during_pursuit,
        "vampire expands its hidden search and abandons positions current sight rules out"
    ) and _expect(
        exhausted_dead_end_is_not_reselected,
        "vampire continues from an exhausted dead end instead of returning to stale evidence"
    ) and _expect(
        single_noise_uses_last_spotted_direction,
        "a new noise search favours the player's last confirmed walking direction"
    ) and _expect(
        noise_uncertainty_radius_grows_over_time \
            and uncertainty_radius_never_selects_an_unreachable_tile,
        "noise uncertainty expands with elapsed travel time without exceeding its radius"
    ) and _expect(
        consecutive_sounds_infer_path_direction \
            and noise_search_uses_layout_without_cheating \
            and short_dead_end_is_investigated,
        "vampire combines sound direction with layout knowledge without cheating"
    ) and _expect(
        debug_state_label.visible \
            and debug_reports_visible_chase \
            and debug_reports_last_seen_pursuit \
            and debug_reports_junction_scan \
            and vampire.get_node_or_null("DebugStateLabel") == null,
        "Vampire HUD shows its current state and confirmed line of sight"
    ) and _expect(
        hidden_player_is_never_revealed_by_timeout,
        "elapsed time never reveals or targets a hidden player's live position"
    ) and _expect(
        starts_hunting_entrance \
            and landmark_sound_uses_event_evidence \
            and ordinary_sound_uses_only_event_position \
            and ruthlessly_chases_visible_player \
            and hidden_player_is_never_revealed_by_timeout,
        "entrance, ordinary sound, landmark sound, and direct sight obey explicit perception rules"
    ) and _expect(
        strategic_search_avoids_visible_empty_tiles,
        "without fresh evidence the vampire strategically searches only hidden positions"
    ) and _expect(
        sound_becomes_route_without_revealing_player,
        "an allowed noise becomes the route without consulting the hidden player"
    ) and _expect(
        development_toggle_disables_vampire and development_toggle_restores_vampire,
        "the editor development toggle completely disables and cleanly restores the vampire"
    )
    passed = pickup_passed \
        and deposit_passed \
        and footstep_passed \
        and bat_noise_passed \
        and fog_passed \
        and senses_passed \
        and passed

    victim.free()
    disabled_victim.free()
    level_controller.free()
    return passed


func _test_vampire_navigation_reports_scaled_search_contract() -> bool:
    var holder := Node3D.new()
    root.add_child(holder)
    var body := CharacterBody3D.new()
    holder.add_child(body)
    var body_collision := CollisionShape3D.new()
    body_collision.name = "CollisionShape3D"
    var body_shape := CapsuleShape3D.new()
    body_shape.radius = 0.3
    body_shape.height = 1.6
    body_collision.shape = body_shape
    body.add_child(body_collision)
    var pivot := Node3D.new()
    body.add_child(pivot)
    var navigation := GDVampireNavigation.new()
    holder.add_child(navigation)
    var settings := load(
        "res://enemies/vampire/vampire_settings.tres"
    ).duplicate(true) as Resource
    navigation.configure(body, pivot, settings)

    var no_grid_target_selected := navigation.select_target(Vector3.ONE)
    var no_grid_route := navigation.build_route_to(Vector3.ONE) as Array[Vector3]
    var no_grid_status_is_explicit: bool = no_grid_route.is_empty() \
        and not no_grid_target_selected \
        and not bool(navigation.get("has_target")) \
        and navigation.get_last_route_search_status() \
            == GDVampireNavigation.RouteSearchStatus.NoGridMap \
        and navigation.get_route_traversal_status() \
            == GDVampireNavigation.RouteTraversalStatus.Failed

    var wall_grid_map := GridMap.new()
    holder.add_child(wall_grid_map)
    wall_grid_map.cell_size = Vector3(2.0, 1.0, 3.0)
    wall_grid_map.scale = Vector3(2.0, 1.0, 0.5)
    var mesh_library := MeshLibrary.new()
    mesh_library.create_item(0)
    mesh_library.set_item_name(0, "Wall Test")
    mesh_library.create_item(1)
    mesh_library.set_item_name(1, "Decoration Test")
    wall_grid_map.mesh_library = mesh_library
    for coordinate in 7:
        wall_grid_map.set_cell_item(Vector3i(coordinate, 0, 0), 0)
        wall_grid_map.set_cell_item(Vector3i(coordinate, 0, 6), 0)
        wall_grid_map.set_cell_item(Vector3i(0, 0, coordinate), 0)
        wall_grid_map.set_cell_item(Vector3i(6, 0, coordinate), 0)
    wall_grid_map.set_cell_item(Vector3i(100, 0, 100), 1)
    navigation.set_wall_grid_map(wall_grid_map)

    var origin_cell := Vector3i(1, 0, 1)
    var target_cell := Vector3i(3, 0, 2)
    body.global_position = wall_grid_map.to_global(
        wall_grid_map.map_to_local(origin_cell)
    )
    var target_position := wall_grid_map.to_global(
        wall_grid_map.map_to_local(target_cell)
    )
    var complete_route := navigation.build_route_to(target_position) as Array[Vector3]
    var x_edge_length := wall_grid_map.to_global(
        wall_grid_map.map_to_local(origin_cell + Vector3i.RIGHT)
    ).distance_to(body.global_position)
    var z_edge_length := wall_grid_map.to_global(
        wall_grid_map.map_to_local(origin_cell + Vector3i.BACK)
    ).distance_to(body.global_position)
    var scaled_route_distance := navigation.get_path_distance(
        body.global_position,
        target_position
    )
    var explicit_scaled_grid_is_respected: bool = not complete_route.is_empty() \
        and navigation.get("grid_bounds") == Rect2i(0, 0, 7, 7) \
        and is_equal_approx(scaled_route_distance, x_edge_length * 2.0 + z_edge_length) \
        and is_equal_approx(float(navigation.call("_get_body_clearance_world")), 0.32)

    var projected_target_cell := Vector3i(3, 0, 3)
    wall_grid_map.set_cell_item(projected_target_cell, 0)
    body.global_position = wall_grid_map.to_global(
        wall_grid_map.map_to_local(Vector3i(5, 0, 3))
    )
    var projected_target := wall_grid_map.to_global(
        wall_grid_map.map_to_local(projected_target_cell) + Vector3(0.49, 0.0, 0.0)
    )
    navigation.select_visible_target(projected_target, projected_target, false)
    var projected_route := navigation.get_route_points()
    var projected_route_cell := wall_grid_map.local_to_map(
        wall_grid_map.to_local(projected_route.back())
    ) if not projected_route.is_empty() else Vector3i(-1, -1, -1)
    projected_route_cell.y = 0
    var projected_refresh_target := wall_grid_map.to_global(
        wall_grid_map.map_to_local(projected_route_cell) + Vector3(0.0, 0.0, 0.1)
    )
    var projected_endpoint_refreshes: bool = not projected_route.is_empty() \
        and projected_route_cell == Vector3i(4, 0, 3) \
        and navigation.refresh_visible_route_target(projected_refresh_target)

    body.global_position = wall_grid_map.to_global(
        wall_grid_map.map_to_local(origin_cell)
    )
    navigation.select_target(target_position)
    var successful_route_is_following := navigation.get_route_traversal_status() \
        == GDVampireNavigation.RouteTraversalStatus.Following
    var half_recovery_seconds := float(
        settings.get("wall_stall_recovery_seconds")
    ) * 0.5
    navigation.call(
        "_update_wall_stall_recovery",
        half_recovery_seconds,
        false,
        float(settings.get("wall_stall_minimum_progress_speed")) * 2.0,
        float(settings.get("max_speed"))
    )
    navigation.call(
        "_update_wall_stall_recovery",
        half_recovery_seconds,
        false,
        0.0,
        float(settings.get("max_speed"))
    )
    var useful_window_progress_avoids_recovery: bool = navigation \
        .get_wall_stall_recovery_count() == 0
    navigation.call(
        "_update_wall_stall_recovery",
        half_recovery_seconds,
        false,
        0.0,
        float(settings.get("max_speed"))
    )
    navigation.call(
        "_update_wall_stall_recovery",
        half_recovery_seconds,
        false,
        0.0,
        float(settings.get("max_speed"))
    )
    var sustained_window_stall_recovers: bool = navigation \
        .get_wall_stall_recovery_count() == 1

    settings.set("maximum_route_search_cells", 2)
    var budget_target := wall_grid_map.to_global(
        wall_grid_map.map_to_local(Vector3i(5, 0, 5))
    )
    var budget_route := navigation.build_route_to(budget_target) as Array[Vector3]
    navigation.get_reachable_search_points(body.global_position, 100.0, 0.0)
    var bounded_searches_report_truncation: bool = budget_route.is_empty() \
        and navigation.get_last_route_search_status() \
            == GDVampireNavigation.RouteSearchStatus.SearchBudgetExhausted \
        and navigation.was_last_frontier_search_truncated()

    settings.set("maximum_route_search_cells", 32768)
    var outside_target := wall_grid_map.to_global(
        wall_grid_map.map_to_local(Vector3i(100, 0, 100))
    )
    var clamped_route := navigation.build_route_to(outside_target) as Array[Vector3]
    navigation.set("last_movement_direction", Vector3.RIGHT)
    navigation.stop_immediately()
    var public_search_handles_partial_configuration := GDVampireNavigation.new()
    holder.add_child(public_search_handles_partial_configuration)
    public_search_handles_partial_configuration.set_wall_grid_map(wall_grid_map)
    var unconfigured_points := public_search_handles_partial_configuration \
        .get_reachable_search_points(body.global_position, 10.0, 0.0)
    var edge_cases_are_safe: bool = not clamped_route.is_empty() \
        and navigation.get_last_route_search_status() \
            == GDVampireNavigation.RouteSearchStatus.Complete \
        and (navigation.get("last_movement_direction") as Vector3).is_zero_approx() \
        and unconfigured_points.is_empty()

    navigation.set("route_points", [body.global_position] as Array[Vector3])
    navigation.set("route_index", 0)
    navigation.set("has_target", true)
    navigation.set(
        "route_traversal_status",
        GDVampireNavigation.RouteTraversalStatus.Following
    )
    navigation.call("_advance_reached_route_points")
    var completed_route_reports_arrival := not bool(navigation.get("has_target")) \
        and navigation.get_route_traversal_status() \
            == GDVampireNavigation.RouteTraversalStatus.Arrived

    var passed := _expect(
        no_grid_status_is_explicit \
            and explicit_scaled_grid_is_respected \
            and projected_endpoint_refreshes,
        "vampire navigation uses its explicit wall layer, physical body, and scaled cell edges"
    ) and _expect(
        useful_window_progress_avoids_recovery \
            and sustained_window_stall_recovers \
            and bounded_searches_report_truncation,
        "vampire navigation distinguishes route-budget exhaustion and truncated frontiers"
    ) and _expect(
        edge_cases_are_safe \
            and successful_route_is_following \
            and completed_route_reports_arrival,
        "vampire navigation separates route failure, active travel, arrival, and cancellation"
    )
    holder.free()
    return passed


func _test_vampire_maze_owns_its_development_view() -> bool:
    var vampire_maze_uid := ResourceLoader.get_resource_uid(
        "res://levels/vampire-maze/level.tscn"
    )
    var level_one_uid := ResourceLoader.get_resource_uid("res://levels/1/level.tscn")
    var level_scene := load("res://levels/vampire-maze/level.tscn") as PackedScene
    var level := level_scene.instantiate() as Node3D
    var vampire := level.get_node_or_null("Vampire") as CharacterBody3D
    var level_settings := level.get_node_or_null("LevelSettings") as GDLevelSettings
    var development_view := level.get_node_or_null("VampireDevelopmentView") as Node3D
    var debug_hud := level.get_node_or_null("VampireDebugHUD") as CanvasLayer
    var camera := level.get_node_or_null("VampireDevelopmentView/Camera3D") as Camera3D
    var route_overlay := level.get_node_or_null("MinimapRouteOverlay") as MultiMeshInstance3D
    var generated_maze := level.get_node_or_null("GeneratedMaze") as Node3D
    var wall_grid_map := level.get_node_or_null("GeneratedMaze/PNGGridMap") as GridMap
    var floor_grid_map := level.get_node_or_null("GeneratedMaze/PNGFloorGridMap") as GridMap
    var camera_profile := camera.get("camera_profile") as Resource if camera != null else null
    var maze_configuration := generated_maze.get("configuration") as Resource \
        if generated_maze != null else null
    var configured_width := int(maze_configuration.get("width")) \
        if maze_configuration != null else 0
    var configured_height := int(maze_configuration.get("height")) \
        if maze_configuration != null else 0
    var serialized_floor_cells := floor_grid_map.get_used_cells() \
        if floor_grid_map != null else []
    var serialized_wall_cells := wall_grid_map.get_used_cells() \
        if wall_grid_map != null else []
    var has_no_baked_cells := serialized_floor_cells.is_empty() \
        and serialized_wall_cells.is_empty()
    var has_current_baked_cells := serialized_floor_cells.size() \
        == configured_width * configured_height
    for wall_cell_value in serialized_wall_cells:
        var wall_cell := wall_cell_value as Vector3i
        if wall_cell.x < 0 or wall_cell.x >= configured_width \
                or wall_cell.z < 0 or wall_cell.z >= configured_height:
            has_current_baked_cells = false
            break
    root.add_child(level)
    var authored_player := level.get_node_or_null("Player") as Node3D
    var stale_character_position := Vector3(512.0, 32.0, 512.0)
    if authored_player != null:
        authored_player.global_position = stale_character_position
    if vampire != null:
        vampire.global_position = stale_character_position
    var regeneration_result := generated_maze.call("regenerate_maze") as Dictionary \
        if generated_maze != null else {}
    var regenerated_player_spawn := regeneration_result.get(
        "player_spawn",
        Transform3D.IDENTITY
    ) as Transform3D
    var regenerated_vampire_spawn := regeneration_result.get(
        "vampire_spawn",
        Transform3D.IDENTITY
    ) as Transform3D
    var automatic_regeneration_repositions_characters := authored_player != null \
        and vampire != null \
        and not (generated_maze.get("player_path") as NodePath).is_empty() \
        and not (generated_maze.get("vampire_path") as NodePath).is_empty() \
        and authored_player.global_transform.is_equal_approx(
            regenerated_player_spawn
        ) \
        and vampire.global_transform.is_equal_approx(
            regenerated_vampire_spawn
        )
    var passed := _expect(
        vampire_maze_uid != ResourceUID.INVALID_ID and vampire_maze_uid != level_one_uid,
        "Vampire Maze has a unique scene identity"
    ) and _expect(
        level.get_script().resource_path == "res://levels/vampire-maze/vampire_maze.gd" \
            and vampire != null \
            and not (level.get("end_gate_path") as NodePath).is_empty() \
            and not (level.get("generated_content_path") as NodePath).is_empty(),
        "Vampire Maze owns its boss and noise wiring"
    ) and _expect(
        automatic_regeneration_repositions_characters,
        "Vampire Maze resizing repositions the player and Vampire onto the regenerated floor"
    ) and _expect(
        level_settings != null \
            and level_settings.show_minimap \
            and level.call("get_minimap_target") == vampire,
        "Vampire Maze enables the minimap and makes it track the vampire"
    ) and _expect(
        route_overlay != null \
            and route_overlay.layers == TEST_MINIMAP_ROUTE_VISUAL_LAYER,
        "Vampire Maze owns its minimap-only route overlay"
    ) and _expect(
        generated_maze != null \
            and generated_maze.get_script().resource_path.ends_with("generated_maze.gd") \
            and wall_grid_map != null \
            and floor_grid_map != null \
            and int(generated_maze.get("maze_seed")) >= 0,
        "Vampire Maze owns its seeded GridMap generator and generated maps"
    ) and _expect(
        (has_no_baked_cells or has_current_baked_cells) \
            and level.get_node_or_null("Objects") == null,
        "Vampire Maze contains only empty or current generated GridMap cells and no obsolete content"
    ) and _expect(
        development_view != null \
            and development_view.visible \
            and is_equal_approx(float(development_view.get("development_ambient_energy")), 0.24) \
            and camera != null,
        "Vampire Maze exposes its development camera and ambient helper as a visible scene node"
    ) and _expect(
        camera_profile != null \
            and is_equal_approx(float(camera_profile.get("zoom_distance")), 32.0) \
            and camera.has_method("is_runtime_camera_enabled"),
        "Vampire Maze development camera is level-local and further zoomed out"
    ) and _expect(
        debug_hud != null \
            and debug_hud.get_node_or_null("Screen/StateLabel") is Label,
        "Vampire Maze owns its level-local Vampire diagnostics HUD"
    )

    var graveyard := TestGraveyard.new()
    var default_target := Node3D.new()
    graveyard.current_level = level
    passed = _expect(
        graveyard.call("_get_minimap_target", default_target) == vampire,
        "level-specific minimap targets override the normal player target"
    ) and passed
    graveyard.current_level = Node3D.new()
    passed = _expect(
        graveyard.call("_get_minimap_target", default_target) == default_target,
        "levels without a minimap override continue tracking the player"
    ) and passed
    graveyard.current_level.free()
    default_target.free()
    graveyard.free()
    level.free()
    return passed


func _test_vampire_minimap_reports_live_belief_and_route_state() -> bool:
    var holder := Node3D.new()
    root.add_child(holder)
    var vampire := VAMPIRE_SCENE.instantiate() as GDVampire
    holder.add_child(vampire)
    var player := Node3D.new()
    holder.add_child(player)
    player.global_position = Vector3(8.0, 0.0, 4.0)

    var hunt := vampire.get_node("VampireHunt") as GDVampireHunt
    var navigation := vampire.get_node("VampireNavigation")
    hunt.set("player", player)
    hunt.set("settings", vampire.settings)
    hunt.set("has_noise_position", true)
    hunt.set("last_noise_position", Vector3(3.0, 0.0, 4.0))
    hunt.set("noise_elapsed_seconds", 2.0)
    hunt.set("noise_target_active", true)
    hunt.set("awareness_source", GDVampireHunt.AwarenessSource.Noise)
    navigation.set("has_target", true)
    navigation.set("target_position", Vector3(6.0, 0.0, 4.0))
    navigation.set("route_index", 1)
    navigation.set(
        "route_points",
        [Vector3(4.0, 0.0, 4.0), Vector3(6.0, 0.0, 4.0)] as Array[Vector3]
    )
    navigation.set(
        "route_traversal_status",
        GDVampireNavigation.RouteTraversalStatus.Following
    )
    vampire.set("state", GDVampire.VampireState.Hunting)

    var status_backdrop := ColorRect.new()
    status_backdrop.name = "StatusBackdrop"
    var status_label := Label.new()
    status_label.name = "StatusLabel"
    status_backdrop.add_child(status_label)
    var overlay := VAMPIRE_MINIMAP_OVERLAY_SCRIPT.new() as Control
    overlay.add_child(status_backdrop)
    var viewport_container := SubViewportContainer.new()
    var minimap_viewport := SubViewport.new()
    minimap_viewport.size = Vector2i(256, 256)
    var minimap_camera := Camera3D.new()
    viewport_container.add_child(minimap_viewport)
    minimap_viewport.add_child(minimap_camera)
    root.add_child(viewport_container)
    root.add_child(overlay)
    overlay.set_runtime_references(vampire, minimap_camera, viewport_container)
    var snapshot := overlay.call("get_snapshot") as Dictionary

    var game_runtime_scene := load("res://game/game_runtime.tscn") as PackedScene
    var game_runtime := game_runtime_scene.instantiate()
    var authored_overlay := game_runtime.get_node_or_null(
        "MinimapHud/MinimapView/VampireOverlay"
    ) as Control
    var passed := _expect(
        bool(snapshot.get("has_belief", false)) \
            and snapshot.get("belief_kind") == "Sound Origin" \
            and snapshot.get("belief_position") == Vector3(3.0, 0.0, 4.0) \
            and is_equal_approx(float(snapshot.get("belief_error")), 5.0),
        "Vampire minimap distinguishes its sound belief from the player's actual position"
    ) and _expect(
        snapshot.get("search_plan") == "NoiseRadius" \
            and bool(snapshot.get("has_navigation_target", false)) \
            and snapshot.get("navigation_target") == Vector3(6.0, 0.0, 4.0) \
            and int(snapshot.get("route_index")) == 1 \
            and int(snapshot.get("route_points")) == 2,
        "Vampire minimap reports its search plan, destination, and route progress"
    ) and _expect(
        status_label.text.contains("BELIEF SOUND ORIGIN") \
            and status_label.text.contains("SEARCH NOISE RADIUS") \
            and status_label.text.contains("ROUTE 1/2"),
        "Vampire minimap overlays readable live AI diagnostics"
    ) and _expect(
        authored_overlay != null \
            and authored_overlay.get_node_or_null("StatusBackdrop/StatusLabel") is Label,
        "game runtime authors the Vampire diagnostics directly over the minimap"
    )

    game_runtime.free()
    overlay.call("clear_runtime_references")
    passed = _expect(
        not overlay.visible and not overlay.is_processing(),
        "hidden minimaps stop Vampire diagnostics processing"
    ) and passed
    overlay.queue_free()
    viewport_container.queue_free()
    holder.queue_free()
    return passed


func _test_generated_maze_floor_settings() -> bool:
    var generated_maze := VAMPIRE_GENERATED_MAZE_SCENE.instantiate() as Node3D
    var custom_floor_material := StandardMaterial3D.new()
    custom_floor_material.albedo_color = Color(0.18, 0.42, 0.73, 1.0)
    generated_maze.set("floor_material", custom_floor_material)
    generated_maze.set("floor_texture_tiles", Vector2i(2, 3))
    root.add_child(generated_maze)

    var floor_grid_map := generated_maze.get_node("PNGFloorGridMap") as GridMap
    var floor_library := floor_grid_map.mesh_library
    var first_floor_mesh := floor_library.get_item_mesh(0) as PlaneMesh
    var x_phase_floor_mesh := floor_library.get_item_mesh(1) as PlaneMesh
    var y_phase_floor_mesh := floor_library.get_item_mesh(2) as PlaneMesh
    var first_material := first_floor_mesh.material as BaseMaterial3D
    var x_phase_material := x_phase_floor_mesh.material as BaseMaterial3D
    var y_phase_material := y_phase_floor_mesh.material as BaseMaterial3D
    var passed := _expect(
        generated_maze.get("floor_material") == custom_floor_material \
            and generated_maze.get("floor_texture_tiles") == Vector2i(2, 3),
        "GeneratedMaze exposes floor material and tiles-per-texture settings directly"
    ) and _expect(
        floor_library.get_item_list().size() == 6 \
            and first_material != null \
            and first_material != custom_floor_material \
            and first_material.albedo_color.is_equal_approx(
                custom_floor_material.albedo_color
            ) \
            and first_material.uv1_scale.is_equal_approx(
                Vector3(0.5, 1.0 / 3.0, 1.0)
            ) \
            and first_material.uv1_offset.is_equal_approx(Vector3.ZERO) \
            and x_phase_material.uv1_offset.is_equal_approx(Vector3(0.5, 0.0, 0.0)) \
            and y_phase_material.uv1_offset.is_equal_approx(
                Vector3(0.0, 1.0 / 3.0, 0.0)
            ) \
            and floor_grid_map.get_cell_item(Vector3i.ZERO) == 0 \
            and floor_grid_map.get_cell_item(Vector3i(1, 0, 0)) == 1 \
            and floor_grid_map.get_cell_item(Vector3i(0, 0, 1)) == 2,
        "one complete generated-floor texture spans the configured X/Y cell count"
    )

    generated_maze.free()
    return passed


func _test_vampire_maze_generates_seeded_grid_maps() -> bool:
    var generated_maze := VAMPIRE_GENERATED_MAZE_SCENE.instantiate() as Node3D
    root.add_child(generated_maze)
    var walls := generated_maze.get_node("PNGGridMap") as GridMap
    var floor := generated_maze.get_node("PNGFloorGridMap") as GridMap
    var configuration := generated_maze.get("configuration") as Resource
    var configured_width := int(configuration.get("width"))
    var configured_height := int(configuration.get("height"))
    var hallway_width := int(configuration.get("hallway_width"))
    var configured_internal_connection_percent := float(
        configuration.get("internal_connection_percent")
    )
    var configured_internal_connection_count := int(generated_maze.call(
        "_get_internal_connection_count",
        configured_width,
        configured_height,
        hallway_width,
        configured_internal_connection_percent
    ))
    var compact_internal_connection_count := int(generated_maze.call(
        "_get_internal_connection_count",
        22,
        22,
        hallway_width,
        configured_internal_connection_percent
    ))
    var tree_floor_cells := generated_maze.call(
        "_build_floor_cells",
        configured_width,
        configured_height,
        hallway_width,
        1730,
        0
    ) as Dictionary
    var loop_floor_cells := generated_maze.call(
        "_build_floor_cells",
        configured_width,
        configured_height,
        hallway_width,
        1730,
        configured_internal_connection_percent
    ) as Dictionary
    var repeated_loop_floor_cells := generated_maze.call(
        "_build_floor_cells",
        configured_width,
        configured_height,
        hallway_width,
        1730,
        configured_internal_connection_percent
    ) as Dictionary
    var added_internal_floor_cells := 0
    var internal_connections_preserve_outer_wall := true
    for cell_value in loop_floor_cells:
        var cell := cell_value as Vector2i
        if tree_floor_cells.has(cell):
            continue
        added_internal_floor_cells += 1
        if cell.x <= 0 or cell.y <= 0 \
                or cell.x >= configured_width - 1 \
                or cell.y >= configured_height - 1:
            internal_connections_preserve_outer_wall = false
    var internal_connections_are_deterministic := loop_floor_cells \
        == repeated_loop_floor_cells \
        and configured_internal_connection_count > compact_internal_connection_count \
        and compact_internal_connection_count > 0 \
        and added_internal_floor_cells \
            == configured_internal_connection_count * hallway_width \
        and internal_connections_preserve_outer_wall
    var scene_seed_floor_cells := generated_maze.call(
        "_build_floor_cells",
        configured_width,
        configured_height,
        hallway_width,
        2,
        configured_internal_connection_percent
    ) as Dictionary
    var isolated_wall_count := 0
    var isolated_wall_x_bands := {}
    var isolated_wall_y_bands := {}
    for z_coordinate in range(1, configured_height - 1):
        for x_coordinate in range(1, configured_width - 1):
            var wall_cell := Vector2i(x_coordinate, z_coordinate)
            if scene_seed_floor_cells.has(wall_cell):
                continue
            var wall_is_isolated := true
            for direction in [
                Vector2i.UP,
                Vector2i.RIGHT,
                Vector2i.DOWN,
                Vector2i.LEFT,
            ]:
                if not scene_seed_floor_cells.has(wall_cell + direction):
                    wall_is_isolated = false
                    break
            if not wall_is_isolated:
                continue
            isolated_wall_count += 1
            isolated_wall_x_bands[x_coordinate * 4 / configured_width] = true
            isolated_wall_y_bands[z_coordinate * 4 / configured_height] = true
    var isolated_walls_are_not_clustered := isolated_wall_count <= 8 \
        and isolated_wall_x_bands.size() >= 3 \
        and isolated_wall_y_bands.size() >= 3
    var player := TestGeneratedPlayer.new()
    var vampire := CharacterBody3D.new()
    generated_maze.add_child(player)
    generated_maze.add_child(vampire)

    var first_result := generated_maze.call(
        "generate_from_config",
        configuration,
        1729,
        player,
        vampire
    ) as Dictionary
    var first_wall_cells := walls.get_used_cells()
    first_wall_cells.sort()
    var first_signature := str(first_wall_cells)
    var repeat_result := generated_maze.call(
        "generate_from_config",
        configuration,
        1729,
        player,
        vampire
    ) as Dictionary
    var repeat_wall_cells := walls.get_used_cells()
    repeat_wall_cells.sort()
    var repeat_signature := str(repeat_wall_cells)
    var changed_result := generated_maze.call(
        "generate_from_config",
        configuration,
        1730,
        player,
        vampire
    ) as Dictionary
    var changed_wall_cells := walls.get_used_cells()
    changed_wall_cells.sort()
    var changed_signature := str(changed_wall_cells)

    var wall_item_ids := {}
    for wall_cell in walls.get_used_cells():
        wall_item_ids[walls.get_cell_item(wall_cell)] = true
    var gate_opening_origin_x := int(
        changed_result.get("end_gate_opening_origin_x", -1)
    )
    var gate_opening_width_tiles := int(
        changed_result.get("end_gate_opening_width_tiles", 0)
    )
    var gate_aperture_is_clear := true
    for x_coordinate in range(
        gate_opening_origin_x,
        gate_opening_origin_x + gate_opening_width_tiles
    ):
        if walls.get_cell_item(Vector3i(x_coordinate, 0, configured_height - 1)) \
                != GridMap.INVALID_CELL_ITEM:
            gate_aperture_is_clear = false
            break
    var gate_aperture_has_wall_shoulders := walls.get_cell_item(Vector3i(
        gate_opening_origin_x - 1,
        0,
        configured_height - 1
    )) != GridMap.INVALID_CELL_ITEM and walls.get_cell_item(Vector3i(
        gate_opening_origin_x + gate_opening_width_tiles,
        0,
        configured_height - 1
    )) != GridMap.INVALID_CELL_ITEM
    var bottom_right_corner_is_enclosed := true
    for corner_cell in [
        Vector3i(configured_width - 2, 0, configured_height - 1),
        Vector3i(configured_width - 1, 0, configured_height - 1),
        Vector3i(configured_width - 1, 0, configured_height - 2),
    ]:
        if walls.get_cell_item(corner_cell) == GridMap.INVALID_CELL_ITEM:
            bottom_right_corner_is_enclosed = false
            break
    var player_cell := changed_result.get("player_cell") as Vector3i
    var vampire_cell := changed_result.get("vampire_cell") as Vector3i
    var end_gate_cell := changed_result.get("end_gate_cell") as Vector3i
    var maze_origin := changed_result.get("maze_origin") as Vector2i
    var logical_width := int(changed_result.get("logical_width", 0))
    var logical_height := int(changed_result.get("logical_height", 0))
    var generated_floor_cells := {}
    var used_edge_lanes := {
        &"top": false,
        &"right": false,
        &"bottom": false,
        &"left": false,
    }
    for cell_value in changed_result.get("floor_cells", []):
        var floor_cell := cell_value as Vector2i
        generated_floor_cells[floor_cell] = true
        if floor_cell.y <= hallway_width:
            used_edge_lanes[&"top"] = true
        if floor_cell.x >= configured_width - 1 - hallway_width:
            used_edge_lanes[&"right"] = true
        if floor_cell.y >= configured_height - 1 - hallway_width:
            used_edge_lanes[&"bottom"] = true
        if floor_cell.x <= hallway_width:
            used_edge_lanes[&"left"] = true
    var perimeter_break_sides := {
        &"top": false,
        &"right": false,
        &"bottom": false,
        &"left": false,
    }
    var perimeter_break_count := 0
    var allowed_perimeter_connection_count := 0
    var open_perimeter_connection_count := 0
    for logical_x in range(logical_width - 1):
        var top_from := Vector2i(logical_x, 0)
        var top_to := Vector2i(logical_x + 1, 0)
        var top_connection_is_allowed := bool(generated_maze.call(
            "_logical_transition_is_allowed",
            top_from,
            top_to,
            logical_width,
            logical_height
        ))
        if top_connection_is_allowed:
            allowed_perimeter_connection_count += 1
        else:
            perimeter_break_sides[&"top"] = true
            perimeter_break_count += 1
        var top_connection_is_open := bool(generated_maze.call(
            "_logical_connection_is_open",
            generated_floor_cells,
            top_from,
            top_to,
            hallway_width,
            maze_origin
        ))
        if top_connection_is_open:
            open_perimeter_connection_count += 1
        var bottom_from := Vector2i(logical_x, logical_height - 1)
        var bottom_to := Vector2i(logical_x + 1, logical_height - 1)
        var bottom_connection_is_allowed := bool(generated_maze.call(
            "_logical_transition_is_allowed",
            bottom_from,
            bottom_to,
            logical_width,
            logical_height
        ))
        if bottom_connection_is_allowed:
            allowed_perimeter_connection_count += 1
        else:
            perimeter_break_sides[&"bottom"] = true
            perimeter_break_count += 1
        var bottom_connection_is_open := bool(generated_maze.call(
            "_logical_connection_is_open",
            generated_floor_cells,
            bottom_from,
            bottom_to,
            hallway_width,
            maze_origin
        ))
        if bottom_connection_is_open:
            open_perimeter_connection_count += 1
    for logical_y in range(logical_height - 1):
        var left_from := Vector2i(0, logical_y)
        var left_to := Vector2i(0, logical_y + 1)
        var left_connection_is_allowed := bool(generated_maze.call(
            "_logical_transition_is_allowed",
            left_from,
            left_to,
            logical_width,
            logical_height
        ))
        if left_connection_is_allowed:
            allowed_perimeter_connection_count += 1
        else:
            perimeter_break_sides[&"left"] = true
            perimeter_break_count += 1
        var left_connection_is_open := bool(generated_maze.call(
            "_logical_connection_is_open",
            generated_floor_cells,
            left_from,
            left_to,
            hallway_width,
            maze_origin
        ))
        if left_connection_is_open:
            open_perimeter_connection_count += 1
        var right_from := Vector2i(logical_width - 1, logical_y)
        var right_to := Vector2i(logical_width - 1, logical_y + 1)
        var right_connection_is_allowed := bool(generated_maze.call(
            "_logical_transition_is_allowed",
            right_from,
            right_to,
            logical_width,
            logical_height
        ))
        if right_connection_is_allowed:
            allowed_perimeter_connection_count += 1
        else:
            perimeter_break_sides[&"right"] = true
            perimeter_break_count += 1
        var right_connection_is_open := bool(generated_maze.call(
            "_logical_connection_is_open",
            generated_floor_cells,
            right_from,
            right_to,
            hallway_width,
            maze_origin
        ))
        if right_connection_is_open:
            open_perimeter_connection_count += 1
    var full_map_edges_are_used := true
    for edge_name in used_edge_lanes:
        if not bool(used_edge_lanes[edge_name]):
            full_map_edges_are_used = false
            break
    var sparse_perimeter_breaks_prevent_border_bypass := perimeter_break_count > 0 \
        and allowed_perimeter_connection_count > perimeter_break_count * 2 \
        and open_perimeter_connection_count > perimeter_break_count
    for edge_name in perimeter_break_sides:
        if not bool(perimeter_break_sides[edge_name]):
            sparse_perimeter_breaks_prevent_border_bypass = false
            break
    var content_plan := changed_result.get("content_plan", {}) as Dictionary
    var content_configuration := configuration.get("content_configuration") as Resource
    var doors := content_plan.get("doors", []) as Array
    var keys := content_plan.get("keys", []) as Array
    var coffins := content_plan.get("coffins", []) as Array
    var treasure_caches := content_plan.get("treasure_caches", []) as Array
    var bat_nests := content_plan.get("bat_nests", []) as Array
    var vampire_gate_clearance_cell := Vector2i(end_gate_cell.x, end_gate_cell.z - 1)
    var vampire_gate_clearance_is_empty := true
    for placements in [doors, keys, coffins, treasure_caches, bat_nests]:
        for placement_value in placements:
            var placement := placement_value as Dictionary
            if placement.get("cell") == vampire_gate_clearance_cell \
                    or placement.get("paired_cell") == vampire_gate_clearance_cell:
                vampire_gate_clearance_is_empty = false
    var exploration_bat_count := 0
    for bat_value in bat_nests:
        var bat := bat_value as Dictionary
        if int(bat["placement_band"]) \
                == VAMPIRE_GENERATED_CONTENT_PLANNER.PlacementBand.Exploration:
            exploration_bat_count += 1
    var configured_bat_count := int(content_configuration.get("bat_nest_count"))
    var expected_exploration_bat_count := clampi(
        roundi(
            float(configured_bat_count)
            * float(content_configuration.get("bat_off_path_percent"))
            / 100.0
        ),
        0,
        configured_bat_count
    )
    var generated_content := generated_maze.get_node("GeneratedContent")
    var generated_treasure_pile_count := 0
    var generated_preview_roots_are_transient := true
    for child in generated_content.get_children():
        if child.owner != null:
            generated_preview_roots_are_transient = false
        if child.name.begins_with("GeneratedTreasureCache"):
            generated_treasure_pile_count += 1
    var vampire_layout_landmarks := generated_content.call(
        "get_vampire_layout_landmarks"
    ) as Array[Dictionary]
    var generated_gate := generated_content.get_node_or_null("GeneratedLockedGate") as Node3D
    var generated_staircase := generated_gate.get_node_or_null(
        "ProceduralStaircase"
    ) as Node3D if generated_gate != null else null
    var generated_gate_uses_authored_scale := generated_gate != null \
        and generated_gate.scale.is_equal_approx(Vector3.ONE)
    var staircase_mesh_instance := generated_staircase.get_node_or_null(
        "GeneratedStairMesh"
    ) as MeshInstance3D if generated_staircase != null else null
    var staircase_mesh := staircase_mesh_instance.mesh as ArrayMesh \
        if staircase_mesh_instance != null else null
    var staircase_material := staircase_mesh_instance.material_override \
        as StandardMaterial3D if staircase_mesh_instance != null else null
    var generated_staircase_is_visible: bool = generated_staircase != null \
        and generated_staircase.scale.is_equal_approx(Vector3.ONE) \
        and staircase_mesh_instance != null \
        and staircase_mesh_instance.visible \
        and staircase_mesh != null \
        and staircase_material != null \
        and staircase_material.albedo_color.get_luminance() >= 0.35 \
        and staircase_material.emission_enabled
    var staircase_is_single_procedural_mesh: bool = generated_staircase != null \
        and generated_staircase.get_script() == PROCEDURAL_STAIRCASE_SCRIPT \
        and staircase_mesh != null \
        and staircase_mesh.get_surface_count() == 1 \
        and staircase_mesh.get_aabb().position.y <= -0.09 \
        and generated_staircase.get_node_or_null("Steps") == null
    var staircase_threshold: CollisionShape3D = null
    var staircase_ramp: CollisionShape3D = null
    var staircase_top_landing: CollisionShape3D = null
    var staircase_left_guard: CollisionShape3D = null
    var staircase_right_guard: CollisionShape3D = null
    if generated_staircase != null:
        staircase_threshold = generated_staircase.get_node_or_null(
            "StairCollision/GateThresholdShape"
        ) as CollisionShape3D
        staircase_ramp = generated_staircase.get_node_or_null(
            "StairCollision/RampShape"
        ) as CollisionShape3D
        staircase_top_landing = generated_staircase.get_node_or_null(
            "StairCollision/TopLandingShape"
        ) as CollisionShape3D
        staircase_left_guard = generated_staircase.get_node_or_null(
            "StairCollision/LeftSideGuardShape"
        ) as CollisionShape3D
        staircase_right_guard = generated_staircase.get_node_or_null(
            "StairCollision/RightSideGuardShape"
        ) as CollisionShape3D
    var staircase_has_walkable_transition := false
    if staircase_ramp != null and staircase_top_landing != null:
        var ramp_box := staircase_ramp.shape as BoxShape3D
        var landing_box := staircase_top_landing.shape as BoxShape3D
        if ramp_box != null and landing_box != null:
            var ramp_direction := staircase_ramp.transform.basis.x.normalized()
            var ramp_surface_normal := staircase_ramp.transform.basis.y.normalized()
            var lower_ramp_surface := staircase_ramp.position \
                - ramp_direction * ramp_box.size.x * 0.5 \
                + ramp_surface_normal * ramp_box.size.y * 0.5
            var upper_ramp_surface := staircase_ramp.position \
                + ramp_direction * ramp_box.size.x * 0.5 \
                + ramp_surface_normal * ramp_box.size.y * 0.5
            var landing_start := staircase_top_landing.position.x \
                - landing_box.size.x * 0.5
            var landing_top := staircase_top_landing.position.y \
                + landing_box.size.y * 0.5
            var ramp_angle_degrees := rad_to_deg(asin(ramp_direction.y))
            staircase_has_walkable_transition = staircase_threshold == null \
                and lower_ramp_surface.x >= 1.2 \
                and lower_ramp_surface.x <= 1.3 \
                and absf(lower_ramp_surface.y) <= 0.02 \
                and landing_start <= upper_ramp_surface.x \
                and absf(upper_ramp_surface.y - landing_top) <= 0.02 \
                and ramp_angle_degrees <= 15.0 \
                and ramp_box.size.z >= 2.8
    var staircase_completion_area := generated_staircase.get_node_or_null(
        "CompletionArea"
    ) as Area3D if generated_staircase != null else null
    var staircase_has_guarded_victory_runoff := false
    if staircase_top_landing != null \
            and staircase_left_guard != null \
            and staircase_right_guard != null \
            and staircase_completion_area != null:
        var top_landing_box := staircase_top_landing.shape as BoxShape3D
        var left_guard_box := staircase_left_guard.shape as BoxShape3D
        var right_guard_box := staircase_right_guard.shape as BoxShape3D
        if top_landing_box != null \
                and left_guard_box != null \
                and right_guard_box != null:
            var top_landing_end := staircase_top_landing.position.x \
                + top_landing_box.size.x * 0.5
            var top_landing_top := staircase_top_landing.position.y \
                + top_landing_box.size.y * 0.5
            var guard_start := staircase_left_guard.position.x \
                - left_guard_box.size.x * 0.5
            var guard_end := staircase_left_guard.position.x \
                + left_guard_box.size.x * 0.5
            var guard_top := staircase_left_guard.position.y \
                + left_guard_box.size.y * 0.5
            var guarded_walkway_width := staircase_right_guard.position.z \
                - right_guard_box.size.z * 0.5 \
                - staircase_left_guard.position.z \
                - left_guard_box.size.z * 0.5
            staircase_has_guarded_victory_runoff = \
                top_landing_end - staircase_completion_area.position.x >= 4.0 \
                and guard_start <= -0.4 \
                and guard_end >= top_landing_end - 0.01 \
                and guard_top >= top_landing_top + 3.0 \
                and guarded_walkway_width >= 2.5 \
                and staircase_left_guard.position.z < 0.0 \
                and staircase_right_guard.position.z > 0.0
    var locked_staircase_rejects_completion := generated_gate != null \
        and not bool(generated_gate.call("try_complete_with", player))
    var staircase_completion_count: Array[int] = [0]
    generated_content.connect(
        &"level_completed",
        func() -> void:
            staircase_completion_count[0] += 1
    )
    if generated_gate != null:
        generated_gate.set("locked", false)
        generated_gate.emit_signal(&"unlocked")
    var unlocked_staircase_completes := generated_gate != null \
        and bool(generated_gate.call("try_complete_with", player)) \
        and staircase_completion_count[0] == 1
    var staircase_is_outside_gate := generated_gate != null \
        and generated_staircase != null \
        and staircase_completion_area != null \
        and staircase_completion_area.global_position.z > generated_gate.global_position.z \
        and staircase_completion_area.global_position.y > generated_gate.global_position.y
    var generated_doors: Array[Node3D] = []
    for child in generated_content.get_children():
        if child.name.begins_with("GeneratedLockedDoor"):
            generated_doors.append(child as Node3D)
    var generated_passages_use_authored_leaves := generated_doors.size() == doors.size()
    for generated_door in generated_doors:
        var door_leaf := generated_door.get_node_or_null("Leaves/DoorLeaf") as RigidBody3D
        if generated_door.scene_file_path != "res://placeables/lockables/locked_door.tscn" \
                or door_leaf == null \
                or door_leaf.global_position.distance_to(generated_door.global_position) > 2.0 \
                or not bool(generated_door.call("is_locked")):
            generated_passages_use_authored_leaves = false
            break
    var gate_left_leaf := generated_gate.get_node_or_null("Leaves/LeftGateLeaf") as RigidBody3D \
        if generated_gate != null else null
    var generated_gate_keeps_its_leaves: bool = generated_gate != null \
        and gate_left_leaf != null \
        and gate_left_leaf.global_position.distance_to(generated_gate.global_position) < 3.0
    var coffin_cells := {}
    for coffin_value in coffins:
        var planned_coffin := coffin_value as Dictionary
        coffin_cells[planned_coffin["cell"] as Vector2i] = true
    var door_approaches_are_clear := true
    for door_value in doors:
        var planned_door := door_value as Dictionary
        var travel_direction := planned_door["travel_direction"] as Vector2i
        for blocked_cell_value in planned_door.get("blocked_cells", []):
            var blocked_cell := blocked_cell_value as Vector2i
            for distance in range(
                0,
                VAMPIRE_GENERATED_CONTENT_PLANNER.DOOR_APPROACH_CLEARANCE_TILES + 1
            ):
                if coffin_cells.has(blocked_cell + travel_direction * distance) \
                        or coffin_cells.has(blocked_cell - travel_direction * distance):
                    door_approaches_are_clear = false
                    break
    var bat_noise_positions: Array[Vector3] = []
    generated_content.connect(
        &"bat_noise_triggered",
        func(noise_position: Vector3) -> void:
            bat_noise_positions.append(noise_position)
    )
    var vampire_collision_bodies := generated_content.call(
        "get_vampire_collision_bodies"
    ) as Array[PhysicsBody3D]
    var vampire_ignores_every_generated_blocker := vampire_collision_bodies.size() \
        >= doors.size() * 2 + coffins.size()
    for collision_body in vampire_collision_bodies:
        if not vampire.get_collision_exceptions().has(collision_body):
            vampire_ignores_every_generated_blocker = false
            break
    var bat_noise := generated_content.get_node_or_null("GeneratedBatNoise01")
    if bat_noise != null:
        var bat_nest := bat_noise.get_node("BatNest")
        bat_nest.call("force_take_flight", player)
        bat_noise.call("_physics_process", 0.0)
    var generation_constants: Dictionary = generated_maze.get_script().get_script_constant_map()
    generated_maze.set(
        "baked_generation_version",
        int(generation_constants.get("CURRENT_GENERATION_VERSION", 0))
    )
    generated_maze.set("baked_maze_seed", int(generated_maze.get("maze_seed")))
    generated_maze.set("baked_width", configured_width)
    generated_maze.set("baked_height", configured_height)
    var current_bake_is_reusable := bool(
        generated_maze.call("_can_reuse_runtime_grid_maps", configuration)
    )
    var total_treasure_weight := float(content_plan.get("total_treasure_weight", 0.0))
    var target_load_weight := float(content_configuration.get("assumed_carry_capacity")) \
        * float(content_configuration.get("target_carry_load_percent")) / 100.0
    var expected_coffin_count := maxi(
        ceili(total_treasure_weight / target_load_weight) \
            if total_treasure_weight > 0.0 else 0,
        int(content_configuration.get("minimum_coffin_count"))
    )
    var minimum_coins_per_pile := int(content_configuration.get("minimum_coins_per_pile"))
    var maximum_coins_per_pile := maxi(
        int(content_configuration.get("maximum_coins_per_pile")),
        minimum_coins_per_pile
    )
    var pile_coin_counts_are_in_range := treasure_caches.size() \
        == int(content_configuration.get("treasure_pile_count"))
    var supports_large_treasure_pile_budgets := false
    var treasure_pile_count_hint := ""
    for property_value in content_configuration.get_property_list():
        var property := property_value as Dictionary
        if property.get("name") == &"treasure_pile_count":
            treasure_pile_count_hint = String(property.get("hint_string", ""))
            var hint_parts := treasure_pile_count_hint.split(",")
            supports_large_treasure_pile_budgets = hint_parts.size() >= 2 \
                and roundi(float(hint_parts[1])) >= 256
            break
    var treasure_spatial_regions := {}
    var treasure_x_bands := {}
    var treasure_y_bands := {}
    var treasure_uses_route_or_exploration_bands := true
    var main_path_pile_count := 0
    var perimeter_treasure_count := 0
    for cache_value in treasure_caches:
        var cache := cache_value as Dictionary
        var counts := cache["counts"] as Dictionary
        var coin_count := int(counts.get(&"gold_coin", 0))
        if coin_count < minimum_coins_per_pile or coin_count > maximum_coins_per_pile:
            pile_coin_counts_are_in_range = false
            break
        var cache_cell := cache["cell"] as Vector2i
        var x_band := clampi(
            floori(float(cache_cell.x) * 4.0 / float(configured_width)),
            0,
            3
        )
        var y_band := clampi(
            floori(float(cache_cell.y) * 4.0 / float(configured_height)),
            0,
            3
        )
        treasure_spatial_regions[Vector2i(x_band, y_band)] = true
        treasure_x_bands[x_band] = true
        treasure_y_bands[y_band] = true
        var placement_band := int(cache["placement_band"])
        var map_edge_clearance := int(cache.get("map_edge_clearance_tiles", 0))
        if placement_band \
                    != VAMPIRE_GENERATED_CONTENT_PLANNER.PlacementBand.MainPath \
                and placement_band \
                    != VAMPIRE_GENERATED_CONTENT_PLANNER.PlacementBand.Exploration:
            treasure_uses_route_or_exploration_bands = false
        if placement_band == VAMPIRE_GENERATED_CONTENT_PLANNER.PlacementBand.MainPath:
            main_path_pile_count += 1
        if map_edge_clearance <= 2:
            perimeter_treasure_count += 1
    var treasure_is_distributed_through_available_space := treasure_caches.size() < 4 \
        or (treasure_uses_route_or_exploration_bands \
            and treasure_spatial_regions.size() >= 8 \
            and treasure_x_bands.size() >= 3 \
            and treasure_y_bands.size() >= 3 \
            and perimeter_treasure_count > 0 \
            and main_path_pile_count < treasure_caches.size() / 2)
    var treasure_pile_cells: Array[Vector2i] = []
    var treasure_piles_use_distinct_cells := true
    for cache_value in treasure_caches:
        var cache := cache_value as Dictionary
        var cache_cell := cache["cell"] as Vector2i
        for other_cell in treasure_pile_cells:
            if cache_cell == other_cell:
                treasure_piles_use_distinct_cells = false
                break
        treasure_pile_cells.append(cache_cell)
    var coffins_do_not_overlap_treasure := true
    var coffin_spatial_regions := {}
    var coffin_x_bands := {}
    var coffin_y_bands := {}
    var coffin_cells_for_spacing: Array[Vector2i] = []
    var minimum_coffin_spacing := int(
        content_configuration.get("minimum_coffin_spacing_tiles")
    )
    var coffins_keep_their_spacing := true
    for coffin_value in coffins:
        var planned_coffin := coffin_value as Dictionary
        var coffin_cell := planned_coffin["cell"] as Vector2i
        var coffin_x_band := clampi(
            floori(float(coffin_cell.x) * 2.0 / float(configured_width)),
            0,
            1
        )
        var coffin_y_band := clampi(
            floori(float(coffin_cell.y) * 2.0 / float(configured_height)),
            0,
            1
        )
        coffin_spatial_regions[Vector2i(coffin_x_band, coffin_y_band)] = true
        coffin_x_bands[coffin_x_band] = true
        coffin_y_bands[coffin_y_band] = true
        for other_coffin_cell in coffin_cells_for_spacing:
            if coffin_cell.distance_to(other_coffin_cell) \
                    < float(minimum_coffin_spacing):
                coffins_keep_their_spacing = false
                break
        coffin_cells_for_spacing.append(coffin_cell)
        for treasure_cell in treasure_pile_cells:
            if coffin_cell == treasure_cell:
                coffins_do_not_overlap_treasure = false
                break
    var coffins_use_separate_maze_regions := coffins.size() < 3 \
        or (coffin_spatial_regions.size() >= 3 \
            and coffin_x_bands.size() >= 2 \
            and coffin_y_bands.size() >= 2)

    var challenging_configuration := content_configuration.duplicate(true) as Resource
    challenging_configuration.set("treasure_pile_count", 4)
    challenging_configuration.set("minimum_coins_per_pile", 2)
    challenging_configuration.set("maximum_coins_per_pile", 4)
    challenging_configuration.set("main_path_treasure_percent", 100.0)
    challenging_configuration.set("gold_bar_budget", 0)
    var gem_types: Array[StringName] = [
        &"diamond",
        &"ruby",
        &"sapphire",
        &"emerald",
        &"amethyst",
    ]
    for gem_type in gem_types:
        challenging_configuration.set(StringName("%s_budget" % gem_type), 1)
    var generated_walkable := {}
    for cell_value in changed_result.get("floor_cells", []):
        generated_walkable[cell_value as Vector2i] = true
    var challenging_planner := VAMPIRE_GENERATED_CONTENT_PLANNER.new()
    var challenging_plan := challenging_planner.build_plan(
        generated_walkable,
        player_cell,
        vampire_cell,
        end_gate_cell,
        Vector2i(configured_width, configured_height),
        1730,
        challenging_configuration
    ) as Dictionary
    var challenging_caches := challenging_plan.get("treasure_caches", []) as Array
    var challenging_gem_totals := {}
    for gem_type in gem_types:
        challenging_gem_totals[gem_type] = 0
    var gems_use_only_challenging_piles := (
        challenging_plan.get("errors", []) as Array
    ).is_empty()
    for cache_value in challenging_caches:
        var cache := cache_value as Dictionary
        var counts := cache["counts"] as Dictionary
        for gem_type in gem_types:
            var gem_count := int(counts.get(gem_type, 0))
            challenging_gem_totals[gem_type] = int(challenging_gem_totals[gem_type]) \
                + gem_count
            if gem_count > 0 and int(cache["placement_band"]) \
                    != VAMPIRE_GENERATED_CONTENT_PLANNER.PlacementBand.Exploration:
                gems_use_only_challenging_piles = false
    for gem_type in gem_types:
        if int(challenging_gem_totals[gem_type]) != 1:
            gems_use_only_challenging_piles = false
            break
    var spacious_coffins_avoid_nearby_treasure := (
        challenging_plan.get("errors", []) as Array
    ).is_empty()
    var challenging_treasure_cells: Array[Vector2i] = []
    for cache_value in challenging_caches:
        var cache := cache_value as Dictionary
        challenging_treasure_cells.append(cache["cell"] as Vector2i)
    var preferred_coffin_clearance := int(
        challenging_configuration.get("preferred_coffin_treasure_clearance_tiles")
    )
    for coffin_value in challenging_plan.get("coffins", []):
        var planned_coffin := coffin_value as Dictionary
        var coffin_cell := planned_coffin["cell"] as Vector2i
        for treasure_cell in challenging_treasure_cells:
            if coffin_cell.distance_to(treasure_cell) < float(preferred_coffin_clearance):
                spacious_coffins_avoid_nearby_treasure = false
                break
    var freeze_generated_level_action := generated_maze.get(
        "freeze_generated_level_action"
    ) as Callable
    var passed := _expect(
        (first_result.get("errors", []) as Array).is_empty() \
            and (repeat_result.get("errors", []) as Array).is_empty() \
            and (changed_result.get("errors", []) as Array).is_empty(),
        "seeded GridMap maze generation completes without configuration or repair errors"
    ) and _expect(
        first_signature == repeat_signature and first_signature != changed_signature,
        "the same maze seed is stable and changing the seed creates a different map"
    ) and _expect(
        coffins_do_not_overlap_treasure \
            and spacious_coffins_avoid_nearby_treasure \
            and coffins_keep_their_spacing \
            and coffins_use_separate_maze_regions,
        "generated coffins occupy separate maze regions with useful spacing from treasure"
    ) and _expect(
        configured_internal_connection_percent > 0.0 \
            and internal_connections_are_deterministic,
        "internal opening density adds deterministic size-scaled loops without piercing the outer wall"
    ) and _expect(
        isolated_walls_are_not_clustered,
        "extra openings do not cluster isolated wall pieces into one part of the maze"
    ) and _expect(
        maze_origin == Vector2i.ONE \
            and full_map_edges_are_used \
            and sparse_perimeter_breaks_prevent_border_bypass,
        "ordinary edge corridors use sparse breaks instead of forming a border bypass"
    ) and _expect(
        treasure_is_distributed_through_available_space,
        "generated treasure spreads through perimeter and interior walkable space"
    ) and _expect(
        doors.size() == int(content_configuration.get("door_count")) \
            and keys.size() == doors.size() + 1 \
            and _generated_plan_keys_are_reachable(content_plan, changed_result) \
            and _generated_exit_key_requires_exploration(content_plan, changed_result),
        "generated keys remain obtainable while the gold exit key requires exploration"
    ) and _expect(
        int(changed_result.get("hallway_width", 0)) == 2 \
            and player_cell == Vector3i(1, 0, 1) \
            and vampire_cell.x == end_gate_cell.x \
            and vampire_cell.z == configured_height - 3 \
            and end_gate_cell.z == configured_height - 1 \
            and vampire_cell.distance_to(end_gate_cell) == 2.0 \
            and vampire_gate_clearance_is_empty \
            and changed_result.get("end_gate_outward_direction") == Vector2i.DOWN,
        "the straight bottom-row gate keeps a clear two-cell buffer before the vampire"
    ) and _expect(
        generated_gate != null \
            and generated_gate.get_parent() == generated_content \
            and changed_result.get("end_gate") == generated_gate \
            and generated_gate_uses_authored_scale,
        "generated dungeon content only rotates the authored unscaled end gate into place"
    ) and _expect(
        generated_passages_use_authored_leaves and generated_gate_keeps_its_leaves,
        "generated passages retain the reusable locked scenes and their closed leaves"
    ) and _expect(
        generated_maze.has_method(&"freeze_generated_level_for_editing") \
            and freeze_generated_level_action.is_valid() \
            and freeze_generated_level_action.get_method() \
                == &"freeze_generated_level_for_editing" \
            and generated_content.has_method(&"make_generated_children_editable") \
            and generated_preview_roots_are_transient,
        "live previews stay transient until editors freeze their generated scene roots"
    ) and _expect(
        generated_gate != null \
            and bool(generated_gate.get("completes_level")) \
            and generated_staircase != null \
            and generated_staircase.get_parent() == generated_gate \
            and generated_content.get_node_or_null("GeneratedExitStaircase") == null \
            and locked_staircase_rejects_completion \
            and unlocked_staircase_completes \
            and staircase_is_outside_gate \
            and generated_staircase_is_visible \
            and staircase_is_single_procedural_mesh,
        "the visible exterior uses one procedural staircase mesh and completes after unlocking"
    ) and _expect(
        staircase_has_walkable_transition,
        "the exit relies on the floor before its continuous shallow staircase ramp"
    ) and _expect(
        staircase_has_guarded_victory_runoff,
        "the exit has invisible side guards and continues safely beyond its victory trigger"
    ) and _expect(
        door_approaches_are_clear,
        "generated coffins stay clear of both sides of every locked doorway"
    ) and _expect(
        floor.get_used_cells().size() == configured_width * configured_height \
            and wall_item_ids.size() > 1 \
            and gate_aperture_is_clear \
            and gate_opening_width_tiles == 1 \
            and gate_aperture_has_wall_shoulders \
            and bottom_right_corner_is_enclosed \
            and current_bake_is_reusable,
        "the generated gate occupies one boundary tile between solid wall shoulders"
    ) and _expect(
        content_plan.get("treasure_budgets", {}) \
                == content_plan.get("placed_treasure_budgets", {}) \
            and pile_coin_counts_are_in_range \
            and supports_large_treasure_pile_budgets \
            and generated_treasure_pile_count == treasure_caches.size() \
            and treasure_piles_use_distinct_cells \
            and (first_result.get("content_plan") as Dictionary).get(
                "treasure_caches",
                []
            ) == (repeat_result.get("content_plan") as Dictionary).get(
                "treasure_caches",
                []
            ),
        "generated treasure piles support large budgets and honour their count, distinct cells, and range"
    ) and _expect(
        gems_use_only_challenging_piles,
        "generated gems are reserved for challenging off-main-path treasure piles"
    ) and _expect(
        vampire_layout_landmarks.size() \
            == treasure_caches.size() + keys.size() + coffins.size() + doors.size() + 1,
        "generated content supplies every strategic treasure, key, coffin, door, and gate landmark"
    ) and _expect(
        vampire_ignores_every_generated_blocker,
        "the vampire crosses generated doors and coffins without changing player collision"
    ) and _expect(
        coffins.size() == expected_coffin_count \
            and target_load_weight > 0.0,
        "coffin count follows the configured carry load and real treasure weights"
    ) and _expect(
        bat_nests.size() == configured_bat_count \
            and exploration_bat_count == expected_exploration_bat_count \
            and bat_noise_positions.size() == 1 \
            and bat_noise_positions[0] == player.global_position,
        "bat difficulty controls off-path placement and take-off reports the player's location as noise"
    )

    var automatic_configuration := configuration.duplicate(true) as Resource
    var automatic_content_configuration := content_configuration.duplicate(true) as Resource
    automatic_configuration.set(
        "content_configuration",
        automatic_content_configuration
    )
    generated_maze.set("configuration", automatic_configuration)
    var automatic_baseline_result := generated_maze.call(
        "generate_from_config",
        automatic_configuration,
        1730,
        player,
        vampire
    ) as Dictionary
    var automatic_baseline_plan := automatic_baseline_result.get(
        "content_plan",
        {}
    ) as Dictionary
    var automatic_wall_cells_before := walls.get_used_cells()
    automatic_wall_cells_before.sort()
    var automatic_generation_results: Array[Dictionary] = []
    generated_maze.connect(
        &"maze_generated",
        func(_seed: int, result: Dictionary) -> void:
            automatic_generation_results.append(result)
    )
    generated_maze.set("_generation_queued", false)
    automatic_content_configuration.set(
        "treasure_pile_count",
        int(content_configuration.get("treasure_pile_count")) + 1
    )
    var settings_change_queued_regeneration := bool(
        generated_maze.get("_generation_queued")
    )
    generated_maze.set("_last_regeneration_request_milliseconds", 0)
    generated_maze.call("_run_queued_regeneration")
    var automatic_wall_cells_after := walls.get_used_cells()
    automatic_wall_cells_after.sort()
    var automatic_result := automatic_generation_results[-1] \
        if not automatic_generation_results.is_empty() else {}
    var automatic_plan := automatic_result.get("content_plan", {}) as Dictionary
    passed = _expect(
        settings_change_queued_regeneration \
            and automatic_generation_results.size() == 1 \
            and automatic_wall_cells_before == automatic_wall_cells_after \
            and automatic_baseline_result.get("player_cell") \
                == automatic_result.get("player_cell") \
            and automatic_baseline_result.get("vampire_cell") \
                == automatic_result.get("vampire_cell") \
            and automatic_baseline_result.get("end_gate_cell") \
                == automatic_result.get("end_gate_cell") \
            and automatic_baseline_plan.get("doors", []) \
                == automatic_plan.get("doors", []) \
            and automatic_baseline_plan.get("keys", []) \
                == automatic_plan.get("keys", []) \
            and (automatic_result.get("errors", []) as Array).is_empty() \
            and (automatic_plan.get("treasure_caches", []) as Array).size() \
                == int(automatic_content_configuration.get("treasure_pile_count")),
        "content setting changes regenerate automatically without changing the seeded maze layout"
    ) and passed

    var changed_connection_percent := float(
        automatic_configuration.get("internal_connection_percent")
    ) + 5.0
    automatic_configuration.set(
        "internal_connection_percent",
        changed_connection_percent
    )
    var layout_change_queued_regeneration := bool(
        generated_maze.get("_generation_queued")
    )
    generated_maze.set("_last_regeneration_request_milliseconds", 0)
    generated_maze.call("_run_queued_regeneration")
    var rebuilt_wall_cells := walls.get_used_cells()
    rebuilt_wall_cells.sort()
    var rebuilt_result := automatic_generation_results[-1] \
        if automatic_generation_results.size() >= 2 else {}
    passed = _expect(
        layout_change_queued_regeneration \
            and automatic_generation_results.size() == 2 \
            and rebuilt_wall_cells != automatic_wall_cells_after \
            and is_equal_approx(
                float(rebuilt_result.get("internal_connection_percent", -1.0)),
                changed_connection_percent
            ) \
            and (rebuilt_result.get("errors", []) as Array).is_empty(),
        "maze layout setting changes rebuild immediately for editor feedback"
    ) and passed

    generated_maze.free()
    return passed


func _test_vampire_maze_exit_key_requires_exploration() -> bool:
    var generated_maze := VAMPIRE_GENERATED_MAZE_SCENE.instantiate() as Node3D
    root.add_child(generated_maze)
    var player := TestGeneratedPlayer.new()
    var vampire := CharacterBody3D.new()
    generated_maze.add_child(player)
    generated_maze.add_child(vampire)
    var result := generated_maze.call(
        "generate_from_config",
        generated_maze.get("configuration") as Resource,
        1730,
        player,
        vampire
    ) as Dictionary
    var plan := result.get("content_plan", {}) as Dictionary
    var passed := _expect(
        (result.get("errors", []) as Array).is_empty() \
            and _generated_plan_keys_are_reachable(plan, result) \
            and _generated_exit_key_requires_exploration(plan, result),
        "the generated gold gate key is reachable only after leaving the direct exit route"
    )
    generated_maze.free()
    return passed


func _generated_plan_keys_are_reachable(content_plan: Dictionary, maze_result: Dictionary) -> bool:
    var walkable := {}
    for cell_value in maze_result.get("floor_cells", []):
        walkable[cell_value as Vector2i] = true
    var player_cell_3d := maze_result.get("player_cell") as Vector3i
    var end_gate_cell_3d := maze_result.get("end_gate_cell") as Vector3i
    var player_cell := Vector2i(player_cell_3d.x, player_cell_3d.z)
    var end_gate_cell := Vector2i(end_gate_cell_3d.x, end_gate_cell_3d.z)
    var doors := content_plan.get("doors", []) as Array
    var keys := content_plan.get("keys", []) as Array

    for door_index in doors.size():
        var blocked := {}
        for future_index in range(door_index, doors.size()):
            var future_door := doors[future_index] as Dictionary
            for blocked_cell in future_door.get("blocked_cells", []):
                blocked[blocked_cell as Vector2i] = true
        var reachable := _get_test_reachable_cells(player_cell, walkable, blocked)
        var matching_key_cell := Vector2i(-1, -1)
        for key_value in keys:
            var key := key_value as Dictionary
            if int(key["unlocks_door_index"]) == door_index:
                matching_key_cell = key["cell"] as Vector2i
                break
        if matching_key_cell == Vector2i(-1, -1) or not reachable.has(matching_key_cell):
            return false

    var all_reachable := _get_test_reachable_cells(player_cell, walkable, {})
    var exit_key_reachable := false
    for key_value in keys:
        var key := key_value as Dictionary
        if int(key["unlocks_door_index"]) == doors.size():
            exit_key_reachable = all_reachable.has(key["cell"] as Vector2i)
            break
    return exit_key_reachable and all_reachable.has(end_gate_cell)


func _generated_exit_key_requires_exploration(
    content_plan: Dictionary,
    maze_result: Dictionary
) -> bool:
    var main_path := content_plan.get("main_path", []) as Array
    var keys := content_plan.get("keys", []) as Array
    var doors := content_plan.get("doors", []) as Array
    var end_gate_cell_3d := maze_result.get("end_gate_cell") as Vector3i
    var end_gate_cell := Vector2i(end_gate_cell_3d.x, end_gate_cell_3d.z)
    var player_cell_3d := maze_result.get("player_cell") as Vector3i
    var player_cell := Vector2i(player_cell_3d.x, player_cell_3d.z)
    var walkable := {}
    for cell_value in maze_result.get("floor_cells", []):
        walkable[cell_value as Vector2i] = true

    var exit_key_cell := Vector2i(-1, -1)
    var exit_key_is_off_main_path := false
    for key_value in keys:
        var key := key_value as Dictionary
        if int(key["unlocks_door_index"]) != doors.size():
            continue
        exit_key_cell = key["cell"] as Vector2i
        exit_key_is_off_main_path = bool(key.get("off_main_path", false))
        break
    if exit_key_cell == Vector2i(-1, -1) \
            or main_path.has(exit_key_cell) \
            or not exit_key_is_off_main_path:
        return false

    var route_from_key_to_gate := _get_test_shortest_path(
        exit_key_cell,
        end_gate_cell,
        walkable,
        {}
    )
    var reachable_before_unlocking_gate := _get_test_reachable_cells(
        player_cell,
        walkable,
        {end_gate_cell: true}
    )
    return reachable_before_unlocking_gate.has(exit_key_cell) \
        and route_from_key_to_gate.size() - 1 \
        >= VAMPIRE_GENERATED_CONTENT_PLANNER.MIN_EXIT_KEY_DISTANCE_FROM_GATE_TILES


func _get_test_reachable_cells(
    start: Vector2i,
    walkable: Dictionary,
    blocked: Dictionary
) -> Dictionary:
    var reachable := {start: true}
    var pending: Array[Vector2i] = [start]
    var read_index := 0
    while read_index < pending.size():
        var current := pending[read_index]
        read_index += 1
        for direction in [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]:
            var neighbour: Vector2i = current + direction
            if not walkable.has(neighbour) or blocked.has(neighbour) or reachable.has(neighbour):
                continue
            reachable[neighbour] = true
            pending.append(neighbour)
    return reachable


func _get_test_shortest_path(
    start: Vector2i,
    destination: Vector2i,
    walkable: Dictionary,
    blocked: Dictionary
) -> Array[Vector2i]:
    var previous := {start: start}
    var pending: Array[Vector2i] = [start]
    var read_index := 0
    while read_index < pending.size():
        var current := pending[read_index]
        read_index += 1
        if current == destination:
            break
        for direction in [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]:
            var neighbour: Vector2i = current + direction
            if not walkable.has(neighbour) \
                    or blocked.has(neighbour) \
                    or previous.has(neighbour):
                continue
            previous[neighbour] = current
            pending.append(neighbour)
    if not previous.has(destination):
        return []

    var path: Array[Vector2i] = [destination]
    var cursor := destination
    while cursor != start:
        cursor = previous[cursor] as Vector2i
        path.append(cursor)
    path.reverse()
    return path


func _test_vampire_maze_minimap_shows_all_shortest_routes() -> bool:
    var source_camera := Camera3D.new()
    source_camera.current = true
    root.add_child(source_camera)

    var level := Node3D.new()
    var player := Node3D.new()
    player.name = "Player"
    var gate := Node3D.new()
    gate.name = "LockedGate"
    var walls := GridMap.new()
    walls.name = "PNGGridMap"
    var wall_library := MeshLibrary.new()
    wall_library.create_item(0)
    walls.mesh_library = wall_library
    walls.set_cell_item(Vector3i(1, 0, 1), 0)
    var floor := GridMap.new()
    floor.name = "PNGFloorGridMap"
    var floor_library := MeshLibrary.new()
    floor_library.create_item(0)
    floor.mesh_library = floor_library
    for x_coordinate in 3:
        for z_coordinate in 3:
            floor.set_cell_item(Vector3i(x_coordinate, 0, z_coordinate), 0)
    player.position = floor.map_to_local(Vector3i(0, 0, 1))
    gate.position = floor.map_to_local(Vector3i(2, 0, 1))
    var route_overlay := VAMPIRE_MINIMAP_ROUTE_SCENE.instantiate() as MultiMeshInstance3D

    level.add_child(player)
    level.add_child(gate)
    level.add_child(walls)
    level.add_child(floor)
    level.add_child(route_overlay)
    root.add_child(level)

    var initial_cells := route_overlay.call("get_highlighted_cells") as Array[Vector3i]
    var minimap := MINIMAP_VIEW_SCRIPT.new() as Control
    root.add_child(minimap)
    var minimap_cull_mask := int(minimap.call("_get_source_cull_mask"))
    var passed := _expect(
        initial_cells.size() == 8 \
            and initial_cells.has(Vector3i(1, 0, 0)) \
            and initial_cells.has(Vector3i(1, 0, 2)),
        "Vampire Maze minimap colours every equal-shortest route to the gate"
    ) and _expect(
        route_overlay.multimesh.instance_count == initial_cells.size(),
        "Vampire Maze route overlay draws one coloured tile per route cell"
    ) and _expect(
        (source_camera.cull_mask & TEST_MINIMAP_ROUTE_VISUAL_LAYER) == 0 \
            and (minimap_cull_mask & TEST_MINIMAP_ROUTE_VISUAL_LAYER) != 0,
        "Vampire Maze route tiles render on the minimap but not the gameplay camera"
    )

    player.position = floor.map_to_local(Vector3i.ZERO)
    route_overlay.call("_process", 0.016)
    var moved_cells := route_overlay.call("get_highlighted_cells") as Array[Vector3i]
    passed = _expect(
        moved_cells.size() == 4 \
            and moved_cells.has(Vector3i.ZERO) \
            and not moved_cells.has(Vector3i(0, 0, 2)),
        "Vampire Maze minimap routes update when the player enters another floor cell"
    ) and passed

    minimap.free()
    level.free()
    source_camera.free()
    return passed


func _test_skeleton_contact_uses_non_fire_death() -> bool:
    var skeleton := SKELETON_SCENE.instantiate()
    var victim := TestSkeletonVictim.new()
    skeleton.call("_kill_body_if_player", victim)
    var passed := _expect(
        victim.killed_by_enemy and not victim.killed_by_fire,
        "skeleton contact selects an ordinary enemy death instead of a fire death"
    )
    skeleton.free()
    victim.free()
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


func _test_skeleton_uses_dedicated_movement_audio() -> bool:
    var skeleton := SKELETON_SCENE.instantiate()
    skeleton.set_physics_process(false)
    skeleton.set("spawn_time", 10.0)
    root.add_child(skeleton)

    var footstep_sounds := skeleton.get("footstep_sounds") as Array[AudioStream]
    skeleton.call("_play_footstep", float(skeleton.get("shuffle_speed")))
    var path_follow := skeleton.get_node("PathFollow3D") as PathFollow3D
    var footstep_audio := path_follow.get_node_or_null("FootstepAudio") as AudioStreamPlayer3D

    skeleton.call("_start_drop_in")
    var drop_pivot := skeleton.get_node("PathFollow3D/DropPivot") as Node3D
    var drop_interval := float(skeleton.get("drop_duration")) * 0.25
    var drop_distances: Array[float] = []
    for interval_index in range(4):
        var prior_height := drop_pivot.position.y
        skeleton.call("_update_drop_in", drop_interval)
        drop_distances.append(prior_height - drop_pivot.position.y)
    var landing_audio := (
        path_follow.get_node_or_null("SkeletonLandingAudio") as AudioStreamPlayer3D
    )
    var passed := _expect(
        footstep_sounds.size() == 1 \
            and footstep_sounds[0] is AudioStreamMP3 \
            and footstep_audio != null \
            and footstep_audio.stream == footstep_sounds[0] \
            and footstep_audio.bus == GDAudio.SFX_BUS,
        "skeleton patrol steps use the dedicated spatial footstep sample"
    ) and _expect(
        drop_distances[0] < drop_distances[1] \
            and drop_distances[1] < drop_distances[2] \
            and drop_distances[2] < drop_distances[3],
        "a skeleton's visible spawn drop accelerates continuously into the floor"
    ) and _expect(
        landing_audio != null \
            and landing_audio.stream == skeleton.get("landing_sound") \
            and landing_audio.bus == GDAudio.SFX_BUS \
            and is_equal_approx(landing_audio.volume_db, 4.0) \
            and is_equal_approx(landing_audio.max_distance, 48.0) \
            and is_equal_approx(landing_audio.unit_size, 16.0),
        "a skeleton's visible spawn landing uses an audible spatial impact sample"
    )

    skeleton.queue_free()
    return passed


func _test_zombie_spawn_uses_existing_enemy_landing_audio() -> bool:
    var zombie := ZOMBIE_SCENE.instantiate()
    zombie.set("spawn_time", 10.0)
    root.add_child(zombie)
    zombie.set_physics_process(false)
    var zombie_body := zombie.get_node("ZombieBody") as CharacterBody3D
    var no_audio_before_drop := zombie_body.get_node_or_null("ZombieLandingAudio") == null

    zombie.call("_start_drop_in")
    zombie.call("_finish_drop_in")
    var landing_audio := zombie_body.get_node_or_null("ZombieLandingAudio") \
        as AudioStreamPlayer3D
    var passed := _expect(
        no_audio_before_drop,
        "an authored zombie does not play landing audio before its visible spawn drop"
    ) and _expect(
        landing_audio != null \
            and landing_audio.stream == zombie.get("landing_sound") \
            and landing_audio.bus == GDAudio.SFX_BUS \
            and is_equal_approx(landing_audio.volume_db, 4.0) \
            and is_equal_approx(landing_audio.max_distance, 48.0) \
            and is_equal_approx(landing_audio.unit_size, 16.0),
        "a zombie spawn drop plays the existing generic enemy landing sample"
    )
    zombie.queue_free()
    return passed


func _test_ground_enemies_block_each_other() -> bool:
    var skeleton := SKELETON_SCENE.instantiate()
    skeleton.set_physics_process(false)
    skeleton.set("has_landed", true)
    root.add_child(skeleton)

    var other_skeleton := SKELETON_SCENE.instantiate()
    other_skeleton.set_physics_process(false)
    other_skeleton.set("has_landed", true)
    other_skeleton.position.x = 0.45
    root.add_child(other_skeleton)

    var zombie := ZOMBIE_SCENE.instantiate()
    zombie.set_physics_process(false)
    root.add_child(zombie)
    var player := PLAYER_SCENE.instantiate() as GDPlayer
    player.set_physics_process(false)
    root.add_child(player)
    await physics_frame

    var skeleton_body := skeleton.get_node(
        "PathFollow3D/DropPivot/SkeletonBody"
    ) as AnimatableBody3D
    var zombie_body := zombie.get_node("ZombieBody") as CharacterBody3D
    var path_follow := skeleton.get_node("PathFollow3D") as PathFollow3D
    var enemy_collision_mask := int(skeleton.get("enemy_collision_mask"))
    var detects_skeleton_ahead := bool(skeleton.call(
        "_would_hit_map_collision",
        path_follow.progress + 0.01,
        0.01
    ))
    var passed := _expect(
        skeleton_body.collision_layer != 0,
        "skeletons expose an authored enemy collision body"
    ) and _expect(
        (enemy_collision_mask & skeleton_body.collision_layer) != 0,
        "skeleton patrol probes include other skeletons"
    ) and _expect(
        (enemy_collision_mask & zombie_body.collision_layer) != 0,
        "skeleton patrol probes include zombies"
    ) and _expect(
        (zombie_body.collision_mask & skeleton_body.collision_layer) != 0,
        "zombie bodies collide with skeleton bodies"
    ) and _expect(
        (player.collision_mask & skeleton_body.collision_layer) == 0,
        "skeleton avoidance bodies do not create invisible obstacles for the player"
    ) and _expect(
        detects_skeleton_ahead,
        "skeletons reverse before overlapping another skeleton"
    )

    skeleton.queue_free()
    other_skeleton.queue_free()
    zombie.queue_free()
    player.queue_free()
    return passed


func _test_ground_enemies_fall_before_moving() -> bool:
    var floor_body := StaticBody3D.new()
    floor_body.collision_layer = 1
    var floor_shape := CollisionShape3D.new()
    var floor_box := BoxShape3D.new()
    floor_box.size = Vector3(12.0, 0.2, 12.0)
    floor_shape.shape = floor_box
    floor_shape.position.y = -0.1
    floor_body.add_child(floor_shape)
    root.add_child(floor_body)

    var skeleton := SKELETON_SCENE.instantiate()
    skeleton.position = Vector3(0.0, 2.0, 0.0)
    root.add_child(skeleton)

    var zombie := ZOMBIE_SCENE.instantiate()
    zombie.position = Vector3(3.0, 2.0, 0.0)
    root.add_child(zombie)
    var zombie_body := zombie.get_node("ZombieBody") as CharacterBody3D

    var low_skeleton := SKELETON_SCENE.instantiate()
    low_skeleton.position = Vector3(-2.0, -0.08, 0.0)
    root.add_child(low_skeleton)

    var low_zombie := ZOMBIE_SCENE.instantiate()
    low_zombie.position = Vector3(2.0, -0.08, 2.0)
    root.add_child(low_zombie)
    var low_zombie_body := low_zombie.get_node("ZombieBody") as CharacterBody3D

    await physics_frame
    var airborne_enemies_remained_above_floor: bool = skeleton.global_position.y > 1.0 \
        and zombie_body.global_position.y > 1.0
    for frame_index in range(3):
        await physics_frame
    var low_skeleton_shifted_up: bool = bool(low_skeleton.get("has_landed")) \
        and low_skeleton.get_node("PathFollow3D").global_position.y >= -0.001
    var low_zombie_shifted_up := low_zombie_body.global_position.y >= -0.001
    var skeleton_start_x := float(skeleton.global_position.x)
    var zombie_start_x := float(zombie_body.global_position.x)
    for frame_index in range(10):
        await physics_frame

    var stayed_on_patrol_start_while_falling := (
        is_equal_approx(skeleton.global_position.x, skeleton_start_x)
        and is_equal_approx(zombie_body.global_position.x, zombie_start_x)
    )

    var falling_skeleton_played_landing_audio := false
    for frame_index in range(80):
        await physics_frame
        falling_skeleton_played_landing_audio = (
            falling_skeleton_played_landing_audio
            or skeleton.get_node_or_null("PathFollow3D/SkeletonLandingAudio") != null
        )

    var passed := _expect(
        airborne_enemies_remained_above_floor,
        "ground enemies spawned in the air are not snapped down to the floor"
    ) and _expect(
        low_skeleton_shifted_up,
        "skeletons spawned slightly below the floor are shifted up before falling"
    ) and _expect(
        low_zombie_shifted_up,
        "zombies spawned slightly below the floor are shifted up before falling"
    ) and _expect(
        stayed_on_patrol_start_while_falling,
        "ground enemies do not follow their patrol while falling"
    ) and _expect(
        bool(skeleton.get("has_landed")) and absf(skeleton.global_position.y) <= 0.01,
        "a skeleton placed in mid-air falls to the floor before patrolling"
    ) and _expect(
        falling_skeleton_played_landing_audio,
        "a skeleton falling from mid-air plays its landing sound on floor impact"
    ) and _expect(
        low_skeleton.get_node_or_null("PathFollow3D/SkeletonLandingAudio") == null,
        "a skeleton's tiny initial floor correction does not play a landing sound"
    ) and _expect(
        zombie_body.is_on_floor() and absf(zombie_body.global_position.y) <= 0.02,
        "a zombie placed in mid-air falls to the floor even while its AI is waiting"
    )

    skeleton.queue_free()
    zombie.queue_free()
    low_skeleton.queue_free()
    low_zombie.queue_free()
    floor_body.queue_free()
    return passed


func _test_enemies_use_fake_shadows_without_warning_light_blobs() -> bool:
    var zombie := ZOMBIE_SCENE.instantiate()
    var skeleton := SKELETON_SCENE.instantiate()
    root.add_child(zombie)
    root.add_child(skeleton)

    var zombie_character := zombie.get_node("ZombieBody/DropPivot/Pivot/Character")
    var skeleton_character := skeleton.get_node("PathFollow3D/DropPivot/Pivot/Character")
    var zombie_shadow := zombie.get_node_or_null("ZombieBody/ZombieShadow") as GeometryInstance3D
    var skeleton_shadow := (
        skeleton.get_node_or_null("PathFollow3D/SkeletonShadow") as GeometryInstance3D
    )
    var zombie_light := zombie.get_node("ZombieBody/DropPivot/Pivot/ZombieLight") as OmniLight3D
    var skeleton_light := (
        skeleton.get_node("PathFollow3D/DropPivot/Pivot/SkeletonLight") as OmniLight3D
    )
    var passed := _expect(
        zombie_shadow != null \
            and zombie_shadow.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_OFF,
        "zombie scene retains its fake ground shadow"
    ) and _expect(
        skeleton_shadow != null \
            and skeleton_shadow.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_OFF,
        "skeleton scene retains its fake ground shadow"
    ) and _expect(
        _all_geometry_casts_normal_shadows(zombie_character),
        "zombie model geometry casts normal light shadows"
    ) and _expect(
        _all_geometry_casts_normal_shadows(skeleton_character),
        "skeleton model geometry casts normal light shadows"
    ) and _expect(
        _light_illuminates_but_does_not_shadow_geometry(zombie_light, zombie_character),
        "zombie warning light illuminates its model without using it as a shadow caster"
    ) and _expect(
        _light_illuminates_but_does_not_shadow_geometry(skeleton_light, skeleton_character),
        "skeleton warning light illuminates its model without using it as a shadow caster"
    ) and _expect(
        zombie_light.shadow_enabled and (zombie_light.shadow_caster_mask & 1) == 1,
        "zombie warning light retains shadows from level geometry"
    ) and _expect(
        skeleton_light.shadow_enabled and (skeleton_light.shadow_caster_mask & 1) == 1,
        "skeleton warning light retains shadows from level geometry"
    )

    zombie.queue_free()
    skeleton.queue_free()
    return passed


func _all_geometry_casts_normal_shadows(node: Node) -> bool:
    var geometry_instances: Array[GeometryInstance3D] = []
    _collect_shadow_test_geometry(node, geometry_instances)
    if geometry_instances.is_empty():
        return false

    for geometry in geometry_instances:
        if geometry.cast_shadow != GeometryInstance3D.SHADOW_CASTING_SETTING_ON:
            return false

    return true


func _all_geometry_has_shadow_mode(node: Node, shadow_mode: int) -> bool:
    var geometry_instances: Array[GeometryInstance3D] = []
    _collect_shadow_test_geometry(node, geometry_instances)
    if geometry_instances.is_empty():
        return false

    for geometry in geometry_instances:
        if geometry.cast_shadow != shadow_mode:
            return false

    return true


func _light_illuminates_but_does_not_shadow_geometry(light: Light3D, node: Node) -> bool:
    var geometry_instances: Array[GeometryInstance3D] = []
    _collect_shadow_test_geometry(node, geometry_instances)
    if geometry_instances.is_empty():
        return false

    for geometry in geometry_instances:
        if (light.light_cull_mask & geometry.layers) != geometry.layers \
                or (light.shadow_caster_mask & geometry.layers) != 0:
            return false

    return true


func _collect_shadow_test_geometry(
        node: Node,
        geometry_instances: Array[GeometryInstance3D]
) -> void:
    if node is GeometryInstance3D:
        geometry_instances.append(node as GeometryInstance3D)

    for child in node.get_children():
        _collect_shadow_test_geometry(child, geometry_instances)


func _test_gridmap_repair_uses_configured_connection_groups() -> bool:
    var settings: Resource = PNG_TO_GRIDMAP_SETTINGS.new()
    var mapping: Resource = PNG_TO_GRIDMAP_COLOR_MAPPING.new()
    mapping.autotile_enabled = true
    mapping.autotile_connectivity_group = "walls"
    mapping.base_item_ref = "wall-base"
    mapping.solo_item_ref = "wall-solo"
    mapping.end_item_ref = "wall-end"
    mapping.corner_item_ref = "wall-corner"
    mapping.tee_item_ref = "wall-tee"
    mapping.cross_item_ref = "wall-cross"
    var floor_mapping: Resource = PNG_TO_GRIDMAP_COLOR_MAPPING.new()
    floor_mapping.autotile_enabled = true
    floor_mapping.autotile_connectivity_group = "floors"
    floor_mapping.base_item_ref = "floor-base"
    floor_mapping.solo_item_ref = "floor-solo"
    var alternate_wall_mapping: Resource = PNG_TO_GRIDMAP_COLOR_MAPPING.new()
    alternate_wall_mapping.autotile_enabled = true
    alternate_wall_mapping.autotile_connectivity_group = "walls"
    alternate_wall_mapping.base_item_ref = "wall-alt-base"
    alternate_wall_mapping.end_item_ref = "wall-alt-end"
    var mappings: Array[Resource] = [mapping, floor_mapping, alternate_wall_mapping]
    settings.color_mappings = mappings

    var library := MeshLibrary.new()
    _add_test_mesh_library_item(library, TestAutotileItem.Base, "wall-base")
    _add_test_mesh_library_item(library, TestAutotileItem.Solo, "wall-solo")
    _add_test_mesh_library_item(library, TestAutotileItem.End, "wall-end")
    _add_test_mesh_library_item(library, TestAutotileItem.Corner, "wall-corner")
    _add_test_mesh_library_item(library, TestAutotileItem.Tee, "wall-tee")
    _add_test_mesh_library_item(library, TestAutotileItem.Cross, "wall-cross")
    _add_test_mesh_library_item(library, TestAutotileItem.FloorBase, "floor-base")
    _add_test_mesh_library_item(library, TestAutotileItem.FloorSolo, "floor-solo")
    _add_test_mesh_library_item(library, TestAutotileItem.AltWallBase, "wall-alt-base")
    _add_test_mesh_library_item(library, TestAutotileItem.AltWallEnd, "wall-alt-end")

    var grid_map := GridMap.new()
    grid_map.mesh_library = library
    grid_map.set_cell_item(Vector3i(0, 0, 0), TestAutotileItem.Base)
    grid_map.set_cell_item(Vector3i(1, 0, 0), TestAutotileItem.Base)
    grid_map.set_cell_item(Vector3i(2, 0, 0), TestAutotileItem.End)
    grid_map.set_cell_item(Vector3i(3, 0, 0), TestAutotileItem.AltWallBase)
    grid_map.set_cell_item(Vector3i(0, 0, -1), TestAutotileItem.FloorBase)

    var repairer: RefCounted = PNG_TO_GRIDMAP_REPAIRER.new()
    var plan: Dictionary = repairer.build_plan(settings, grid_map, {})
    var errors: Array = plan["errors"]
    var changes: Array = plan["changes"]
    var left_change := _gridmap_repair_change_for_cell(changes, Vector3i(0, 0, 0))
    var right_change := _gridmap_repair_change_for_cell(changes, Vector3i(2, 0, 0))
    var warnings: Array = plan["warnings"]

    var passed := _expect(errors.is_empty(), "GridMap repair accepts configured autotile mappings") \
        and _expect(
            int(left_change.get("item_id", GridMap.INVALID_CELL_ITEM)) == TestAutotileItem.End,
            "GridMap repair does not connect different configured tile types"
        ) \
        and _expect(
            int(right_change.get("item_id", GridMap.INVALID_CELL_ITEM)) == TestAutotileItem.Base,
            "GridMap repair connects mappings in the same configured tile type"
        ) \
        and _expect(warnings.is_empty(), "GridMap repair recognises every configured autotile cell")
    grid_map.free()
    return passed


func _test_gridmap_repair_merges_equivalent_configurations() -> bool:
    var settings: Resource = PNG_TO_GRIDMAP_SETTINGS.new()
    var first_mapping: Resource = PNG_TO_GRIDMAP_COLOR_MAPPING.new()
    first_mapping.colour = Color.BLACK
    first_mapping.autotile_enabled = true
    first_mapping.base_item_ref = "wall-base"
    first_mapping.end_item_ref = "wall-end"
    var duplicate_mapping: Resource = PNG_TO_GRIDMAP_COLOR_MAPPING.new()
    duplicate_mapping.colour = Color.RED
    duplicate_mapping.autotile_enabled = true
    duplicate_mapping.base_item_ref = "wall-base"
    duplicate_mapping.end_item_ref = "wall-end"
    var mappings: Array[Resource] = [first_mapping, duplicate_mapping]
    settings.color_mappings = mappings

    var library := MeshLibrary.new()
    _add_test_mesh_library_item(library, TestAutotileItem.Base, "wall-base")
    _add_test_mesh_library_item(library, TestAutotileItem.End, "wall-end")
    var grid_map := GridMap.new()
    grid_map.mesh_library = library
    grid_map.set_cell_item(Vector3i.ZERO, TestAutotileItem.Base)
    grid_map.set_cell_item(Vector3i.RIGHT, TestAutotileItem.Base)

    var repairer: RefCounted = PNG_TO_GRIDMAP_REPAIRER.new()
    var plan: Dictionary = repairer.build_plan(settings, grid_map, {})
    var errors: Array = plan["errors"]
    var changes: Array = plan["changes"]
    var passed := _expect(
        errors.is_empty(),
        "GridMap repair accepts duplicate colours with equivalent autotile configuration"
    ) and _expect(
        changes.size() == 2,
        "GridMap repair replaces base pieces with configured wall ends"
    )
    grid_map.free()
    return passed


func _test_gridmap_repair_preserves_only_matching_alternatives() -> bool:
    var settings: Resource = PNG_TO_GRIDMAP_SETTINGS.new()
    var mapping: Resource = PNG_TO_GRIDMAP_COLOR_MAPPING.new()
    mapping.autotile_enabled = true
    mapping.base_item_ref = "wall-base"
    mapping.end_item_ref = "wall-end"
    mapping.tee_item_ref = "wall-tee"
    var alternative: Resource = PNG_TO_GRIDMAP_ALTERNATIVE.new()
    alternative.item_ref = "wall-sides"
    alternative.connection_shape = PNG_TO_GRIDMAP_ALTERNATIVE.ConnectionShape.STRAIGHT
    var alternatives: Array[Resource] = [alternative]
    mapping.autotile_alternatives = alternatives
    var mappings: Array[Resource] = [mapping]
    settings.color_mappings = mappings

    var library := MeshLibrary.new()
    _add_test_mesh_library_item(library, TestAutotileItem.Base, "wall-base")
    _add_test_mesh_library_item(library, TestAutotileItem.End, "wall-end")
    _add_test_mesh_library_item(library, TestAutotileItem.Tee, "wall-tee")
    _add_test_mesh_library_item(library, TestAutotileItem.AltWallBase, "wall-sides")
    var grid_map := GridMap.new()
    grid_map.mesh_library = library
    grid_map.set_cell_item(Vector3i.LEFT, TestAutotileItem.Base)
    grid_map.set_cell_item(Vector3i.ZERO, TestAutotileItem.AltWallBase)
    grid_map.set_cell_item(Vector3i.RIGHT, TestAutotileItem.Base)

    var repairer: RefCounted = PNG_TO_GRIDMAP_REPAIRER.new()
    var sideways_basis := Basis.IDENTITY.rotated(Vector3.UP, PI * 0.5)
    var sideways_orientation := grid_map.get_orthogonal_index_from_basis(sideways_basis)
    var fixed_orientation := grid_map.get_orthogonal_index_from_basis(
        Basis.IDENTITY.rotated(Vector3.UP, PI)
    )
    grid_map.set_cell_item(Vector3i.ZERO, TestAutotileItem.AltWallBase, sideways_orientation)
    var orientation_plan: Dictionary = repairer.build_plan(settings, grid_map, {})
    var orientation_change := _gridmap_repair_change_for_cell(orientation_plan["changes"], Vector3i.ZERO)
    grid_map.set_cell_item(
        Vector3i.ZERO,
        TestAutotileItem.AltWallBase,
        fixed_orientation
    )
    var matching_plan: Dictionary = repairer.build_plan(settings, grid_map, {})
    var matching_change := _gridmap_repair_change_for_cell(matching_plan["changes"], Vector3i.ZERO)
    grid_map.set_cell_item(Vector3i(0, 0, -1), TestAutotileItem.Base)
    var tee_plan: Dictionary = repairer.build_plan(settings, grid_map, {})
    var tee_change := _gridmap_repair_change_for_cell(tee_plan["changes"], Vector3i.ZERO)

    var passed := _expect(
        int(orientation_change.get("item_id", GridMap.INVALID_CELL_ITEM)) == TestAutotileItem.AltWallBase,
        "GridMap repair keeps a correctly shaped alternative while repairing its orientation"
    ) and _expect(
        int(orientation_change.get("orientation", -1)) == fixed_orientation,
        "GridMap repair rotates a placed alternative to match its neighbours"
    ) and _expect(
        matching_change.is_empty(),
        "GridMap repair preserves an alternative whose configured joins match"
    ) and _expect(
        int(tee_change.get("item_id", GridMap.INVALID_CELL_ITEM)) == TestAutotileItem.Tee,
        "GridMap repair replaces a straight alternative when it needs a tee junction"
    )
    grid_map.free()
    return passed


func _test_gridmap_repair_matches_updated_wall_mesh_orientations() -> bool:
    var settings: Resource = PNG_TO_GRIDMAP_SETTINGS.new()
    var mapping: Resource = PNG_TO_GRIDMAP_COLOR_MAPPING.new()
    mapping.autotile_enabled = true
    mapping.base_item_ref = "wall-base"
    mapping.solo_item_ref = "wall-solo"
    mapping.end_item_ref = "wall-end"
    mapping.corner_item_ref = "wall-corner"
    mapping.corner_rotation_offset = 1
    mapping.tee_item_ref = "wall-tee"
    mapping.cross_item_ref = "wall-cross"
    settings.color_mappings = [mapping] as Array[Resource]

    var library := MeshLibrary.new()
    _add_test_mesh_library_item(library, TestAutotileItem.Base, "wall-base")
    _add_test_mesh_library_item(library, TestAutotileItem.Solo, "wall-solo")
    _add_test_mesh_library_item(library, TestAutotileItem.End, "wall-end")
    _add_test_mesh_library_item(library, TestAutotileItem.Corner, "wall-corner")
    _add_test_mesh_library_item(library, TestAutotileItem.Tee, "wall-tee")
    _add_test_mesh_library_item(library, TestAutotileItem.Cross, "wall-cross")
    var grid_map := GridMap.new()
    grid_map.mesh_library = library
    var repairer: RefCounted = PNG_TO_GRIDMAP_REPAIRER.new()
    var passed := true
    var shape_specs: Array[Dictionary] = [
        {
            "item_id": TestAutotileItem.Corner,
            "source_mask": PNG_TO_GRIDMAP_AUTOTILE.WEST | PNG_TO_GRIDMAP_AUTOTILE.SOUTH,
            "world_masks": [
                PNG_TO_GRIDMAP_AUTOTILE.NORTH | PNG_TO_GRIDMAP_AUTOTILE.EAST,
                PNG_TO_GRIDMAP_AUTOTILE.EAST | PNG_TO_GRIDMAP_AUTOTILE.SOUTH,
                PNG_TO_GRIDMAP_AUTOTILE.SOUTH | PNG_TO_GRIDMAP_AUTOTILE.WEST,
                PNG_TO_GRIDMAP_AUTOTILE.WEST | PNG_TO_GRIDMAP_AUTOTILE.NORTH,
            ],
        },
        {
            "item_id": TestAutotileItem.Tee,
            "source_mask": (
                PNG_TO_GRIDMAP_AUTOTILE.EAST
                | PNG_TO_GRIDMAP_AUTOTILE.SOUTH
                | PNG_TO_GRIDMAP_AUTOTILE.WEST
            ),
            "world_masks": [
                PNG_TO_GRIDMAP_AUTOTILE.NORTH | PNG_TO_GRIDMAP_AUTOTILE.EAST | PNG_TO_GRIDMAP_AUTOTILE.SOUTH,
                PNG_TO_GRIDMAP_AUTOTILE.EAST | PNG_TO_GRIDMAP_AUTOTILE.SOUTH | PNG_TO_GRIDMAP_AUTOTILE.WEST,
                PNG_TO_GRIDMAP_AUTOTILE.SOUTH | PNG_TO_GRIDMAP_AUTOTILE.WEST | PNG_TO_GRIDMAP_AUTOTILE.NORTH,
                PNG_TO_GRIDMAP_AUTOTILE.WEST | PNG_TO_GRIDMAP_AUTOTILE.NORTH | PNG_TO_GRIDMAP_AUTOTILE.EAST,
            ],
        },
    ]
    for shape_spec: Dictionary in shape_specs:
        for world_mask: int in shape_spec["world_masks"]:
            grid_map.clear()
            grid_map.set_cell_item(Vector3i.ZERO, TestAutotileItem.Base)
            _set_gridmap_neighbours_for_mask(grid_map, world_mask)
            var plan: Dictionary = repairer.build_plan(settings, grid_map, {})
            var change := _gridmap_repair_change_for_cell(plan["changes"], Vector3i.ZERO)
            var orientation := int(change.get("orientation", -1))
            var repaired_mask := _transform_cardinal_mask(
                int(shape_spec["source_mask"]),
                grid_map.get_basis_with_orthogonal_index(orientation)
            )
            passed = _expect(
                int(change.get("item_id", GridMap.INVALID_CELL_ITEM)) == int(shape_spec["item_id"])
                    and repaired_mask == world_mask,
                "GridMap repair aligns updated corner and tee meshes for world mask %s" % world_mask
            ) and passed
    grid_map.free()
    return passed


func _test_auto_repair_watches_mapping_configuration_changes() -> bool:
    var settings: Resource = PNG_TO_GRIDMAP_SETTINGS.new()
    var mapping: Resource = PNG_TO_GRIDMAP_COLOR_MAPPING.new()
    mapping.autotile_enabled = true
    mapping.base_item_ref = "wall-base"
    mapping.corner_item_ref = "wall-corner"
    settings.color_mappings = [mapping] as Array[Resource]
    var repairer: RefCounted = PNG_TO_GRIDMAP_REPAIRER.new()
    var initial_configuration := int(repairer.configuration_fingerprint(settings, {}))
    mapping.corner_rotation_offset = 1
    var changed_configuration := int(repairer.configuration_fingerprint(settings, {}))
    var grid_map := GridMap.new()
    var watch: RefCounted = PNG_TO_GRIDMAP_AUTO_REPAIR_WATCH.new()
    var observes_initial_state: bool = not watch.should_repair(grid_map, 0, initial_configuration)
    var debounces_configuration_change: bool = not watch.should_repair(
        grid_map,
        200,
        changed_configuration
    )
    var repairs_after_debounce: bool = watch.should_repair(grid_map, 800, changed_configuration)
    watch.accept_repair(grid_map, changed_configuration)
    var passed := _expect(
        initial_configuration != changed_configuration,
        "autotile rotation edits change the repair configuration fingerprint"
    ) and _expect(
        observes_initial_state and debounces_configuration_change and repairs_after_debounce,
        "auto repair runs after mapping changes settle without requiring a GridMap paint edit"
    )
    grid_map.free()
    return passed


func _test_png_mapping_catalog_supports_manual_add_and_remove() -> bool:
    var settings: Resource = PNG_TO_GRIDMAP_SETTINGS.new()
    var colour := Color(0.25, 0.5, 0.75, 1.0)
    var key := PNGToGridMapImageGrid.colour_key(colour)
    var mapping: Resource = PNG_TO_GRIDMAP_MAPPING_CATALOG.add_mapping(settings, colour)
    var manual_keys: Array[String] = PNG_TO_GRIDMAP_MAPPING_CATALOG.ordered_keys(settings, [])
    PNG_TO_GRIDMAP_MAPPING_CATALOG.remove_mapping(settings, mapping)
    var ignored_detection: Resource = PNG_TO_GRIDMAP_MAPPING_CATALOG.ensure_detected_mapping(
        settings,
        key,
        colour
    )
    var detected_keys: Array[String] = PNG_TO_GRIDMAP_MAPPING_CATALOG.ordered_keys(
        settings,
        [key]
    )
    var stayed_unconfigured: bool = ignored_detection == null \
        and settings.color_mappings.is_empty() \
        and detected_keys == [key]
    var restored: Resource = PNG_TO_GRIDMAP_MAPPING_CATALOG.add_mapping(settings, colour)
    return _expect(
        manual_keys == [key],
        "manual colour mappings remain editable when no PNG is loaded"
    ) and _expect(
        stayed_unconfigured,
        "removed mappings stay unconfigured while their PNG colour remains visible"
    ) and _expect(
        restored != null and not settings.ignored_colour_keys.has(key),
        "an editor can restore a removed mapping from the manual controls"
    )


func _test_graveyard_wall_profile_uses_updated_mesh_offsets() -> bool:
    var settings := load(
        "res://addons/png_to_gridmap/settings/png_to_gridmap_configuration_for_graveyard.tres"
    ) as Resource
    var configured_autotiles := 0
    var passed := settings != null
    if settings == null:
        return _expect(false, "graveyard PNG-to-GridMap profile loads")
    for mapping: Resource in settings.color_mappings:
        if not mapping.autotile_enabled:
            continue
        configured_autotiles += 1
        passed = _expect(
            mapping.end_rotation_offset == 0
                and mapping.corner_rotation_offset == 1
                and mapping.tee_rotation_offset == 0,
            "graveyard wall mapping matches the updated end, corner, and tee mesh orientations"
        ) and passed
    return _expect(configured_autotiles == 2, "both graveyard wall colours use autotiling") and passed


func _set_gridmap_neighbours_for_mask(grid_map: GridMap, mask: int) -> void:
    var directions: Array[Array] = [
        [PNG_TO_GRIDMAP_AUTOTILE.NORTH, Vector3i(0, 0, -1)],
        [PNG_TO_GRIDMAP_AUTOTILE.EAST, Vector3i(1, 0, 0)],
        [PNG_TO_GRIDMAP_AUTOTILE.SOUTH, Vector3i(0, 0, 1)],
        [PNG_TO_GRIDMAP_AUTOTILE.WEST, Vector3i(-1, 0, 0)],
    ]
    for direction: Array in directions:
        if (mask & int(direction[0])) != 0:
            grid_map.set_cell_item(direction[1] as Vector3i, TestAutotileItem.Base)


func _transform_cardinal_mask(mask: int, basis: Basis) -> int:
    var result := 0
    var directions: Array[Array] = [
        [PNG_TO_GRIDMAP_AUTOTILE.NORTH, Vector3(0.0, 0.0, -1.0)],
        [PNG_TO_GRIDMAP_AUTOTILE.EAST, Vector3(1.0, 0.0, 0.0)],
        [PNG_TO_GRIDMAP_AUTOTILE.SOUTH, Vector3(0.0, 0.0, 1.0)],
        [PNG_TO_GRIDMAP_AUTOTILE.WEST, Vector3(-1.0, 0.0, 0.0)],
    ]
    for direction: Array in directions:
        if (mask & int(direction[0])) == 0:
            continue
        var transformed := basis * (direction[1] as Vector3)
        if absf(transformed.x) > absf(transformed.z):
            result |= PNG_TO_GRIDMAP_AUTOTILE.EAST \
                if transformed.x > 0.0 else PNG_TO_GRIDMAP_AUTOTILE.WEST
        else:
            result |= PNG_TO_GRIDMAP_AUTOTILE.SOUTH \
                if transformed.z > 0.0 else PNG_TO_GRIDMAP_AUTOTILE.NORTH
    return result


func _test_png_floor_gridmap_uses_non_transparent_pixels_and_safe_collision() -> bool:
    var image := Image.create(2, 2, false, Image.FORMAT_RGBA8)
    image.fill(Color.TRANSPARENT)
    image.set_pixel(0, 0, Color.RED)
    image.set_pixel(1, 0, Color(0.0, 0.0, 1.0, 0.1))
    image.set_pixel(1, 1, Color.WHITE)

    var settings: Resource = PNG_TO_GRIDMAP_SETTINGS.new()
    settings.floor_material_path = "res://Assets/environment/floors/dirt_floor.material"
    var level_root := Node3D.new()
    var source_grid_map := GridMap.new()
    source_grid_map.cell_size = Vector3.ONE
    source_grid_map.cell_center_y = true
    source_grid_map.position = Vector3(4.0, 0.0, -2.0)
    level_root.add_child(source_grid_map)

    var builder: RefCounted = PNG_TO_GRIDMAP_FLOOR_BUILDER.new()
    var result: Dictionary = builder.run(settings, image, level_root, source_grid_map)
    var errors: Array = result.get("errors", [])
    if not _expect(errors.is_empty(), "PNG floor builder accepts a valid material and image"):
        level_root.free()
        return false
    var floor_grid_map: GridMap = result["grid_map"]
    var library := floor_grid_map.mesh_library
    var item_ids := library.get_item_list()
    var floor_item_id := int(item_ids[0])
    var shapes: Array = library.get_item_shapes(floor_item_id)
    var floor_shape := shapes[0] as BoxShape3D
    var floor_shape_transform: Transform3D = shapes[1]
    var floor_mesh := library.get_item_mesh(floor_item_id) as PlaneMesh
    var floor_material := floor_mesh.material
    var player := PLAYER_SCENE.instantiate() as CharacterBody3D

    var passed := _expect(int(result["placed"]) == 3, "PNG floor uses every pixel with non-zero alpha") \
        and _expect(
            floor_grid_map.get_cell_item(Vector3i(0, 0, 1)) == GridMap.INVALID_CELL_ITEM,
            "PNG floor leaves fully transparent pixels empty"
        ) \
        and _expect(item_ids.size() == 1, "PNG floor uses one shared MeshLibrary item for batching") \
        and _expect(floor_grid_map.get_child_count() == 0, "PNG floor does not create one node per pixel") \
        and _expect(floor_grid_map.cell_octant_size == 16, "PNG floor batches cells into larger octants") \
        and _expect(
            floor_grid_map.transform == source_grid_map.transform,
            "PNG floor aligns with the selected GridMap"
        ) \
        and _expect(not floor_grid_map.cell_center_y, "PNG floor keeps its collision surface at local Y zero") \
        and _expect(floor_grid_map.collision_layer == 1, "PNG floor collides on the world layer") \
        and _expect(
            (player.collision_mask & floor_grid_map.collision_layer) != 0,
            "player collision mask includes the generated floor"
        ) \
        and _expect(floor_shape != null and floor_shape.size.y >= 0.5, "PNG floor has a substantial collision box") \
        and _expect(
            is_equal_approx(floor_shape_transform.origin.y + floor_shape.size.y * 0.5, 0.0),
            "PNG floor collision top is flush with the visible surface"
        ) \
        and _expect(
            floor_material == load("res://Assets/environment/floors/dirt_floor.material"),
            "PNG floor uses the selected authored material"
        )
    player.free()
    level_root.free()
    return passed


func _test_png_gridmap_import_disables_y_cell_centering() -> bool:
    var image := Image.create(1, 1, false, Image.FORMAT_RGBA8)
    image.fill(Color.BLACK)
    var settings: Resource = PNG_TO_GRIDMAP_SETTINGS.new()
    var mapping: Resource = PNG_TO_GRIDMAP_COLOR_MAPPING.new()
    mapping.colour = Color.BLACK
    mapping.base_item_ref = "wall-base"
    var mappings: Array[Resource] = [mapping]
    settings.color_mappings = mappings
    var library := MeshLibrary.new()
    _add_test_mesh_library_item(library, TestAutotileItem.Base, "wall-base")
    var level_root := Node3D.new()
    var importer: RefCounted = PNG_TO_GRIDMAP_IMPORTER.new()
    var result: Dictionary = importer.run(
        settings,
        image,
        level_root,
        null,
        library,
        {"wall-base": TestAutotileItem.Base},
        {},
        "FFFFFFFF"
    )
    var grid_map: GridMap = result["grid_map"]
    var passed := _expect(
        not grid_map.cell_center_y,
        "PNG GridMap import disables Y cell centering so wall bases remain grounded"
    )
    level_root.free()
    return passed


func _add_test_mesh_library_item(library: MeshLibrary, item_id: int, item_name: String) -> void:
    library.create_item(item_id)
    library.set_item_name(item_id, item_name)


func _gridmap_repair_change_for_cell(changes: Array, cell: Vector3i) -> Dictionary:
    for change: Dictionary in changes:
        if change["cell"] == cell:
            return change
    return {}


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
        and _expect(
            minimap_viewport.process_mode == Node.PROCESS_MODE_DISABLED,
            "disabled minimap stops SubViewport processing"
        ) \
        and _expect(
            minimap_viewport.render_target_update_mode == SubViewport.UPDATE_DISABLED,
            "disabled minimap stops SubViewport rendering"
        ) \
        and _expect(not minimap_camera.current, "disabled minimap camera is not current")

    minimap.queue_free()
    return passed


func _test_minimap_left_trigger_expands_and_restores_layout() -> bool:
    var minimap: Control = MINIMAP_VIEW_SCRIPT.new()
    minimap.set("settings", MINIMAP_VIEW_SETTINGS)
    var viewport_container := SubViewportContainer.new()
    viewport_container.name = "ViewportContainer"
    var minimap_viewport := SubViewport.new()
    minimap_viewport.name = "MinimapViewport"
    var minimap_camera := Camera3D.new()
    minimap_camera.name = "MinimapCamera"
    var vampire_overlay: Control = VAMPIRE_MINIMAP_OVERLAY_SCRIPT.new()
    vampire_overlay.name = "VampireOverlay"
    var status_backdrop := ColorRect.new()
    status_backdrop.name = "StatusBackdrop"
    status_backdrop.offset_top = 8.0
    var status_label := Label.new()
    status_label.name = "StatusLabel"

    minimap.add_child(viewport_container)
    viewport_container.add_child(minimap_viewport)
    minimap_viewport.add_child(minimap_camera)
    minimap.add_child(vampire_overlay)
    vampire_overlay.add_child(status_backdrop)
    status_backdrop.add_child(status_label)
    root.add_child(minimap)

    var level_root := Node3D.new()
    var level_mesh := MeshInstance3D.new()
    var level_box := BoxMesh.new()
    level_box.size = Vector3(200.0, 2.0, 80.0)
    level_mesh.mesh = level_box
    level_mesh.position = Vector3(50.0, 0.0, -20.0)
    level_root.add_child(level_mesh)
    root.add_child(level_root)
    var target := Node3D.new()
    target.position = Vector3(150.0, 0.0, -20.0)
    root.add_child(target)

    minimap.call("set_runtime_references", target, null, level_root)
    minimap.call("set_minimap_enabled", true)
    var corner_width := minimap.offset_right - minimap.offset_left
    var corner_text_hidden := not status_backdrop.visible
    var has_left_trigger := false
    for event: InputEvent in InputMap.action_get_events(&"expand_minimap"):
        if event is InputEventJoypadMotion:
            var joypad_motion := event as InputEventJoypadMotion
            has_left_trigger = joypad_motion.axis == JOY_AXIS_TRIGGER_LEFT \
                and joypad_motion.axis_value > 0.0
            if has_left_trigger:
                break

    Input.action_press(&"expand_minimap")
    var expand_event := InputEventAction.new()
    expand_event.action = &"expand_minimap"
    expand_event.pressed = true
    minimap.call("_unhandled_input", expand_event)
    minimap.call("_process", 0.016)
    var visible_size := root.get_visible_rect().size
    var expected_expanded_size := visible_size \
        - Vector2.ONE * MINIMAP_VIEW_SETTINGS.expanded_screen_margin * 2.0
    var expanded_size := Vector2(
        minimap.offset_right - minimap.offset_left + visible_size.x,
        minimap.offset_bottom - minimap.offset_top + visible_size.y
    )
    var expanded_world_size := Vector2(
        _get_camera_visible_world_width(minimap_camera, minimap),
        minimap_camera.size
    )
    var level_center := level_mesh.global_position
    var passed := _expect(has_left_trigger, "minimap expansion is mapped to the left trigger") \
        and _expect(
            corner_text_hidden,
            "corner minimap hides Vampire diagnostic text"
        ) \
        and _expect(
            minimap.call("is_minimap_expanded") as bool,
            "holding the minimap action enables the expanded layout"
        ) \
        and _expect(
            expanded_size.is_equal_approx(expected_expanded_size),
            "expanded minimap fills the viewport"
        ) \
        and _expect(
            status_label.get_theme_font_size("font_size")
                == MINIMAP_VIEW_SETTINGS.expanded_status_font_size,
            "expanded minimap enlarges Vampire diagnostic text"
        ) \
        and _expect(
            status_backdrop.visible,
            "expanded minimap reveals Vampire diagnostic text"
        ) \
        and _expect(
            viewport_container.offset_top >= status_backdrop.offset_bottom,
            "expanded minimap keeps the rendered map below its diagnostic header"
        ) \
        and _expect(
            expanded_world_size.x >= level_box.size.x
                and expanded_world_size.y >= level_box.size.z,
            "expanded minimap zooms out to contain the complete level"
        ) \
        and _expect(
            is_equal_approx(minimap_camera.global_position.x, level_center.x)
                and is_equal_approx(minimap_camera.global_position.z, level_center.z),
            "expanded minimap centres the complete level instead of tracking an edge"
        )

    Input.action_release(&"expand_minimap")
    var restore_event := InputEventAction.new()
    restore_event.action = &"expand_minimap"
    restore_event.pressed = false
    minimap.call("_unhandled_input", restore_event)
    minimap.call("_process", 0.016)
    passed = _expect(
        not (minimap.call("is_minimap_expanded") as bool),
        "releasing the minimap action restores the corner layout"
    ) and passed
    passed = _expect(
        is_equal_approx(minimap.offset_right - minimap.offset_left, corner_width),
        "restored minimap returns to its configured corner width"
    ) and passed
    passed = _expect(
        not status_backdrop.visible,
        "restored corner minimap hides Vampire diagnostic text again"
    ) and passed

    minimap.queue_free()
    level_root.queue_free()
    target.queue_free()
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
        and _expect(
            is_equal_approx(panel_width, expected_panel_width),
            "minimap width follows the configured viewport fraction"
        ) \
        and _expect(viewport_container.stretch, "minimap render target stretches to fill the visible panel content") \
        and _expect(
            minimap_camera.projection == Camera3D.PROJECTION_ORTHOGONAL,
            "minimap camera uses an orthographic top-down view"
        ) \
        and _expect(
            is_equal_approx(minimap_camera.size, level_box.size.z),
            "wide minimap fits the level depth to avoid vertical empty space"
        ) \
        and _expect(minimap_camera.size < 150.0, "minimap bounds ignore outlier light volumes") \
        and _expect(
            (source_camera.cull_mask & TEST_TEXT_OVERLAY_VISUAL_LAYER) != 0,
            "main camera keeps the text overlay visual layer"
        ) \
        and _expect(
            (minimap_camera.cull_mask & TEST_TEXT_OVERLAY_VISUAL_LAYER) == 0,
            "minimap camera hides the text overlay visual layer"
        ) \
        and _expect(minimap_environment != null, "minimap camera has its own environment override") \
        and _expect(
            is_equal_approx(minimap_environment.ambient_light_energy, MINIMAP_VIEW_SETTINGS.ambient_light_energy),
            "minimap environment has ambient light"
        ) \
        and _expect(
            is_equal_approx(minimap_camera.global_position.x, expected_clamped_x),
            "wide minimap clamps horizontally at the level edge"
        ) \
        and _expect(
            is_equal_approx(minimap_camera.global_position.z, level_center.z),
            "wide minimap keeps the full level depth visible"
        ) \
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
    var passed := _expect(
        is_equal_approx(minimap_camera.size, expected_size),
        "tall minimap fits the level width to avoid horizontal empty space"
    ) \
        and _expect(
            is_equal_approx(minimap_camera.global_position.x, level_center.x),
            "tall minimap keeps the full level width visible"
        ) \
        and _expect(
            is_equal_approx(minimap_camera.global_position.z, expected_clamped_z),
            "tall minimap clamps vertically at the level edge"
        )

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
        and _expect(
            nest.get_bat_nest_state() == BAT_NEST_SCRIPT.BatNestState.Roosting,
            "bat nest waits while the player is far away"
        ) \
        and _expect(_are_bats_visible(nest) == false, "bat nest hides bats before triggering")

    player.global_position = Vector3.ZERO
    nest._physics_process(0.016)
    passed = _expect(
        nest.get_bat_nest_state() == BAT_NEST_SCRIPT.BatNestState.Swarming,
        "bat nest starts swarming when the player is close"
    ) and passed
    passed = _expect(_are_bats_visible(nest), "bat nest shows bats after triggering") and passed
    passed = _expect(
        _are_bats_spawned_near_player(nest, player.global_position),
        "bat nest spawns bats close to the player"
    ) and passed
    passed = _expect(
        _get_flap_audio_player_count(nest) > 0,
        "bat nest plays flap audio immediately on trigger"
    ) and passed
    passed = _expect(
        _get_squeak_audio_player_count(nest) > 0,
        "bat nest plays squeak audio immediately on trigger"
    ) and passed
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
    passed = _expect(
        nest.get_bat_nest_state() == BAT_NEST_SCRIPT.BatNestState.FlyingOff,
        "bat nest switches from swarming to flying off"
    ) and passed
    passed = _expect(height_after_fly_off > height_before_fly_off, "bat nest rises while flying away") and passed
    var halfway_turn := nest._slerp_horizontal_direction(Vector3.RIGHT, Vector3.FORWARD, 0.5)
    passed = _expect(
        halfway_turn.dot(Vector3.RIGHT) > 0.5 and halfway_turn.dot(Vector3.FORWARD) > 0.5,
        "bat nest blends fly-off turn directions"
    ) and passed
    passed = _expect(
        first_bat_final_fly_direction.dot(first_bat_turn_target) > 0.9,
        "bat nest finishes fly-off turn toward escape direction"
    ) and passed
    passed = _expect(
        audio_volume_after_fade < audio_volume_before_fade,
        "bat nest fades audio during fly-off"
    ) and passed
    passed = _expect(_are_bats_flying_as_group(nest), "bat nest flies away as a group") and passed
    passed = _expect(
        animation_player.has_animation(&"combined_flap"),
        "bat nest combines separate wing animations"
    ) and passed
    passed = _expect(
        animation_player.current_animation == &"combined_flap",
        "bat nest plays the combined wing animation"
    ) and passed

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
