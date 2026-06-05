extends Node3D

const WIN_SCENE := "res://ui/screens/win_screen.tscn"
const SCREEN_FADE := preload("res://ui/screens/screen_fade.gd")

const CURRENT_LEVEL_NAME := "CurrentLevel"

## Seconds used for the black transition before loading the win screen.
@export var win_fade_out_duration := 0.8
## Level scene used when nothing has been selected yet.
@export var default_level_scene: PackedScene
## Speed used to move the active level's flame boundary along its authored path.
@export var flame_boundary_speed := 1.0

var coins_collected := 0
var max_coins_collected := 0
var showing_result := false
var current_level: Node


func _ready() -> void:
	_load_selected_level()
	_configure_common_runtime_references()
	max_coins_collected = _calculate_max_coins_collected()
	_store_result_stats()

	for deposit in _get_coin_deposits():
		if deposit.has_signal("coin_absorbed"):
			deposit.coin_absorbed.connect(_on_coin_absorbed)


func _physics_process(delta: float) -> void:
	var path_follow := _get_flame_path_follow()
	if path_follow != null:
		path_follow.progress += flame_boundary_speed * delta


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


func _configure_common_runtime_references() -> void:
	if current_level == null:
		return

	var player := current_level.get_node_or_null("Player")
	var flame_boundary := current_level.get_node_or_null("LongRoad/PathFollow3D/FlameBoundary")
	var camera := get_node_or_null("LevelCommon/Camera3D")
	if camera != null and camera.has_method("set_runtime_targets"):
		camera.set_runtime_targets(player, flame_boundary)

	var energy_hud := get_node_or_null("LevelCommon/EnergyHud")
	if energy_hud != null and energy_hud.has_method("set_runtime_references") and player != null:
		energy_hud.set_runtime_references(
			player.get_node_or_null("PlayerDeath"),
			player.get_node_or_null("PlayerGoldInventory")
		)


func _get_coin_deposits() -> Array[Node]:
	if current_level == null:
		return []

	var deposits: Array[Node] = []
	for node in _get_descendants(current_level):
		if node.has_signal("coin_absorbed"):
			deposits.append(node)
	return deposits


func _get_flame_path_follow() -> PathFollow3D:
	if current_level == null:
		return null

	return current_level.get_node_or_null("LongRoad/PathFollow3D") as PathFollow3D


func _show_win_screen() -> void:
	if showing_result:
		return

	showing_result = true
	var tween := SCREEN_FADE.fade_out(self, "ResultFade", win_fade_out_duration, "ResultFadeLayer")
	await tween.finished

	get_tree().change_scene_to_file(WIN_SCENE)
