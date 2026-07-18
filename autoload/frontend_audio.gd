class_name GDFrontendAudio
extends Node

## Shared frontend sound playback and joypad-focus feedback across menu scenes.

const AUDIO_SCRIPT := preload("res://game/audio.gd")
const MOVE_CURSOR_SOUND_PATH := "res://Assets/audio/frontend-move-cursor.mp3"
const PURCHASE_SOUND_PATH := "res://Assets/audio/frontend-purchase.mp3"
const SELECT_SOUND_PATH := "res://Assets/audio/frontend-select.mp3"

enum FrontendSound {
    MoveCursor,
    Purchase,
    Select,
}

var last_focused_control: Control
var last_input_was_joypad := false
var explicit_focus_change_in_progress := false
var sound_streams: Dictionary = {}


func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    sound_streams = {
        FrontendSound.MoveCursor: AUDIO_SCRIPT.load_stream(MOVE_CURSOR_SOUND_PATH),
        FrontendSound.Purchase: AUDIO_SCRIPT.load_stream(PURCHASE_SOUND_PATH),
        FrontendSound.Select: AUDIO_SCRIPT.load_stream(SELECT_SOUND_PATH),
    }
    get_viewport().gui_focus_changed.connect(_on_gui_focus_changed)


func _input(event: InputEvent) -> void:
    if event is InputEventJoypadButton:
        last_input_was_joypad = event.pressed and _is_navigation_button(event.button_index)
    elif event is InputEventJoypadMotion:
        if event.axis in [JOY_AXIS_LEFT_X, JOY_AXIS_LEFT_Y] \
                and absf(event.axis_value) >= 0.5:
            last_input_was_joypad = true
    elif event is InputEventKey or event is InputEventMouse:
        last_input_was_joypad = false


func play_select() -> void:
    _play_sound(FrontendSound.Select)


func play_move_cursor() -> void:
    _play_sound(FrontendSound.MoveCursor)


func play_purchase() -> void:
    _play_sound(FrontendSound.Purchase)


func begin_explicit_focus_change() -> void:
    explicit_focus_change_in_progress = true


func end_explicit_focus_change() -> void:
    explicit_focus_change_in_progress = false


func _play_sound(sound: FrontendSound) -> void:
    var sound_stream := sound_streams.get(sound) as AudioStream
    if sound_stream == null:
        return
    AUDIO_SCRIPT.play_one_shot(self, sound_stream, _get_sound_name(sound))


func _get_sound_name(sound: FrontendSound) -> String:
    match sound:
        FrontendSound.MoveCursor:
            return "FrontendMoveCursor"
        FrontendSound.Purchase:
            return "FrontendPurchase"
        _:
            return "FrontendSelect"


func _is_navigation_button(button_index: JoyButton) -> bool:
    return button_index in [
        JOY_BUTTON_DPAD_UP,
        JOY_BUTTON_DPAD_DOWN,
        JOY_BUTTON_DPAD_LEFT,
        JOY_BUTTON_DPAD_RIGHT,
    ]


func _on_gui_focus_changed(control: Control) -> void:
    if not explicit_focus_change_in_progress and last_input_was_joypad \
            and last_focused_control != null and control != null \
            and control != last_focused_control:
        play_move_cursor()
    last_focused_control = control
