class_name GDFocusScrollList
extends ScrollContainer

## Reusable smooth-scrolling vertical focus list shared by frontend screens.

signal row_focused(index: int)

## Empty space retained around a focused row when it is scrolled into view.
@export_range(0.0, 100.0, 1.0) var focus_scroll_margin := 10.0
## Duration of the eased scroll used after focus changes.
@export_range(0.0, 1.0, 0.01) var focus_scroll_duration := 0.18
## Stick travel required to perform one menu movement.
@export_range(0.0, 1.0, 0.01) var analog_trigger_threshold := 0.62
## Partial stick release that permits the next deliberate menu movement.
@export_range(0.0, 1.0, 0.01) var analog_rearm_threshold := 0.50
## Seconds a direction is held before menu movement begins repeating.
@export_range(0.0, 2.0, 0.01) var navigation_repeat_delay := 0.42
## Seconds between repeated menu movements while a direction remains held.
@export_range(0.01, 1.0, 0.01) var navigation_repeat_interval := 0.11

var rows: Array[Button] = []
var selected_index := -1
var scroll_tween: Tween
var initial_focus_pending := true
var exit_left: Button
var exit_right: Button
var exit_actions: Array[Button] = []
var analog_x_armed := true
var analog_y_armed := true
var held_direction := Vector2i.ZERO
var repeat_time_remaining := 0.0


func _ready() -> void:
	set_process(false)


func _process(delta: float) -> void:
	if held_direction == Vector2i.ZERO:
		set_process(false)
		return

	repeat_time_remaining -= delta
	while repeat_time_remaining <= 0.0:
		_move_focus_with_sound(held_direction)
		repeat_time_remaining += navigation_repeat_interval


func configure_rows(
	new_rows: Array[Button],
	left_button: Button = null,
	right_button: Button = null,
	bottom_actions: Array[Button] = []
) -> void:
	rows = new_rows
	exit_left = left_button
	exit_right = right_button
	exit_actions.clear()
	for button in bottom_actions:
		exit_actions.append(button)
	if exit_actions.is_empty():
		if exit_left != null:
			exit_actions.append(exit_left)
		if exit_right != null and exit_right != exit_left:
			exit_actions.append(exit_right)
	initial_focus_pending = true

	var focusable_indices := _get_focusable_indices()
	for focus_position in focusable_indices.size():
		var index := focusable_indices[focus_position]
		var row := rows[index]
		var previous_row := rows[focusable_indices[maxi(focus_position - 1, 0)]]
		var next_row := rows[
			focusable_indices[mini(focus_position + 1, focusable_indices.size() - 1)]
		]
		row.focus_neighbor_top = row.get_path_to(previous_row)
		row.focus_neighbor_bottom = row.get_path_to(next_row)
		row.focus_previous = row.get_path_to(previous_row)
		row.focus_next = row.get_path_to(next_row)
		row.focus_neighbor_left = row.get_path_to(exit_left) if exit_left != null \
			else row.get_path_to(row)
		row.focus_neighbor_right = row.get_path_to(exit_right) if exit_right != null \
			else row.get_path_to(row)
		if not row.focus_entered.is_connected(_on_row_focused.bind(index)):
			row.focus_entered.connect(_on_row_focused.bind(index))

	_configure_exit_buttons()


func focus_row(index: int, center_initial := false) -> bool:
	if index < 0 or index >= rows.size() or not _is_focusable(rows[index]):
		return false

	initial_focus_pending = center_initial
	rows[index].grab_focus()
	return true


func focus_selected_or_last_row() -> bool:
	if focus_row(selected_index):
		return true

	var focusable_indices := _get_focusable_indices()
	return not focusable_indices.is_empty() and focus_row(focusable_indices.back())


func handle_analog_motion(event: InputEventJoypadMotion) -> bool:
	var direction := Vector2i.ZERO
	if event.axis == JOY_AXIS_LEFT_X:
		if absf(event.axis_value) <= analog_rearm_threshold:
			analog_x_armed = true
			_stop_repeat_for_axis(true)
		elif analog_x_armed:
			direction.x = _get_analog_direction(event.axis_value)
			analog_x_armed = direction.x == 0
	elif event.axis == JOY_AXIS_LEFT_Y:
		if absf(event.axis_value) <= analog_rearm_threshold:
			analog_y_armed = true
			_stop_repeat_for_axis(false)
		elif analog_y_armed:
			direction.y = _get_analog_direction(event.axis_value)
			analog_y_armed = direction.y == 0
	else:
		return false

	if direction != Vector2i.ZERO:
		_move_focus_with_sound(direction)
		_start_repeat(direction)
	return true


func handle_dpad_button(event: InputEventJoypadButton) -> bool:
	var direction := _get_dpad_direction(event.button_index)
	if direction == Vector2i.ZERO:
		return false
	if event.pressed:
		_move_focus_with_sound(direction)
		_start_repeat(direction)
	elif held_direction == direction:
		_stop_repeat()
	return true


func move_focus(direction: Vector2i) -> void:
	if rows.is_empty():
		return
	var focused_action_index := _get_focused_action_index()
	if focused_action_index >= 0:
		if direction.y < 0:
			focus_selected_or_last_row()
		elif direction.x != 0:
			var next_action_index := clampi(
				focused_action_index + signi(direction.x),
				0,
				exit_actions.size() - 1
			)
			exit_actions[next_action_index].grab_focus()
		return

	if direction.x < 0 and exit_left != null:
		exit_left.grab_focus()
		return
	if direction.x > 0 and exit_right != null:
		exit_right.grab_focus()
		return
	if direction.y == 0:
		return

	var next_index := selected_index + signi(direction.y)
	while next_index >= 0 and next_index < rows.size():
		if _is_focusable(rows[next_index]):
			rows[next_index].grab_focus()
			return
		next_index += signi(direction.y)


func _move_focus_with_sound(direction: Vector2i) -> void:
	var frontend_audio: Node = get_node_or_null("/root/FrontendAudio")
	if frontend_audio != null:
		frontend_audio.call("begin_explicit_focus_change")
	var previous_focus := get_viewport().gui_get_focus_owner()
	move_focus(direction)
	var current_focus := get_viewport().gui_get_focus_owner()
	if frontend_audio != null:
		frontend_audio.call("end_explicit_focus_change")
	if current_focus == null or current_focus == previous_focus:
		return
	if frontend_audio != null:
		frontend_audio.call("play_move_cursor")


func scroll_row_into_view(index: int, center := false) -> void:
	if index < 0 or index >= rows.size():
		return
	if size.y <= 0.0 or rows[index].size.y <= 0.0:
		scroll_row_into_view.call_deferred(index, center)
		return

	if scroll_tween != null and scroll_tween.is_valid():
		scroll_tween.kill()

	var viewport_rect := get_global_rect()
	var row_rect := rows[index].get_global_rect()
	var vertical_scale := maxf(absf(get_global_transform().get_scale().y), 0.001)
	var target_scroll := float(scroll_vertical)
	if center:
		target_scroll += (row_rect.get_center().y - viewport_rect.get_center().y) / vertical_scale
	else:
		var scaled_margin := focus_scroll_margin * vertical_scale
		if row_rect.end.y > viewport_rect.end.y - scaled_margin:
			target_scroll += (row_rect.end.y - viewport_rect.end.y + scaled_margin) / vertical_scale
		elif row_rect.position.y < viewport_rect.position.y + scaled_margin:
			target_scroll -= (viewport_rect.position.y + scaled_margin - row_rect.position.y) \
				/ vertical_scale

	var scroll_bar := get_v_scroll_bar()
	var maximum_scroll := maxf(scroll_bar.max_value - scroll_bar.page, 0.0)
	target_scroll = clampf(target_scroll, 0.0, maximum_scroll)
	if center:
		scroll_vertical = roundi(target_scroll)
		return
	if is_equal_approx(target_scroll, float(scroll_vertical)):
		return

	scroll_tween = create_tween()
	scroll_tween.set_trans(Tween.TRANS_QUART)
	scroll_tween.set_ease(Tween.EASE_OUT)
	scroll_tween.tween_method(
		_set_scroll_vertical,
		float(scroll_vertical),
		target_scroll,
		focus_scroll_duration
	)


func _on_row_focused(index: int) -> void:
	selected_index = index
	row_focused.emit(index)
	if initial_focus_pending:
		initial_focus_pending = false
		scroll_row_into_view.call_deferred(index, true)
	else:
		scroll_row_into_view(index)


func _configure_exit_buttons() -> void:
	for button in exit_actions:
		if button == null:
			continue
		button.focus_neighbor_top = button.get_path_to(button)
		button.focus_neighbor_bottom = button.get_path_to(button)
		if not button.focus_entered.is_connected(_on_exit_button_focused.bind(button)):
			button.focus_entered.connect(_on_exit_button_focused.bind(button))

	for index in exit_actions.size():
		var button := exit_actions[index]
		var previous_button := exit_actions[maxi(index - 1, 0)]
		var next_button := exit_actions[mini(index + 1, exit_actions.size() - 1)]
		button.focus_neighbor_left = button.get_path_to(previous_button)
		button.focus_neighbor_right = button.get_path_to(next_button)


func _on_exit_button_focused(button: Button) -> void:
	var row := _get_selected_or_last_row()
	if row != null:
		button.focus_neighbor_top = button.get_path_to(row)


func _get_selected_or_last_row() -> Button:
	if selected_index >= 0 and selected_index < rows.size() and _is_focusable(rows[selected_index]):
		return rows[selected_index]
	var focusable_indices := _get_focusable_indices()
	return rows[focusable_indices.back()] if not focusable_indices.is_empty() else null


func _get_focused_action_index() -> int:
	for index in exit_actions.size():
		if exit_actions[index] != null and exit_actions[index].has_focus():
			return index
	return -1


func _get_focusable_indices() -> Array[int]:
	var focusable_indices: Array[int] = []
	for index in rows.size():
		if _is_focusable(rows[index]):
			focusable_indices.append(index)
	return focusable_indices


func _is_focusable(row: Button) -> bool:
	return row != null and not row.disabled and row.focus_mode != Control.FOCUS_NONE


func _get_analog_direction(value: float) -> int:
	if value >= analog_trigger_threshold:
		return 1
	if value <= -analog_trigger_threshold:
		return -1
	return 0


func _get_dpad_direction(button_index: JoyButton) -> Vector2i:
	match button_index:
		JOY_BUTTON_DPAD_UP:
			return Vector2i.UP
		JOY_BUTTON_DPAD_DOWN:
			return Vector2i.DOWN
		JOY_BUTTON_DPAD_LEFT:
			return Vector2i.LEFT
		JOY_BUTTON_DPAD_RIGHT:
			return Vector2i.RIGHT
		_:
			return Vector2i.ZERO


func _start_repeat(direction: Vector2i) -> void:
	held_direction = direction
	repeat_time_remaining = navigation_repeat_delay
	set_process(true)


func _stop_repeat_for_axis(horizontal: bool) -> void:
	if (horizontal and held_direction.x != 0) or (not horizontal and held_direction.y != 0):
		_stop_repeat()


func _stop_repeat() -> void:
	held_direction = Vector2i.ZERO
	repeat_time_remaining = 0.0
	set_process(false)


func _set_scroll_vertical(value: float) -> void:
	scroll_vertical = roundi(value)
