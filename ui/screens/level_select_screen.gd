class_name GDLevelSelectScreen
extends "res://ui/frontend/frontend_screen.gd"

const SCREEN_FADE := preload("res://ui/screens/screen_fade.gd")
const LEVEL_ROW_SCENE := preload("res://ui/screens/level_select_item_row.tscn")
const FOCUS_SCROLL_LIST_SCRIPT := preload("res://ui/frontend/focus_scroll_list.gd")
const LEVEL_RUN_PLAYBACK_SCRIPT := preload("res://ui/screens/level_run_playback.gd")
const TITLE_SCENE_PATH := "res://ui/screens/title_screen.tscn"
const SETTINGS_SCENE_PATH := "res://ui/frontend/settings.tscn"
const FOCUS_SCROLL_MARGIN := 12.0
const FOCUS_SCROLL_DURATION := 0.16

enum LevelResultState {
    Unplayed,
    Failed,
    Complete,
    Success,
}

## Scene loaded after a level slot is selected.
@export var game_scene := "res://game/graveyard.tscn"
## Shop scene opened from the button beneath the level list.
@export_file("*.tscn") var shop_scene_path := "res://ui/frontend/shop.tscn"
## Seconds used for the black overlay to fade out when the screen opens.
@export var fade_in_duration := 0.35

var starting := false
var scroll_container: FOCUS_SCROLL_LIST_SCRIPT
var level_list: VBoxContainer
var selected_tomb_name_label: Label
var selected_tomb_status_label: Label
var level_run_playback: LEVEL_RUN_PLAYBACK_SCRIPT
var liberated_loot_heading_label: Label
var liberated_summary_label: Label
var loot_summary_separator: TextureRect
var loot_tiles: GridContainer
var shop_button: Button
var settings_button: Button
var back_button: Button
var level_buttons: Array[Button] = []
var selected_button_index := 0
var scroll_tween: Tween:
    get:
        return scroll_container.scroll_tween if scroll_container != null else null


func _ready() -> void:
    _bind_scene_nodes()
    _sync_screen_container()
    _populate_level_list()
    _bind_bottom_actions()
    scroll_container.configure_rows(
        level_buttons,
        back_button,
        shop_button,
        [back_button, settings_button, shop_button]
    )
    _focus_initial_level()
    SCREEN_FADE.fade_in(self, "LevelSelectFade", fade_in_duration)
    set_process_input(true)
    set_process_unhandled_input(true)


func _input(event: InputEvent) -> void:
    if starting:
        return

    if event is InputEventJoypadMotion and scroll_container.handle_analog_motion(event):
        get_viewport().set_input_as_handled()
    elif event is InputEventJoypadButton and scroll_container.handle_dpad_button(event):
        get_viewport().set_input_as_handled()


func _unhandled_input(event: InputEvent) -> void:
    if starting or not _is_accept_event(event):
        return

    if back_button.has_focus():
        _return_to_title()
    elif settings_button.has_focus():
        _open_settings()
    elif shop_button.has_focus():
        _open_shop()
    else:
        _start_level(selected_button_index)


func _bind_scene_nodes() -> void:
    screen_container = get_node_or_null(screen_container_path) as Control
    scroll_container = get_node(
        "ScreenContainer/LevelListFrame/Content/LevelScroll"
    ) as FOCUS_SCROLL_LIST_SCRIPT
    level_list = scroll_container.get_node("ListMargin/LevelList") as VBoxContainer
    selected_tomb_name_label = get_node(
        "ScreenContainer/LootFrame/Content/SelectedTombPanel/SelectedTombNameLabel"
    ) as Label
    selected_tomb_status_label = get_node(
        "ScreenContainer/LootFrame/Content/SelectedTombPanel/SelectedTombStatusLabel"
    ) as Label
    level_run_playback = get_node(
        "ScreenContainer/LootFrame/Content/LevelRunPlayback"
    ) as LEVEL_RUN_PLAYBACK_SCRIPT
    liberated_loot_heading_label = get_node(
        "ScreenContainer/LootFrame/Content/SelectedTombPanel/LiberatedLootHeadingLabel"
    ) as Label
    liberated_summary_label = get_node(
        "ScreenContainer/LootFrame/Content/SelectedTombPanel/LiberatedSummaryLabel"
    ) as Label
    loot_summary_separator = get_node(
        "ScreenContainer/LootFrame/Content/SelectedTombPanel/LootSummarySeparator"
    ) as TextureRect
    loot_tiles = get_node(
        "ScreenContainer/LootFrame/Content/SelectedTombPanel/LootTiles"
    ) as GridContainer
    back_button = get_node("ScreenContainer/BottomActions/BackButton") as Button
    settings_button = get_node("ScreenContainer/BottomActions/SettingsButton") as Button
    shop_button = get_node("ScreenContainer/BottomActions/ShopButton") as Button


func _bind_bottom_actions() -> void:
    GDGameFont.apply_to_button(back_button)
    GDGameFont.apply_to_button(settings_button)
    GDGameFont.apply_to_button(shop_button)
    back_button.pressed.connect(_return_to_title)
    settings_button.pressed.connect(_open_settings)
    shop_button.pressed.connect(_open_shop)
    back_button.mouse_entered.connect(back_button.grab_focus)
    settings_button.mouse_entered.connect(settings_button.grab_focus)
    shop_button.mouse_entered.connect(shop_button.grab_focus)


func _populate_level_list() -> void:
    var level_selection := _get_level_selection()
    var level_count := level_selection.get_level_count() if level_selection != null else 8
    level_buttons.clear()

    for child in level_list.get_children():
        level_list.remove_child(child)
        child.queue_free()

    for index in level_count:
        var button := _create_level_button(index)
        level_buttons.append(button)
        level_list.add_child(button)


func _create_level_button(index: int) -> Button:
    var level_selection := _get_level_selection()
    var level_data := level_selection.get_level_data(index) if level_selection != null else {}
    var available := level_selection.is_level_available(index) if level_selection != null else false
    var button := LEVEL_ROW_SCENE.instantiate() as Button
    button.name = "LevelButton%d" % (index + 1)
    button.set_meta(&"runtime_level_button", true)
    button.disabled = not available
    button.focus_mode = Control.FOCUS_ALL if available else Control.FOCUS_NONE
    button.modulate = Color.WHITE if available else Color(0.48, 0.48, 0.48, 1.0)
    button.pressed.connect(_start_level.bind(index))
    button.focus_entered.connect(_on_button_focused.bind(index))
    button.gui_input.connect(_on_button_gui_input.bind(index))

    var title := button.get_node("Title") as Label
    var status := button.get_node("LevelStatus") as Label
    var percentage := button.get_node("Percentage") as Label
    var plays := button.get_node("Plays") as Label
    title.text = String(level_data.get("name", "Level %d" % (index + 1)))
    var result_status := _get_status_text(index, available)
    var is_tutorial := bool(level_data.get("tutorial", false))
    status.text = _get_level_status_text(result_status, is_tutorial)
    status.add_theme_color_override(
        &"font_color",
        Color(0.58, 0.86, 0.82) if is_tutorial else _get_status_color(index, available)
    )
    percentage.text = _get_percentage_text(index, available)
    percentage.add_theme_color_override(&"font_color", _get_percentage_color(index, available))
    plays.text = _get_play_count_text(int(_get_level_result(index).get("play_count", 0))) \
        if available else "0 PLAYS"
    return button


func _focus_initial_level() -> void:
    var level_selection := _get_level_selection()
    if level_selection != null:
        var highlighted_index := level_selection.get_last_highlighted_level_index()
        if scroll_container.focus_row(highlighted_index, true):
            return

    for index in level_buttons.size():
        if scroll_container.focus_row(index, true):
            return

    _update_selected_level_details(0)


func _on_button_focused(index: int) -> void:
    selected_button_index = index
    _update_selected_level_details(index)
    var level_selection := _get_level_selection()
    if level_selection != null:
        level_selection.remember_highlighted_level(index)


func _update_selected_level_details(index: int) -> void:
    if index < 0 or index >= level_buttons.size():
        return

    var level_selection := _get_level_selection()
    var level_data := level_selection.get_level_data(index) if level_selection != null else {}
    var available := level_selection.is_level_available(index) if level_selection != null else false
    var result := _get_level_result(index)
    selected_tomb_name_label.text = String(
        level_data.get("name", "Level %d" % (index + 1))
    ).to_upper()
    selected_tomb_status_label.text = _get_selected_tomb_status(index, available, result)
    if level_run_playback != null:
        level_run_playback.show_level_run(
            String(level_data.get("id", "")),
            String(level_data.get("scene_path", ""))
        )

    var level_was_played := bool(result.get("played", false))
    var liberated_counts := result.get("banked_treasure_counts", {}) as Dictionary
    var liberated_total := 0
    for loot_tile: Control in loot_tiles.get_children():
        var treasure_type := StringName(loot_tile.get_meta(&"treasure_type", &""))
        var quantity := maxi(int(liberated_counts.get(String(treasure_type), 0)), 0)
        var quantity_label := loot_tile.get_node("TreasureQuantityLabel") as Label
        quantity_label.text = "x%d" % quantity
        loot_tile.visible = level_was_played and quantity > 0
        liberated_total += quantity

    var has_liberated_loot := level_was_played and liberated_total > 0
    liberated_loot_heading_label.visible = has_liberated_loot
    loot_tiles.visible = has_liberated_loot
    loot_summary_separator.visible = has_liberated_loot
    liberated_summary_label.visible = has_liberated_loot
    if has_liberated_loot:
        liberated_summary_label.text = "%d PIECE%s LIBERATED  •  %d%% RECOVERED" % [
            liberated_total,
            "" if liberated_total == 1 else "S",
            int(result.get("best_percentage", 0)),
        ]


func _get_selected_tomb_status(index: int, available: bool, result: Dictionary) -> String:
    if not available:
        return "COMING SOON"
    var status := _get_status_text(index, available)
    var play_count := int(result.get("play_count", 0))
    if _get_result_state(result) == LevelResultState.Unplayed:
        return "%s  •  %s" % [status, _get_play_count_text(play_count)]
    return "%s  •  %d%% RECOVERED  •  %s" % [
        status,
        int(result.get("best_percentage", 0)),
        _get_play_count_text(play_count),
    ]


func _on_button_gui_input(event: InputEvent, index: int) -> void:
    if starting or index < 0 or index >= level_buttons.size() or level_buttons[index].disabled:
        return
    if event is InputEventMouseMotion and not level_buttons[index].has_focus():
        level_buttons[index].grab_focus()


func _move_focus(direction: Vector2i) -> void:
    scroll_container.move_focus(direction)


func _get_status_text(index: int, available: bool) -> String:
    if not available:
        return "COMING SOON"
    match _get_result_state(_get_level_result(index)):
        LevelResultState.Failed:
            return "FAILED"
        LevelResultState.Complete:
            return "COMPLETE"
        LevelResultState.Success:
            return "SUCCESS"
        _:
            return "UNPLAYED"


func _get_level_status_text(result_status: String, is_tutorial: bool) -> String:
    if not is_tutorial:
        return result_status
    return "TUTORIAL" if result_status == "UNPLAYED" else "TUTORIAL  •  %s" % result_status


func _get_percentage_text(index: int, available: bool) -> String:
    if not available or _get_result_state(_get_level_result(index)) == LevelResultState.Unplayed:
        return "--"
    return "%d%%" % int(_get_level_result(index).get("best_percentage", 0))


func _get_play_count_text(play_count: int) -> String:
    return "%d PLAY%s" % [play_count, "" if play_count == 1 else "S"]


func _get_status_color(index: int, available: bool) -> Color:
    if not available:
        return Color(0.54, 0.52, 0.46)
    match _get_result_state(_get_level_result(index)):
        LevelResultState.Failed:
            return Color(0.92, 0.42, 0.35)
        LevelResultState.Complete:
            return Color(0.88, 0.78, 0.58)
        LevelResultState.Success:
            return Color(0.62, 0.94, 0.58)
        _:
            return Color(0.68, 0.64, 0.58)


func _get_percentage_color(index: int, available: bool) -> Color:
    if not available:
        return Color(0.46, 0.44, 0.4)
    if _get_result_state(_get_level_result(index)) == LevelResultState.Success:
        return Color(0.7, 1.0, 0.62)
    return Color(1.0, 0.82, 0.3)


func _get_level_result(index: int) -> Dictionary:
    var level_selection := _get_level_selection()
    return level_selection.get_level_result(index) if level_selection != null else {}


func _get_result_state(result: Dictionary) -> LevelResultState:
    if not bool(result.get("played", false)):
        return LevelResultState.Unplayed
    if not bool(result.get("escaped", false)):
        return LevelResultState.Failed
    if int(result.get("best_percentage", 0)) >= 100:
        return LevelResultState.Success
    return LevelResultState.Complete


func _get_level_selection() -> GDLevelSelection:
    return get_node_or_null("/root/LevelSelection") as GDLevelSelection


func _start_level(index: int) -> void:
    if starting:
        return
    var level_selection := _get_level_selection()
    if level_selection == null or not level_selection.select_level(index):
        return
    _play_select_sound()
    starting = true
    await _change_scene_after_playback_shutdown(game_scene)


func _return_to_title() -> void:
    if starting:
        return
    _play_select_sound()
    starting = true
    await _change_scene_after_playback_shutdown(TITLE_SCENE_PATH)


func _open_shop() -> void:
    if starting:
        return
    _play_select_sound()
    starting = true
    await _change_scene_after_playback_shutdown(shop_scene_path)


func _open_settings() -> void:
    if starting:
        return
    _play_select_sound()
    starting = true
    await _change_scene_after_playback_shutdown(SETTINGS_SCENE_PATH)


func _change_scene_after_playback_shutdown(scene_path: String) -> void:
    if level_run_playback != null:
        await level_run_playback.stop_for_scene_change()
    if not is_inside_tree():
        return
    var change_error := get_tree().change_scene_to_file(scene_path)
    if change_error != OK:
        starting = false
        push_warning("Could not open scene '%s'." % scene_path)
