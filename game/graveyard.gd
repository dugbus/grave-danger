extends Node3D

const WIN_SCENE := "res://ui/screens/win_screen.tscn"
const SCREEN_FADE := preload("res://ui/screens/screen_fade.gd")
const FLAME_BOUNDARY_SCRIPT := preload("res://levels/common/flame_boundary.gd")

const CURRENT_LEVEL_NAME := "CurrentLevel"

## Seconds used for the black transition before loading the win screen.
@export var win_fade_out_duration := 0.8
## Level scene used when nothing has been selected yet.
@export var default_level_scene: PackedScene

var coins_collected := 0
var max_coins_collected := 0
var showing_result := false
var current_level: Node


func _ready() -> void:
	_load_selected_level()
	_configure_ground_for_level()
	_configure_common_runtime_references()
	_configure_flame_boundary_animation()
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


func _configure_ground_for_level() -> void:
	if current_level == null:
		return

	var grid := _find_grid_map(current_level)
	var ground := get_node_or_null("LevelCommon/Ground") as StaticBody3D
	if grid == null or ground == null:
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


func _configure_common_runtime_references() -> void:
	if current_level == null:
		return

	var player := current_level.get_node_or_null("Player")
	var flame_boundary := _get_flame_boundary()
	var camera := get_node_or_null("LevelCommon/Camera3D")
	if camera != null and camera.has_method("set_runtime_targets"):
		camera.set_runtime_targets(player, flame_boundary)

	var energy_hud := get_node_or_null("LevelCommon/EnergyHud")
	if energy_hud != null and energy_hud.has_method("set_runtime_references") and player != null:
		energy_hud.set_runtime_references(
			player.get_node_or_null("PlayerDeath"),
			player.get_node_or_null("PlayerGoldInventory")
		)


func _configure_flame_boundary_animation() -> void:
	var flame_boundary := _get_flame_boundary()
	if flame_boundary != null:
		flame_boundary.play_runtime_animation()


func _get_flame_boundary() -> Node:
	if current_level == null:
		return null

	if current_level.get_script() == FLAME_BOUNDARY_SCRIPT:
		return current_level
	for node in _get_descendants(current_level):
		if node.get_script() == FLAME_BOUNDARY_SCRIPT:
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
