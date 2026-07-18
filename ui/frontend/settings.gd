class_name GDSettingsScreen
extends "res://ui/frontend/frontend_screen.gd"

## Frontend settings screen with persistent audio preferences and guarded progress reset.

const LEVEL_SELECT_SCENE_PATH := "res://ui/screens/level_select_screen.tscn"

var is_transitioning := false

@onready var music_slider := (
	get_node(
		"ScreenContainer/SettingsFrame/Content/SettingsPanel/MusicRow/MusicContent/MusicSlider"
	)
	as HSlider
)
@onready var music_value_label := (
	get_node(
		"ScreenContainer/SettingsFrame/Content/SettingsPanel/MusicRow/MusicContent/MusicValueLabel"
	)
	as Label
)
@onready var music_focus_border := (
	get_node("ScreenContainer/SettingsFrame/Content/SettingsPanel/MusicRow/FocusBorder") as Panel
)
@onready var sound_effect_slider := (
	get_node(
		"ScreenContainer/SettingsFrame/Content/SettingsPanel/SoundEffectRow/SoundEffectContent/SoundEffectSlider"
	)
	as HSlider
)
@onready var sound_effect_value_label := (
	get_node(
		"ScreenContainer/SettingsFrame/Content/SettingsPanel/SoundEffectRow/SoundEffectContent/SoundEffectValueLabel"
	)
	as Label
)
@onready var sound_effect_focus_border := (
	get_node("ScreenContainer/SettingsFrame/Content/SettingsPanel/SoundEffectRow/FocusBorder")
	as Panel
)
@onready var reset_button := (
	get_node("ScreenContainer/SettingsFrame/Content/SettingsPanel/ResetProgressButton") as Button
)
@onready var status_label := (
	get_node("ScreenContainer/SettingsFrame/Content/SettingsPanel/StatusLabel") as Label
)
@onready var back_button := get_node("ScreenContainer/BottomActions/BackButton") as Button
@onready var confirmation_shade := get_node("ScreenContainer/ResetConfirmationShade") as ColorRect
@onready
var confirmation_frame := get_node("ScreenContainer/ResetConfirmationFrame") as NinePatchRect
@onready var no_button := (
	get_node("ScreenContainer/ResetConfirmationFrame/Content/ConfirmationActions/NoButton")
	as Button
)
@onready var yes_button := (
	get_node("ScreenContainer/ResetConfirmationFrame/Content/ConfirmationActions/YesButton")
	as Button
)


func _ready() -> void:
	_sync_screen_container()
	var game_settings := _get_game_settings()
	music_slider.value = game_settings.music_volume_percent if game_settings != null else 80.0
	sound_effect_slider.value = (
		game_settings.sound_effect_volume_percent if game_settings != null else 80.0
	)
	_update_volume_labels()
	music_slider.value_changed.connect(_on_music_volume_changed)
	sound_effect_slider.value_changed.connect(_on_sound_effect_volume_changed)
	music_slider.drag_ended.connect(_on_volume_drag_ended)
	sound_effect_slider.drag_ended.connect(_on_volume_drag_ended)
	music_slider.focus_entered.connect(_set_focus_border_visible.bind(music_focus_border, true))
	music_slider.focus_exited.connect(_set_focus_border_visible.bind(music_focus_border, false))
	sound_effect_slider.focus_entered.connect(
		_set_focus_border_visible.bind(sound_effect_focus_border, true)
	)
	sound_effect_slider.focus_exited.connect(
		_set_focus_border_visible.bind(sound_effect_focus_border, false)
	)
	reset_button.button_down.connect(_show_reset_confirmation)
	# button_down responds immediately for mouse, keyboard, and joypad activation.
	back_button.button_down.connect(_return_to_level_select)
	no_button.pressed.connect(_hide_reset_confirmation)
	yes_button.pressed.connect(_confirm_reset_progress)
	back_button.mouse_entered.connect(back_button.grab_focus)
	music_slider.mouse_entered.connect(music_slider.grab_focus)
	sound_effect_slider.mouse_entered.connect(sound_effect_slider.grab_focus)
	reset_button.mouse_entered.connect(reset_button.grab_focus)
	no_button.mouse_entered.connect(no_button.grab_focus)
	yes_button.mouse_entered.connect(yes_button.grab_focus)
	_configure_focus()
	music_slider.call_deferred("grab_focus")


func _set_focus_border_visible(border: Panel, should_show: bool) -> void:
	border.visible = should_show


func _unhandled_input(event: InputEvent) -> void:
	var viewport := get_viewport()
	if confirmation_frame.visible and event.is_action_pressed("ui_cancel"):
		_hide_reset_confirmation()
		viewport.set_input_as_handled()
	elif not confirmation_frame.visible and event.is_action_pressed("ui_cancel"):
		_return_to_level_select()
		viewport.set_input_as_handled()
	elif _is_accept_event(event) and _activate_focused_control():
		viewport.set_input_as_handled()


func _activate_focused_control() -> bool:
	if confirmation_frame.visible:
		if yes_button.has_focus():
			_confirm_reset_progress()
			return true
		if no_button.has_focus():
			_hide_reset_confirmation()
			return true
		return false

	if reset_button.has_focus():
		_show_reset_confirmation()
		return true
	if back_button.has_focus():
		_return_to_level_select()
		return true
	return false


func _on_music_volume_changed(value: float) -> void:
	var game_settings := _get_game_settings()
	if game_settings != null:
		game_settings.set_music_volume_percent(value)
	_update_volume_labels()


func _on_sound_effect_volume_changed(value: float) -> void:
	var game_settings := _get_game_settings()
	if game_settings != null:
		game_settings.set_sound_effect_volume_percent(value)
	_update_volume_labels()


func _on_volume_drag_ended(_value_changed: bool) -> void:
	var game_settings := _get_game_settings()
	if game_settings != null:
		game_settings.flush_pending_save()


func _update_volume_labels() -> void:
	music_value_label.text = "%d%%" % roundi(music_slider.value)
	sound_effect_value_label.text = "%d%%" % roundi(sound_effect_slider.value)


func _show_reset_confirmation() -> void:
	_play_select_sound()
	# Keep the modal above every full-screen control even if the scene is instanced elsewhere.
	confirmation_shade.move_to_front()
	confirmation_frame.move_to_front()
	confirmation_shade.show()
	confirmation_frame.show()
	no_button.grab_focus()


func _hide_reset_confirmation(play_sound := true) -> void:
	if play_sound:
		_play_select_sound()
	confirmation_shade.visible = false
	confirmation_frame.visible = false
	reset_button.grab_focus()


func _confirm_reset_progress() -> void:
	_play_select_sound()
	var level_selection := get_node_or_null("/root/LevelSelection") as GDLevelSelection
	if level_selection != null:
		level_selection.reset_progress()
	status_label.text = "PROGRESS RESET"
	status_label.visible = true
	_hide_reset_confirmation(false)


func _configure_focus() -> void:
	music_slider.focus_neighbor_bottom = music_slider.get_path_to(sound_effect_slider)
	sound_effect_slider.focus_neighbor_top = sound_effect_slider.get_path_to(music_slider)
	sound_effect_slider.focus_neighbor_bottom = sound_effect_slider.get_path_to(reset_button)
	reset_button.focus_neighbor_top = reset_button.get_path_to(sound_effect_slider)
	reset_button.focus_neighbor_bottom = reset_button.get_path_to(back_button)
	back_button.focus_neighbor_top = back_button.get_path_to(reset_button)
	no_button.focus_neighbor_right = no_button.get_path_to(yes_button)
	yes_button.focus_neighbor_left = yes_button.get_path_to(no_button)


func _return_to_level_select() -> void:
	if is_transitioning:
		return
	_play_select_sound()
	var game_settings := _get_game_settings()
	if game_settings != null:
		game_settings.flush_pending_save()
	is_transitioning = true
	var change_error := get_tree().change_scene_to_file(LEVEL_SELECT_SCENE_PATH)
	if change_error != OK:
		is_transitioning = false
		push_error(
			"Could not return from Settings to Level Select: %s" % error_string(change_error)
		)


func _get_game_settings() -> GDGameSettings:
	return get_node_or_null("/root/GameSettings") as GDGameSettings
