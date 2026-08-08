extends Resource
class_name GDLevelDefinition

## Stable identifier used by saved progress and replay files.
@export var id := ""
## Player-facing name shown by level-selection screens.
@export var display_name := ""
## Folder below `res://levels` that owns the level scene.
@export var folder_name := ""
## Legacy result key used while migrating older saved progress.
@export var legacy_result_key := ""
## Whether the level can currently be selected and launched.
@export var available := false
## Whether the level should be presented as a tutorial.
@export var tutorial := false
## Whether the level-select screen may show the last recorded run.
@export var run_playback_enabled := true


## Returns the dictionary contract consumed by existing level-selection code.
func to_level_data() -> Dictionary:
	var level_data := {
		"available": available,
		"folder_name": folder_name,
		"id": id,
		"name": display_name,
		"run_playback_enabled": run_playback_enabled,
		"tutorial": tutorial,
	}
	if not legacy_result_key.is_empty():
		level_data["legacy_result_key"] = legacy_result_key
	return level_data
