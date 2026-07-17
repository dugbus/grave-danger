extends Resource
class_name GDLevelMapping

const LEVEL_SCENE_FILE := "level.tscn"

@export var level_entries: Array[Dictionary] = []


func get_level_count() -> int:
    return level_entries.size()


func get_level_data(index: int) -> Dictionary:
    var level_data := get_level_entry(index).duplicate()
    if level_data.is_empty():
        return {}

    level_data["scene_path"] = get_level_scene_path(index)
    return level_data


func get_level_entry(index: int) -> Dictionary:
    if index < 0 or index >= level_entries.size():
        return {}

    return level_entries[index]


func get_level_scene_path(index: int) -> String:
    var folder_name := get_level_folder_name(index)
    if folder_name.is_empty():
        return ""

    return "res://levels/%s/%s" % [folder_name, LEVEL_SCENE_FILE]


func get_level_folder_name(index: int) -> String:
    var level_data := get_level_entry(index)
    return String(level_data.get("folder_name", ""))


func get_level_id(index: int) -> String:
    var level_data := get_level_entry(index)
    var level_id := String(level_data.get("id", ""))
    if not level_id.is_empty():
        return level_id

    var level_name := String(level_data.get("name", ""))
    if not level_name.is_empty():
        return level_name.to_snake_case()

    return get_level_folder_name(index).to_snake_case()


func get_legacy_result_key(index: int) -> String:
    return String(get_level_entry(index).get("legacy_result_key", ""))


func find_level_index_by_id(level_id: String) -> int:
    if level_id.is_empty():
        return -1

    for index in level_entries.size():
        if get_level_id(index) == level_id:
            return index
    return -1


func find_level_index_by_legacy_result_key(legacy_result_key: String) -> int:
    if legacy_result_key.is_empty():
        return -1

    for index in level_entries.size():
        if get_legacy_result_key(index) == legacy_result_key:
            return index
    return -1


func is_level_available(index: int) -> bool:
    var level_data := get_level_entry(index)
    return bool(level_data.get("available", false))


func is_level_tutorial(index: int) -> bool:
    var level_data := get_level_entry(index)
    return bool(level_data.get("tutorial", false))
