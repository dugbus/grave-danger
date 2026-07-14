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


func is_level_available(index: int) -> bool:
    var level_data := get_level_entry(index)
    return bool(level_data.get("available", false))


func is_level_tutorial(index: int) -> bool:
    var level_data := get_level_entry(index)
    return bool(level_data.get("tutorial", false))
