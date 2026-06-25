extends Node
class_name GDLevelSelection

const DEFAULT_LEVEL_MAPPING := preload("res://levels/level_mapping.tres")
const RESULTS_PATH := "user://level_results.json"

var level_mapping = DEFAULT_LEVEL_MAPPING
var selected_level_index := 0
var level_results := {}


func _ready() -> void:
	_load_results()


func get_level_count() -> int:
	if level_mapping == null:
		return 0

	return level_mapping.get_level_count()


func get_level_data(index: int) -> Dictionary:
	if level_mapping == null:
		return {}

	return level_mapping.get_level_data(index)


func is_level_available(index: int) -> bool:
	if level_mapping == null:
		return false

	return level_mapping.is_level_available(index)


func select_level(index: int) -> bool:
	if not is_level_available(index):
		return false

	selected_level_index = index
	return true


func get_selected_level_scene() -> PackedScene:
	var scene_path := ""
	if level_mapping != null:
		scene_path = level_mapping.get_level_scene_path(selected_level_index)
	if scene_path.is_empty():
		return null

	return load(scene_path) as PackedScene


func get_selected_level_name() -> String:
	return String(get_level_data(selected_level_index).get("name", "Level 1"))


func get_level_result(index: int) -> Dictionary:
	var key := _get_result_key(index)
	if level_results.has(key):
		return level_results[key]

	return {
		"best_score": 0,
		"best_percentage": 0,
		"played": false,
	}


func record_selected_level_result(score: int, percentage: int) -> void:
	record_level_result(selected_level_index, score, percentage)


func record_level_result(index: int, score: int, percentage: int) -> void:
	if index < 0 or index >= get_level_count():
		return

	var existing := get_level_result(index)
	level_results[_get_result_key(index)] = {
		"best_score": maxi(int(existing.get("best_score", 0)), score),
		"best_percentage": maxi(int(existing.get("best_percentage", 0)), percentage),
		"played": true,
	}
	_save_results()


func _load_results() -> void:
	if not FileAccess.file_exists(RESULTS_PATH):
		level_results = {}
		return

	var results_file := FileAccess.open(RESULTS_PATH, FileAccess.READ)
	if results_file == null:
		push_warning("Could not open level results file: %s" % RESULTS_PATH)
		level_results = {}
		return

	var parsed = JSON.parse_string(results_file.get_as_text())
	if parsed is Dictionary:
		level_results = parsed.get("levels", {})
	else:
		push_warning("Level results file is not valid JSON: %s" % RESULTS_PATH)
		level_results = {}


func _save_results() -> void:
	var results_file := FileAccess.open(RESULTS_PATH, FileAccess.WRITE)
	if results_file == null:
		push_warning("Could not write level results file: %s" % RESULTS_PATH)
		return

	results_file.store_string(JSON.stringify({"levels": level_results}, "\t"))


func _get_result_key(index: int) -> String:
	return "%02d" % (index + 1)
