extends Node3D

const WIN_SCENE := "res://win_screen.tscn"

## Seconds used for the black transition before loading the win screen.
@export var win_fade_out_duration := 0.8

var coins_collected := 0
var max_coins_collected := 0
var showing_result := false


func _ready() -> void:
	max_coins_collected = _calculate_max_coins_collected()
	_store_result_stats()

	for deposit in get_tree().get_nodes_in_group("coin_deposit"):
		if deposit.has_signal("coin_absorbed"):
			deposit.coin_absorbed.connect(_on_coin_absorbed)


func _physics_process(delta: float) -> void:
	const move_speed := 1.0
	$LongRoad/PathFollow3D.progress += move_speed * delta


func _on_coin_absorbed(count: int) -> void:
	if showing_result:
		return

	coins_collected += maxi(count, 0)
	_store_result_stats()

	if max_coins_collected > 0 and coins_collected >= max_coins_collected:
		_show_win_screen()


func _calculate_max_coins_collected() -> int:
	var total := 0
	for node in _get_descendants(self):
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


func _show_win_screen() -> void:
	if showing_result:
		return

	showing_result = true
	var fade := _create_fade_overlay()
	var tween := create_tween()
	tween.tween_property(fade, "color:a", 1.0, win_fade_out_duration)
	await tween.finished

	get_tree().change_scene_to_file(WIN_SCENE)


func _create_fade_overlay() -> ColorRect:
	var layer := CanvasLayer.new()
	layer.name = "ResultFadeLayer"
	layer.layer = 100
	add_child(layer)

	var fade := ColorRect.new()
	fade.name = "ResultFade"
	fade.color = Color(0.0, 0.0, 0.0, 0.0)
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(fade)

	return fade
