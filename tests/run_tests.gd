extends SceneTree

const BAT_NEST_SCRIPT := preload("res://enemies/bat_nest.gd")
const TREASURE_DEPOSIT_COFFIN_SCENE := preload("res://placeables/treasure_deposit/treasure_deposit_coffin.tscn")
const DETERMINISTIC_SEED := preload("res://game/deterministic_seed.gd")
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
const KEY_SCENE := preload("res://inventory/key.tscn")
const LEVEL_SETTINGS_SCRIPT := preload("res://levels/level_settings.gd")
const LEVEL_SELECT_SCENE := preload("res://ui/screens/level_select_screen.tscn")
const LOW_HEALTH_VIGNETTE_SCRIPT := preload("res://ui/hud/low_health_vignette.gd")
const LOCKED_GATE_SCENE := preload("res://placeables/lockables/locked_gate.tscn")
const INDOOR_LIGHTING_SCENE := preload("res://lighting/gd_indoor_lighting.tscn")
const MINIMAP_VIEW_SCRIPT := preload("res://ui/hud/minimap/minimap_view.gd")
const MINIMAP_VIEW_SETTINGS := preload("res://ui/hud/minimap/minimap_view_settings.tres")
const PANEL_SCENE := preload("res://ui/hud/panel.tscn")
const PLAYER_SCENE := preload("res://player/player.tscn")
const RUBY_ITEM := preload("res://placeables/treasure/gems/ruby_inventory.tres")
const RUBY_SCENE := preload("res://placeables/treasure/gems/ruby.tscn")
const SAPPHIRE_ITEM := preload("res://placeables/treasure/gems/sapphire_inventory.tres")
const SAPPHIRE_SCENE := preload("res://placeables/treasure/gems/sapphire.tscn")
const PNG_TO_GRIDMAP_ALTERNATIVE := preload("res://addons/png_to_gridmap/png_to_gridmap_autotile_alternative.gd")
const PNG_TO_GRIDMAP_COLOR_MAPPING := preload("res://addons/png_to_gridmap/png_to_gridmap_color_mapping.gd")
const PNG_TO_GRIDMAP_FLOOR_BUILDER := preload("res://addons/png_to_gridmap/png_to_gridmap_floor_builder.gd")
const PNG_TO_GRIDMAP_IMPORTER := preload("res://addons/png_to_gridmap/png_to_gridmap_importer.gd")
const PNG_TO_GRIDMAP_PROFILE_STORE := preload("res://addons/png_to_gridmap/png_to_gridmap_profile_store.gd")
const PNG_TO_GRIDMAP_REPAIRER := preload("res://addons/png_to_gridmap/png_to_gridmap_repairer.gd")
const PNG_TO_GRIDMAP_SETTINGS := preload("res://addons/png_to_gridmap/png_to_gridmap_settings.gd")
const SKELETON_SCENE := preload("res://enemies/skeleton.tscn")
const SILVER_KEY_SCENE := preload("res://inventory/silver_key.tscn")
const TEST_TEXT_OVERLAY_VISUAL_LAYER := 1 << 19
const TORCH_SCENE := preload("res://placeables/torch/torch.tscn")
const TREASURE_PILE_SCENE := preload("res://placeables/treasure/treasure_pile.tscn")
const ZOMBIE_SCENE := preload("res://enemies/zombie.tscn")

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


func _init() -> void:
    _run_tests.call_deferred()


func _run_tests() -> void:
    var failed := false
    failed = not _test_deterministic_seed_helper_is_stable() or failed
    failed = not _test_coin_pile_derives_stable_seed_and_disables_camera_gate_by_default() or failed
    failed = not _test_treasure_pile_discovers_compatible_scenes_and_spawns_mixed_counts() \
        or failed
    failed = not _test_diamond_collectible_value_and_material() or failed
    failed = not _test_gem_variants_share_model_and_scale_values() or failed
    failed = not _test_audio_fallback_is_deterministic() or failed
    failed = not _test_player_fall_death_threshold() or failed
    failed = not _test_torch_scene_and_persistent_activation() or failed
    failed = not _test_indoor_lighting_strengthens_occlusion() or failed
    failed = not _test_held_drop_input_accelerates() or failed
    failed = not _test_drop_direction_variation_is_deterministic_and_compact() or failed
    failed = not _test_gold_treasure_stays_lit_and_uses_indoor_bloom() or failed
    failed = not await _test_gold_bar_uses_inventory_capacity_and_physics_drop() or failed
    failed = not _test_result_percentage_uses_mixed_treasure_value() or failed
    failed = not _test_treasure_absorption_does_not_complete_level() or failed
    failed = not _test_gate_completion_completes_level() or failed
    failed = not _test_reusable_gate_and_treasure_deposit_coffin_scenes() or failed
    failed = not _test_key_scenes_have_authored_pickup_areas() or failed
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
    failed = not _test_enemies_use_fake_shadows_without_warning_light_blobs() or failed
    failed = not _test_skeleton_facing_is_driven_by_movement() or failed
    failed = not _test_minimap_disables_processing_and_rendering() or failed
    failed = not _test_minimap_camera_scrolls_wide_level_without_empty_space() or failed
    failed = not _test_minimap_camera_scrolls_tall_level_without_empty_space() or failed
    failed = not _test_bat_nest_swarms_then_rises_away() or failed
    failed = not _test_bat_nest_camera_scare_grows_one_bat() or failed
    failed = not _test_gridmap_repair_uses_configured_connection_groups() or failed
    failed = not _test_gridmap_repair_merges_equivalent_configurations() or failed
    failed = not _test_gridmap_repair_preserves_only_matching_alternatives() or failed
    failed = not _test_png_profile_store_only_accepts_level_subfolders() or failed
    failed = not _test_png_floor_gridmap_uses_non_transparent_pixels_and_safe_collision() or failed
    failed = not _test_png_gridmap_import_disables_y_cell_centering() or failed
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
        and _expect(
            pile.get_max_coin_count() == 200 and pile.get_max_item_count() == 200,
            "coin pile keeps its existing quantity API and default"
        ) \
        and _expect(
            not bool(pile.get("spawn_when_near_camera")),
            "coin pile does not camera-gate spawn timing by default"
        )

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
        not diamond_preview.find_children("*", "MeshInstance3D", true, false).is_empty() \
            and not gold_bar_preview.find_children(
                "*", "MeshInstance3D", true, false
            ).is_empty() \
            and not gold_coin_preview.find_children(
                "*", "MeshInstance3D", true, false
            ).is_empty() \
            and diamond_preview.find_children(
                "*", "CollisionObject3D", true, false
            ).is_empty() \
            and gold_bar_preview.find_children(
                "*", "CollisionObject3D", true, false
            ).is_empty(),
        "mixed pile editor previews contain visible meshes without physics bodies"
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


func _test_diamond_collectible_value_and_material() -> bool:
    var diamond := DIAMOND_SCENE.instantiate() as GDDiamond
    root.add_child(diamond)
    var diamond_collision := diamond.get_node_or_null("CollisionShape3D") as CollisionShape3D
    var diamond_shape := (
        diamond_collision.shape as ConvexPolygonShape3D if diamond_collision != null else null
    )
    var diamond_meshes := diamond.find_children("*", "MeshInstance3D", true, false)
    var diamond_mesh := (
        diamond_meshes[0] as MeshInstance3D if not diamond_meshes.is_empty() else null
    )
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
            and diamond_mesh.mesh != null \
            and diamond_mesh.mesh.resource_path.begins_with("res://Assets/placeables/treasure/gems/diamond.glb") \
            and diamond_mesh.mesh.get_faces().size() >= 200,
        "diamond uses a purpose-built, densely faceted GLB model"
    ) and _expect(
        diamond_material.shader.resource_path \
            == "res://placeables/treasure/gems/gem_stylized.gdshader" \
            and (diamond_material.get_shader_parameter(&"body_color") as Color).a == 1.0 \
            and float(diamond_material.get_shader_parameter(&"rim_energy")) > 0.0 \
            and diamond_mesh.material_overlay == null,
        "diamond uses one opaque game-styled facet shader without a corrective overlay"
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


func _test_gem_variants_share_model_and_scale_values() -> bool:
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
    var shared_mesh: Mesh
    var body_colors: Array[Color] = []
    var passed := true

    for index in gem_items.size():
        var gem := gem_scenes[index].instantiate() as GDInventoryPickup
        root.add_child(gem)
        var gem_meshes := gem.find_children("*", "MeshInstance3D", true, false)
        var gem_mesh := (
            gem_meshes[0] as MeshInstance3D if not gem_meshes.is_empty() else null
        )
        var gem_material := (
            gem_mesh.material_override as ShaderMaterial if gem_mesh != null else null
        )
        if shared_mesh == null and gem_mesh != null:
            shared_mesh = gem_mesh.mesh
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
            gem_mesh != null \
                and gem_mesh.mesh == shared_mesh \
                and gem_material != null \
                and gem_material.shader.resource_path \
                    == "res://placeables/treasure/gems/gem_stylized.gdshader",
            "%s shares the gem GLB and stylized shader" \
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


func _test_png_profile_store_only_accepts_level_subfolders() -> bool:
    var profile_store := PNG_TO_GRIDMAP_PROFILE_STORE.new(null, PNG_TO_GRIDMAP_SETTINGS)
    var rejected_save_result: Error = profile_store.save(
        PNG_TO_GRIDMAP_SETTINGS.new(),
        "res://player/player.tscn"
    )
    return _expect(
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


func _test_torch_scene_and_persistent_activation() -> bool:
    var torch_scene := TORCH_SCENE.instantiate()
    var mount := torch_scene.get_node("RaisedWallMount") as Node3D
    var particles := torch_scene.get_node(
        "RaisedWallMount/FabricFlameAttachment/FlameParticles"
    ) as GPUParticles3D
    var embers := torch_scene.get_node(
        "RaisedWallMount/FabricFlameAttachment/EmberParticles"
    ) as GPUParticles3D
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
        and float(outline_material.get_shader_parameter(&"outline_intensity")) > 0.0,
        "an unlit torch gains a subtle shader outline when the player approaches"
    ) and _expect(
        torch_scene.find_children("*", "MeshInstance3D", true, false).size() == 1,
        "torch guidance reuses the original model without duplicate shadow geometry"
    ) and passed
    torch_scene._set_lit(false)
    passed = _expect(
        is_zero_approx(float(outline_material.get_shader_parameter(&"outline_intensity"))),
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


func _test_gold_treasure_stays_lit_and_uses_indoor_bloom() -> bool:
    var coin := GOLD_COIN_SCENE.instantiate() as GDGoldCoin
    var coin_mesh := coin.get_node_or_null("CoinMesh") as MeshInstance3D
    var coin_material: Material = (
        coin_mesh.get_active_material(0) if coin_mesh != null else null
    )
    var bar := GOLD_BAR_SCENE.instantiate() as GDGoldBar
    root.add_child(bar)
    var bar_meshes := bar.find_children("*", "MeshInstance3D", true, false)
    var bar_mesh := bar_meshes[0] as MeshInstance3D if not bar_meshes.is_empty() else null
    var bar_material: Material = (
        bar_mesh.get_surface_override_material(0) if bar_mesh != null else null
    )
    var indoor_lighting := INDOOR_LIGHTING_SCENE.instantiate() as GDIndoorLighting
    var world_environment := (
        indoor_lighting.get_node_or_null("WorldEnvironment") as WorldEnvironment
    )
    var environment: Environment = (
        world_environment.environment if world_environment != null else null
    )
    var gold_material := GOLD_TREASURE_MATERIAL as StandardMaterial3D

    var passed := _expect(
        coin_material == GOLD_TREASURE_MATERIAL,
        "coins use the shared gold treasure material"
    ) and _expect(
        bar_material == GOLD_TREASURE_MATERIAL,
        "the imported gold-bar model receives the shared material override"
    ) and _expect(
        gold_material.metallic > 0.0 and gold_material.roughness > 0.0,
        "gold treasure retains reflective lighting and visible surface shape"
    ) and _expect(
        gold_material.emission_enabled \
            and gold_material.emission.r * gold_material.emission_energy_multiplier > 1.0 \
            and gold_material.emission_energy_multiplier < 2.0,
        "gold treasure stays visible unlit without the previous solid-fill emission strength"
    ) and _expect(
        environment != null and environment.glow_enabled and environment.glow_bloom > 0.0,
        "indoor lighting enables a modest bloom for emissive treasure"
    )

    indoor_lighting.free()
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


func _test_gate_completion_completes_level() -> bool:
    var graveyard := TestGraveyard.new()
    graveyard._on_level_completed()

    var passed := _expect(graveyard.win_requested, "gate completion completes the level")
    graveyard.free()
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
    if deposit != null:
        deposit.treasure_absorbed.connect(
            func(value: int) -> void:
                absorbed_values.append(value)
        )
        deposit._absorb_treasure(DIAMOND_ITEM.treasure_value)
    var world_coin := GOLD_COIN_SCENE.instantiate() as GDGoldCoin
    var world_coin_mesh := world_coin.get_node_or_null("CoinMesh") as MeshInstance3D
    var passed := _expect(gate.completes_level, "locked gate scene completes the level") \
        and _expect(gate.get_node_or_null("Leaves/LeftGateLeaf") != null, "locked gate includes its left leaf") \
        and _expect(gate.get_node_or_null("Leaves/RightGateLeaf") != null, "locked gate includes its right leaf") \
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
                and absorbed_values == [DIAMOND_ITEM.treasure_value],
            "diamonds retain their visual and award their full value when deposited"
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
    gate.queue_free()
    coffin.queue_free()
    return passed


func _test_key_scenes_have_authored_pickup_areas() -> bool:
    var gold_key := KEY_SCENE.instantiate() as GDKey
    var silver_key := SILVER_KEY_SCENE.instantiate() as GDKey
    var passed := _expect(_key_has_valid_pickup_area(gold_key), "gold key scene has a valid pickup area") \
        and _expect(_key_has_valid_pickup_area(silver_key), "silver key scene has a valid pickup area")
    gold_key.free()
    silver_key.free()
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
    var passed := _expect(
        graveyard.get_node_or_null("CurrentLevel") == null,
        "graveyard editor scene does not embed level 1"
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
        test_mapping.level_entries.append({
            "available": true,
            "folder_name": str(index + 1),
            "id": "test_level_%02d" % (index + 1),
            "name": "Test Level %d" % (index + 1),
            "tutorial": index == 0,
        })
    level_selection.level_mapping = test_mapping
    level_selection.last_highlighted_level_index = 12
    level_selection.level_results = {
        "test_level_01": {"best_percentage": 40, "escaped": false, "play_count": 2, "played": true},
        "test_level_02": {"best_percentage": 70, "escaped": true, "play_count": 3, "played": true},
        "test_level_03": {"best_percentage": 100, "escaped": true, "play_count": 1, "played": true},
    }

    var screen := LEVEL_SELECT_SCENE.instantiate() as GDLevelSelectScreen
    root.add_child(screen)
    await process_frame
    await process_frame

    var scroll := screen.scroll_container
    var initial_button_rect := screen.level_buttons[12].get_global_rect()
    var initial_viewport_rect := scroll.get_global_rect()
    var passed := _expect(scroll != null, "level selection places cards in a scrolling viewport") \
        and _expect(
            screen.background.texture.resource_path \
            == "res://Assets/frontend/level-select.png",
            "level selection retains its page background"
        ) \
        and _expect(
            screen.level_buttons[0].get_node("CardBackground").texture.resource_path \
            == "res://Assets/frontend/level-background.png",
            "each level card uses the authored card background"
        ) \
        and _expect(
            screen.level_buttons[0].get_node("Title").get_theme_font("font") \
            == GDGameFont.get_almendra_font(),
            "level cards use the bold Almendra game font"
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
            >= initial_viewport_rect.position.y + GDLevelSelectScreen.FOCUS_SCROLL_MARGIN \
            and initial_button_rect.end.y \
            <= initial_viewport_rect.end.y - GDLevelSelectScreen.FOCUS_SCROLL_MARGIN,
            "the remembered level card and its focus surround start fully visible"
        ) \
        and _expect(
            screen.level_buttons[0].get_node("LevelStatus").text.begins_with("TUTORIAL"),
            "tutorial levels are identified on their cards"
        ) \
        and _expect(
            screen.level_buttons[0].get_node("LevelStatus").text == "TUTORIAL  •  FAILED" \
            and screen.level_buttons[0].get_node("Percentage").text == "40%" \
            and screen.level_buttons[0].get_node("Plays").text == "2 PLAYS",
            "failed level cards separate status, treasure percentage, and play count"
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
        )

    screen.level_buttons[6].grab_focus()
    await create_timer(GDLevelSelectScreen.FOCUS_SCROLL_DURATION + 0.05).timeout
    screen._move_focus(Vector2i.DOWN)
    screen._move_focus(Vector2i.DOWN)
    passed = _expect(
        screen.selected_button_index == 12,
        "a double down tap moves focus twice without waiting for scrolling"
    ) and passed
    passed = _expect(
        screen.scroll_tween != null and screen.scroll_tween.is_running(),
        "a double down tap retargets one active smooth scroll"
    ) and passed
    await create_timer(GDLevelSelectScreen.FOCUS_SCROLL_DURATION + 0.05).timeout
    passed = _expect(
        screen.selected_button_index == 12,
        "joypad-style grid navigation reaches later level rows"
    ) and passed
    passed = _expect(
        scroll.scroll_vertical > 0,
        "focused joypad selections automatically scroll into view"
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
    return passed


func _test_level_lookup_supports_debug_and_stable_ids() -> bool:
    var mapping := load("res://levels/level_mapping.tres") as GDLevelMapping
    return _expect(mapping.get_level_count() == 17, "level lookup exposes the debug level and sixteen slots") \
        and _expect(mapping.get_level_id(0) == "debug_level", "debug level has a stable mapping ID") \
        and _expect(mapping.get_level_id(1) == "level_01", "level 1 has a stable mapping ID") \
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
        {
            "available": true,
            "folder_name": "alpha",
            "id": "alpha",
            "legacy_result_key": "01",
            "name": "Alpha",
        },
        {
            "available": true,
            "folder_name": "bravo",
            "id": "bravo",
            "legacy_result_key": "02",
            "name": "Bravo",
        },
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

    mapping.level_entries.insert(0, {
        "available": true,
        "folder_name": "new",
        "id": "new_level",
        "name": "New Level",
    })
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
