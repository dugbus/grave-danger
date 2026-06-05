extends Control

const SCREEN_FADE := preload("res://screen_fade.gd")

const GRID_COLUMNS := 4
const ANALOG_TRIGGER_THRESHOLD := 0.62
const ANALOG_RELEASE_THRESHOLD := 0.25

## Image shown full-screen behind the level select screen.
@export var background_texture: Texture2D
## Scene loaded after a level slot is selected.
@export var game_scene := "res://graveyard.tscn"
## Seconds used for the black overlay to fade out when the screen opens.
@export var fade_in_duration := 0.35

var starting := false
var level_buttons: Array[Button] = []
var selected_button_index := 0
var analog_x_armed := true
var analog_y_armed := true


func _ready() -> void:
	_create_background()
	_create_level_grid()
	_focus_first_available_level()
	SCREEN_FADE.fade_in(self, "LevelSelectFade", fade_in_duration)
	set_process_input(true)
	set_process_unhandled_input(true)


func _input(event: InputEvent) -> void:
	if starting:
		return

	if event is InputEventJoypadMotion and _is_left_stick_axis(event.axis):
		_handle_analog_navigation(event)
		get_viewport().set_input_as_handled()


func _unhandled_input(event: InputEvent) -> void:
	if starting:
		return

	if _is_accept_event(event):
		_start_level(selected_button_index)


func _create_background() -> void:
	var background := TextureRect.new()
	background.name = "Background"
	background.texture = background_texture
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)

	var shade := ColorRect.new()
	shade.name = "Shade"
	shade.color = Color(0.0, 0.0, 0.0, 0.44)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)


func _create_level_grid() -> void:
	var panel := VBoxContainer.new()
	panel.name = "LevelSelectPanel"
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left = -920.0
	panel.offset_top = -450.0
	panel.offset_right = 920.0
	panel.offset_bottom = 450.0
	panel.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_theme_constant_override("separation", 48)
	add_child(panel)

	var title := Label.new()
	title.name = "Title"
	title.text = "Select Level"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 96)
	title.add_theme_color_override("font_color", Color(1.0, 0.86, 0.35))
	title.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.85))
	title.add_theme_constant_override("shadow_offset_x", 3)
	title.add_theme_constant_override("shadow_offset_y", 3)
	panel.add_child(title)

	var grid := GridContainer.new()
	grid.name = "LevelGrid"
	grid.columns = GRID_COLUMNS
	grid.add_theme_constant_override("h_separation", 32)
	grid.add_theme_constant_override("v_separation", 32)
	panel.add_child(grid)

	var level_selection := get_node_or_null("/root/LevelSelection")
	var level_count := 8
	if level_selection != null and level_selection.has_method("get_level_count"):
		level_count = level_selection.get_level_count()

	for index in level_count:
		var button := _create_level_button(index)
		level_buttons.append(button)
		grid.add_child(button)


func _create_level_button(index: int) -> Button:
	var level_selection := get_node_or_null("/root/LevelSelection")
	var level_data := {}
	var available := false
	if level_selection != null:
		level_data = level_selection.get_level_data(index)
		available = level_selection.is_level_available(index)

	var button := Button.new()
	button.custom_minimum_size = Vector2(420.0, 264.0)
	button.disabled = not available
	button.focus_mode = Control.FOCUS_ALL if available else Control.FOCUS_NONE
	button.add_theme_stylebox_override("normal", _create_button_style(Color(0.08, 0.07, 0.08, 0.82), Color(0.86, 0.68, 0.32, 0.48), 2))
	button.add_theme_stylebox_override("hover", _create_button_style(Color(0.15, 0.12, 0.11, 0.92), Color(1.0, 0.78, 0.28, 0.72), 3))
	button.add_theme_stylebox_override("pressed", _create_button_style(Color(0.20, 0.13, 0.08, 0.98), Color(1.0, 0.88, 0.42, 0.9), 3))
	button.add_theme_stylebox_override("focus", _create_button_style(Color(0.18, 0.12, 0.08, 0.25), Color(0.72, 1.0, 0.62, 0.95), 4))
	button.add_theme_stylebox_override("disabled", _create_button_style(Color(0.04, 0.04, 0.045, 0.70), Color(0.45, 0.43, 0.38, 0.32), 2))
	button.pressed.connect(_start_level.bind(index))
	button.focus_entered.connect(_on_button_focused.bind(index))

	var content := VBoxContainer.new()
	content.name = "Content"
	content.set_anchors_preset(Control.PRESET_FULL_RECT)
	content.offset_left = 28.0
	content.offset_top = 24.0
	content.offset_right = -28.0
	content.offset_bottom = -24.0
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_theme_constant_override("separation", 16)
	button.add_child(content)

	var title := Label.new()
	title.name = "Title"
	title.text = String(level_data.get("name", "Level %d" % (index + 1)))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 68)
	title.add_theme_color_override("font_color", Color(1.0, 0.86, 0.35) if available else Color(0.62, 0.58, 0.48))
	title.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.86))
	title.add_theme_constant_override("shadow_offset_x", 2)
	title.add_theme_constant_override("shadow_offset_y", 2)
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(title)

	var result := Label.new()
	result.name = "Result"
	result.text = _get_result_text(index, available)
	result.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	result.add_theme_font_size_override("font_size", 40)
	result.add_theme_color_override("font_color", Color(0.9, 0.86, 0.72) if available else Color(0.48, 0.46, 0.40))
	result.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.8))
	result.add_theme_constant_override("shadow_offset_x", 1)
	result.add_theme_constant_override("shadow_offset_y", 1)
	result.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(result)

	return button


func _get_result_text(index: int, available: bool) -> String:
	if not available:
		return "Empty"

	var level_selection := get_node_or_null("/root/LevelSelection")
	if level_selection == null or not level_selection.has_method("get_level_result"):
		return "Best: --\nComplete: --"

	var result: Dictionary = level_selection.get_level_result(index)
	if not bool(result.get("played", false)):
		return "Best: --\nComplete: --"

	return "Best: %d\nComplete: %d%%" % [
		int(result.get("best_score", 0)),
		int(result.get("best_percentage", 0)),
	]


func _create_button_style(fill_color: Color, border_color: Color, border_width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill_color
	style.border_color = border_color
	style.set_border_width_all(border_width)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.32)
	style.shadow_size = 8
	style.shadow_offset = Vector2(0.0, 4.0)
	return style


func _focus_first_available_level() -> void:
	for index in level_buttons.size():
		if not level_buttons[index].disabled:
			selected_button_index = index
			level_buttons[index].grab_focus()
			return


func _handle_analog_navigation(event: InputEventJoypadMotion) -> void:
	if event.axis == JOY_AXIS_LEFT_X:
		analog_x_armed = _handle_analog_axis(event.axis_value, analog_x_armed, Vector2i(1, 0), Vector2i(-1, 0))
	elif event.axis == JOY_AXIS_LEFT_Y:
		analog_y_armed = _handle_analog_axis(event.axis_value, analog_y_armed, Vector2i(0, 1), Vector2i(0, -1))


func _is_left_stick_axis(axis: int) -> bool:
	return axis == JOY_AXIS_LEFT_X or axis == JOY_AXIS_LEFT_Y


func _handle_analog_axis(value: float, is_armed: bool, positive_direction: Vector2i, negative_direction: Vector2i) -> bool:
	if absf(value) <= ANALOG_RELEASE_THRESHOLD:
		return true

	if not is_armed:
		return false

	if value >= ANALOG_TRIGGER_THRESHOLD:
		_move_focus(positive_direction)
		return false

	if value <= -ANALOG_TRIGGER_THRESHOLD:
		_move_focus(negative_direction)
		return false

	return is_armed


func _move_focus(direction: Vector2i) -> void:
	if level_buttons.is_empty():
		return

	var next_index := selected_button_index
	if direction.x != 0:
		next_index += direction.x
	elif direction.y != 0:
		next_index += direction.y * GRID_COLUMNS

	next_index = clampi(next_index, 0, level_buttons.size() - 1)
	var skip_step := direction.x if direction.x != 0 else direction.y * GRID_COLUMNS
	while next_index >= 0 and next_index < level_buttons.size() and level_buttons[next_index].disabled:
		next_index += skip_step

	if next_index < 0 or next_index >= level_buttons.size() or next_index == selected_button_index:
		return

	selected_button_index = next_index
	level_buttons[selected_button_index].grab_focus()


func _on_button_focused(index: int) -> void:
	selected_button_index = index


func _is_accept_event(event: InputEvent) -> bool:
	if InputMap.has_action("ui_accept") and event.is_action_pressed("ui_accept"):
		return true

	if event is InputEventJoypadButton:
		return event.pressed and event.button_index == JOY_BUTTON_A

	if event is InputEventKey:
		return event.pressed and not event.echo and (
			event.physical_keycode == KEY_ENTER
			or event.physical_keycode == KEY_SPACE
		)

	return false


func _start_level(index: int) -> void:
	if starting:
		return

	var level_selection := get_node_or_null("/root/LevelSelection")
	if level_selection == null or not level_selection.select_level(index):
		return

	starting = true
	get_tree().change_scene_to_file(game_scene)
