extends GDResultScreen
class_name GDLoseScreen


const LEVEL_SELECT_SCENE := "res://ui/screens/level_select_screen.tscn"
const GAME_SCENE := "res://game/graveyard.tscn"
const ANALOG_TRIGGER_THRESHOLD := 0.62
const ANALOG_RELEASE_THRESHOLD := 0.25

enum LoseAction {
	Back,
	Retry,
}

var action_buttons: Array[Button] = []
var selected_button_index := int(LoseAction.Retry)
var analog_x_armed := true


func _ready() -> void:
	super()
	_bind_action_buttons()
	set_process_input(true)
	call_deferred("_focus_retry_button")


func _record_level_result() -> void:
	var stats := get_node_or_null("/root/ResultStats")
	if stats == null or stats.max_treasure_value <= 0:
		return

	var level_selection := get_node_or_null("/root/LevelSelection")
	if level_selection != null and level_selection.has_method("record_selected_level_result"):
		level_selection.record_selected_level_result(
			stats.treasure_collected,
			stats.get_completion_percentage(),
			false
		)


func _input(event: InputEvent) -> void:
	if returning_to_title:
		return

	if event is InputEventJoypadMotion and event.axis == JOY_AXIS_LEFT_X:
		analog_x_armed = _handle_analog_axis(event.axis_value, analog_x_armed)
		get_viewport().set_input_as_handled()


func _unhandled_input(event: InputEvent) -> void:
	if returning_to_title:
		return

	if _is_left_event(event):
		_select_button(LoseAction.Back)
		get_viewport().set_input_as_handled()
	elif _is_right_event(event):
		_select_button(LoseAction.Retry)
		get_viewport().set_input_as_handled()
	elif _is_primary_event(event):
		get_viewport().set_input_as_handled()
		_choose_selected_action()


func _bind_action_buttons() -> void:
	var buttons_layer := get_node_or_null("ButtonsLayer")
	if buttons_layer == null:
		return

	var action_buttons_container := buttons_layer.get_node_or_null("ActionButtons")
	if action_buttons_container == null:
		return

	var back_button := action_buttons_container.get_node_or_null("BackButton") as Button
	var retry_button := action_buttons_container.get_node_or_null("RetryButton") as Button
	if back_button == null or retry_button == null:
		return

	action_buttons = [back_button, retry_button]
	_configure_action_button(back_button, LoseAction.Back)
	_configure_action_button(retry_button, LoseAction.Retry)
	back_button.pressed.connect(_choose_action.bind(LoseAction.Back))
	retry_button.pressed.connect(_choose_action.bind(LoseAction.Retry))
	back_button.focus_neighbor_right = back_button.get_path_to(retry_button)
	retry_button.focus_neighbor_left = retry_button.get_path_to(back_button)


func _configure_action_button(button: Button, action: LoseAction) -> void:
	GDGameFont.apply_to_button(button)
	button.focus_mode = Control.FOCUS_ALL
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	button.focus_entered.connect(_select_button.bind(action))


func _focus_retry_button() -> void:
	_select_button(LoseAction.Retry)


func _select_button(action: LoseAction) -> void:
	selected_button_index = int(action)
	if selected_button_index < 0 or selected_button_index >= action_buttons.size():
		return

	var button := action_buttons[selected_button_index]
	if button != null and not button.has_focus():
		button.grab_focus()


func _choose_selected_action() -> void:
	if selected_button_index == int(LoseAction.Back):
		_choose_action(LoseAction.Back)
	else:
		_choose_action(LoseAction.Retry)


func _choose_action(action: LoseAction) -> void:
	if returning_to_title:
		return

	returning_to_title = true
	var target_scene := LEVEL_SELECT_SCENE if action == LoseAction.Back else GAME_SCENE
	var tween := SCREEN_FADE.fade_out(self, "ResultFade", fade_duration, FADE_LAYER_NAME, FADE_LAYER_INDEX)
	await tween.finished

	get_tree().change_scene_to_file(target_scene)


func _handle_analog_axis(value: float, is_armed: bool) -> bool:
	if absf(value) <= ANALOG_RELEASE_THRESHOLD:
		return true

	if not is_armed:
		return false

	if value >= ANALOG_TRIGGER_THRESHOLD:
		_select_button(LoseAction.Retry)
		return false

	if value <= -ANALOG_TRIGGER_THRESHOLD:
		_select_button(LoseAction.Back)
		return false

	return is_armed


func _is_left_event(event: InputEvent) -> bool:
	if _is_action_event(event, "ui_left") or _is_action_event(event, "move_left"):
		return true

	if event is InputEventJoypadButton:
		return event.pressed and event.button_index == JOY_BUTTON_DPAD_LEFT

	if event is InputEventKey:
		return event.pressed and not event.echo and event.physical_keycode == KEY_LEFT

	return false


func _is_right_event(event: InputEvent) -> bool:
	if _is_action_event(event, "ui_right") or _is_action_event(event, "move_right"):
		return true

	if event is InputEventJoypadButton:
		return event.pressed and event.button_index == JOY_BUTTON_DPAD_RIGHT

	if event is InputEventKey:
		return event.pressed and not event.echo and event.physical_keycode == KEY_RIGHT

	return false


func _is_action_event(event: InputEvent, action_name: StringName) -> bool:
	return InputMap.has_action(action_name) and event.is_action_pressed(action_name)
