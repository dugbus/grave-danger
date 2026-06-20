extends Node3D

const WIN_SCENE := "res://ui/screens/win_screen.tscn"
const SCREEN_FADE := preload("res://ui/screens/screen_fade.gd")
const KILL_BOUNDARY_SCRIPT := preload("res://levels/common/kill_boundary.gd")

const CURRENT_LEVEL_NAME := "CurrentLevel"
const COMMON_LEVEL_PATH := "LevelCommon"
const COMMON_WORLD_ENVIRONMENT_PATH := "LevelCommon/WorldEnvironment"
const COMMON_DIRECTIONAL_LIGHT_PATH := "LevelCommon/DirectionalLight3D"
const COMMON_GROUND_PATH := "LevelCommon/Ground"

## Seconds used for the black transition before loading the win screen.
@export var win_fade_out_duration := 0.8
## Level scene used when nothing has been selected yet.
@export var default_level_scene: PackedScene

var coins_collected := 0
var max_coins_collected := 0
var showing_result := false
var current_level: Node
var _common_world_environment_resources: Dictionary = {}
var _common_light_visibilities: Dictionary = {}


func _ready() -> void:
	_load_selected_level()
	_configure_player_light_for_level()
	_configure_common_level_settings_enabled()
	if _current_level_uses_common_level_settings():
		_configure_world_environment()
		_configure_common_directional_light()
		_configure_ground_for_level()
		_configure_common_runtime_references()
	else:
		_activate_current_level_camera()
	_configure_kill_boundary_animation()
	max_coins_collected = _calculate_max_coins_collected()
	_store_result_stats()

	for deposit in _get_coin_deposits():
		if deposit.has_signal("coin_absorbed"):
			deposit.coin_absorbed.connect(_on_coin_absorbed)


func _on_coin_absorbed(count: int) -> void:
	if showing_result:
		return

	coins_collected += maxi(count, 0)
	_store_result_stats()

	if max_coins_collected > 0 and coins_collected >= max_coins_collected:
		_show_win_screen()


func _calculate_max_coins_collected() -> int:
	var total := 0
	if current_level == null:
		return total

	for node in _get_descendants(current_level):
		if node.has_method("get_max_coin_count"):
			total += maxi(node.get_max_coin_count(), 0)
	return total


func _get_descendants(root: Node) -> Array[Node]:
	var descendants: Array[Node] = []
	for child in root.get_children():
		descendants.append(child)
		descendants.append_array(_get_descendants(child))
	return descendants


func _store_result_stats() -> void:
	var stats := get_node_or_null("/root/ResultStats")
	if stats != null and stats.has_method("set_result"):
		stats.set_result(coins_collected, max_coins_collected)


func _load_selected_level() -> void:
	var selected_scene := _get_selected_level_scene()
	current_level = get_node_or_null(CURRENT_LEVEL_NAME)
	if selected_scene == null:
		return

	if current_level != null and current_level.scene_file_path == selected_scene.resource_path:
		return

	if current_level != null:
		remove_child(current_level)
		current_level.queue_free()

	current_level = selected_scene.instantiate()
	current_level.name = CURRENT_LEVEL_NAME
	add_child(current_level)


func _get_selected_level_scene() -> PackedScene:
	var level_selection := get_node_or_null("/root/LevelSelection")
	if level_selection != null and level_selection.has_method("get_selected_level_scene"):
		var selected_scene = level_selection.get_selected_level_scene()
		if selected_scene is PackedScene:
			return selected_scene

	return default_level_scene


func _configure_common_level_settings_enabled() -> void:
	var common_level := get_node_or_null(COMMON_LEVEL_PATH)
	if common_level == null:
		return

	var enabled := _current_level_uses_common_level_settings()
	common_level.process_mode = Node.PROCESS_MODE_INHERIT if enabled else Node.PROCESS_MODE_DISABLED
	if common_level is Node3D:
		(common_level as Node3D).visible = enabled

	_configure_common_world_environments_enabled(common_level, enabled)
	_configure_common_lights_enabled(common_level, enabled)
	_configure_common_cameras_enabled(common_level, enabled)
	_configure_common_audio_enabled(common_level, enabled)


func _configure_common_world_environments_enabled(root: Node, enabled: bool) -> void:
	var nodes: Array[Node] = [root]
	nodes.append_array(_get_descendants(root))
	for node in nodes:
		if not node is WorldEnvironment:
			continue

		var world_environment := node as WorldEnvironment
		var key := str(world_environment.get_path())
		if enabled:
			if world_environment.environment == null and _common_world_environment_resources.has(key):
				world_environment.environment = _common_world_environment_resources[key]
		else:
			if world_environment.environment != null:
				_common_world_environment_resources[key] = world_environment.environment
			world_environment.environment = null


func _configure_common_lights_enabled(root: Node, enabled: bool) -> void:
	var nodes: Array[Node] = [root]
	nodes.append_array(_get_descendants(root))
	for node in nodes:
		if not node is Light3D:
			continue

		var light := node as Light3D
		var key := str(light.get_path())
		if enabled:
			if _common_light_visibilities.has(key):
				light.visible = bool(_common_light_visibilities[key])
			light.process_mode = Node.PROCESS_MODE_INHERIT
		else:
			if not _common_light_visibilities.has(key):
				_common_light_visibilities[key] = light.visible
			light.visible = false
			light.process_mode = Node.PROCESS_MODE_DISABLED


func _configure_common_cameras_enabled(root: Node, enabled: bool) -> void:
	for node in _get_descendants(root):
		if node is Camera3D and not enabled:
			(node as Camera3D).current = false


func _configure_common_audio_enabled(root: Node, enabled: bool) -> void:
	for node in _get_descendants(root):
		if not node is AudioStreamPlayer:
			continue

		var player := node as AudioStreamPlayer
		if enabled:
			if player.autoplay and not player.playing:
				player.play()
		else:
			player.stop()


func _configure_world_environment() -> void:
	var common_world_environment := get_node_or_null(COMMON_WORLD_ENVIRONMENT_PATH) as WorldEnvironment
	if common_world_environment == null:
		return

	var level_environment := _get_current_level_environment()
	if level_environment != null:
		common_world_environment.environment = level_environment


func _get_current_level_environment() -> Environment:
	if current_level == null:
		return null

	if current_level.has_method("get_custom_environment"):
		var custom_environment = current_level.get_custom_environment()
		if custom_environment is Environment:
			return custom_environment

	var level_world_environment := _find_world_environment(current_level)
	if level_world_environment != null:
		return level_world_environment.environment

	return null


func _find_world_environment(root: Node) -> WorldEnvironment:
	if root == null:
		return null
	if root is WorldEnvironment:
		return root as WorldEnvironment

	for child in root.get_children():
		var world_environment := _find_world_environment(child)
		if world_environment != null:
			return world_environment

	return null


func _configure_common_directional_light() -> void:
	var common_light := get_node_or_null(COMMON_DIRECTIONAL_LIGHT_PATH) as DirectionalLight3D
	if common_light == null:
		return

	common_light.visible = not _current_level_uses_custom_lighting()


func _configure_ground_for_level() -> void:
	if current_level == null:
		return

	var grid := _find_grid_map(current_level)
	var ground := get_node_or_null(COMMON_GROUND_PATH) as StaticBody3D
	if ground == null:
		return

	if _current_level_uses_custom_ground():
		ground.process_mode = Node.PROCESS_MODE_DISABLED
		ground.visible = false
		return

	ground.process_mode = Node.PROCESS_MODE_INHERIT
	# Keep the common ground collision-only; GridMap levels draw their own floor tiles.
	ground.visible = false
	if grid == null:
		return

	var cells := grid.get_used_cells()
	if cells.is_empty():
		return

	var minimum := cells[0]
	var maximum := cells[0]
	for cell in cells:
		minimum.x = mini(minimum.x, cell.x)
		minimum.z = mini(minimum.z, cell.z)
		maximum.x = maxi(maximum.x, cell.x)
		maximum.z = maxi(maximum.z, cell.z)

	var floor_size := Vector2(
		float(maximum.x - minimum.x + 1) * grid.cell_size.x,
		float(maximum.z - minimum.z + 1) * grid.cell_size.z
	)
	var first_cell := grid.map_to_local(Vector3i(minimum.x, 0, minimum.z))
	var last_cell := grid.map_to_local(Vector3i(maximum.x, 0, maximum.z))
	var floor_center_global := grid.to_global((first_cell + last_cell) * 0.5)
	var floor_center := ground.get_parent_node_3d().to_local(floor_center_global)
	ground.position = Vector3(floor_center.x, -1.0, floor_center.z)

	var collision := ground.get_node_or_null("CollisionShape3D") as CollisionShape3D
	if collision != null and collision.shape is BoxShape3D:
		collision.shape = collision.shape.duplicate()
		(collision.shape as BoxShape3D).size = Vector3(floor_size.x, 2.0, floor_size.y)

	var mesh_instance := ground.get_node_or_null("MeshInstance3D") as MeshInstance3D
	if mesh_instance == null or not mesh_instance.mesh is PlaneMesh:
		return

	mesh_instance.mesh = mesh_instance.mesh.duplicate()
	(mesh_instance.mesh as PlaneMesh).size = floor_size
	var material := mesh_instance.get_active_material(0) as StandardMaterial3D
	if material != null:
		material = material.duplicate()
		material.uv1_scale = Vector3(floor_size.x, floor_size.y, 1.0)
		mesh_instance.set_surface_override_material(0, material)

	var edge_mesh := ground.get_node_or_null("EdgeMesh") as MeshInstance3D
	if edge_mesh != null and edge_mesh.mesh is BoxMesh:
		edge_mesh.mesh = edge_mesh.mesh.duplicate()
		(edge_mesh.mesh as BoxMesh).size = Vector3(floor_size.x, 2.0, floor_size.y)


func _find_grid_map(root: Node) -> GridMap:
	if root is GridMap:
		return root as GridMap

	for child in root.get_children():
		var grid := _find_grid_map(child)
		if grid != null:
			return grid

	return null


func _current_level_uses_custom_ground() -> bool:
	return current_level != null and current_level.has_method("uses_custom_ground") and bool(current_level.uses_custom_ground())


func _current_level_uses_custom_lighting() -> bool:
	return current_level != null and current_level.has_method("uses_custom_lighting") and bool(current_level.uses_custom_lighting())


func _current_level_uses_common_level_settings() -> bool:
	if current_level == null or not current_level.has_method("uses_common_level_settings"):
		return true

	return bool(current_level.uses_common_level_settings())


func _current_level_uses_player_light() -> bool:
	if current_level == null or not current_level.has_method("uses_player_light"):
		return true

	return bool(current_level.uses_player_light())


func _configure_player_light_for_level() -> void:
	if current_level == null:
		return

	var player := current_level.get_node_or_null("Player")
	if player == null:
		return

	var enabled := _current_level_uses_player_light()
	for node in _get_descendants(player):
		if node.name != "PlayerLight":
			continue

		node.process_mode = Node.PROCESS_MODE_INHERIT if enabled else Node.PROCESS_MODE_DISABLED
		if node is Node3D:
			(node as Node3D).visible = enabled
		if node is Light3D and not enabled:
			(node as Light3D).light_energy = 0.0


func _configure_common_runtime_references() -> void:
	if current_level == null:
		return

	var player := current_level.get_node_or_null("Player")
	var kill_boundary := _get_kill_boundary()
	var camera := get_node_or_null("LevelCommon/Camera3D")
	if camera != null and camera.has_method("set_runtime_targets"):
		camera.set_runtime_targets(player, kill_boundary)

	var energy_hud := get_node_or_null("LevelCommon/EnergyHud")
	if energy_hud != null and energy_hud.has_method("set_runtime_references") and player != null:
		energy_hud.set_runtime_references(
			player.get_node_or_null("PlayerDeath"),
			player.get_node_or_null("PlayerInventory")
		)


func _activate_current_level_camera() -> void:
	if current_level == null:
		return

	var player := current_level.get_node_or_null("Player")
	var kill_boundary := _get_kill_boundary()
	if _configure_runtime_cameras(current_level, player, kill_boundary, true):
		return

	if current_level.has_method("activate_runtime_camera"):
		current_level.activate_runtime_camera()
		return

	var camera := _find_camera(current_level)
	if camera != null:
		camera.current = true


func _configure_runtime_cameras(root: Node, target: Node, kill_boundary: Node, make_current: bool) -> bool:
	var configured := false
	for node in _get_descendants(root):
		if not node is Camera3D or not node.has_method("set_runtime_targets"):
			continue

		node.set_runtime_targets(target, kill_boundary)
		if make_current:
			(node as Camera3D).current = true
		configured = true

	return configured


func _find_camera(root: Node) -> Camera3D:
	if root is Camera3D:
		return root as Camera3D

	for child in root.get_children():
		var camera := _find_camera(child)
		if camera != null:
			return camera

	return null


func _configure_kill_boundary_animation() -> void:
	var kill_boundary := _get_kill_boundary()
	if kill_boundary != null:
		kill_boundary.play_runtime_animation()


func _get_kill_boundary() -> Node:
	if current_level == null:
		return null

	if current_level.get_script() == KILL_BOUNDARY_SCRIPT:
		return current_level
	for node in _get_descendants(current_level):
		if node.get_script() == KILL_BOUNDARY_SCRIPT:
			return node
	return null

func _get_coin_deposits() -> Array[Node]:
	if current_level == null:
		return []

	var deposits: Array[Node] = []
	for node in _get_descendants(current_level):
		if node.has_signal("coin_absorbed"):
			deposits.append(node)
	return deposits

func _show_win_screen() -> void:
	if showing_result:
		return

	showing_result = true
	var tween := SCREEN_FADE.fade_out(self, "ResultFade", win_fade_out_duration, "ResultFadeLayer")
	await tween.finished

	get_tree().change_scene_to_file(WIN_SCENE)
