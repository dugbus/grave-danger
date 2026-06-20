extends Node
class_name GDLevelSelection

const RESULTS_PATH := "user://level_results.json"
const LEVELS := [
	{"name": "Level 1", "scene_path": "res://levels/1/level_01.tscn", "available": true},
	{"name": "Level 2", "scene_path": "res://levels/2/level_02.tscn", "available": true},
	{"name": "Level 3", "scene_path": "res://levels/3/level_03.tscn", "available": true},
	{"name": "Level 4", "scene_path": "res://levels/4/level_04.tscn", "available": true},
	{"name": "Level 5", "scene_path": "res://levels/5/level_05.tscn", "available": true},
	{"name": "Level 6", "scene_path": "res://levels/6/level_06.tscn", "available": true},
	{"name": "Level 7", "scene_path": "res://levels/7/level_07.tscn", "available": true},
	{"name": "Level 8", "scene_path": "res://levels/8/level_08.tscn", "available": true},
]

var selected_level_index := 0
var level_results := {}


func _ready() -> void:
	_load_results()


func get_level_count() -> int:
	return LEVELS.size()


func get_level_data(index: int) -> Dictionary:
	if index < 0 or index >= LEVELS.size():
		return {}

	return LEVELS[index]


func is_level_available(index: int) -> bool:
	var level_data := get_level_data(index)
	return bool(level_data.get("available", false))


func select_level(index: int) -> bool:
	if not is_level_available(index):
		return false

	selected_level_index = index
	return true


func get_selected_level_scene() -> PackedScene:
	var level_data := get_level_data(selected_level_index)
	var scene_path := String(level_data.get("scene_path", ""))
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
	if index < 0 or index >= LEVELS.size():
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
