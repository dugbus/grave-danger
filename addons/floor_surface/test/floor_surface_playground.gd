class_name FloorSurfacePlayground
extends Node3D

## Runtime coordinator for the isolated human-testable floor-surface fixture.

const FIXTURE_ID := "M5 / styled-mixed-rim-pit-v1"
const CAMERA_VIEW_COUNT := 3
const TRIAL_COUNT := 3
const HUD_REFRESH_SECONDS := 0.1
const CAMERA_SETTINGS_SCRIPT := preload(
	"res://addons/floor_surface/test/floor_surface_camera_settings.gd"
)
const PLAYER_SCRIPT := preload(
	"res://addons/floor_surface/test/floor_surface_test_player.gd"
)
const SURFACE_SCRIPT := preload("res://addons/floor_surface/floor_surface.gd")
const SAMPLE_SCRIPT := preload("res://addons/floor_surface/floor_surface_sample.gd")
const MAP_SCRIPT := preload("res://addons/floor_surface/floor_map.gd")

## Independent camera arrangements used by this playground only.
@export var camera_settings: CAMERA_SETTINGS_SCRIPT
## Camera switched between the named evaluation arrangements.
@export var camera_path: NodePath = ^"Camera3D"
## Standalone player whose state appears in the debug panel.
@export var player_path: NodePath = ^"Player"
## Isolated surface queried by the debug panel; production floors remain unrelated.
@export var surface_path: NodePath = ^"FloorSurface"
## Label updated with live controller and future floor-surface information.
@export var status_label_path: NodePath = ^"HUD/Panel/Margin/Rows/Status"
## Repeatable main, low-lane and high-lane player reset points cycled with T.
@export var trial_start_paths: Array[NodePath] = []
## Camera focus points paired with the repeatable trial starts.
@export var trial_focus_paths: Array[NodePath] = []
## Human-readable trial names shown in the runtime HUD.
@export var trial_names: Array[String] = []

@onready var evaluation_camera := get_node_or_null(camera_path) as Camera3D
@onready var player := get_node_or_null(player_path) as PLAYER_SCRIPT
@onready var floor_surface := get_node_or_null(surface_path) as SURFACE_SCRIPT
@onready var status_label := get_node_or_null(status_label_path) as Label

var current_camera_view := CAMERA_SETTINGS_SCRIPT.CameraView.Overview
var current_trial := 0
var _hud_elapsed_seconds := HUD_REFRESH_SECONDS
var _trial_starts: Array[Node3D] = []
var _trial_focuses: Array[Node3D] = []
var _camera_focus := Vector3.ZERO


func _ready() -> void:
	_resolve_trial_nodes()
	_select_trial(0, false)
	apply_camera_view(current_camera_view)
	_update_status()


func _process(delta: float) -> void:
	_hud_elapsed_seconds += delta
	if _hud_elapsed_seconds < HUD_REFRESH_SECONDS:
		return
	_hud_elapsed_seconds = 0.0
	_update_status()


func _unhandled_key_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	if event.keycode == KEY_V:
		cycle_camera_view()
		get_viewport().set_input_as_handled()
	elif event.keycode == KEY_T:
		cycle_trial()
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
	evaluation_camera.global_position = camera_settings.get_view_position(view) + _camera_focus
	evaluation_camera.look_at(camera_settings.get_view_target(view) + _camera_focus, Vector3.UP)
	evaluation_camera.size = camera_settings.get_view_size(view)


## Returns the current human-readable camera arrangement.
func get_camera_view_name() -> String:
	if camera_settings == null:
		return "Unavailable"
	return camera_settings.get_view_name(current_camera_view)


## Advances among the accepted room and the two local-delta comparison lanes.
func cycle_trial() -> void:
	if _trial_starts.is_empty():
		return
	_select_trial((current_trial + 1) % mini(TRIAL_COUNT, _trial_starts.size()), true)


## Returns the current repeatable trial's human-readable name.
func get_trial_name() -> String:
	if current_trial >= 0 and current_trial < trial_names.size():
		return trial_names[current_trial]
	return "Floor surface"


func _update_status() -> void:
	if status_label == null:
		return
	var player_position := player.global_position if player != null else Vector3.ZERO
	var grounded_text := "yes" if player != null and player.is_on_floor() else "no"
	var controller_text := "Unavailable"
	if player != null and player.settings != null:
		controller_text = "%s | %.1f m/s | jump %.2f m | step %.2f m | slope %.0f°" % [
			player.get_traversal_mode_name(),
			player.settings.movement_speed,
			player.settings.get_jump_height(player.traversal_mode),
			player.settings.maximum_step_height,
			player.settings.maximum_floor_angle_degrees,
		]
	var sample: SAMPLE_SCRIPT = null
	if floor_surface != null:
		sample = floor_surface.sample_surface(player_position)
	var surface_text := _format_surface_status(sample)
	status_label.text = (
		"Fixture: %s\nTrial: %s\nCamera: %s\nPlayer: (%.2f, %.2f, %.2f) | grounded: %s\n"
		+ "Controller: %s\n\n%s"
	) % [
		FIXTURE_ID,
		get_trial_name(),
		get_camera_view_name(),
		player_position.x,
		player_position.y,
		player_position.z,
		grounded_text,
		controller_text,
		surface_text,
	]


func _format_surface_status(sample: SAMPLE_SCRIPT) -> String:
	if floor_surface == null or sample == null:
		return "Floor surface: unavailable"
	var elevation_unit := floor_surface.elevation_profile.elevation_unit \
		if floor_surface.elevation_profile != null else 0.0
	if not sample.valid:
		return (
			"Floor surface: NO SURFACE\nCell: (%d, %d) | sampled height: unavailable\n"
			+ "Unit: %.2f m | normal: unavailable | transition: unavailable"
		) % [sample.cell.x, sample.cell.y, elevation_unit]
	return (
		"Floor surface: valid\nCell: (%d, %d) | sampled height: %.2f m\n"
		+ "Elevation: %d units | unit: %.2f m | normal: (%.1f, %.1f, %.1f)\n"
		+ "East edge: %s | delta: %s\nStyle: %d — %s | transition: %s"
	) % [
		sample.cell.x,
		sample.cell.y,
		sample.world_height,
		floor_surface.get_cell_elevation(sample.cell),
		elevation_unit,
		sample.surface_normal.x,
		sample.surface_normal.y,
		sample.surface_normal.z,
		_get_east_traversal_name(sample.cell),
		_get_east_delta_text(sample.cell),
		sample.style_index,
		_get_style_name(sample.style_index),
		floor_surface.floor_map.get_transition_name(sample.transition),
	]


func _get_style_name(style_index: int) -> String:
	if style_index < 0 or style_index >= floor_surface.styles.size():
		return "Invalid"
	return floor_surface.styles[style_index].display_name


func _resolve_trial_nodes() -> void:
	_trial_starts.clear()
	_trial_focuses.clear()
	for path in trial_start_paths:
		var marker := get_node_or_null(path) as Node3D
		if marker != null:
			_trial_starts.append(marker)
	for path in trial_focus_paths:
		var marker := get_node_or_null(path) as Node3D
		if marker != null:
			_trial_focuses.append(marker)


func _select_trial(index: int, reset_player: bool) -> void:
	if _trial_starts.is_empty():
		return
	current_trial = clampi(index, 0, _trial_starts.size() - 1)
	var start := _trial_starts[current_trial]
	if player != null:
		player.set_reset_marker(start)
		if reset_player:
			player.reset_to_start()
	_camera_focus = _trial_focuses[current_trial].global_position \
		if current_trial < _trial_focuses.size() else Vector3.ZERO
	apply_camera_view(current_camera_view)
	_update_status()


func _get_east_traversal_name(cell: Vector2i) -> String:
	var east_cell := cell + Vector2i.RIGHT
	if not floor_surface.has_floor(east_cell):
		return "No neighbour"
	return floor_surface.elevation_profile.get_traversal_name(
		floor_surface.classify_edge(cell, east_cell)
	)


func _get_east_delta_text(cell: Vector2i) -> String:
	var delta := floor_surface.get_elevation_delta(cell, cell + Vector2i.RIGHT)
	if delta == MAP_SCRIPT.INVALID_ELEVATION:
		return "—"
	return "%+d units" % delta
