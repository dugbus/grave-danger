extends Control
class_name GDLevelSelectScreen

const SCREEN_FADE := preload("res://ui/screens/screen_fade.gd")

const GRID_COLUMNS := 3
const ANALOG_TRIGGER_THRESHOLD := 0.62
const ANALOG_RELEASE_THRESHOLD := 0.25
const CARD_SCROLL_MARGIN := 24
const FOCUS_SCROLL_MARGIN := 18.0
const FOCUS_SCROLL_DURATION := 0.16

enum LevelResultState {
	Unplayed,
	Failed,
	Complete,
	Success,
}

## Image shown full-screen behind the level select screen.
@export var background_texture: Texture2D
## Scene loaded after a level slot is selected.
@export var game_scene := "res://game/graveyard.tscn"
## Seconds used for the black overlay to fade out when the screen opens.
@export var fade_in_duration := 0.35

var starting := false
var background: TextureRect
var shade: ColorRect
var panel: VBoxContainer
var scroll_container: ScrollContainer
var scroll_tween: Tween
var grid: GridContainer
var level_button_template: Button
var level_buttons: Array[Button] = []
var selected_button_index := 0
var initial_focus_pending := true
var analog_x_armed := true
var analog_y_armed := true


func _ready() -> void:
	_bind_background()
	_bind_level_grid()
	_populate_level_grid()
	_focus_initial_level()
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


func _bind_background() -> void:
	background = get_node_or_null("Background") as TextureRect
	if background == null:
		background = TextureRect.new()
		background.name = "Background"
		add_child(background)

	if background_texture != null:
		background.texture = background_texture
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE

	shade = get_node_or_null("Shade") as ColorRect
	if shade == null:
		shade = ColorRect.new()
		shade.name = "Shade"
		shade.color = Color(0.0, 0.0, 0.0, 0.44)
		add_child(shade)

	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _bind_level_grid() -> void:
	panel = get_node_or_null("LevelSelectFrame/Margin/LevelSelectPanel") as VBoxContainer
	if panel == null:
		var frame := PanelContainer.new()
		frame.name = "LevelSelectFrame"
		frame.set_anchors_preset(Control.PRESET_CENTER)
		frame.offset_left = -940.0
		frame.offset_top = -520.0
		frame.offset_right = 940.0
		frame.offset_bottom = 520.0
		add_child(frame)

		var margin := MarginContainer.new()
		margin.name = "Margin"
		margin.add_theme_constant_override("margin_left", 38)
		margin.add_theme_constant_override("margin_top", 30)
		margin.add_theme_constant_override("margin_right", 38)
		margin.add_theme_constant_override("margin_bottom", 24)
		frame.add_child(margin)

		panel = VBoxContainer.new()
		panel.name = "LevelSelectPanel"
		panel.add_theme_constant_override("separation", 18)
		margin.add_child(panel)

	var title := panel.get_node_or_null("Header/Title") as Label
	if title == null:
		title = panel.get_node_or_null("Title") as Label
	if title == null:
		title = Label.new()
		title.name = "Title"
		title.text = "Select Level"
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		GDGameFont.apply_to_label(title)
		title.add_theme_font_size_override("font_size", 76)
		title.add_theme_color_override("font_color", Color(1.0, 0.86, 0.35))
		title.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.85))
		title.add_theme_constant_override("shadow_offset_x", 3)
		title.add_theme_constant_override("shadow_offset_y", 3)
		panel.add_child(title)
	else:
		GDGameFont.apply_to_label(title)

	var subtitle := panel.get_node_or_null("Header/Subtitle") as Label
	if subtitle != null:
		GDGameFont.apply_to_label(subtitle)

	scroll_container = panel.get_node_or_null("LevelScroll") as ScrollContainer
	if scroll_container == null:
		scroll_container = ScrollContainer.new()
		scroll_container.name = "LevelScroll"
		scroll_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
		scroll_container.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		scroll_container.follow_focus = false
		panel.add_child(scroll_container)

	grid = scroll_container.get_node_or_null("GridMargin/LevelGrid") as GridContainer
	if grid == null:
		var grid_margin := MarginContainer.new()
		grid_margin.name = "GridMargin"
		grid_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		grid_margin.add_theme_constant_override("margin_left", CARD_SCROLL_MARGIN)
		grid_margin.add_theme_constant_override("margin_top", CARD_SCROLL_MARGIN)
		grid_margin.add_theme_constant_override("margin_right", CARD_SCROLL_MARGIN)
		grid_margin.add_theme_constant_override("margin_bottom", CARD_SCROLL_MARGIN)
		scroll_container.add_child(grid_margin)

		grid = GridContainer.new()
		grid.name = "LevelGrid"
		grid.columns = GRID_COLUMNS
		grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		grid.add_theme_constant_override("h_separation", 24)
		grid.add_theme_constant_override("v_separation", 24)
		grid_margin.add_child(grid)
	else:
		grid.columns = GRID_COLUMNS

	level_button_template = grid.get_node_or_null("LevelButtonTemplate") as Button
	if level_button_template == null:
		level_button_template = _create_fallback_level_button_template()
		grid.add_child(level_button_template)

	_apply_level_button_fonts(level_button_template)


func _populate_level_grid() -> void:
	var level_selection := get_node_or_null("/root/LevelSelection")
	var level_count := 8
	if level_selection != null and level_selection.has_method("get_level_count"):
		level_count = level_selection.get_level_count()

	level_button_template.hide()
	level_buttons.clear()

	for child in grid.get_children():
		if child != level_button_template and child.get_meta("runtime_level_button", false):
			child.queue_free()

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

	var button := level_button_template.duplicate() as Button
	button.name = "LevelButton%d" % (index + 1)
	_apply_level_button_fonts(button)
	button.show()
	button.set_meta("runtime_level_button", true)
	button.disabled = not available
	button.focus_mode = Control.FOCUS_ALL if available else Control.FOCUS_NONE
	button.pressed.connect(_start_level.bind(index))
	button.focus_entered.connect(_on_button_focused.bind(index))
	button.gui_input.connect(_on_button_gui_input.bind(index))

	var title := button.get_node_or_null("Title") as Label
	if title != null:
		title.text = String(level_data.get("name", "Level %d" % (index + 1)))
		title.modulate = Color.WHITE if available else Color(0.62, 0.58, 0.48)
		title.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var status := button.get_node_or_null("LevelStatus") as Label
	if status != null:
		var result_status := _get_status_text(index, available)
		var is_tutorial := bool(level_data.get("tutorial", false))
		status.text = _get_level_status_text(result_status, is_tutorial)
		status.add_theme_color_override(
			"font_color",
			Color(0.58, 0.86, 0.82) if is_tutorial else _get_status_color(index, available)
		)
		status.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var percentage := button.get_node_or_null("Percentage") as Label
	if percentage != null:
		percentage.text = _get_percentage_text(index, available)
		percentage.add_theme_color_override("font_color", _get_percentage_color(index, available))
		percentage.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var plays := button.get_node_or_null("Plays") as Label
	if plays != null:
		plays.text = _get_play_count_text(int(_get_level_result(index).get("play_count", 0))) \
			if available else "0 PLAYS"
		plays.mouse_filter = Control.MOUSE_FILTER_IGNORE

	return button


func _create_fallback_level_button_template() -> Button:
	var button := Button.new()
	button.name = "LevelButtonTemplate"
	button.custom_minimum_size = Vector2(550.0, 360.0)
	button.add_theme_stylebox_override(
		"normal",
		_create_button_style(Color(0.075, 0.065, 0.065, 0.94), Color(0.62, 0.46, 0.22, 0.7), 2)
	)
	button.add_theme_stylebox_override(
		"hover",
		_create_button_style(Color(0.17, 0.125, 0.08, 0.98), Color(1.0, 0.76, 0.25, 0.9), 3)
	)
	button.add_theme_stylebox_override(
		"pressed",
		_create_button_style(Color(0.20, 0.13, 0.08, 0.98), Color(1.0, 0.88, 0.42, 0.9), 3)
	)
	button.add_theme_stylebox_override(
		"focus",
		_create_button_style(Color(0.21, 0.145, 0.07, 0.4), Color(1.0, 0.87, 0.42, 1.0), 4)
	)
	button.add_theme_stylebox_override(
		"disabled",
		_create_button_style(Color(0.04, 0.04, 0.045, 0.70), Color(0.45, 0.43, 0.38, 0.32), 2)
	)

	var content := VBoxContainer.new()
	content.name = "Content"
	content.set_anchors_preset(Control.PRESET_FULL_RECT)
	content.offset_left = 28.0
	content.offset_top = 14.0
	content.offset_right = -28.0
	content.offset_bottom = -14.0
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_theme_constant_override("separation", 4)
	button.add_child(content)

	var level_number := Label.new()
	level_number.name = "LevelNumber"
	level_number.text = "TUTORIAL"
	level_number.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	GDGameFont.apply_to_label(level_number)
	level_number.add_theme_font_size_override("font_size", 28)
	level_number.add_theme_color_override("font_color", Color(0.72, 0.58, 0.32))
	level_number.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(level_number)

	var title := Label.new()
	title.name = "Title"
	title.text = "Level Name"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	GDGameFont.apply_to_label(title)
	title.add_theme_font_size_override("font_size", 56)
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.max_lines_visible = 2
	title.add_theme_color_override("font_color", Color(1.0, 0.86, 0.35))
	title.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.86))
	title.add_theme_constant_override("shadow_offset_x", 2)
	title.add_theme_constant_override("shadow_offset_y", 2)
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(title)

	var status := Label.new()
	status.name = "Status"
	status.text = "UNPLAYED"
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	GDGameFont.apply_to_label(status)
	status.add_theme_font_size_override("font_size", 30)
	status.add_theme_color_override("font_color", Color(0.68, 0.64, 0.58))
	status.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(status)

	var treasure_caption := Label.new()
	treasure_caption.name = "TreasureCaption"
	treasure_caption.text = "TREASURE RECOVERED"
	treasure_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	GDGameFont.apply_to_label(treasure_caption)
	treasure_caption.add_theme_font_size_override("font_size", 22)
	treasure_caption.add_theme_color_override("font_color", Color(0.7, 0.64, 0.52))
	treasure_caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(treasure_caption)

	var percentage := Label.new()
	percentage.name = "Percentage"
	percentage.text = "--"
	percentage.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	GDGameFont.apply_to_label(percentage)
	percentage.add_theme_font_size_override("font_size", 72)
	percentage.add_theme_color_override("font_color", Color(1.0, 0.82, 0.3))
	percentage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(percentage)

	var plays := Label.new()
	plays.name = "Plays"
	plays.text = "0 PLAYS"
	plays.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	GDGameFont.apply_to_label(plays)
	plays.add_theme_font_size_override("font_size", 26)
	plays.add_theme_color_override("font_color", Color(0.7, 0.66, 0.58))
	plays.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(plays)

	return button


func _apply_level_button_fonts(button: Button) -> void:
	if button == null:
		return

	GDGameFont.apply_to_button(button)

	var title := button.get_node_or_null("Title") as Label
	if title != null:
		GDGameFont.apply_to_label(title)

	for label_name in [&"LevelStatus", &"Percentage", &"Plays"]:
		var detail_label := button.get_node_or_null(NodePath(String(label_name))) as Label
		if detail_label != null:
			GDGameFont.apply_to_label(detail_label)


func _get_status_text(index: int, available: bool) -> String:
	if not available:
		return "COMING SOON"

	var result := _get_level_result(index)
	match _get_result_state(result):
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
	if result_status == "UNPLAYED":
		return "TUTORIAL"

	return "TUTORIAL  •  %s" % result_status


func _get_percentage_text(index: int, available: bool) -> String:
	if not available:
		return "--"

	var result := _get_level_result(index)
	if _get_result_state(result) == LevelResultState.Unplayed:
		return "--"

	return "%d%%" % int(result.get("best_percentage", 0))


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
	var level_selection := get_node_or_null("/root/LevelSelection")
	if level_selection == null or not level_selection.has_method("get_level_result"):
		return {}

	return level_selection.get_level_result(index)


func _get_result_state(result: Dictionary) -> LevelResultState:
	if not bool(result.get("played", false)):
		return LevelResultState.Unplayed
	if not bool(result.get("escaped", false)):
		return LevelResultState.Failed
	if int(result.get("best_percentage", 0)) >= 100:
		return LevelResultState.Success

	return LevelResultState.Complete


func _create_button_style(fill_color: Color, border_color: Color, border_width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill_color
	style.border_color = border_color
	style.set_border_width_all(border_width)
	style.corner_radius_top_right = 14
	style.corner_radius_bottom_left = 14
	style.corner_radius_bottom_right = 14
	style.corner_radius_top_left = 14
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.32)
	style.shadow_size = 8
	style.shadow_offset = Vector2(0.0, 4.0)
	return style


func _focus_initial_level() -> void:
	var level_selection := get_node_or_null("/root/LevelSelection")
	if level_selection != null and level_selection.has_method("get_last_highlighted_level_index"):
		var highlighted_index := int(level_selection.get_last_highlighted_level_index())
		if highlighted_index >= 0 and highlighted_index < level_buttons.size() \
				and not level_buttons[highlighted_index].disabled:
			selected_button_index = highlighted_index
			level_buttons[highlighted_index].grab_focus()
			return

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


func _handle_analog_axis(
	value: float,
	is_armed: bool,
	positive_direction: Vector2i,
	negative_direction: Vector2i
) -> bool:
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
	var level_selection := get_node_or_null("/root/LevelSelection")
	if level_selection != null and level_selection.has_method("remember_highlighted_level"):
		level_selection.remember_highlighted_level(index)

	if initial_focus_pending:
		initial_focus_pending = false
		_position_initial_button.call_deferred(index)
		return

	if scroll_container != null and scroll_container.size.y > 0.0 \
			and level_buttons[index].size.y > 0.0:
		_scroll_button_into_view(index)
	else:
		_scroll_button_into_view.call_deferred(index)


func _on_button_gui_input(event: InputEvent, index: int) -> void:
	if starting or index < 0 or index >= level_buttons.size() or level_buttons[index].disabled:
		return
	if event is InputEventMouseMotion and not level_buttons[index].has_focus():
		level_buttons[index].grab_focus()


func _scroll_button_into_view(index: int) -> void:
	if scroll_container == null or index < 0 or index >= level_buttons.size():
		return

	if scroll_tween != null and scroll_tween.is_valid():
		scroll_tween.kill()

	var viewport_rect := scroll_container.get_global_rect()
	var button_rect := level_buttons[index].get_global_rect()
	var target_scroll := float(scroll_container.scroll_vertical)
	if button_rect.end.y > viewport_rect.end.y - FOCUS_SCROLL_MARGIN:
		target_scroll += button_rect.end.y - (viewport_rect.end.y - FOCUS_SCROLL_MARGIN)
	elif button_rect.position.y < viewport_rect.position.y + FOCUS_SCROLL_MARGIN:
		target_scroll -= viewport_rect.position.y + FOCUS_SCROLL_MARGIN - button_rect.position.y

	var scroll_bar := scroll_container.get_v_scroll_bar()
	var maximum_scroll := maxf(scroll_bar.max_value - scroll_bar.page, 0.0)
	target_scroll = clampf(target_scroll, 0.0, maximum_scroll)
	if is_equal_approx(target_scroll, float(scroll_container.scroll_vertical)):
		return

	scroll_tween = create_tween()
	scroll_tween.set_trans(Tween.TRANS_QUART)
	scroll_tween.set_ease(Tween.EASE_OUT)
	scroll_tween.tween_method(
		_set_scroll_vertical,
		float(scroll_container.scroll_vertical),
		target_scroll,
		FOCUS_SCROLL_DURATION
	)


func _set_scroll_vertical(value: float) -> void:
	if scroll_container != null:
		scroll_container.scroll_vertical = roundi(value)


func _position_initial_button(index: int) -> void:
	if scroll_container == null or index != selected_button_index \
			or index < 0 or index >= level_buttons.size():
		return

	var viewport_rect := scroll_container.get_global_rect()
	var button_rect := level_buttons[index].get_global_rect()
	var centered_scroll := float(scroll_container.scroll_vertical) \
		+ button_rect.get_center().y - viewport_rect.get_center().y
	var scroll_bar := scroll_container.get_v_scroll_bar()
	var maximum_scroll := maxf(scroll_bar.max_value - scroll_bar.page, 0.0)
	scroll_container.scroll_vertical = roundi(clampf(centered_scroll, 0.0, maximum_scroll))


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
