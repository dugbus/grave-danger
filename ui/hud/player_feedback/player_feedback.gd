class_name GDPlayerFeedback
extends CanvasLayer

## Always-available, debounced controller affordance for marking recorded gameplay.

signal feedback_submitted(note: String)
signal feedback_note_submitted(note: String)
signal feedback_dialog_opened
signal feedback_dialog_closed

const SETTINGS_SCRIPT := preload("res://ui/hud/player_feedback/player_feedback_settings.gd")

enum NoteDialogAction {
    Cancel,
    Proceed,
}

const JOYPAD_AXIS_PRESS_THRESHOLD := 0.6
const JOYPAD_AXIS_RELEASE_THRESHOLD := 0.3

## Shared default mapping and debounce timing for the feedback controls.
@export var settings: Resource
## Authored panel containing the optional written feedback field.
@export var note_panel_path: NodePath = ^"NotePanel"
## Multiline text area used to attach an optional explanation to a feedback marker.
@export var note_field_path: NodePath = ^"NotePanel/Center/Panel/Margin/VBox/NoteField"
## Short confirmation shown after a feedback marker is accepted.
@export var confirmation_label_path: NodePath = ^"Confirmation"
## Large title shown at the top of the centered feedback form.
@export var prompt_label_path: NodePath = ^"NotePanel/Center/Panel/Margin/VBox/Prompt"
## Player-facing instructions shown above the feedback entry field.
@export var instructions_label_path: NodePath = \
    ^"NotePanel/Center/Panel/Margin/VBox/Instructions"
## Joypad-focusable action that attaches the entered note to the marker.
@export var proceed_button_path: NodePath = \
    ^"NotePanel/Center/Panel/Margin/VBox/Actions/ProceedButton"
## Joypad-focusable action that dismisses the form without attaching a note.
@export var cancel_button_path: NodePath = \
    ^"NotePanel/Center/Panel/Margin/VBox/Actions/CancelButton"

@onready var note_panel := get_node_or_null(note_panel_path) as Control
@onready var note_field := get_node_or_null(note_field_path) as TextEdit
@onready var confirmation_label := get_node_or_null(confirmation_label_path) as Label
@onready var prompt_label := get_node_or_null(prompt_label_path) as Label
@onready var instructions_label := get_node_or_null(instructions_label_path) as Label
@onready var proceed_button := get_node_or_null(proceed_button_path) as Button
@onready var cancel_button := get_node_or_null(cancel_button_path) as Button

var report_button: int = SETTINGS_SCRIPT.FeedbackButton.FaceLeft
var text_button: int = SETTINGS_SCRIPT.FeedbackButton.Disabled
var _pressed_buttons: Dictionary = {}
var _last_press_milliseconds: Dictionary = {}
var _note_offer_until_milliseconds := -1
var _confirmation_tween: Tween
var _selected_note_action := NoteDialogAction.Proceed
var _joypad_horizontal_direction := 0
var _joypad_vertical_direction := 0


func _ready() -> void:
    if settings == null:
        settings = SETTINGS_SCRIPT.new()
    process_mode = Node.PROCESS_MODE_ALWAYS
    report_button = settings.report_button
    text_button = settings.text_button
    if note_panel != null:
        note_panel.hide()
    if confirmation_label != null:
        GDGameFont.apply_to_label(confirmation_label)
        confirmation_label.hide()
    GDGameFont.apply_to_label(prompt_label)
    GDGameFont.apply_to_label(instructions_label)
    if note_field != null:
        GDGameFont.apply_to_text_edit(note_field)
        note_field.text_changed.connect(_on_note_text_changed)
    if proceed_button != null:
        GDGameFont.apply_to_button(proceed_button)
        proceed_button.pressed.connect(_on_proceed_pressed)
        proceed_button.mouse_entered.connect(proceed_button.grab_focus)
        proceed_button.focus_entered.connect(_on_proceed_focus_entered)
    if cancel_button != null:
        GDGameFont.apply_to_button(cancel_button)
        cancel_button.pressed.connect(_on_cancel_pressed)
        cancel_button.mouse_entered.connect(cancel_button.grab_focus)
        cancel_button.focus_entered.connect(_on_cancel_focus_entered)
    _configure_note_focus()


func _input(event: InputEvent) -> void:
    if note_panel != null and note_panel.visible:
        var key_event := event as InputEventKey
        if key_event != null:
            _route_keyboard_to_note_field(key_event)
            get_viewport().set_input_as_handled()
            return
        var dialog_button_event := event as InputEventJoypadButton
        if dialog_button_event != null and _handle_dialog_joypad_button(
            dialog_button_event
        ):
            get_viewport().set_input_as_handled()
            return
        var motion_event := event as InputEventJoypadMotion
        if motion_event != null and _handle_dialog_joypad_motion(motion_event):
            get_viewport().set_input_as_handled()
        return

    var button_event := event as InputEventJoypadButton
    if button_event == null:
        return
    var button_index := button_event.button_index
    if not button_event.pressed:
        _pressed_buttons.erase(button_index)
        return
    if bool(_pressed_buttons.get(button_index, false)) or not _debounce_allows(button_index):
        return
    _pressed_buttons[button_index] = true

    if button_index == report_button:
        _submit_feedback("", true)
        get_viewport().set_input_as_handled()
    elif button_index == text_button \
            and Time.get_ticks_msec() <= _note_offer_until_milliseconds:
        _show_note_field()
        get_viewport().set_input_as_handled()


## Lets a directed Codex playtest override the two face-button operations.
func configure_buttons(
    configured_report_button: int,
    configured_text_button: int
) -> void:
    report_button = configured_report_button
    text_button = configured_text_button


## Shows whether the commit-ready report and playback were stored successfully.
func show_repository_status(message: String, succeeded: bool) -> void:
    if confirmation_label == null:
        return
    confirmation_label.add_theme_color_override(
        "font_color",
        Color(1.0, 0.84, 0.2) if succeeded else Color(1.0, 0.42, 0.3)
    )
    _show_confirmation(message, 2.0)


func _debounce_allows(button_index: int) -> bool:
    var now := Time.get_ticks_msec()
    var previous := int(_last_press_milliseconds.get(button_index, -1_000_000))
    if now - previous < roundi(settings.debounce_seconds * 1000.0):
        return false
    _last_press_milliseconds[button_index] = now
    return true


func _show_note_field() -> void:
    if note_panel == null or note_field == null:
        return
    if note_panel.visible:
        return
    note_panel.show()
    note_field.clear()
    _select_note_action(NoteDialogAction.Proceed)
    feedback_dialog_opened.emit()


func _on_proceed_pressed() -> void:
    var note := note_field.text if note_field != null else ""
    _close_note_field()
    _submit_feedback(note.strip_edges(), false)


func _on_cancel_pressed() -> void:
    _close_note_field()


func _on_note_text_changed() -> void:
    if note_field == null or note_field.text.length() <= settings.maximum_note_characters:
        return
    note_field.text = note_field.text.left(settings.maximum_note_characters)
    var final_line := maxi(note_field.get_line_count() - 1, 0)
    note_field.set_caret_line(final_line)
    note_field.set_caret_column(note_field.get_line(final_line).length())


func _configure_note_focus() -> void:
    if note_field == null or proceed_button == null or cancel_button == null:
        return
    note_field.focus_mode = Control.FOCUS_CLICK
    proceed_button.focus_neighbor_top = proceed_button.get_path_to(proceed_button)
    proceed_button.focus_neighbor_bottom = proceed_button.get_path_to(proceed_button)
    proceed_button.focus_neighbor_left = proceed_button.get_path_to(cancel_button)
    proceed_button.focus_neighbor_right = proceed_button.get_path_to(proceed_button)
    cancel_button.focus_neighbor_top = cancel_button.get_path_to(cancel_button)
    cancel_button.focus_neighbor_bottom = cancel_button.get_path_to(cancel_button)
    cancel_button.focus_neighbor_left = cancel_button.get_path_to(cancel_button)
    cancel_button.focus_neighbor_right = cancel_button.get_path_to(proceed_button)


func _route_keyboard_to_note_field(key_event: InputEventKey) -> void:
    if note_field == null or not key_event.pressed:
        return
    if key_event.keycode == KEY_ESCAPE:
        _on_cancel_pressed()
        return

    var shortcut_pressed := key_event.ctrl_pressed or key_event.meta_pressed
    if shortcut_pressed:
        match key_event.keycode:
            KEY_A:
                note_field.select_all()
            KEY_C:
                note_field.copy()
            KEY_X:
                note_field.cut()
            KEY_V:
                note_field.paste()
            KEY_Z:
                if key_event.shift_pressed:
                    note_field.redo()
                else:
                    note_field.undo()
        return

    match key_event.keycode:
        KEY_BACKSPACE:
            note_field.backspace()
        KEY_DELETE:
            _delete_note_character_at_caret()
        KEY_ENTER, KEY_KP_ENTER:
            note_field.insert_text_at_caret("\n")
        KEY_TAB:
            note_field.insert_text_at_caret("\t")
        KEY_LEFT:
            _move_note_caret_horizontal(-1)
        KEY_RIGHT:
            _move_note_caret_horizontal(1)
        KEY_UP:
            _move_note_caret_vertical(-1)
        KEY_DOWN:
            _move_note_caret_vertical(1)
        KEY_HOME:
            note_field.set_caret_column(0)
        KEY_END:
            note_field.set_caret_column(
                note_field.get_line(note_field.get_caret_line()).length()
            )
        _:
            if key_event.unicode >= 32 and not key_event.alt_pressed:
                note_field.insert_text_at_caret(String.chr(key_event.unicode))


func _delete_note_character_at_caret() -> void:
    if note_field.has_selection():
        note_field.delete_selection()
        return
    var line := note_field.get_caret_line()
    var column := note_field.get_caret_column()
    if column < note_field.get_line(line).length():
        note_field.remove_text(line, column, line, column + 1)
    elif line + 1 < note_field.get_line_count():
        note_field.remove_text(line, column, line + 1, 0)


func _move_note_caret_horizontal(direction: int) -> void:
    var line := note_field.get_caret_line()
    var column := note_field.get_caret_column()
    if direction < 0:
        if column > 0:
            column -= 1
        elif line > 0:
            line -= 1
            column = note_field.get_line(line).length()
    elif column < note_field.get_line(line).length():
        column += 1
    elif line + 1 < note_field.get_line_count():
        line += 1
        column = 0
    note_field.set_caret_line(line)
    note_field.set_caret_column(column)


func _move_note_caret_vertical(direction: int) -> void:
    var line := clampi(
        note_field.get_caret_line() + direction,
        0,
        note_field.get_line_count() - 1
    )
    var column := mini(
        note_field.get_caret_column(),
        note_field.get_line(line).length()
    )
    note_field.set_caret_line(line)
    note_field.set_caret_column(column)


func _handle_dialog_joypad_button(button_event: InputEventJoypadButton) -> bool:
    var button_index := button_event.button_index
    if not button_event.pressed:
        _pressed_buttons.erase(button_index)
        return true
    if bool(_pressed_buttons.get(button_index, false)) or not _debounce_allows(button_index):
        return true
    _pressed_buttons[button_index] = true

    match button_index:
        JOY_BUTTON_DPAD_LEFT, JOY_BUTTON_DPAD_UP:
            _select_note_action(NoteDialogAction.Cancel)
        JOY_BUTTON_DPAD_RIGHT, JOY_BUTTON_DPAD_DOWN:
            _select_note_action(NoteDialogAction.Proceed)
        JOY_BUTTON_A:
            _activate_selected_note_action()
        JOY_BUTTON_B:
            _on_cancel_pressed()
        _:
            if button_index == report_button:
                _on_cancel_pressed()
            else:
                return false
    return true


func _handle_dialog_joypad_motion(motion_event: InputEventJoypadMotion) -> bool:
    if motion_event.axis == JOY_AXIS_LEFT_X:
        var direction := _get_axis_direction(
            motion_event.axis_value,
            _joypad_horizontal_direction
        )
        if direction == _joypad_horizontal_direction:
            return false
        _joypad_horizontal_direction = direction
        if direction != 0:
            _select_note_action(
                NoteDialogAction.Proceed if direction > 0 else NoteDialogAction.Cancel
            )
            return true
    elif motion_event.axis == JOY_AXIS_LEFT_Y:
        var direction := _get_axis_direction(
            motion_event.axis_value,
            _joypad_vertical_direction
        )
        if direction == _joypad_vertical_direction:
            return false
        _joypad_vertical_direction = direction
        if direction != 0:
            _select_note_action(
                NoteDialogAction.Proceed if direction > 0 else NoteDialogAction.Cancel
            )
            return true
    return false


func _get_axis_direction(axis_value: float, previous_direction: int) -> int:
    if absf(axis_value) <= JOYPAD_AXIS_RELEASE_THRESHOLD:
        return 0
    if absf(axis_value) < JOYPAD_AXIS_PRESS_THRESHOLD:
        return previous_direction
    return 1 if axis_value > 0.0 else -1


func _select_note_action(action: NoteDialogAction) -> void:
    _selected_note_action = action
    if action == NoteDialogAction.Cancel and cancel_button != null:
        cancel_button.grab_focus()
    elif proceed_button != null:
        proceed_button.grab_focus()


func _activate_selected_note_action() -> void:
    if _selected_note_action == NoteDialogAction.Cancel:
        _on_cancel_pressed()
    else:
        _on_proceed_pressed()


func _on_cancel_focus_entered() -> void:
    _selected_note_action = NoteDialogAction.Cancel


func _on_proceed_focus_entered() -> void:
    _selected_note_action = NoteDialogAction.Proceed


func _submit_feedback(note: String, offer_note: bool) -> void:
    var clean_note := note.left(settings.maximum_note_characters)
    if offer_note:
        feedback_submitted.emit(clean_note)
    else:
        feedback_note_submitted.emit(clean_note)
    _note_offer_until_milliseconds = (
        Time.get_ticks_msec() + roundi(settings.note_offer_seconds * 1000.0)
        if offer_note else -1
    )
    if offer_note:
        _show_note_field()
    if confirmation_label == null:
        return
    var confirmation_text := (
        "FEEDBACK MARKED"
        if offer_note else "FEEDBACK NOTE SAVED"
    )
    _show_confirmation(confirmation_text, 1.0)


func _close_note_field() -> void:
    if note_panel == null or not note_panel.visible:
        return
    note_panel.hide()
    if note_field != null:
        note_field.clear()
    feedback_dialog_closed.emit()


func _show_confirmation(message: String, hold_seconds: float) -> void:
    confirmation_label.text = message
    confirmation_label.modulate.a = 1.0
    confirmation_label.show()
    if _confirmation_tween != null:
        _confirmation_tween.kill()
    _confirmation_tween = create_tween()
    _confirmation_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
    _confirmation_tween.tween_interval(hold_seconds)
    _confirmation_tween.tween_property(confirmation_label, "modulate:a", 0.0, 0.25)
    _confirmation_tween.tween_callback(confirmation_label.hide)
