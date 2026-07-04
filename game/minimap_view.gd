extends Control
class_name GDMinimapView


const DEFAULT_SETTINGS := preload("res://game/minimap_view_settings.tres")
const VIEWPORT_CONTAINER_NAME := "ViewportContainer"
const MINIMAP_VIEWPORT_NAME := "MinimapViewport"
const MINIMAP_CAMERA_NAME := "MinimapCamera"
const CAMERA_ENVIRONMENT_PROPERTY := "environment"
const DEFAULT_CAMERA_CULL_MASK := (1 << 20) - 1
const TEXT_OVERLAY_VISUAL_LAYER := 1 << 19
const MINIMAP_HIDDEN_VISUAL_LAYERS := TEXT_OVERLAY_VISUAL_LAYER
const MINIMAP_VISIBLE_CULL_MASK := DEFAULT_CAMERA_CULL_MASK ^ MINIMAP_HIDDEN_VISUAL_LAYERS
const BOUNDS_EPSILON := 0.001

## Shared minimap tuning values for the whole game.
@export var settings: GDMinimapViewSettings = DEFAULT_SETTINGS

var target: Node3D
var kill_boundary: Node
var level_root: Node
var level_bounds := AABB()
var has_level_bounds := false
var minimap_environment: Environment
var minimap_enabled := false

@onready var viewport_container := get_node_or_null(VIEWPORT_CONTAINER_NAME) as SubViewportContainer
@onready var minimap_viewport := get_node_or_null("%s/%s" % [VIEWPORT_CONTAINER_NAME, MINIMAP_VIEWPORT_NAME]) as SubViewport
@onready var minimap_camera := get_node_or_null("%s/%s/%s" % [VIEWPORT_CONTAINER_NAME, MINIMAP_VIEWPORT_NAME, MINIMAP_CAMERA_NAME]) as Camera3D


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_minimap_enabled(minimap_enabled)


func _process(_delta: float) -> void:
	if not minimap_enabled:
		return

	_configure_viewport()
	_update_camera_transform()


func set_runtime_targets(target_node: Node, kill_boundary_node: Node) -> void:
	set_runtime_references(target_node, kill_boundary_node, null)


func set_runtime_references(target_node: Node, kill_boundary_node: Node, level_root_node: Node) -> void:
	target = target_node as Node3D
	kill_boundary = kill_boundary_node
	level_root = level_root_node
	_refresh_level_bounds()
	if minimap_enabled:
		_update_camera_transform()


func clear_runtime_references() -> void:
	target = null
	kill_boundary = null
	level_root = null
	level_bounds = AABB()
	has_level_bounds = false


func set_minimap_enabled(enabled: bool) -> void:
	minimap_enabled = enabled
	visible = enabled
	set_process(enabled)

	if viewport_container != null:
		viewport_container.process_mode = Node.PROCESS_MODE_INHERIT if enabled else Node.PROCESS_MODE_DISABLED

	if minimap_viewport != null:
		minimap_viewport.process_mode = Node.PROCESS_MODE_INHERIT if enabled else Node.PROCESS_MODE_DISABLED
		minimap_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS if enabled else SubViewport.UPDATE_DISABLED

	if minimap_camera != null:
		minimap_camera.current = enabled

	if enabled:
		_configure_viewport()
		_update_camera_transform()


func _configure_viewport() -> void:
	if not minimap_enabled:
		_configure_disabled_viewport()
		return

	_configure_panel_layout()

	if minimap_viewport == null:
		return

	var active_settings := _get_settings()
	minimap_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	minimap_viewport.world_3d = get_viewport().world_3d

	if viewport_container != null:
		viewport_container.stretch = true

	if minimap_camera == null:
		return

	minimap_camera.current = true
	minimap_camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	minimap_camera.size = _get_minimap_orthographic_size()
	minimap_camera.near = 0.05
	minimap_camera.far = active_settings.top_down_camera_height + _get_bounds_height() + 100.0
	minimap_camera.cull_mask = _get_source_cull_mask()
	_configure_minimap_environment(active_settings)


func _configure_disabled_viewport() -> void:
	if minimap_viewport != null:
		minimap_viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED

	if minimap_camera != null:
		minimap_camera.current = false


func _update_camera_transform() -> void:
	if minimap_camera == null:
		return

	var focus := _get_minimap_focus()
	var active_settings := _get_settings()
	var camera_position := focus + Vector3.UP * active_settings.top_down_camera_height

	minimap_camera.global_position = camera_position
	minimap_camera.look_at(focus, Vector3.FORWARD)


func _get_minimap_focus() -> Vector3:
	if target != null and is_instance_valid(target):
		return _clamp_focus_to_playable_bounds(target.global_position)

	if _has_playable_bounds():
		return _get_playable_bounds().get_center()

	if _has_kill_boundary():
		return kill_boundary.get_bounds_center() as Vector3

	return _clamp_focus_to_playable_bounds(Vector3.ZERO)


func _get_minimap_orthographic_size() -> float:
	var active_settings := _get_settings()
	if not _has_playable_bounds():
		return active_settings.fallback_orthographic_size

	var bounds := _get_playable_bounds()
	return _get_fitted_orthographic_size(Vector2(bounds.size.x, bounds.size.z))


func _get_fitted_orthographic_size(bounds_size: Vector2) -> float:
	var viewport_aspect := _get_minimap_aspect()
	var map_aspect := bounds_size.x / maxf(bounds_size.y, BOUNDS_EPSILON)

	if map_aspect >= viewport_aspect:
		return bounds_size.y

	return bounds_size.x / maxf(viewport_aspect, BOUNDS_EPSILON)


func _get_minimap_visible_world_size() -> Vector2:
	var orthographic_size := _get_minimap_orthographic_size()
	return Vector2(orthographic_size * _get_minimap_aspect(), orthographic_size)


func _get_minimap_aspect() -> float:
	var viewport_size := _get_viewport_size()
	return viewport_size.x / maxf(viewport_size.y, BOUNDS_EPSILON)


func _clamp_focus_to_playable_bounds(focus: Vector3) -> Vector3:
	if not _has_playable_bounds():
		return focus

	var bounds := _get_playable_bounds()
	var visible_size := _get_minimap_visible_world_size()
	var bounds_end := bounds.end
	return Vector3(
		_clamp_focus_axis(focus.x, bounds.position.x, bounds_end.x, visible_size.x),
		bounds.get_center().y,
		_clamp_focus_axis(focus.z, bounds.position.z, bounds_end.z, visible_size.y)
	)


func _clamp_focus_axis(value: float, bounds_minimum: float, bounds_maximum: float, visible_size: float) -> float:
	var bounds_size := bounds_maximum - bounds_minimum
	if bounds_size <= visible_size + BOUNDS_EPSILON:
		return (bounds_minimum + bounds_maximum) * 0.5

	return clampf(value, bounds_minimum + visible_size * 0.5, bounds_maximum - visible_size * 0.5)


func _has_playable_bounds() -> bool:
	if _is_valid_playable_bounds(level_bounds, has_level_bounds):
		return true

	if not _has_kill_boundary():
		return false

	var boundary_size := kill_boundary.get_bounds_size() as Vector2
	return boundary_size.x > BOUNDS_EPSILON and boundary_size.y > BOUNDS_EPSILON


func _get_playable_bounds() -> AABB:
	if _is_valid_playable_bounds(level_bounds, has_level_bounds):
		return level_bounds

	var boundary_size := kill_boundary.get_bounds_size() as Vector2
	var boundary_center := kill_boundary.get_bounds_center() as Vector3
	var boundary_height := _get_bounds_height()
	return AABB(
		Vector3(
			boundary_center.x - boundary_size.x * 0.5,
			boundary_center.y - boundary_height * 0.5,
			boundary_center.z - boundary_size.y * 0.5
		),
		Vector3(boundary_size.x, boundary_height, boundary_size.y)
	)


func _is_valid_playable_bounds(bounds: AABB, has_bounds: bool) -> bool:
	return has_bounds and bounds.size.x > BOUNDS_EPSILON and bounds.size.z > BOUNDS_EPSILON


func _get_bounds_height() -> float:
	if has_level_bounds:
		return level_bounds.size.y

	if _has_kill_boundary() and kill_boundary.has_method("get_bounds_height"):
		return maxf(kill_boundary.get_bounds_height() as float, 0.0)

	return 0.0


func _get_viewport_size() -> Vector2:
	if minimap_viewport != null or viewport_container != null:
		return Vector2(_get_minimap_render_size(_get_settings()))

	return size


func _get_minimap_render_size(active_settings: GDMinimapViewSettings) -> Vector2i:
	var visible_size := get_viewport().get_visible_rect().size
	var panel_width := maxf(visible_size.x * active_settings.viewport_width_fraction, active_settings.minimum_panel_width)
	var panel_height := panel_width / maxf(active_settings.panel_aspect_ratio, 0.001)
	var content_size := Vector2(panel_width, panel_height) - Vector2.ONE * active_settings.content_padding * 2.0
	return Vector2i(maxi(roundi(content_size.x), 1), maxi(roundi(content_size.y), 1))


func _configure_panel_layout() -> void:
	var active_settings := _get_settings()
	var render_size := _get_minimap_render_size(active_settings)
	var panel_size := Vector2(render_size) + Vector2.ONE * active_settings.content_padding * 2.0

	anchor_left = 1.0
	anchor_top = 1.0
	anchor_right = 1.0
	anchor_bottom = 1.0
	offset_left = -active_settings.screen_margin - panel_size.x
	offset_top = -active_settings.screen_margin - panel_size.y
	offset_right = -active_settings.screen_margin
	offset_bottom = -active_settings.screen_margin

	if viewport_container != null:
		viewport_container.offset_left = active_settings.content_padding
		viewport_container.offset_top = active_settings.content_padding
		viewport_container.offset_right = -active_settings.content_padding
		viewport_container.offset_bottom = -active_settings.content_padding
		viewport_container.custom_minimum_size = Vector2(render_size)


func _configure_minimap_environment(active_settings: GDMinimapViewSettings) -> void:
	if minimap_camera == null or not _has_camera_property(CAMERA_ENVIRONMENT_PROPERTY):
		return

	if minimap_environment == null:
		minimap_environment = Environment.new()

	minimap_environment.background_mode = Environment.BG_COLOR
	minimap_environment.background_color = active_settings.background_color
	minimap_environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	minimap_environment.ambient_light_color = active_settings.ambient_light_color
	minimap_environment.ambient_light_energy = active_settings.ambient_light_energy
	minimap_camera.set(CAMERA_ENVIRONMENT_PROPERTY, minimap_environment)


func _has_camera_property(property_name: String) -> bool:
	for property in minimap_camera.get_property_list():
		if property.name == property_name:
			return true

	return false


func _get_source_cull_mask() -> int:
	var source_camera := _get_source_camera()
	if source_camera != null:
		return source_camera.cull_mask & MINIMAP_VISIBLE_CULL_MASK

	return MINIMAP_VISIBLE_CULL_MASK


func _get_source_camera() -> Camera3D:
	var current_camera := get_viewport().get_camera_3d()
	if current_camera != null and current_camera != minimap_camera:
		return current_camera

	return null


func _refresh_level_bounds() -> void:
	has_level_bounds = false
	level_bounds = AABB()

	if level_root == null or not is_instance_valid(level_root):
		return

	_collect_level_bounds(level_root)


func _collect_level_bounds(root: Node) -> void:
	if root is VisualInstance3D and not root is Camera3D and not root is Light3D:
		_merge_visual_bounds(root as VisualInstance3D)

	for child in root.get_children():
		_collect_level_bounds(child)


func _merge_visual_bounds(visual: VisualInstance3D) -> void:
	if not visual.is_visible_in_tree():
		return

	if (visual.layers & MINIMAP_HIDDEN_VISUAL_LAYERS) != 0:
		return

	var local_bounds := visual.get_aabb()
	if local_bounds.size.is_zero_approx():
		return

	for point in _get_aabb_corners(local_bounds):
		var global_point := visual.global_transform * point
		if has_level_bounds:
			level_bounds = level_bounds.expand(global_point)
		else:
			level_bounds = AABB(global_point, Vector3.ZERO)
			has_level_bounds = true


func _get_aabb_corners(bounds: AABB) -> Array[Vector3]:
	var end := bounds.end
	return [
		Vector3(bounds.position.x, bounds.position.y, bounds.position.z),
		Vector3(end.x, bounds.position.y, bounds.position.z),
		Vector3(bounds.position.x, end.y, bounds.position.z),
		Vector3(end.x, end.y, bounds.position.z),
		Vector3(bounds.position.x, bounds.position.y, end.z),
		Vector3(end.x, bounds.position.y, end.z),
		Vector3(bounds.position.x, end.y, end.z),
		Vector3(end.x, end.y, end.z),
	]


func _has_kill_boundary() -> bool:
	return (
		kill_boundary != null
		and is_instance_valid(kill_boundary)
		and kill_boundary.has_method("get_bounds_size")
		and kill_boundary.has_method("get_bounds_center")
	)


func _get_settings() -> GDMinimapViewSettings:
	if settings != null:
		return settings

	return DEFAULT_SETTINGS
