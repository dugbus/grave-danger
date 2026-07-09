extends SceneTree

const ADD_TO_TREE := false
const EXCLUDE_DIRS := [
	"res://.godot",
	"res://addons"
]

var checked := 0
var failures := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var scenes: Array[String] = []
	_collect_scenes("res://", scenes)
	scenes.sort()

	print("Checking %d scene(s)..." % scenes.size())

	for scene_path in scenes:
		await _check_scene(scene_path)

	print("")
	print("Checked %d scene(s), failures: %d" % [checked, failures])

	quit(1 if failures > 0 else 0)


func _collect_scenes(dir_path: String, scenes: Array[String]) -> void:
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

		if dir.current_is_dir():
			_collect_scenes(path, scenes)
		elif name.ends_with(".tscn") or name.ends_with(".scn"):
			scenes.append(path)

	dir.list_dir_end()


func _check_scene(scene_path: String) -> void:
	checked += 1
	print("--- %s" % scene_path)

	var res := ResourceLoader.load(scene_path, "PackedScene")

	if res == null:
		push_error("Failed to load scene: %s" % scene_path)
		failures += 1
		return

	if not res is PackedScene:
		push_error("Resource is not a PackedScene: %s" % scene_path)
		failures += 1
		return

	var packed := res as PackedScene

	if not packed.can_instantiate():
		push_error("Scene cannot be instantiated: %s" % scene_path)
		failures += 1
		return

	var instance := packed.instantiate()

	if instance == null:
		push_error("Instantiation returned null: %s" % scene_path)
		failures += 1
		return

	if ADD_TO_TREE:
		root.add_child(instance)
		await process_frame
		root.remove_child(instance)

	instance.free()