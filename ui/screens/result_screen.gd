class_name GDResultScreen
extends "res://ui/frontend/frontend_screen.gd"

## Shared win and loss presentation for a completed level attempt.

const SCREEN_FADE := preload("res://ui/screens/screen_fade.gd")
const LEVEL_SELECT_SCENE_PATH := "res://ui/screens/level_select_screen.tscn"
const GAME_SCENE_PATH := "res://game/graveyard.tscn"
const FADE_LAYER_NAME := "ResultFadeLayer"
const FADE_LAYER_INDEX := 100
const ANALOG_TRIGGER_THRESHOLD := 0.62
const ANALOG_REARM_THRESHOLD := 0.50

enum ResultOutcome {
	Win,
	Lose,
}

## Selects successful banking or unsuccessful loss behaviour and presentation.
@export var outcome := ResultOutcome.Win
## Seconds used for transitions into and out of the result screen.
@export_range(0.0, 3.0, 0.05) var fade_duration := 0.5

var transitioning := false
var analog_x_armed := true

@onready var percentage_value_label := (
	get_node(
		"ScreenContainer/ResultFrame/Content/ResultContentCenter/ResultContent/PercentageValueLabel"
	)
	as Label
)
@onready var treasure_tiles := (
	get_node("ScreenContainer/ResultFrame/Content/ResultContentCenter/ResultContent/TreasureTiles")
	as HFlowContainer
)
@onready var content_separator := (
	get_node(
		"ScreenContainer/ResultFrame/Content/ResultContentCenter/ResultContent/ContentSeparator"
	)
	as TextureRect
)
@onready var back_button := get_node("ScreenContainer/BottomActions/BackButton") as Button
@onready var secondary_button := get_node("ScreenContainer/BottomActions/SecondaryButton") as Button


func _ready() -> void:
	_sync_screen_container()
	_configure_copy()
	var displayed_treasure := _record_level_result()
	_update_result_details(displayed_treasure)
	_bind_actions()
	SCREEN_FADE.fade_in(
		self, "ResultFade", fade_duration, Color.BLACK, FADE_LAYER_NAME, FADE_LAYER_INDEX
	)
	_focus_default_action.call_deferred()


func _input(event: InputEvent) -> void:
	if transitioning or not event is InputEventJoypadMotion or event.axis != JOY_AXIS_LEFT_X:
		return
	if absf(event.axis_value) <= ANALOG_REARM_THRESHOLD:
		analog_x_armed = true
	elif analog_x_armed and absf(event.axis_value) >= ANALOG_TRIGGER_THRESHOLD:
		if event.axis_value < 0.0:
			back_button.grab_focus()
		else:
			secondary_button.grab_focus()
		analog_x_armed = false
	get_viewport().set_input_as_handled()


func _unhandled_input(event: InputEvent) -> void:
	if transitioning or not _is_accept_event(event):
		return

	var viewport := get_viewport()
	if back_button.has_focus():
		_change_scene(LEVEL_SELECT_SCENE_PATH)
	elif secondary_button.has_focus():
		_change_scene(GAME_SCENE_PATH)
	else:
		return
	viewport.set_input_as_handled()


func _configure_copy() -> void:
	back_button.text = "LEVEL SELECT"
	secondary_button.text = "RETRY"


func _focus_default_action() -> void:
	if outcome == ResultOutcome.Lose:
		secondary_button.grab_focus()
	else:
		back_button.grab_focus()


func _update_result_details(displayed_treasure: Dictionary) -> void:
	var stats := get_node_or_null("/root/ResultStats") as GDResultStats
	var percentage := stats.get_completion_percentage() if stats != null else 0
	percentage_value_label.text = "%d%%" % percentage

	var visible_tile_count := 0
	for tile: Control in treasure_tiles.get_children():
		var treasure_type := tile.get_meta(&"treasure_type", &"") as StringName
		var quantity := maxi(int(displayed_treasure.get(String(treasure_type), 0)), 0)
		var quantity_label := tile.get_node_or_null(^"TreasureQuantityLabel") as Label
		if quantity_label != null:
			quantity_label.text = "x%d" % quantity
		tile.visible = quantity > 0
		tile.modulate = (
			Color.WHITE if outcome == ResultOutcome.Win else Color(0.46, 0.46, 0.46, 1.0)
		)
		if tile.visible:
			visible_tile_count += 1

	treasure_tiles.visible = visible_tile_count > 0
	content_separator.visible = visible_tile_count > 0


func _record_level_result() -> Dictionary:
	var stats := get_node_or_null("/root/ResultStats") as GDResultStats
	var level_selection := get_node_or_null("/root/LevelSelection") as GDLevelSelection
	if stats == null:
		return {}

	var attempt_treasure := stats.take_unbanked_treasure()
	if level_selection == null:
		return attempt_treasure if outcome == ResultOutcome.Lose else {}
	var newly_recovered := level_selection.record_selected_level_result(
		stats.treasure_collected,
		stats.get_completion_percentage(),
		outcome == ResultOutcome.Win,
		attempt_treasure
	)
	return newly_recovered if outcome == ResultOutcome.Win else attempt_treasure


func _bind_actions() -> void:
	back_button.button_down.connect(_change_scene.bind(LEVEL_SELECT_SCENE_PATH))
	secondary_button.button_down.connect(_change_scene.bind(GAME_SCENE_PATH))
	back_button.mouse_entered.connect(back_button.grab_focus)
	secondary_button.mouse_entered.connect(secondary_button.grab_focus)
	back_button.focus_neighbor_left = back_button.get_path_to(back_button)
	back_button.focus_neighbor_right = back_button.get_path_to(secondary_button)
	secondary_button.focus_neighbor_left = secondary_button.get_path_to(back_button)
	secondary_button.focus_neighbor_right = secondary_button.get_path_to(secondary_button)


func _change_scene(scene_path: String) -> void:
	if transitioning:
		return
	_play_select_sound()
	transitioning = true
	var tween := SCREEN_FADE.fade_out(
		self, "ResultFade", fade_duration, FADE_LAYER_NAME, FADE_LAYER_INDEX
	)
	await tween.finished
	var change_error := get_tree().change_scene_to_file(scene_path)
	if change_error != OK:
		transitioning = false
		push_error("Could not leave result screen: %s" % error_string(change_error))
