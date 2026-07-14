extends Node
class_name GDLevelSelection

const DEFAULT_LEVEL_MAPPING := preload("res://levels/level_mapping.tres")
const RESULTS_PATH := "user://level_results.json"

var level_mapping = DEFAULT_LEVEL_MAPPING
var selected_level_index := 0
var last_highlighted_level_index := -1
var level_results := {}
var persistence_enabled := true


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

	var result := get_level_result(index)
	result["play_count"] = int(result.get("play_count", 0)) + 1
	result["played"] = true
	level_results[_get_result_key(index)] = result
	selected_level_index = index
	last_highlighted_level_index = index
	_save_results()
	return true


func remember_highlighted_level(index: int) -> bool:
	if not is_level_available(index):
		return false
	if last_highlighted_level_index == index:
		return true

	last_highlighted_level_index = index
	_save_results()
	return true


func get_last_highlighted_level_index() -> int:
	if last_highlighted_level_index < 0 or last_highlighted_level_index >= get_level_count() \
			or not is_level_available(last_highlighted_level_index):
		return -1

	return last_highlighted_level_index


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
		var stored_result: Dictionary = level_results[key].duplicate()
		var played := bool(stored_result.get("played", false))
		stored_result["best_score"] = int(stored_result.get("best_score", 0))
		stored_result["best_percentage"] = int(stored_result.get("best_percentage", 0))
		stored_result["escaped"] = bool(stored_result.get("escaped", false))
		stored_result["play_count"] = int(stored_result.get("play_count", 1 if played else 0))
		stored_result["played"] = played
		stored_result["lit_torches"] = _normalize_lit_torches(stored_result.get("lit_torches", []))
		return stored_result

	return {
		"best_score": 0,
		"best_percentage": 0,
		"escaped": false,
		"play_count": 0,
		"played": false,
		"lit_torches": [],
	}


## Returns whether a torch has been permanently lit for the requested level slot.
func is_torch_lit(torch_id: StringName, level_index: int = selected_level_index) -> bool:
	if torch_id.is_empty() or level_index < 0 or level_index >= get_level_count():
		return false

	var result := get_level_result(level_index)
	var lit_torches := _normalize_lit_torches(result.get("lit_torches", []))
	return String(torch_id) in lit_torches


## Permanently records a lit torch in the same user data as the level's other progress.
func mark_torch_lit(torch_id: StringName, level_index: int = selected_level_index) -> bool:
	if torch_id.is_empty() or level_index < 0 or level_index >= get_level_count():
		return false

	var result := get_level_result(level_index)
	var lit_torches := _normalize_lit_torches(result.get("lit_torches", []))
	var stored_id := String(torch_id)
	if stored_id in lit_torches:
		return true

	lit_torches.append(stored_id)
	result["lit_torches"] = lit_torches
	level_results[_get_result_key(level_index)] = result
	_save_results()
	return true


func record_selected_level_result(score: int, percentage: int, escaped: bool = true) -> void:
	record_level_result(selected_level_index, score, percentage, escaped)


func record_level_result(index: int, score: int, percentage: int, escaped: bool = true) -> void:
	if index < 0 or index >= get_level_count():
		return

	var existing := get_level_result(index)
	var existing_escaped := bool(existing.get("escaped", false))
	var best_score := int(existing.get("best_score", 0))
	var best_percentage := int(existing.get("best_percentage", 0))
	if escaped and existing_escaped:
		best_score = maxi(best_score, score)
		best_percentage = maxi(best_percentage, percentage)
	elif escaped:
		best_score = score
		best_percentage = percentage
	elif not existing_escaped:
		best_score = maxi(best_score, score)
		best_percentage = maxi(best_percentage, percentage)

	level_results[_get_result_key(index)] = {
		"best_score": best_score,
		"best_percentage": best_percentage,
		"escaped": existing_escaped or escaped,
		"play_count": int(existing.get("play_count", 0)),
		"played": true,
		"lit_torches": existing.get("lit_torches", []),
	}
	_save_results()


func _load_results() -> void:
	if not FileAccess.file_exists(RESULTS_PATH):
		level_results = {}
		last_highlighted_level_index = -1
		return

	var results_file := FileAccess.open(RESULTS_PATH, FileAccess.READ)
	if results_file == null:
		push_warning("Could not open level results file: %s" % RESULTS_PATH)
		level_results = {}
		last_highlighted_level_index = -1
		return

	var parsed = JSON.parse_string(results_file.get_as_text())
	if parsed is Dictionary:
		level_results = parsed.get("levels", {})
		last_highlighted_level_index = int(parsed.get(
			"last_highlighted_level_index",
			parsed.get("last_played_level_index", -1)
		))
	else:
		push_warning("Level results file is not valid JSON: %s" % RESULTS_PATH)
		level_results = {}
		last_highlighted_level_index = -1


func _save_results() -> void:
	if not persistence_enabled:
		return

	var results_file := FileAccess.open(RESULTS_PATH, FileAccess.WRITE)
	if results_file == null:
		push_warning("Could not write level results file: %s" % RESULTS_PATH)
		return

	results_file.store_string(JSON.stringify({
		"last_highlighted_level_index": last_highlighted_level_index,
		"levels": level_results,
	}, "\t"))


func _get_result_key(index: int) -> String:
	return "%02d" % (index + 1)


func _normalize_lit_torches(stored_value: Variant) -> Array[String]:
	var lit_torches: Array[String] = []
	if not stored_value is Array:
		return lit_torches

	for stored_id in stored_value:
		var torch_id := String(stored_id)
		if not torch_id.is_empty() and torch_id not in lit_torches:
			lit_torches.append(torch_id)
	return lit_torches
