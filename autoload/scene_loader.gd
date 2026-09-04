class_name GDSceneLoader
extends Node

## Loads complete scene dependency graphs on worker threads and retains them for transitions.

const USE_SUB_THREADS := false

signal scene_loaded(scene_path: String, scene: PackedScene)
signal scene_load_failed(scene_path: String)

enum SceneLoadState {
	NotRequested,
	Queued,
	Loading,
	Loaded,
	Failed,
}

var scene_states: Dictionary[String, SceneLoadState] = {}
var cached_scenes: Dictionary[String, PackedScene] = {}
var pending_scene_paths: Array[String] = []
var active_scene_path := ""
var discard_after_load: Dictionary[String, bool] = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process(true)


func _process(_delta: float) -> void:
	if active_scene_path.is_empty():
		_start_next_request()
	else:
		_poll_scene(active_scene_path)


## Starts loading a scene and all resources referenced by its dependency graph.
func request_scene(scene_path: String, high_priority := false) -> Error:
	if scene_path.is_empty() or not ResourceLoader.exists(scene_path, "PackedScene"):
		return ERR_FILE_NOT_FOUND
	if get_scene_state(scene_path) in [
		SceneLoadState.Queued,
		SceneLoadState.Loading,
		SceneLoadState.Loaded,
	]:
		discard_after_load.erase(scene_path)
		if high_priority and get_scene_state(scene_path) == SceneLoadState.Queued:
			pending_scene_paths.erase(scene_path)
			pending_scene_paths.push_front(scene_path)
		return OK

	scene_states[scene_path] = SceneLoadState.Queued
	if high_priority:
		pending_scene_paths.push_front(scene_path)
	else:
		pending_scene_paths.append(scene_path)
	_start_next_request()
	return OK


## Starts several independent scene dependency graphs without blocking the caller.
func request_scenes(scene_paths: Array[String]) -> void:
	for scene_path in scene_paths:
		request_scene(scene_path)


## Discovers scene files recursively so newly added members of a dynamic catalog are precached.
func request_scene_directory(directory_path: String) -> int:
	var scene_paths: Array[String] = []
	_collect_scene_paths(directory_path, scene_paths)
	scene_paths.sort()
	request_scenes(scene_paths)
	return scene_paths.size()


## Returns a retained scene only after its complete dependency graph is ready.
func get_cached_scene(scene_path: String) -> PackedScene:
	return cached_scenes.get(scene_path) as PackedScene


## Reports the current state without triggering any synchronous resource work.
func get_scene_state(scene_path: String) -> SceneLoadState:
	return scene_states.get(scene_path, SceneLoadState.NotRequested) as SceneLoadState


## Releases a retained scene or drops a queued request after any active worker load completes.
func release_scene(scene_path: String) -> void:
	cached_scenes.erase(scene_path)
	pending_scene_paths.erase(scene_path)
	if active_scene_path == scene_path:
		discard_after_load[scene_path] = true
	else:
		scene_states.erase(scene_path)


## Waits asynchronously for a requested scene while the current screen remains responsive.
func load_scene(scene_path: String) -> PackedScene:
	var request_error := request_scene(scene_path, true)
	if request_error != OK:
		return null

	while get_scene_state(scene_path) in [SceneLoadState.Queued, SceneLoadState.Loading]:
		await get_tree().process_frame
	return get_cached_scene(scene_path)


## Changes scenes only after threaded loading has completed.
func change_scene_to_file(scene_path: String) -> Error:
	var packed_scene := await load_scene(scene_path)
	if packed_scene == null:
		return ERR_CANT_OPEN
	return get_tree().change_scene_to_packed(packed_scene)


func _poll_scene(scene_path: String) -> void:
	var status := ResourceLoader.load_threaded_get_status(scene_path)
	match status:
		ResourceLoader.THREAD_LOAD_LOADED:
			var loaded_scene := ResourceLoader.load_threaded_get(scene_path) as PackedScene
			active_scene_path = ""
			if discard_after_load.has(scene_path):
				discard_after_load.erase(scene_path)
				scene_states.erase(scene_path)
			elif loaded_scene == null:
				_mark_scene_failed(scene_path)
			else:
				_store_loaded_scene(scene_path, loaded_scene)
			_start_next_request()
		ResourceLoader.THREAD_LOAD_FAILED, ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
			active_scene_path = ""
			if discard_after_load.has(scene_path):
				discard_after_load.erase(scene_path)
				scene_states.erase(scene_path)
			else:
				_mark_scene_failed(scene_path)
			_start_next_request()


func _start_next_request() -> void:
	if not active_scene_path.is_empty():
		return

	while not pending_scene_paths.is_empty():
		var scene_path := pending_scene_paths.pop_front() as String
		if get_scene_state(scene_path) != SceneLoadState.Queued:
			continue
		if ResourceLoader.has_cached(scene_path):
			var already_cached := ResourceLoader.load(
				scene_path,
				"PackedScene",
				ResourceLoader.CACHE_MODE_REUSE
			) as PackedScene
			if already_cached != null:
				_store_loaded_scene(scene_path, already_cached)
				continue

		var request_error := ResourceLoader.load_threaded_request(
			scene_path,
			"PackedScene",
			USE_SUB_THREADS,
			ResourceLoader.CACHE_MODE_REUSE
		)
		if request_error != OK:
			_mark_scene_failed(scene_path)
			continue
		active_scene_path = scene_path
		scene_states[scene_path] = SceneLoadState.Loading
		return


func _store_loaded_scene(scene_path: String, scene: PackedScene) -> void:
	cached_scenes[scene_path] = scene
	scene_states[scene_path] = SceneLoadState.Loaded
	scene_loaded.emit(scene_path, scene)


func _mark_scene_failed(scene_path: String) -> void:
	scene_states[scene_path] = SceneLoadState.Failed
	scene_load_failed.emit(scene_path)


func _collect_scene_paths(directory_path: String, scene_paths: Array[String]) -> void:
	var directory := DirAccess.open(directory_path)
	if directory == null:
		return

	directory.list_dir_begin()
	var entry_name := directory.get_next()
	while not entry_name.is_empty():
		if not entry_name.begins_with("."):
			var entry_path := directory_path.path_join(entry_name)
			if directory.current_is_dir():
				_collect_scene_paths(entry_path, scene_paths)
			elif entry_name.get_extension().to_lower() == "tscn":
				scene_paths.append(entry_path)
		entry_name = directory.get_next()
	directory.list_dir_end()
