class_name GDFrontendScreen
extends Control

## Shared reference-canvas scaling, primary-input parsing, and menu audio support.

## Reference canvas used for editor-authored frontend placement before uniform scaling.
@export var reference_screen_size := Vector2(1920.0, 1080.0):
    set(value):
        reference_screen_size = Vector2(maxf(value.x, 1.0), maxf(value.y, 1.0))
        _sync_screen_container()
## Canvas containing controls authored in reference-screen coordinates.
@export var screen_container_path: NodePath = ^"ScreenContainer"

var screen_container: Control


func _notification(what: int) -> void:
    if what == NOTIFICATION_RESIZED:
        _sync_screen_container()


func _sync_screen_container() -> void:
    if screen_container == null:
        screen_container = get_node_or_null(screen_container_path) as Control
    if screen_container == null:
        return

    var viewport_size := size
    if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
        if not is_inside_tree():
            return
        viewport_size = get_viewport_rect().size
    var scale_factor := minf(
        viewport_size.x / reference_screen_size.x,
        viewport_size.y / reference_screen_size.y
    )
    var scaled_size := reference_screen_size * scale_factor
    screen_container.position = (viewport_size - scaled_size) * 0.5
    screen_container.size = reference_screen_size
    screen_container.scale = Vector2.ONE * scale_factor


func _is_accept_event(event: InputEvent) -> bool:
    if InputMap.has_action("ui_accept") and event.is_action_pressed("ui_accept"):
        return true
    if event is InputEventJoypadButton:
        return event.pressed and event.button_index == JOY_BUTTON_A
    if event is InputEventKey:
        return event.pressed and not event.echo and (
            event.physical_keycode == KEY_ENTER or event.physical_keycode == KEY_SPACE
        )
    return false


func _play_select_sound() -> void:
    var frontend_audio := get_node_or_null("/root/FrontendAudio") as GDFrontendAudio
    if frontend_audio != null:
        frontend_audio.play_select()
