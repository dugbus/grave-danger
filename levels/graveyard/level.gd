@tool
extends Node3D
class_name GDLevel05

## Coordinates Graveyard-only dressing, lighting and direct-run camera behaviour.
## The editable FloorSurface scene node now owns all floor rendering and collision.

const SUN_LIGHT_NAME := "SunLight"
const WORLD_ENVIRONMENT_NAME := "WorldEnvironment"
const LEGACY_GRID_MAP_NAME := "PNGGridMap"
const PLAYER_NAME := "Player"
const LEVEL_CAMERA_NAME := "Camera3D"
const TREE_SURROUND_NAME := "TreeSurround"
const FOLLOW_CAMERA_SCRIPT := preload("res://game/follow_camera.gd")
const TREE_SURROUND_SCRIPT := preload("res://levels/graveyard/level_tree_surround.gd")
const DEFAULT_SUN_ROTATION_DEGREES := Vector3(-14.0, -58.0, 0.0)
const DEFAULT_SUN_LIGHT_COLOR := Color(1.0, 0.9, 0.78, 1.0)
const DEFAULT_SUN_ENERGY := 3.2
const DEFAULT_SUN_INDIRECT_ENERGY := 1.0
const DEFAULT_SUN_SHADOW_OPACITY := 0.38
const DEFAULT_AMBIENT_LIGHT_ENERGY := 0.85
const DEFAULT_AMBIENT_LIGHT_COLOR := Color(0.78, 0.84, 1.0, 1.0)
const DEFAULT_SKY_COLOR := Color(0.52, 0.46, 0.66, 1.0)

## Flat world-space area enclosed by the optional generated tree surround.
@export var floor_size := Vector2(100.0, 100.0):
	set(value):
		floor_size = Vector2(maxf(value.x, 1.0), maxf(value.y, 1.0))
		_queue_rebuild()
## Seed used when rebuilding the optional deterministic tree surround.
@export var tree_surround_seed := 5005:
	set(value):
		tree_surround_seed = value
		_queue_rebuild()
## Controls whether the graveyard level builds the surrounding tree wall and blockers.
@export var generate_tree_surround := true:
	set(value):
		generate_tree_surround = value
		_queue_rebuild()
## Keeps the retired PNG wall-layout preview hidden and non-colliding.
@export var disable_legacy_grid_map := true:
	set(value):
		disable_legacy_grid_map = value
		_queue_rebuild()

@export_group("Direct Run Preview")
## Enables the reusable gameplay camera when this level is run directly.
@export var enable_direct_run_camera := true:
	set(value):
		enable_direct_run_camera = value
		_queue_rebuild()
## Direct-run camera offset used when no shared camera profile overrides it.
@export var direct_run_camera_offset := Vector3(0.0, 9.0, 12.0):
	set(value):
		direct_run_camera_offset = value
		_queue_rebuild()
## Shared camera tuning used by the Graveyard direct-run preview.
@export var direct_run_camera_profile: Resource:
	set(value):
		direct_run_camera_profile = value
		_queue_rebuild()

var _rebuild_queued := false


func _enter_tree() -> void:
	if Engine.is_editor_hint():
		_queue_rebuild()


func _notification(what: int) -> void:
	if what == NOTIFICATION_EDITOR_POST_SAVE and Engine.is_editor_hint():
		_queue_rebuild()


func _ready() -> void:
	_rebuild_level()


func _queue_rebuild() -> void:
	if not is_inside_tree() or _rebuild_queued:
		return
	_rebuild_queued = true
	call_deferred("_rebuild_level")


func _rebuild_level() -> void:
	_rebuild_queued = false
	if not is_inside_tree():
		return
	_configure_legacy_grid_map()
	if generate_tree_surround:
		_configure_tree_surround()
	else:
		_clear_tree_surround()
	_snap_player_spawn_to_floor()
	_configure_sun_light()
	_configure_world_environment()
	_configure_direct_run_camera()


func _configure_legacy_grid_map() -> void:
	var grid := get_node_or_null(LEGACY_GRID_MAP_NAME) as GridMap
	if grid == null:
		return
	grid.visible = not disable_legacy_grid_map
	_set_property_if_available(grid, &"collision_layer", 1 if not disable_legacy_grid_map else 0)
	_set_property_if_available(grid, &"collision_mask", 1 if not disable_legacy_grid_map else 0)


func _configure_tree_surround() -> void:
	var surround := get_node_or_null(TREE_SURROUND_NAME) as Node3D
	if surround == null:
		surround = Node3D.new()
		surround.name = TREE_SURROUND_NAME
		add_child(surround)
	surround.visible = true
	if Engine.is_editor_hint():
		_assign_editor_owner(surround)
	if surround.get_script() != TREE_SURROUND_SCRIPT:
		surround.set_script(TREE_SURROUND_SCRIPT)
	if surround.has_method(&"rebuild"):
		surround.call(&"rebuild", floor_size, Callable(self, "_sample_floor_height"), tree_surround_seed)


func _sample_floor_height(_x: float, _z: float) -> float:
	return 0.0


func _clear_tree_surround() -> void:
	var surround := get_node_or_null(TREE_SURROUND_NAME) as Node3D
	if surround == null:
		return
	surround.visible = false
	if surround.has_method(&"clear_generated"):
		surround.call(&"clear_generated")
		return
	for child in surround.get_children():
		surround.remove_child(child)
		child.free()


func _assign_editor_owner(node: Node) -> void:
	var edited_scene_root := get_tree().edited_scene_root
	if edited_scene_root != null:
		node.owner = edited_scene_root


func _snap_player_spawn_to_floor() -> void:
	var player := get_node_or_null(PLAYER_NAME) as Node3D
	if player != null:
		player.position.y = 0.1


func _configure_sun_light() -> void:
	var sun := get_node_or_null(SUN_LIGHT_NAME) as DirectionalLight3D
	var created := false
	if sun == null:
		sun = DirectionalLight3D.new()
		sun.name = SUN_LIGHT_NAME
		add_child(sun)
		created = true
	if created:
		sun.rotation_degrees = DEFAULT_SUN_ROTATION_DEGREES
		sun.light_color = DEFAULT_SUN_LIGHT_COLOR
		sun.light_energy = DEFAULT_SUN_ENERGY
		sun.light_indirect_energy = DEFAULT_SUN_INDIRECT_ENERGY
		sun.shadow_enabled = true
		_set_property_if_available(sun, &"shadow_opacity", DEFAULT_SUN_SHADOW_OPACITY)


func _configure_world_environment() -> void:
	var world_environment := get_node_or_null(WORLD_ENVIRONMENT_NAME) as WorldEnvironment
	var created := false
	if world_environment == null:
		world_environment = WorldEnvironment.new()
		world_environment.name = WORLD_ENVIRONMENT_NAME
		add_child(world_environment)
		created = true
	var environment := world_environment.environment
	if environment == null:
		environment = Environment.new()
		world_environment.environment = environment
		created = true
	if created:
		environment.background_mode = Environment.BG_COLOR
		environment.background_color = DEFAULT_SKY_COLOR
		environment.background_energy_multiplier = 1.0
		environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
		environment.ambient_light_color = DEFAULT_AMBIENT_LIGHT_COLOR
		environment.ambient_light_energy = DEFAULT_AMBIENT_LIGHT_ENERGY


func _configure_direct_run_camera(force_current := false) -> void:
	var preview_camera := _get_or_create_level_camera()
	if not enable_direct_run_camera and not force_current:
		if preview_camera != null:
			preview_camera.current = false
		return
	var player := get_node_or_null(PLAYER_NAME) as Node3D
	_configure_reusable_camera(preview_camera, player)
	var viewport := get_viewport()
	if force_current:
		preview_camera.current = true
	elif viewport == null or viewport.get_camera_3d() == null or viewport.get_camera_3d() == preview_camera:
		preview_camera.current = true
	else:
		preview_camera.current = false


func _get_or_create_level_camera() -> Camera3D:
	var camera := _find_reusable_camera(self)
	if camera != null:
		return camera
	camera = get_node_or_null(LEVEL_CAMERA_NAME) as Camera3D
	if camera == null:
		camera = Camera3D.new()
		camera.name = LEVEL_CAMERA_NAME
		add_child(camera)
	if camera.get_script() == null:
		camera.set_script(FOLLOW_CAMERA_SCRIPT)
	return camera


func _find_reusable_camera(root: Node) -> Camera3D:
	if root is Camera3D and root.has_method(&"set_runtime_targets"):
		return root as Camera3D
	for child in root.get_children():
		var camera := _find_reusable_camera(child)
		if camera != null:
			return camera
	return null


func _configure_reusable_camera(camera: Camera3D, player: Node3D) -> void:
	if camera.get_script() == null:
		camera.set_script(FOLLOW_CAMERA_SCRIPT)
	if not Engine.is_editor_hint() and camera.has_method(&"set_runtime_targets"):
		camera.call(&"set_runtime_targets", player, null)
	if not Engine.is_editor_hint() and direct_run_camera_profile != null \
			and camera.has_method(&"apply_camera_profile"):
		camera.call(&"apply_camera_profile", direct_run_camera_profile)
	else:
		_set_property_if_available(camera, &"camera_offset", direct_run_camera_offset)
		_set_property_if_available(camera, &"zoom_distance", direct_run_camera_offset.length())


func _set_property_if_available(object: Object, property_name: StringName, value: Variant) -> void:
	for property in object.get_property_list():
		if property.get("name", "") == property_name:
			object.set(property_name, value)
			return
