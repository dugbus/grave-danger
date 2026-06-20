@tool
extends Node3D

const TERRAIN_BODY_NAME := "RollingHillsTerrain"
const TERRAIN_MESH_NAME := "TerrainMesh"
const TERRAIN_COLLISION_NAME := "TerrainCollision"
const SUN_LIGHT_NAME := "SunLight"
const WORLD_ENVIRONMENT_NAME := "WorldEnvironment"
const LEGACY_GRID_MAP_NAME := "PNGGridMap"
const PLAYER_NAME := "Player"
const LEVEL_CAMERA_NAME := "Camera3D"
const TREE_SURROUND_NAME := "TreeSurround"
const FOLLOW_CAMERA_SCRIPT := preload("res://game/follow_camera.gd")
const TREE_SURROUND_SCRIPT := preload("res://levels/5/level_05_tree_surround.gd")
const DEFAULT_HEIGHT_MAP_PATH := "res://levels/5/height-map.png"
const DEFAULT_SUN_ROTATION_DEGREES := Vector3(-14.0, -58.0, 0.0)
const DEFAULT_SUN_LIGHT_COLOR := Color(1.0, 0.9, 0.78, 1.0)
const DEFAULT_SUN_ENERGY := 3.2
const DEFAULT_SUN_INDIRECT_ENERGY := 1.0
const DEFAULT_SUN_SHADOW_OPACITY := 0.38
const DEFAULT_AMBIENT_LIGHT_ENERGY := 0.85
const DEFAULT_AMBIENT_LIGHT_COLOR := Color(0.78, 0.84, 1.0, 1.0)
const DEFAULT_SKY_COLOR := Color(0.52, 0.46, 0.66, 1.0)

@export_file("*.png") var height_map_path := DEFAULT_HEIGHT_MAP_PATH:
	set(value):
		height_map_path = value
		_height_map_image = null
		_height_map_load_failed = false
		_queue_rebuild()

@export var height_map_texture: Texture2D:
	set(value):
		height_map_texture = value
		_height_map_image = null
		_height_map_load_failed = false
		_queue_rebuild()

@export var terrain_size := Vector2(100.0, 100.0):
	set(value):
		terrain_size = Vector2(maxf(value.x, 1.0), maxf(value.y, 1.0))
		_queue_rebuild()

@export_range(8, 192, 1) var terrain_resolution := 96:
	set(value):
		terrain_resolution = maxi(value, 8)
		_queue_rebuild()

@export var height_map_min_height := -2.1010067:
	set(value):
		height_map_min_height = value
		_queue_rebuild()

@export var height_map_max_height := 2.1064764:
	set(value):
		height_map_max_height = value
		_queue_rebuild()

@export var tree_surround_seed := 5005:
	set(value):
		tree_surround_seed = value
		_queue_rebuild()

@export var terrain_tint := Color(1.0, 1.0, 1.0, 1.0):
	set(value):
		terrain_tint = value
		_queue_rebuild()

@export_group("Terrain Shading")
@export var valley_tint := Color(0.74, 0.9, 0.58, 1.0):
	set(value):
		valley_tint = value
		_queue_rebuild()

@export var ridge_tint := Color(0.94, 0.9, 0.58, 1.0):
	set(value):
		ridge_tint = value
		_queue_rebuild()

@export var slope_shadow_tint := Color(0.42, 0.58, 0.34, 1.0):
	set(value):
		slope_shadow_tint = value
		_queue_rebuild()

@export_range(0.0, 1.0, 0.01) var height_tint_strength := 0.18:
	set(value):
		height_tint_strength = clampf(value, 0.0, 1.0)
		_queue_rebuild()

@export_range(0.0, 1.0, 0.01) var slope_shadow_strength := 0.12:
	set(value):
		slope_shadow_strength = clampf(value, 0.0, 1.0)
		_queue_rebuild()

@export var terrain_material: StandardMaterial3D:
	set(value):
		terrain_material = value
		_queue_rebuild()

@export_range(0.1, 64.0, 0.1) var terrain_uv_scale := 12.0:
	set(value):
		terrain_uv_scale = maxf(value, 0.1)
		_queue_rebuild()

@export var snap_player_to_terrain := true:
	set(value):
		snap_player_to_terrain = value
		_queue_rebuild()

@export_range(0.0, 4.0, 0.05) var player_spawn_clearance := 0.1:
	set(value):
		player_spawn_clearance = maxf(value, 0.0)
		_queue_rebuild()

@export var disable_legacy_grid_map := true:
	set(value):
		disable_legacy_grid_map = value
		_queue_rebuild()

@export_group("Direct Run Preview")
@export var enable_direct_run_camera := true:
	set(value):
		enable_direct_run_camera = value
		_queue_rebuild()

@export var direct_run_camera_offset := Vector3(0.0, 9.0, 12.0):
	set(value):
		direct_run_camera_offset = value
		_queue_rebuild()

@export var direct_run_camera_profile: FollowCameraProfile:
	set(value):
		direct_run_camera_profile = value
		_queue_rebuild()

var _rebuild_queued := false
var _height_map_image: Image
var _height_map_load_failed := false


func _enter_tree() -> void:
	if Engine.is_editor_hint():
		_queue_rebuild()


func _ready() -> void:
	_rebuild_level()


func uses_custom_ground() -> bool:
	return true


func uses_custom_lighting() -> bool:
	return true


func uses_common_level_settings() -> bool:
	return false


func uses_player_light() -> bool:
	return false


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
	_configure_terrain()
	if not Engine.is_editor_hint():
		_configure_tree_surround()
	_snap_player_spawn_to_terrain()
	_configure_sun_light()
	_configure_world_environment()
	_configure_direct_run_camera()


func _configure_legacy_grid_map() -> void:
	var grid := get_node_or_null(LEGACY_GRID_MAP_NAME) as GridMap
	if grid == null:
		return

	grid.visible = not disable_legacy_grid_map
	_set_property_if_available(grid, "collision_layer", 1 if not disable_legacy_grid_map else 0)
	_set_property_if_available(grid, "collision_mask", 1 if not disable_legacy_grid_map else 0)


func _configure_terrain() -> void:
	var terrain := _get_or_create_terrain_body()
	var mesh_instance := _get_or_create_terrain_mesh(terrain)
	var collision := _get_or_create_terrain_collision(terrain)
	var faces := PackedVector3Array()

	mesh_instance.mesh = _build_terrain_mesh(faces)
	mesh_instance.set_surface_override_material(0, _build_terrain_material())

	var shape := ConcavePolygonShape3D.new()
	shape.backface_collision = true
	shape.set_faces(faces)
	collision.shape = shape


func _build_terrain_mesh(faces: PackedVector3Array) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var half_size := terrain_size * 0.5
	for z_index in range(terrain_resolution):
		var z0 := lerpf(-half_size.y, half_size.y, float(z_index) / float(terrain_resolution))
		var z1 := lerpf(-half_size.y, half_size.y, float(z_index + 1) / float(terrain_resolution))
		for x_index in range(terrain_resolution):
			var x0 := lerpf(-half_size.x, half_size.x, float(x_index) / float(terrain_resolution))
			var x1 := lerpf(-half_size.x, half_size.x, float(x_index + 1) / float(terrain_resolution))
			var uv0 := Vector2(float(x_index) / float(terrain_resolution), float(z_index) / float(terrain_resolution))
			var uv1 := Vector2(float(x_index + 1) / float(terrain_resolution), float(z_index + 1) / float(terrain_resolution))

			var p00 := _terrain_point(x0, z0)
			var p10 := _terrain_point(x1, z0)
			var p01 := _terrain_point(x0, z1)
			var p11 := _terrain_point(x1, z1)

			_add_terrain_vertex(st, p00, Vector2(uv0.x, uv0.y))
			_add_terrain_vertex(st, p01, Vector2(uv0.x, uv1.y))
			_add_terrain_vertex(st, p10, Vector2(uv1.x, uv0.y))
			faces.append(p00)
			faces.append(p01)
			faces.append(p10)

			_add_terrain_vertex(st, p10, Vector2(uv1.x, uv0.y))
			_add_terrain_vertex(st, p01, Vector2(uv0.x, uv1.y))
			_add_terrain_vertex(st, p11, Vector2(uv1.x, uv1.y))
			faces.append(p10)
			faces.append(p01)
			faces.append(p11)

	st.generate_normals()
	return st.commit()


func _terrain_point(x: float, z: float) -> Vector3:
	return Vector3(x, _sample_terrain_height(x, z), z)


func _sample_terrain_height(x: float, z: float) -> float:
	return lerpf(height_map_min_height, height_map_max_height, _sample_height_map_value(x, z))


func _sample_height_map_value(x: float, z: float) -> float:
	var image := _get_height_map_image()
	if image == null or image.is_empty():
		return 0.0

	var width := image.get_width()
	var height := image.get_height()
	if width <= 0 or height <= 0:
		return 0.0

	var half_size := terrain_size * 0.5
	var u := clampf(inverse_lerp(-half_size.x, half_size.x, x), 0.0, 1.0)
	var v := clampf(inverse_lerp(-half_size.y, half_size.y, z), 0.0, 1.0)
	var image_x := u * float(width - 1)
	var image_y := v * float(height - 1)
	var x0 := floori(image_x)
	var y0 := floori(image_y)
	var x1 := mini(x0 + 1, width - 1)
	var y1 := mini(y0 + 1, height - 1)
	var tx := image_x - float(x0)
	var ty := image_y - float(y0)

	var h00 := image.get_pixel(x0, y0).r
	var h10 := image.get_pixel(x1, y0).r
	var h01 := image.get_pixel(x0, y1).r
	var h11 := image.get_pixel(x1, y1).r
	return lerpf(lerpf(h00, h10, tx), lerpf(h01, h11, tx), ty)


func _get_height_map_image() -> Image:
	if _height_map_image != null:
		return _height_map_image
	if _height_map_load_failed:
		return null

	if height_map_texture != null:
		_height_map_image = height_map_texture.get_image()
		if _height_map_image != null:
			return _height_map_image

	var image := Image.new()
	var error := image.load(height_map_path)
	if error != OK:
		_height_map_load_failed = true
		push_warning("Unable to load Level 5 height map: %s" % height_map_path)
		return null

	_height_map_image = image
	return _height_map_image


func _configure_tree_surround() -> void:
	var surround := get_node_or_null(TREE_SURROUND_NAME) as Node3D
	if surround == null:
		surround = Node3D.new()
		surround.name = TREE_SURROUND_NAME
		add_child(surround)

	if surround.get_script() != TREE_SURROUND_SCRIPT:
		surround.set_script(TREE_SURROUND_SCRIPT)

	if surround.has_method("rebuild"):
		surround.rebuild(terrain_size, Callable(self, "_sample_terrain_height"), tree_surround_seed)


func _snap_player_spawn_to_terrain() -> void:
	if not snap_player_to_terrain:
		return

	var player := get_node_or_null(PLAYER_NAME) as Node3D
	if player == null:
		return

	player.position.y = _sample_terrain_height(player.position.x, player.position.z) + player_spawn_clearance


func _add_terrain_vertex(st: SurfaceTool, point: Vector3, uv: Vector2) -> void:
	st.set_color(_get_terrain_vertex_color(point))
	st.set_uv(uv * terrain_uv_scale)
	st.add_vertex(point)


func _get_terrain_vertex_color(point: Vector3) -> Color:
	var height_ratio := inverse_lerp(height_map_min_height, height_map_max_height, point.y)
	height_ratio = clampf(height_ratio, 0.0, 1.0)

	var height_color := valley_tint.lerp(ridge_tint, height_ratio)
	var color := terrain_tint.lerp(height_color, height_tint_strength)
	var slope := _estimate_terrain_slope(point)
	return color.lerp(slope_shadow_tint, slope * slope_shadow_strength)


func _estimate_terrain_slope(point: Vector3) -> float:
	var sample_step := maxf(minf(terrain_size.x, terrain_size.y) / float(terrain_resolution), 0.1)
	var height_x := _sample_terrain_height(point.x + sample_step, point.z)
	var height_z := _sample_terrain_height(point.x, point.z + sample_step)
	var grade_x := absf(height_x - point.y) / sample_step
	var grade_z := absf(height_z - point.y) / sample_step
	return clampf((grade_x + grade_z) * 0.5, 0.0, 1.0)


func _build_terrain_material() -> StandardMaterial3D:
	if terrain_material != null:
		var configured_material := terrain_material.duplicate() as StandardMaterial3D
		configured_material.cull_mode = BaseMaterial3D.CULL_DISABLED
		configured_material.albedo_color = terrain_tint
		configured_material.roughness = 0.95
		_set_property_if_available(configured_material, "vertex_color_use_as_albedo", true)
		return configured_material

	var material := StandardMaterial3D.new()
	material.albedo_color = terrain_tint
	material.roughness = 0.95
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.uv1_scale = Vector3.ONE
	_set_property_if_available(material, "vertex_color_use_as_albedo", true)
	return material


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
		_set_property_if_available(sun, "shadow_opacity", DEFAULT_SUN_SHADOW_OPACITY)


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


func get_custom_environment() -> Environment:
	_configure_world_environment()
	var world_environment := get_node_or_null(WORLD_ENVIRONMENT_NAME) as WorldEnvironment
	return world_environment.environment if world_environment != null else null


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
	if root is Camera3D and root.has_method("set_runtime_targets"):
		return root as Camera3D

	for child in root.get_children():
		var camera := _find_reusable_camera(child)
		if camera != null:
			return camera

	return null


func _configure_reusable_camera(camera: Camera3D, player: Node3D) -> void:
	if camera.has_method("set_runtime_targets"):
		camera.set_runtime_targets(player, null)
	if direct_run_camera_profile != null and camera.has_method("apply_camera_profile"):
		camera.apply_camera_profile(direct_run_camera_profile)
	else:
		_set_property_if_available(camera, "camera_offset", direct_run_camera_offset)
		_set_property_if_available(camera, "zoom_distance", direct_run_camera_offset.length())


func _get_or_create_terrain_body() -> StaticBody3D:
	var terrain := get_node_or_null(TERRAIN_BODY_NAME) as StaticBody3D
	if terrain == null:
		terrain = StaticBody3D.new()
		terrain.name = TERRAIN_BODY_NAME
		add_child(terrain)
	return terrain


func _get_or_create_terrain_mesh(terrain: StaticBody3D) -> MeshInstance3D:
	var mesh_instance := terrain.get_node_or_null(TERRAIN_MESH_NAME) as MeshInstance3D
	if mesh_instance == null:
		mesh_instance = MeshInstance3D.new()
		mesh_instance.name = TERRAIN_MESH_NAME
		terrain.add_child(mesh_instance)
	return mesh_instance


func _get_or_create_terrain_collision(terrain: StaticBody3D) -> CollisionShape3D:
	var collision := terrain.get_node_or_null(TERRAIN_COLLISION_NAME) as CollisionShape3D
	if collision == null:
		collision = CollisionShape3D.new()
		collision.name = TERRAIN_COLLISION_NAME
		terrain.add_child(collision)
	return collision


func _set_property_if_available(object: Object, property_name: StringName, value: Variant) -> void:
	for property in object.get_property_list():
		if property.get("name", "") == property_name:
			object.set(property_name, value)
			return
