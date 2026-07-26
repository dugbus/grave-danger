class_name GDQuickExit
extends Node

const RUN_RECORDER_GROUP: StringName = &"run_recorder"

var quit_requested := false


func _ready() -> void:
    get_tree().auto_accept_quit = false


func _notification(what: int) -> void:
    if what == NOTIFICATION_WM_CLOSE_REQUEST:
        _request_quit()


func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed("ui_cancel"):
        _request_quit()
        get_viewport().set_input_as_handled()


func _request_quit() -> void:
    if quit_requested:
        return
    quit_requested = true
    _finish_pending_run_recordings()
    get_tree().quit()


func _finish_pending_run_recordings() -> void:
    get_tree().call_group(RUN_RECORDER_GROUP, "finish_recording")
    var level_selection := get_node_or_null("/root/LevelSelection")
    if level_selection != null \
            and level_selection.has_method("wait_for_run_recording_saves"):
        level_selection.wait_for_run_recording_saves()
