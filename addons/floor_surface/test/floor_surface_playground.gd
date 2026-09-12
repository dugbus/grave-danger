class_name FloorSurfacePlayground
extends Node3D

## Runtime coordinator for the isolated human-testable floor-surface fixture.

const FIXTURE_ID := "M10 / complete-floor-surface-playground-v1"
const CAMERA_VIEW_COUNT := 3
const TRIAL_COUNT := 9
const HUD_REFRESH_SECONDS := 0.1
const CAMERA_SETTINGS_SCRIPT := preload(
	"res://addons/floor_surface/test/floor_surface_camera_settings.gd"
)
const PLAYER_SCRIPT := preload(
	"res://player/player.gd"
)
const CAMERA_SCRIPT := preload("res://game/follow_camera.gd")
const SURFACE_SCRIPT := preload("res://addons/floor_surface/floor_surface.gd")
const SAMPLE_SCRIPT := preload("res://addons/floor_surface/floor_surface_sample.gd")
const MAP_SCRIPT := preload("res://addons/floor_surface/floor_map.gd")
const VISIBILITY_SCRIPT := preload(
	"res://player/visibility/player_occlusion_silhouette.gd"
)

## Independent camera arrangements used by this playground only.
@export var camera_settings: CAMERA_SETTINGS_SCRIPT
## Production follow camera switched between named evaluation angles.
@export var camera_path: NodePath = ^"Camera3D"
## Actual production player whose state appears in the diagnostics.
@export var player_path: NodePath = ^"Player"
## Isolated surface queried by the debug panel; production floors remain unrelated.
@export var surface_path: NodePath = ^"FloorSurface"
## Label updated with live controller and future floor-surface information.
@export var status_label_path: NodePath = ^"HUD/Panel/Margin/Rows/Status"
## Player-owned silhouette shared with ordinary gameplay levels.
@export var visibility_path: NodePath = ^"Player/PlayerOcclusionSilhouette"
## Diagnostics canvas that can be hidden during an unobstructed visual comparison.
@export var hud_path: NodePath = ^"HUD"
## Shows detailed diagnostics on launch; leave disabled for an unobstructed play view.
@export var show_diagnostics_on_start := false
## Repeatable room, comparison-lane, pyramid-route and gradient-wall reset points cycled with T.
@export var trial_start_paths: Array[NodePath] = []
## Human-readable trial names shown in the runtime HUD.
@export var trial_names: Array[String] = []

@onready var evaluation_camera := get_node_or_null(camera_path) as CAMERA_SCRIPT
@onready var player := get_node_or_null(player_path) as PLAYER_SCRIPT
@onready var floor_surface := get_node_or_null(surface_path) as SURFACE_SCRIPT
@onready var status_label := get_node_or_null(status_label_path) as Label
@onready var visibility_experiment := get_node_or_null(visibility_path) as VISIBILITY_SCRIPT
@onready var hud := get_node_or_null(hud_path) as CanvasLayer

var current_camera_view := CAMERA_SETTINGS_SCRIPT.CameraView.Overview
var current_trial := 0
var _hud_elapsed_seconds := HUD_REFRESH_SECONDS
var _trial_starts: Array[Node3D] = []


func _ready() -> void:
	_resolve_trial_nodes()
	_select_trial(0, true)
	apply_camera_view(current_camera_view)
	_update_status()
	if hud != null:
		hud.visible = show_diagnostics_on_start


func _physics_process(_delta: float) -> void:
	# The real player's normal fall death is intentionally left intact. Reset just before its
	# production -4m threshold so repeated visibility passes do not leave this fixture.
	if player != null and player.global_position.y < -2.5:
		_reset_player_to_current_trial()


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
	elif event.keycode == KEY_R:
		_reset_player_to_current_trial()
		get_viewport().set_input_as_handled()
	elif event.keycode == KEY_F:
		if visibility_experiment != null:
			visibility_experiment.set_visibility_enabled(
				not visibility_experiment.visibility_enabled
			)
		_update_status()
		get_viewport().set_input_as_handled()
	elif event.keycode == KEY_H:
		if hud != null:
			hud.visible = not hud.visible
		get_viewport().set_input_as_handled()


## Advances to the next named fixed camera arrangement.
func cycle_camera_view() -> void:
	current_camera_view = (current_camera_view + 1) % CAMERA_VIEW_COUNT
	apply_camera_view(current_camera_view)
	_update_status()


## Applies one production-camera angle immediately for repeatable visual comparisons.
func apply_camera_view(view: CAMERA_SETTINGS_SCRIPT.CameraView) -> void:
	current_camera_view = view
	if evaluation_camera == null or camera_settings == null or player == null:
		return
	var authored_offset := (
		camera_settings.get_view_position(view) - camera_settings.get_view_target(view)
	)
	var horizontal_distance := Vector2(authored_offset.x, authored_offset.z).length()
	evaluation_camera.camera_yaw = atan2(authored_offset.x, authored_offset.z)
	evaluation_camera.view_elevation_degrees = rad_to_deg(
		atan2(maxf(authored_offset.y, 0.01), maxf(horizontal_distance, 0.01))
	)
	evaluation_camera.zoom_distance = maxf(camera_settings.get_view_size(view), 4.2)
	evaluation_camera.set_runtime_targets(player, null)


## Returns the current human-readable camera arrangement.
func get_camera_view_name() -> String:
	if camera_settings == null:
		return "Unavailable"
	return camera_settings.get_view_name(current_camera_view)


## Advances among the accepted room, comparison lanes and authored ramp route.
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
	var controller_text := "Actual GDPlayer | production movement, weight, animation and lighting"
	var sample: SAMPLE_SCRIPT = null
	if floor_surface != null:
		sample = floor_surface.sample_surface(player_position)
	var surface_text := _format_surface_status(sample)
	var visibility_text := "Visibility: unavailable"
	if visibility_experiment != null:
		visibility_text = (
			"Visibility: %s | player meshes: %d | FPS: %d\n"
			+ "Solid fill: #%s | bright outline: #%s | edge: %.3f m | depth bias: %.3f m\n"
			+ "Scene rendering: unchanged; overlay appears only behind opaque depth"
		) % [
			visibility_experiment.get_visibility_status_name(),
			visibility_experiment.get_silhouette_mesh_count(),
			Engine.get_frames_per_second(),
			visibility_experiment.silhouette_fill_colour.to_html(false),
			visibility_experiment.silhouette_outline_colour.to_html(false),
			visibility_experiment.outline_width,
			visibility_experiment.occlusion_depth_bias,
		]
	status_label.text = (
		"Fixture: %s\nTrial: %s\nCamera: %s\nPlayer: (%.2f, %.2f, %.2f) | grounded: %s\n"
		+ "Controller: %s\n%s\n\n%s"
	) % [
		FIXTURE_ID,
		get_trial_name(),
		get_camera_view_name(),
		player_position.x,
		player_position.y,
		player_position.z,
		grounded_text,
		controller_text,
		visibility_text,
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
		+ "East edge: %s | delta: %s\nStyle: %d — %s | transition: %s | low edge: %s\n"
		+ "Map: %d × %d / %d tops | last rebuild: %.2f ms"
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
		floor_surface.floor_map.get_low_edge_name(
			floor_surface.floor_map.get_cell_low_edge(sample.cell)
		),
		floor_surface.floor_map.dimensions.x,
		floor_surface.floor_map.dimensions.y,
		floor_surface.get_generated_cell_count(),
		float(floor_surface.get_last_rebuild_microseconds()) / 1000.0,
	]


func _get_style_name(style_index: int) -> String:
	if style_index < 0 or style_index >= floor_surface.styles.size():
		return "Invalid"
	return floor_surface.styles[style_index].display_name


func _resolve_trial_nodes() -> void:
	_trial_starts.clear()
	for path in trial_start_paths:
		var marker := get_node_or_null(path) as Node3D
		if marker != null:
			_trial_starts.append(marker)


func _select_trial(index: int, reset_player: bool) -> void:
	if _trial_starts.is_empty():
		return
	current_trial = clampi(index, 0, _trial_starts.size() - 1)
	if reset_player:
		_reset_player_to_current_trial()
	apply_camera_view(current_camera_view)
	_update_status()


func _reset_player_to_current_trial() -> void:
	if player == null or current_trial < 0 or current_trial >= _trial_starts.size():
		return
	player.global_transform = _trial_starts[current_trial].global_transform
	player.velocity = Vector3.ZERO


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
