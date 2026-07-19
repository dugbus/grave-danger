class_name GDLevelSelection
extends Node

## Selects playable levels while delegating persisted progression to GDPlayerProgress.

const DEFAULT_LEVEL_MAPPING := preload("res://levels/level_mapping.tres")
const PLAYER_PROGRESS_SCRIPT := preload("res://autoload/player_progress.gd")

var level_mapping = DEFAULT_LEVEL_MAPPING
var selected_level_index := 0
var player_progress := PLAYER_PROGRESS_SCRIPT.new()
var last_highlighted_level_index: int:
    get:
        return player_progress.last_highlighted_level_index
    set(value):
        player_progress.last_highlighted_level_index = value
var level_results: Dictionary:
    get:
        return player_progress.level_results
    set(value):
        player_progress.level_results = value
var treasure_wallet: Dictionary:
    get:
        return player_progress.treasure_wallet
    set(value):
        player_progress.treasure_wallet = value
var shop_purchases: Dictionary:
    get:
        return player_progress.shop_purchases
    set(value):
        player_progress.shop_purchases = value
var persistence_enabled: bool:
    get:
        return player_progress.persistence_enabled
    set(value):
        player_progress.persistence_enabled = value


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

    player_progress.mark_level_started(_get_result_key(index))
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


func get_selected_level_id() -> String:
    return _get_level_id(selected_level_index)


func register_run_recording_save_task(level_id: String, task_id: int) -> bool:
    return player_progress.register_run_recording_save_task(level_id, task_id)


func take_run_recording_save_task(level_id: String) -> int:
    return player_progress.take_run_recording_save_task(level_id)


func get_level_result(index: int) -> Dictionary:
    return player_progress.get_level_result(_get_result_key(index))


## Returns whether a torch has been permanently lit for the requested level slot.
func is_torch_lit(torch_id: StringName, level_index: int = selected_level_index) -> bool:
    if torch_id.is_empty() or level_index < 0 or level_index >= get_level_count():
        return false
    return player_progress.is_torch_lit(_get_result_key(level_index), torch_id)


## Permanently records a lit torch in the same user data as the level's other progress.
func mark_torch_lit(torch_id: StringName, level_index: int = selected_level_index) -> bool:
    if torch_id.is_empty() or level_index < 0 or level_index >= get_level_count():
        return false
    if player_progress.mark_torch_lit(_get_result_key(level_index), torch_id):
        _save_results()
    return true


func record_selected_level_result(
    score: int,
    percentage: int,
    escaped: bool = true,
    collected_treasure: Dictionary = {}
) -> Dictionary:
    return record_level_result(
        selected_level_index,
        score,
        percentage,
        escaped,
        collected_treasure
    )


func get_treasure_count(treasure_type: StringName) -> int:
    return player_progress.get_treasure_count(treasure_type)


func reset_progress() -> void:
    player_progress.reset()
    selected_level_index = 0
    _save_results()


func add_treasure_bundle(treasure_by_type: Dictionary) -> void:
    if player_progress.add_treasure_bundle(treasure_by_type):
        _save_results()


func _add_treasure_bundle_without_saving(treasure_by_type: Dictionary) -> bool:
    return player_progress.add_treasure_bundle(treasure_by_type)


func can_afford_treasure(treasure_type: StringName, amount: int) -> bool:
    return player_progress.can_afford_treasure(treasure_type, amount)


func get_shop_item_purchase_count(item_id: StringName) -> int:
    return player_progress.get_shop_item_purchase_count(item_id)


func purchase_shop_item(
    item_id: StringName,
    treasure_type: StringName,
    amount: int,
    stock_count: int
) -> bool:
    if not player_progress.purchase_shop_item(item_id, treasure_type, amount, stock_count):
        return false
    _save_results()
    return true


func record_level_result(
    index: int,
    score: int,
    percentage: int,
    escaped: bool = true,
    collected_treasure: Dictionary = {}
) -> Dictionary:
    if index < 0 or index >= get_level_count():
        return {}

    var newly_recovered: Dictionary = player_progress.record_level_result(
        _get_result_key(index),
        score,
        percentage,
        escaped,
        collected_treasure
    )
    _save_results()
    return newly_recovered


func _load_results() -> void:
    player_progress.load_results(level_mapping)


func _save_results() -> void:
    player_progress.save_results(level_mapping)


func _normalize_count_dictionary(stored_value: Variant) -> Dictionary:
    return player_progress.normalize_count_dictionary(stored_value)


func _get_result_key(index: int) -> String:
    return _get_level_id(index)


func _get_level_id(index: int) -> String:
    return player_progress.get_level_id(level_mapping, index)


func _migrate_legacy_results(stored_results: Dictionary) -> Dictionary:
    return player_progress.migrate_legacy_results(stored_results, level_mapping)


func _resolve_saved_highlighted_level_index(parsed_results: Dictionary) -> int:
    return player_progress.resolve_saved_highlighted_level_index(parsed_results, level_mapping)


func _normalize_lit_torches(stored_value: Variant) -> Array[String]:
    return player_progress.normalize_lit_torches(stored_value)
