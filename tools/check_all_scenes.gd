extends SceneTree

const EXCLUDE_DIRS := [
	"res://.godot",
	"res://addons/copy_all_errors",
	"res://addons/simplegrasstextured",
	"res://tests/run_tests.gd"
]
const TEXT_RESOURCE_EXTENSIONS: Array[String] = ["tscn", "tres"]

var checked := 0
var failures := 0


func _init() -> void:
	call_deferred(&"_run")


func _run() -> void:
	var scenes: Array[String] = []
	var text_resources: Array[String] = []
	_collect_resources("res://", scenes, text_resources)
	scenes.sort()
	text_resources.sort()
	scenes = _filter_requested_scenes(scenes)
	_validate_text_resource_uids(text_resources)
	print("Validated UIDs in %d text resources." % text_resources.size())

	for scene_path in scenes:
		_check_scene(scene_path)

	print("Checked %d/%d scenes." % [checked, scenes.size()])
	await _settle_engine_teardown()

	quit(1 if failures > 0 else 0)


func _filter_requested_scenes(scenes: Array[String]) -> Array[String]:
	var requested_fragment := ""
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--scene-filter="):
			requested_fragment = argument.trim_prefix("--scene-filter=")
	if requested_fragment.is_empty():
		return scenes

	var filtered_scenes: Array[String] = []
	for scene_path in scenes:
		if requested_fragment in scene_path:
			filtered_scenes.append(scene_path)
	return filtered_scenes


func _settle_engine_teardown() -> void:
	# Scene destruction queues renderer cleanup. Give the dummy renderer enough
	# frames to release its shader RIDs before this short-lived process exits.
	for _frame_index in 3:
		await process_frame
	RenderingServer.force_sync()


func _collect_resources(
	dir_path: String,
	scenes: Array[String],
	text_resources: Array[String]
) -> void:
	for excluded in EXCLUDE_DIRS:
		if dir_path.begins_with(excluded):
			return

	var dir := DirAccess.open(dir_path)
	if dir == null:
		push_error("Could not open directory: %s" % dir_path)
		failures += 1
		return

	dir.list_dir_begin()

	while true:
		var name := dir.get_next()
		if name == "":
			break

		if name.begins_with("."):
			continue

		var path := dir_path.path_join(name)
		var is_directory := dir.current_is_dir()

		if is_directory:
			_collect_resources(path, scenes, text_resources)
		elif name.ends_with(".tscn") or name.ends_with(".scn"):
			scenes.append(path)
		if not is_directory \
				and TEXT_RESOURCE_EXTENSIONS.has(name.get_extension().to_lower()):
			text_resources.append(path)

	dir.list_dir_end()


func _validate_text_resource_uids(resource_paths: Array[String]) -> void:
	var root_paths_by_uid: Dictionary = {}
	for resource_path in resource_paths:
		var source := FileAccess.get_file_as_string(resource_path)
		var lines := source.split("\n")
		if lines.is_empty():
			continue

		var root_uid := _get_quoted_attribute(lines[0], "uid")
		if not root_uid.is_empty():
			if root_paths_by_uid.has(root_uid):
				push_error(
					"Duplicate root UID %s: %s and %s"
					% [root_uid, String(root_paths_by_uid[root_uid]), resource_path]
				)
				failures += 1
			else:
				root_paths_by_uid[root_uid] = resource_path

		for line_index in lines.size():
			var line := lines[line_index]
			if not line.begins_with("[ext_resource "):
				continue
			_validate_external_resource_uid(resource_path, line_index + 1, line)


func _validate_external_resource_uid(
	owner_path: String,
	line_number: int,
	declaration: String
) -> void:
	var declared_uid := _get_quoted_attribute(declaration, "uid")
	if declared_uid.is_empty():
		return
	var referenced_path := _get_quoted_attribute(declaration, "path")
	if referenced_path.is_empty():
		return

	var declared_id := ResourceUID.text_to_id(declared_uid)
	var actual_id := ResourceLoader.get_resource_uid(referenced_path)
	if declared_id == actual_id and actual_id != ResourceUID.INVALID_ID:
		return

	var actual_uid := ResourceUID.id_to_text(actual_id) \
		if actual_id != ResourceUID.INVALID_ID else "no UID"
	push_error(
		"%s:%d declares stale UID %s for %s (actual: %s)"
		% [owner_path, line_number, declared_uid, referenced_path, actual_uid]
	)
	failures += 1


func _get_quoted_attribute(declaration: String, attribute: String) -> String:
	var prefix := " %s=\"" % attribute
	var value_start := declaration.find(prefix)
	if value_start < 0:
		return ""
	value_start += prefix.length()
	var value_end := declaration.find("\"", value_start)
	if value_end < 0:
		return ""
	return declaration.substr(value_start, value_end - value_start)


func _check_scene(scene_path: String) -> void:
	checked += 1

	# Validation owns this scene load only for the duration of this function.
	# Avoid adding its dependency graph to the process-wide resource cache.
	var res := ResourceLoader.load(
		scene_path,
		"PackedScene",
		ResourceLoader.CACHE_MODE_IGNORE_DEEP
	)

	if res == null:
		print("--- %s" % scene_path)
		push_error("Failed to load scene: %s" % scene_path)
		failures += 1
		return

	if not res is PackedScene:
		print("--- %s" % scene_path)
		push_error("Resource is not a PackedScene: %s" % scene_path)
		failures += 1
		return

	var packed := res as PackedScene

	if not packed.can_instantiate():
		print("--- %s" % scene_path)
		push_error("Scene cannot be instantiated: %s" % scene_path)
		failures += 1
		return

	var instance := packed.instantiate()

	if instance == null:
		print("--- %s" % scene_path)
		push_error("Instantiation returned null: %s" % scene_path)
		failures += 1
		return

	instance.free()
	instance = null
	packed = null
	res = null
