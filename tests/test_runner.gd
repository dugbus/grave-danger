extends SceneTree

## Discovers co-located tests only when this dedicated runner is launched.

const TEST_CASE := preload("res://tests/test_case.gd")
const TEST_FILE_SUFFIX := "_test.gd"
const EXCLUDED_DIRECTORIES: Array[String] = [
	"res://.git",
	"res://.godot",
]


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var test_paths: Array[String] = []
	_collect_test_paths("res://", test_paths)
	test_paths.sort()
	test_paths = _filter_requested_tests(test_paths)

	if test_paths.is_empty():
		push_error("No co-located test files matched the requested test filter.")
		quit(1)
		return

	var passed_count := 0
	var failed_count := 0
	for test_path in test_paths:
		var suite_script := load(test_path) as Script
		if suite_script == null:
			push_error("Could not load co-located test suite: %s" % test_path)
			failed_count += 1
			continue

		var suite := suite_script.new() as TEST_CASE
		if suite == null:
			push_error("Test suite must extend res://tests/test_case.gd: %s" % test_path)
			failed_count += 1
			continue

		suite.configure(test_path)
		await suite.run(self)
		passed_count += suite.get_passed_count()
		failed_count += suite.get_failed_count()

	print(
		"Co-located tests: %d suites, %d passed, %d failed." \
		% [test_paths.size(), passed_count, failed_count]
	)
	await _settle_engine_teardown()
	quit(1 if failed_count > 0 else 0)


func _settle_engine_teardown() -> void:
	# Freed test fixtures can leave renderer deletion queued until a later frame.
	for _frame_index in 3:
		await process_frame
	RenderingServer.force_sync()


func _collect_test_paths(directory_path: String, test_paths: Array[String]) -> void:
	if _is_excluded_directory(directory_path):
		return

	var directory := DirAccess.open(directory_path)
	if directory == null:
		push_error("Could not inspect test directory: %s" % directory_path)
		return

	directory.list_dir_begin()
	var entry_name := directory.get_next()
	while not entry_name.is_empty():
		if entry_name == "." or entry_name == "..":
			entry_name = directory.get_next()
			continue

		var entry_path := directory_path.path_join(entry_name)
		if directory.current_is_dir():
			_collect_test_paths(entry_path, test_paths)
		elif entry_name.ends_with(TEST_FILE_SUFFIX):
			test_paths.append(entry_path)
		entry_name = directory.get_next()
	directory.list_dir_end()


func _is_excluded_directory(directory_path: String) -> bool:
	for excluded_path in EXCLUDED_DIRECTORIES:
		if directory_path == excluded_path or directory_path.begins_with(excluded_path + "/"):
			return true
	return false


func _filter_requested_tests(test_paths: Array[String]) -> Array[String]:
	var requested_path := ""
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--test-file="):
			requested_path = argument.trim_prefix("--test-file=")

	if requested_path.is_empty():
		return test_paths

	var normalized_path := requested_path
	if not normalized_path.begins_with("res://"):
		normalized_path = "res://" + normalized_path.trim_prefix("/")
	var filtered_paths: Array[String] = []
	if test_paths.has(normalized_path):
		filtered_paths.append(normalized_path)
	return filtered_paths
