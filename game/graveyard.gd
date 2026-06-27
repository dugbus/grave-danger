extends Node3D
class_name GDGraveyard

const WIN_SCENE := "res://ui/screens/win_screen.tscn"
const SCREEN_FADE := preload("res://ui/screens/screen_fade.gd")
const KILL_BOUNDARY_SCRIPT := preload("res://levels/common/kill_boundary.gd")

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
	_configure_runtime_references()
	_activate_current_level_camera()
	_configure_kill_boundary_animation()
	max_coins_collected = _calculate_max_coins_collected()
	_store_result_stats()

	for deposit in _get_coin_deposits():
		if deposit.has_signal("coin_absorbed"):
			deposit.coin_absorbed.connect(_on_coin_absorbed)

	for completion_source in _get_level_completion_sources():
		if completion_source.has_signal("level_completed"):
			completion_source.level_completed.connect(_on_level_completed)


func _on_coin_absorbed(count: int) -> void:
	if showing_result:
		return

	coins_collected += maxi(count, 0)
	_store_result_stats()

	if max_coins_collected > 0 and coins_collected >= max_coins_collected:
		_show_win_screen()


func _on_level_completed() -> void:
	if showing_result:
		return

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


func _configure_runtime_references() -> void:
	if current_level == null:
		return

	var player := current_level.get_node_or_null("Player")
	var kill_boundary := _get_kill_boundary()
	var camera := get_node_or_null("GameRuntime/Camera3D")
	if camera != null and camera.has_method("set_runtime_targets"):
		camera.set_runtime_targets(player, kill_boundary)

	var energy_hud := get_node_or_null("GameRuntime/EnergyHud")
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


func _get_level_completion_sources() -> Array[Node]:
	if current_level == null:
		return []

	var sources: Array[Node] = []
	for node in _get_descendants(current_level):
		if node.has_signal("level_completed"):
			sources.append(node)
	return sources


func _show_win_screen() -> void:
	if showing_result:
		return

	showing_result = true
	var tween := SCREEN_FADE.fade_out(self, "ResultFade", win_fade_out_duration, "ResultFadeLayer")
	await tween.finished

	get_tree().change_scene_to_file(WIN_SCENE)
