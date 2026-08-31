@tool
class_name GDKillBoundary2BottomPanel
extends VBoxContainer

## Viewport-first authoring panel for the currently selected Kill Boundary 2.

signal preview_changed

var controller := GDKillBoundary2EditorController.new()
var boundary: GDKillBoundary2
var _editor_interface: EditorInterface
var _refreshing := false
var _pose_label: Label
var _pose_option: OptionButton
var _edit_pose_button: Button
var _previous_button: Button
var _next_button: Button
var _delete_button: Button
var _time_spin: SpinBox
var _duration_label: Label
var _easing_label: Label
var _easing_option: OptionButton
var _retiming_option: OptionButton
var _speed_spin: SpinBox
var _loop_return_spin: SpinBox
var _scrubber: HSlider


func _ready() -> void:
	if get_child_count() == 0:
		_build_interface()
	set_process(true)
	_refresh()


func configure_editor_interface(editor_interface: EditorInterface) -> void:
	_editor_interface = editor_interface


func bind_boundary(new_boundary: GDKillBoundary2, undo_redo: EditorUndoRedoManager = null) -> void:
	if boundary != null and boundary != new_boundary:
		boundary.preview_stop()
	if boundary != null and boundary.sequence.sequence_changed.is_connected(_on_sequence_changed):
		boundary.sequence.sequence_changed.disconnect(_on_sequence_changed)
	if (
		boundary != null
		and boundary.editor_active_pose_changed.is_connected(_on_active_pose_changed)
	):
		boundary.editor_active_pose_changed.disconnect(_on_active_pose_changed)
	if (
		boundary != null
		and boundary.playback_configuration_changed.is_connected(_on_playback_configuration_changed)
	):
		boundary.playback_configuration_changed.disconnect(_on_playback_configuration_changed)
	boundary = new_boundary
	controller.configure(boundary, undo_redo)
	if (
		boundary != null
		and not boundary.sequence.sequence_changed.is_connected(_on_sequence_changed)
	):
		boundary.sequence.sequence_changed.connect(_on_sequence_changed)
	if (
		boundary != null
		and not boundary.editor_active_pose_changed.is_connected(_on_active_pose_changed)
	):
		boundary.editor_active_pose_changed.connect(_on_active_pose_changed)
	if (
		boundary != null
		and not boundary.playback_configuration_changed.is_connected(_on_playback_configuration_changed)
	):
		boundary.playback_configuration_changed.connect(_on_playback_configuration_changed)
	_refresh()


func _process(delta: float) -> void:
	if boundary == null:
		return
	boundary.advance_editor_preview(delta)
	if _scrubber == null or _refreshing:
		return
	if not _scrubber.has_focus():
		_scrubber.set_value_no_signal(boundary.get_boundary_animation_position())


func _build_interface() -> void:
	name = "Kill Boundary 2"
	var title := Label.new()
	title.text = (
		"Select the boundary root to manage or delete it. Choose Edit Pose for Move (W), "
		+ "yaw-only Rotate (E), and shape handles."
	)
	add_child(title)

	var navigation := HBoxContainer.new()
	add_child(navigation)
	_pose_label = Label.new()
	_pose_label.custom_minimum_size.x = 150.0
	navigation.add_child(_pose_label)
	_pose_option = OptionButton.new()
	_pose_option.custom_minimum_size.x = 190.0
	_pose_option.tooltip_text = (
		"Choose which pose to edit. The boundary preview jumps to that pose so its shape and "
		+ "position are easy to see."
	)
	_pose_option.item_selected.connect(_on_pose_selected)
	navigation.add_child(_pose_option)
	_edit_pose_button = _add_button(
		navigation,
		"Edit Pose",
		_on_edit_pose_pressed,
		"Select the active Pose in the scene and Inspector so its position, yaw, size, and "
		+ "rounding can be edited in the viewport."
	)
	_previous_button = _add_button(
		navigation,
		"Previous",
		_on_previous_pressed,
		"Edit the pose immediately before this one and show it in the preview."
	)
	_next_button = _add_button(
		navigation,
		"Next",
		_on_next_pressed,
		"Edit the pose immediately after this one and show it in the preview."
	)
	_add_button(
		navigation,
		"Add",
		_on_add_pressed,
		"Add a new default pose one second after the final pose, then select it for editing."
	)
	_add_button(
		navigation,
		"Duplicate",
		_on_duplicate_pressed,
		"Copy this pose one second later. Later poses move forward to keep their timing gaps."
	)
	_delete_button = _add_button(
		navigation,
		"Delete",
		_on_delete_pressed,
		"Remove this pose. At least one pose must remain so the boundary always has a shape."
	)

	var authoring := HBoxContainer.new()
	add_child(authoring)
	var time_help := (
		"Choose when the boundary reaches this pose, measured from the start. Pose 1 always "
		+ "stays at 0 seconds."
	)
	_add_label(authoring, "Absolute time", time_help)
	_time_spin = SpinBox.new()
	_time_spin.min_value = 0.0
	_time_spin.max_value = 100000.0
	_time_spin.step = 0.01
	_time_spin.suffix = " s"
	_time_spin.tooltip_text = time_help
	_time_spin.value_changed.connect(_on_time_changed)
	authoring.add_child(_time_spin)
	_duration_label = _add_label(
		authoring,
		"Duration: —",
		"Shows how long the boundary takes to reach the next pose. Change either pose's "
		+ "Absolute Time to alter it."
	)
	var easing_help := (
		"Choose how movement leaves this pose. Constant moves evenly; Smooth starts and ends "
		+ "gently; Accelerate speeds up; Decelerate slows down."
	)
	_easing_label = _add_label(authoring, "Outgoing easing", easing_help)
	_easing_option = OptionButton.new()
	for easing_value in GDKillBoundary2Pose.TransitionEasing.values():
		var easing := easing_value as GDKillBoundary2Pose.TransitionEasing
		_easing_option.add_item(GDKillBoundary2Pose.TransitionEasing.keys()[easing], easing)
	_easing_option.tooltip_text = easing_help
	_easing_option.item_selected.connect(_on_easing_selected)
	authoring.add_child(_easing_option)
	var retiming_help := (
		"Choose what happens when this pose's time changes. Shift Following keeps every later "
		+ "timing gap; Move This Pose Only changes just this pose and keeps it between its neighbours."
	)
	_add_label(authoring, "Retiming", retiming_help)
	_retiming_option = OptionButton.new()
	for mode_value in GDKillBoundary2Sequence.RetimingMode.values():
		var mode := mode_value as GDKillBoundary2Sequence.RetimingMode
		_retiming_option.add_item(GDKillBoundary2Sequence.RetimingMode.keys()[mode], mode)
	_retiming_option.tooltip_text = retiming_help
	_retiming_option.item_selected.connect(_on_retiming_selected)
	authoring.add_child(_retiming_option)

	var transport := HBoxContainer.new()
	add_child(transport)
	_add_button(
		transport,
		"Start",
		_on_start_pressed,
		"Jump to Pose 1 and pause there, ready to preview from the beginning."
	)
	_add_button(
		transport,
		"Play",
		_on_play_pressed,
		"Run or resume the boundary preview from its current point."
	)
	_add_button(
		transport,
		"Stop",
		_on_stop_pressed,
		"Pause the preview where it is. Press Play to continue from the same point."
	)
	var speed_help := (
		"Make the boundary animation run slower or faster in the preview and during play. "
		+ "The pose times stay unchanged; 0 freezes movement."
	)
	_add_label(transport, "Speed", speed_help)
	_speed_spin = SpinBox.new()
	_speed_spin.min_value = 0.0
	_speed_spin.max_value = 8.0
	_speed_spin.step = 0.05
	_speed_spin.suffix = "×"
	_speed_spin.tooltip_text = speed_help
	_speed_spin.value_changed.connect(_on_speed_changed)
	transport.add_child(_speed_spin)
	var loop_return_help := (
		"In Loop mode, this is how long the boundary takes to move from the final pose back "
		+ "to Pose 1. Increase it for a gentler return or reduce it for a quicker return."
	)
	_add_label(transport, "Loop return", loop_return_help)
	_loop_return_spin = SpinBox.new()
	_loop_return_spin.min_value = 0.01
	_loop_return_spin.max_value = 3600.0
	_loop_return_spin.step = 0.01
	_loop_return_spin.suffix = " s"
	_loop_return_spin.tooltip_text = loop_return_help
	_loop_return_spin.value_changed.connect(_on_loop_return_changed)
	transport.add_child(_loop_return_spin)

	var timeline := HBoxContainer.new()
	timeline.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(timeline)
	var timeline_help := (
		"Drag to inspect any moment of the boundary animation. Scrubbing pauses the preview "
		+ "so the exact shape can be checked."
	)
	_add_label(timeline, "Timeline", timeline_help)
	_scrubber = HSlider.new()
	_scrubber.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scrubber.step = 0.001
	_scrubber.tooltip_text = timeline_help
	_scrubber.value_changed.connect(_on_scrubbed)
	timeline.add_child(_scrubber)


func _add_button(
	parent: Control, text_value: String, callback: Callable, help_text: String
) -> Button:
	var button := Button.new()
	button.text = text_value
	button.tooltip_text = help_text
	button.pressed.connect(callback)
	parent.add_child(button)
	return button


func _add_label(parent: Control, text_value: String, help_text := "") -> Label:
	var label := Label.new()
	label.text = text_value
	label.tooltip_text = help_text
	parent.add_child(label)
	return label


func _refresh() -> void:
	if _pose_label == null:
		return
	_refreshing = true
	var has_boundary := boundary != null
	for control in [
		_previous_button,
		_next_button,
		_delete_button,
		_edit_pose_button,
		_pose_option,
		_time_spin,
		_easing_option,
		_retiming_option,
		_speed_spin,
		_loop_return_spin,
		_scrubber
	]:
		(control as Control).set_process_input(has_boundary)
		(control as Control).mouse_filter = (
			Control.MOUSE_FILTER_STOP if has_boundary else Control.MOUSE_FILTER_IGNORE
		)
	if not has_boundary:
		_pose_label.text = "Select a Kill Boundary 2"
		_refreshing = false
		return
	var count := boundary.sequence.get_pose_count()
	var index := clampi(controller.active_pose_index, 0, count - 1)
	var pose := boundary.sequence.get_pose(index)
	_pose_label.text = "Pose %d of %d" % [index + 1, count]
	_pose_option.clear()
	for pose_index in count:
		var listed_pose := boundary.sequence.get_pose(pose_index)
		_pose_option.add_item(
			"Pose %d — %.2f s" % [pose_index + 1, listed_pose.time_seconds], pose_index
		)
	_pose_option.select(_pose_option.get_item_index(index))
	_previous_button.disabled = index <= 0
	_next_button.disabled = index >= count - 1
	_delete_button.disabled = count <= 1
	_time_spin.editable = index > 0
	_time_spin.value = pose.time_seconds
	var duration := (
		boundary.sequence.get_pose(index + 1).time_seconds - pose.time_seconds
		if index + 1 < count
		else -1.0
	)
	if duration >= 0.0:
		_duration_label.text = "Next duration: %.2f s" % duration
		_easing_label.text = "Outgoing easing"
	elif boundary.playback_mode == GDKillBoundary2Animator.PlaybackMode.Loop:
		_duration_label.text = "Loop return: %.2f s" % boundary.loop_return_seconds
		_easing_label.text = "Loop return easing"
	else:
		_duration_label.text = "Next duration: —"
		_easing_label.text = "Outgoing easing"
	_easing_option.select(_easing_option.get_item_index(pose.outgoing_easing))
	_retiming_option.select(_retiming_option.get_item_index(boundary.retiming_mode))
	_speed_spin.value = boundary.playback_speed
	_loop_return_spin.value = boundary.loop_return_seconds
	_scrubber.max_value = maxf(boundary.sequence.get_duration(), 0.001)
	_scrubber.value = boundary.get_boundary_animation_position()
	_refreshing = false


func _on_previous_pressed() -> void:
	controller.select_pose(controller.active_pose_index - 1)
	_refresh()


func _on_edit_pose_pressed() -> void:
	controller.select_pose(controller.active_pose_index)
	_refresh()


func _on_pose_selected(option_index: int) -> void:
	if _refreshing:
		return
	controller.select_pose(_pose_option.get_item_id(option_index))
	_refresh()


func _on_next_pressed() -> void:
	controller.select_pose(controller.active_pose_index + 1)
	_refresh()


func _on_add_pressed() -> void:
	controller.add_pose()
	_refresh()


func _on_duplicate_pressed() -> void:
	controller.duplicate_pose()
	_refresh()


func _on_delete_pressed() -> void:
	controller.delete_pose()
	_refresh()


func _on_time_changed(value: float) -> void:
	if not _refreshing:
		controller.set_pose_time(value)
		_refresh()


func _on_easing_selected(index: int) -> void:
	if not _refreshing:
		controller.set_pose_easing(
			_easing_option.get_item_id(index) as GDKillBoundary2Pose.TransitionEasing
		)


func _on_retiming_selected(index: int) -> void:
	if not _refreshing and boundary != null:
		controller.set_retiming_mode(
			_retiming_option.get_item_id(index) as GDKillBoundary2Sequence.RetimingMode
		)


func _on_start_pressed() -> void:
	boundary.preview_seek(0.0)
	preview_changed.emit()


func _on_play_pressed() -> void:
	boundary.preview_play()


func _on_stop_pressed() -> void:
	boundary.preview_stop()


func _on_speed_changed(value: float) -> void:
	if not _refreshing:
		controller.set_playback_speed(value)


func _on_loop_return_changed(value: float) -> void:
	if not _refreshing:
		controller.set_loop_return_seconds(value)


func _on_scrubbed(value: float) -> void:
	if not _refreshing:
		boundary.preview_seek(value)
		preview_changed.emit()


func _on_sequence_changed() -> void:
	_refresh()


func _on_active_pose_changed(pose_index: int) -> void:
	controller.active_pose_index = pose_index
	_refresh()
	call_deferred(&"_inspect_active_pose")


func _on_playback_configuration_changed() -> void:
	_refresh()


func _inspect_active_pose() -> void:
	if _editor_interface == null or boundary == null or boundary.sequence == null:
		return
	var pose := boundary.sequence.get_pose(controller.active_pose_index)
	if pose != null:
		_editor_interface.edit_node(pose)
