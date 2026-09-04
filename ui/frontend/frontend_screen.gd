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
var observed_viewport: Viewport


func _enter_tree() -> void:
	observed_viewport = get_viewport()
	if not observed_viewport.size_changed.is_connected(_on_viewport_size_changed):
		observed_viewport.size_changed.connect(_on_viewport_size_changed)
	_sync_screen_container.call_deferred()


func _exit_tree() -> void:
	if observed_viewport != null \
			and observed_viewport.size_changed.is_connected(_on_viewport_size_changed):
		observed_viewport.size_changed.disconnect(_on_viewport_size_changed)
	observed_viewport = null


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_sync_screen_container()


func _on_viewport_size_changed() -> void:
	# Native fullscreen and HiDPI windows can settle over more than one layout pass.
	_sync_screen_container.call_deferred()


func _sync_screen_container() -> void:
	if screen_container == null:
		screen_container = get_node_or_null(screen_container_path) as Control
	if screen_container == null:
		return
	if _is_root_window_screen():
		# The root viewport owns whole-screen scaling. Keeping this reference canvas
		# unscaled lets anchors, fonts, input, and minimum sizes use Godot's stretch.
		screen_container.position = Vector2.ZERO
		screen_container.size = reference_screen_size
		screen_container.scale = Vector2.ONE
		return

	var available_size := _get_available_screen_size()
	if available_size.x <= 0.0 or available_size.y <= 0.0:
		return
	var scale_factor := minf(
		available_size.x / reference_screen_size.x,
		available_size.y / reference_screen_size.y
	)
	var scaled_size := reference_screen_size * scale_factor
	screen_container.position = (available_size - scaled_size) * 0.5
	screen_container.size = reference_screen_size
	screen_container.scale = Vector2.ONE * scale_factor


func _get_available_screen_size() -> Vector2:
	# SubViewport-driven screenshots need to fit their reference canvas explicitly;
	# root-window screens are handled by the project's canvas_items stretch settings.
	if is_inside_tree() and get_parent() is Viewport:
		return get_viewport_rect().size
	# Embedded gallery previews are parented to Controls and intentionally use their
	# authored card size instead of expanding to the gallery's complete viewport.
	return size


func _is_root_window_screen() -> bool:
	return is_inside_tree() and get_parent() == get_tree().root


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
