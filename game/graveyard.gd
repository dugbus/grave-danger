extends Node3D
class_name GDGraveyard

const WIN_SCENE := "res://ui/screens/win_screen.tscn"
const SCREEN_FADE := preload("res://ui/screens/screen_fade.gd")
const KILL_BOUNDARY_SCRIPT := preload("res://placeables/kill_boundary/kill_boundary.gd")
const LEVEL_SETTINGS_SCRIPT := preload("res://levels/level_settings.gd")
const NAVIGATION_BOOTSTRAP := preload("res://game/navigation_bootstrap.gd")
const RUN_RECORDER_SCRIPT := preload("res://game/run_recorder.gd")

const CURRENT_LEVEL_NAME := "CurrentLevel"

## Seconds used for the black transition before loading the win screen.
@export var win_fade_out_duration := 0.8
## Level scene used when nothing has been selected yet.
@export var default_level_scene: PackedScene

var treasure_collected := 0
var max_treasure_value := 0
var showing_result := false
var current_level: Node
var run_recorder: RUN_RECORDER_SCRIPT


func _ready() -> void:
	_load_selected_level()
	_begin_run_recording()
	await NAVIGATION_BOOTSTRAP.prepare_level(current_level)
	_configure_runtime_references()
	_activate_current_level_camera()
	_configure_kill_boundary_animation()
	max_treasure_value = _calculate_max_treasure_value()
	_begin_result_stats()
	get_tree().call_group("treasure_score_display", "set_treasure_total", max_treasure_value)

	for deposit in _get_treasure_deposits():
		if deposit.has_signal("treasure_item_absorbed"):
			deposit.treasure_item_absorbed.connect(_on_treasure_item_absorbed)
		else:
			deposit.treasure_absorbed.connect(_on_treasure_absorbed)

	for completion_source in _get_level_completion_sources():
		if completion_source.has_signal("level_completed"):
			completion_source.level_completed.connect(_on_level_completed)


## Deposited treasure updates result stats only; gate completion owns the win condition.
func _on_treasure_absorbed(value: int) -> void:
	_on_treasure_item_absorbed(&"", value)


func _on_treasure_item_absorbed(item_type: StringName, value: int) -> void:
	if showing_result:
		return

	var safe_value := maxi(value, 0)
	treasure_collected += safe_value
	var stats := _get_result_stats()
	if stats != null and stats.has_method("add_treasure"):
		stats.add_treasure(item_type, safe_value)
	else:
		_store_result_stats()


func _on_level_completed() -> void:
	if showing_result:
		return

	_show_win_screen()


func _calculate_max_treasure_value() -> int:
	var total := 0
	if current_level == null:
		return total

	for node in _get_descendants(current_level):
		if node.has_method("get_max_treasure_value"):
			total += maxi(node.get_max_treasure_value(), 0)
	return total


func _get_descendants(root: Node) -> Array[Node]:
	var descendants: Array[Node] = []
	for child in root.get_children():
		descendants.append(child)
		descendants.append_array(_get_descendants(child))
	return descendants


func _store_result_stats() -> void:
	var stats := _get_result_stats()
	if stats != null and stats.has_method("set_result"):
		stats.set_result(treasure_collected, max_treasure_value)


func _begin_result_stats() -> void:
	var stats := _get_result_stats()
	if stats != null and stats.has_method("begin_attempt"):
		stats.begin_attempt(max_treasure_value)
	else:
		_store_result_stats()


func _begin_run_recording() -> void:
	if current_level == null:
		return
	var player := current_level.get_node_or_null("Player") as Node3D
	var level_selection := get_node_or_null("/root/LevelSelection") as GDLevelSelection
	if player == null or level_selection == null or not level_selection.persistence_enabled:
		return

	run_recorder = RUN_RECORDER_SCRIPT.new() as RUN_RECORDER_SCRIPT
	run_recorder.name = "RunRecorder"
	add_child(run_recorder)
	run_recorder.begin_recording(
		level_selection.get_selected_level_id(),
		player,
		get_viewport().get_camera_3d()
	)


func _get_result_stats() -> Node:
	return get_node_or_null("/root/ResultStats")


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

	var minimap := get_node_or_null("GameRuntime/MinimapHud/MinimapView")
	var show_minimap := _should_show_minimap()
	if minimap != null and minimap.has_method("set_minimap_enabled"):
		minimap.set_minimap_enabled(false)
	if show_minimap and minimap != null and minimap.has_method("set_runtime_references"):
		minimap.set_runtime_references(player, kill_boundary, current_level)
	if minimap != null and minimap.has_method("set_minimap_enabled"):
		minimap.set_minimap_enabled(show_minimap)
	if not show_minimap and minimap != null and minimap.has_method("clear_runtime_references"):
		minimap.clear_runtime_references()

	var energy_hud := get_node_or_null("GameRuntime/EnergyHud")
	if energy_hud != null and energy_hud.has_method("set_runtime_references") and player != null:
		energy_hud.set_runtime_references(
			player.get_node_or_null("PlayerDeath"),
			player.get_node_or_null("PlayerInventory")
		)

	var elapsed_time_hud := get_node_or_null("GameRuntime/ElapsedTimeHud")
	if elapsed_time_hud != null and elapsed_time_hud.has_method("set_runtime_references"):
		elapsed_time_hud.set_runtime_references(kill_boundary)


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


func _should_show_minimap() -> bool:
	var level_settings := _get_level_settings()
	if level_settings == null:
		return false

	return bool(level_settings.get("show_minimap"))


func _get_level_settings() -> Node:
	if current_level == null:
		return null

	if current_level.get_script() == LEVEL_SETTINGS_SCRIPT:
		return current_level

	for node in _get_descendants(current_level):
		if node.get_script() == LEVEL_SETTINGS_SCRIPT:
			return node

	return null


func _get_kill_boundary() -> Node:
	if current_level == null:
		return null

	if current_level.get_script() == KILL_BOUNDARY_SCRIPT:
		return current_level
	for node in _get_descendants(current_level):
		if node.get_script() == KILL_BOUNDARY_SCRIPT:
			return node
	return null


func _get_treasure_deposits() -> Array[Node]:
	if current_level == null:
		return []

	var deposits: Array[Node] = []
	for node in _get_descendants(current_level):
		if node.has_signal("treasure_absorbed"):
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
