@tool
extends EditorPlugin

const EditorDebugger := preload("res://addons/playthrough_position_markers/editor_debugger.gd")
const SampleCollection := preload("res://addons/playthrough_position_markers/sample_collection.gd")
const MarkerBuilder := preload("res://addons/playthrough_position_markers/marker_builder.gd")
const ExportSceneStripper := preload(
	"res://addons/playthrough_position_markers/export_scene_stripper.gd"
)
const OPEN_SCENE_SETTLE_FRAMES := 3
const EXPORT_CUSTOMIZATION_VERSION := 2
const SCENE_FILE_EXTENSION := "tscn"
const EXPORT_CACHE_IGNORED_DIRECTORIES: Array[String] = [
	"builds",
	"screenshots",
]


class SceneSourceHasher:
	extends RefCounted

	static func calculate(root_directory := "res://") -> int:
		var scene_signatures := PackedStringArray()
		_collect_scene_source_signatures(root_directory, scene_signatures)
		scene_signatures.sort()
		return hash(scene_signatures)

	static func _collect_scene_source_signatures(
		directory_path: String, scene_signatures: PackedStringArray
	) -> void:
		var directory := DirAccess.open(directory_path)
		if directory == null:
			return

		directory.list_dir_begin()
		var entry_name := directory.get_next()
		while not entry_name.is_empty():
			var entry_path := directory_path.path_join(entry_name)
			if directory.current_is_dir():
				if (
					not entry_name.begins_with(".")
					and entry_name not in EXPORT_CACHE_IGNORED_DIRECTORIES
				):
					_collect_scene_source_signatures(entry_path, scene_signatures)
			elif entry_name.get_extension().to_lower() == SCENE_FILE_EXTENSION:
				scene_signatures.append("%s:%s" % [entry_path, FileAccess.get_md5(entry_path)])
			entry_name = directory.get_next()
		directory.list_dir_end()


class MarkerExportPlugin:
	extends EditorExportPlugin
	var _stripper := ExportSceneStripper.new()

	func _get_name() -> String:
		return "PlaythroughPositionMarkers"

	func _begin_customize_scenes(
		_platform: EditorExportPlatform, _features: PackedStringArray
	) -> bool:
		return true

	func _get_customization_configuration_hash() -> int:
		# Godot's per-scene export cache does not invalidate an inherited scene when
		# only its base scene changes. Include every source scene in the global cache
		# key so flattened inherited UI layouts cannot survive into later builds.
		return EXPORT_CUSTOMIZATION_VERSION ^ SceneSourceHasher.calculate()

	func _customize_scene(scene: Node, _path: String) -> Node:
		if _stripper.strip_marker_groups(scene):
			return scene
		return null


var _debugger: EditorDebuggerPlugin
var _export_plugin: EditorExportPlugin
var _samples := SampleCollection.new()
var _marker_builder := MarkerBuilder.new()


## Registers the namespaced debugger receiver used by debug game sessions.
func _enter_tree() -> void:
	_debugger = EditorDebugger.new()
	_debugger.position_sample_received.connect(_on_position_sample_received)
	_debugger.playthrough_finished.connect(_on_playthrough_finished)
	add_debugger_plugin(_debugger)
	_export_plugin = MarkerExportPlugin.new()
	add_export_plugin(_export_plugin)


## Removes the debugger receiver when the authoring plugin is disabled.
func _exit_tree() -> void:
	if _export_plugin != null:
		remove_export_plugin(_export_plugin)
	_export_plugin = null
	if _debugger != null:
		remove_debugger_plugin(_debugger)
	_debugger = null


func _on_position_sample_received(
	session_id: int, level_scene_path: String, elapsed_seconds: float, local_position: Vector3
) -> void:
	_samples.add_sample(session_id, level_scene_path, elapsed_seconds, local_position)


func _on_playthrough_finished(session_id: int) -> void:
	var level_samples := _samples.take_session(session_id)
	if not level_samples.is_empty():
		_apply_finished_playthrough.call_deferred(level_samples)


func _apply_finished_playthrough(level_samples: Dictionary) -> void:
	for level_path_value in level_samples:
		var level_path := level_path_value as String
		if not ResourceLoader.exists(level_path, "PackedScene"):
			push_warning("Could not open sampled level scene: %s" % level_path)
			continue

		var scene_root := await _get_or_open_edited_scene(level_path)
		if scene_root == null or not scene_root is Node3D:
			push_warning("Sampled level is not an editable Node3D scene: %s" % level_path)
			continue

		var samples := level_samples[level_path] as Array
		_marker_builder.replace_markers(scene_root as Node3D, samples)
		get_editor_interface().mark_scene_as_unsaved()
		get_editor_interface().get_selection().clear()
		var marker_container := _marker_builder.find_marker_container(scene_root as Node3D)
		if marker_container != null:
			get_editor_interface().get_selection().add_node(marker_container)
			var walked_path := _marker_builder.find_walked_path(marker_container)
			if walked_path != null:
				get_editor_interface().get_selection().add_node(walked_path)


## Reuses the current scene so populated embedded resources are not needlessly reloaded.
func _get_or_open_edited_scene(level_path: String) -> Node:
	var scene_root := get_editor_interface().get_edited_scene_root()
	if edited_scene_matches_level(scene_root, level_path):
		return scene_root
	get_editor_interface().open_scene_from_path(level_path)
	return await _wait_for_edited_scene(level_path)


## Reports whether marker application can safely use the editor's already-loaded scene.
static func edited_scene_matches_level(scene_root: Node, level_path: String) -> bool:
	return scene_root != null \
		and not level_path.is_empty() \
		and scene_root.scene_file_path == level_path


func _wait_for_edited_scene(level_path: String) -> Node:
	for _frame_index in OPEN_SCENE_SETTLE_FRAMES:
		await get_tree().process_frame
		var scene_root := get_editor_interface().get_edited_scene_root()
		if scene_root != null and scene_root.scene_file_path == level_path:
			return scene_root
	return null
