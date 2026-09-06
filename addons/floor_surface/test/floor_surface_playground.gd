class_name FloorSurfacePlayground
extends Node3D

## Runtime coordinator for the isolated human-testable floor-surface fixture.

const FIXTURE_ID := "M1 / isolated-playground-v1"
const CAMERA_VIEW_COUNT := 3
const HUD_REFRESH_SECONDS := 0.1
const CAMERA_SETTINGS_SCRIPT := preload(
	"res://addons/floor_surface/test/floor_surface_camera_settings.gd"
)
const PLAYER_SCRIPT := preload(
	"res://addons/floor_surface/test/floor_surface_test_player.gd"
)

## Independent camera arrangements used by this playground only.
@export var camera_settings: CAMERA_SETTINGS_SCRIPT
## Camera switched between the named evaluation arrangements.
@export var camera_path: NodePath = ^"Camera3D"
## Standalone player whose state appears in the debug panel.
@export var player_path: NodePath = ^"Player"
## Label updated with live controller and future floor-surface information.
@export var status_label_path: NodePath = ^"HUD/Panel/Margin/Rows/Status"

@onready var evaluation_camera := get_node_or_null(camera_path) as Camera3D
@onready var player := get_node_or_null(player_path) as PLAYER_SCRIPT
@onready var status_label := get_node_or_null(status_label_path) as Label

var current_camera_view := CAMERA_SETTINGS_SCRIPT.CameraView.Overview
var _hud_elapsed_seconds := HUD_REFRESH_SECONDS


func _ready() -> void:
	apply_camera_view(current_camera_view)
	_update_status()


func _process(delta: float) -> void:
	_hud_elapsed_seconds += delta
	if _hud_elapsed_seconds < HUD_REFRESH_SECONDS:
		return
	_hud_elapsed_seconds = 0.0
	_update_status()


func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_V:
		cycle_camera_view()
		get_viewport().set_input_as_handled()


## Advances to the next named fixed camera arrangement.
func cycle_camera_view() -> void:
	current_camera_view = (current_camera_view + 1) % CAMERA_VIEW_COUNT
	apply_camera_view(current_camera_view)
	_update_status()


## Applies one named arrangement immediately for repeatable visual comparisons.
func apply_camera_view(view: CAMERA_SETTINGS_SCRIPT.CameraView) -> void:
	current_camera_view = view
	if evaluation_camera == null or camera_settings == null:
		return
	evaluation_camera.global_position = camera_settings.get_view_position(view)
	evaluation_camera.look_at(camera_settings.get_view_target(view), Vector3.UP)
	evaluation_camera.size = camera_settings.get_view_size(view)


## Returns the current human-readable camera arrangement.
func get_camera_view_name() -> String:
	if camera_settings == null:
		return "Unavailable"
	return camera_settings.get_view_name(current_camera_view)


func _update_status() -> void:
	if status_label == null:
		return
	var player_position := player.global_position if player != null else Vector3.ZERO
	var grounded_text := "yes" if player != null and player.is_on_floor() else "no"
	var controller_text := "Unavailable"
	if player != null and player.settings != null:
		controller_text = "%.1f m/s | jump %.2f m | step %.2f m | slope %.0f°" % [
			player.settings.movement_speed,
			player.settings.jump_height,
			player.settings.maximum_step_height,
			player.settings.maximum_floor_angle_degrees,
		]
	status_label.text = (
		"Fixture: %s\nCamera: %s\nPlayer: (%.2f, %.2f, %.2f) | grounded: %s\n"
		+ "Controller: %s\n\nFloor surface: unavailable (M2)\n"
		+ "Cell: unavailable | sampled height: unavailable\n"
		+ "Normal: unavailable | transition: unavailable"
	) % [
		FIXTURE_ID,
		get_camera_view_name(),
		player_position.x,
		player_position.y,
		player_position.z,
		grounded_text,
		controller_text,
	]
