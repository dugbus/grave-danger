extends "res://tests/test_case.gd"

const SUBJECT := preload("res://autoload/scene_loader.gd")
const SUBJECT_PATH := "res://autoload/scene_loader.gd"
const TEST_SCENE_PATH := "res://ui/screens/level_select_item_row.tscn"


func run(tree: SceneTree) -> void:
	expect_script_contract(SUBJECT, SUBJECT_PATH)
	expect(
		not SUBJECT.USE_SUB_THREADS,
		"Scene dependencies load on one worker so production UI frames remain responsive."
	)
	await _expect_scene_dependencies_load_without_blocking(tree)
	_expect_missing_scenes_fail_immediately()
	_expect_scene_directories_are_discovered_recursively()


func _expect_scene_dependencies_load_without_blocking(tree: SceneTree) -> void:
	var loader := SUBJECT.new() as SUBJECT
	loader.name = "SceneLoaderTest"
	tree.root.add_child(loader)
	var request_error := loader.request_scene(TEST_SCENE_PATH)
	expect_equal(request_error, OK, "A valid scene can be queued for threaded loading.")
	var loaded_scene := await loader.load_scene(TEST_SCENE_PATH)
	expect(loaded_scene != null, "A queued scene becomes available without a synchronous load.")
	expect_equal(
		loader.get_scene_state(TEST_SCENE_PATH),
		SUBJECT.SceneLoadState.Loaded,
		"Completed scene requests remain retained for later transitions."
	)
	loader.release_scene(TEST_SCENE_PATH)
	expect_equal(
		loader.get_scene_state(TEST_SCENE_PATH),
		SUBJECT.SceneLoadState.NotRequested,
		"Callers can release levels that are no longer likely to be selected."
	)
	loader.queue_free()
	await tree.process_frame


func _expect_missing_scenes_fail_immediately() -> void:
	var loader := SUBJECT.new() as SUBJECT
	expect_equal(
		loader.request_scene("res://missing/loading_test_scene.tscn"),
		ERR_FILE_NOT_FOUND,
		"Missing scenes fail without starting a threaded request."
	)
	loader.free()


func _expect_scene_directories_are_discovered_recursively() -> void:
	var loader := SUBJECT.new() as SUBJECT
	var scene_paths: Array[String] = []
	loader._collect_scene_paths("res://placeables/treasure", scene_paths)
	expect(
		scene_paths.has("res://placeables/treasure/gems/amethyst.tscn"),
		"Dynamic scene catalogs include newly added nested scene files automatically."
	)
	loader.free()
