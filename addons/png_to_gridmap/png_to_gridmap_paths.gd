@tool
class_name PNGToGridMapPaths
extends RefCounted

## Normalises project and filesystem paths used by PNG-to-GridMap editor workflows.
## Keeping path policy here prevents import, export, and profile storage from disagreeing.


## Returns a project-relative resource path when a filesystem path is inside the project.
static func localize_project_path(path: String) -> String:
	if path == "" or path.begins_with("res://") or path.begins_with("user://"):
		return path
	var localized := ProjectSettings.localize_path(path)
	if localized.begins_with("res://"):
		return localized
	return path


## Ensures PNG paths end in the PNG extension before display or writing.
static func normalize_png_output_path(path: String) -> String:
	var localized := localize_project_path(path)
	if localized.get_extension().to_lower() == "png":
		return localized
	return localized + ".png"
