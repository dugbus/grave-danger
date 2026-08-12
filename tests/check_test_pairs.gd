extends SceneTree

## Prevents new production scripts from bypassing the co-located test convention.

const TEST_FILE_SUFFIX := "_test.gd"
const EXCLUDED_DIRECTORIES: Array[String] = [
	"res://.git",
	"res://.godot",
	"res://addons/simplegrasstextured",
	"res://tests",
]


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var production_paths: Array[String] = []
	_collect_production_scripts("res://", production_paths)
	production_paths.sort()
	var failures := 0

	for production_path in production_paths:
		var test_path := production_path.trim_suffix(".gd") + TEST_FILE_SUFFIX
		var has_test := FileAccess.file_exists(test_path)
		if has_test:
			failures += _validate_test_suite(test_path)
		else:
			push_error("Production script requires a sibling test: %s" % test_path)
			failures += 1

	print("Checked test pairing for %d production scripts." % production_paths.size())
	quit(1 if failures > 0 else 0)


func _validate_test_suite(test_path: String) -> int:
	var source_code := FileAccess.get_file_as_string(test_path)
	var has_test_base := source_code.contains(
		"extends \"res://tests/test_case.gd\""
	)
	var has_run_entry_point := source_code.contains("func run(")
	var has_assertion := source_code.contains("expect(") \
		or source_code.contains("expect_equal(") \
		or source_code.contains("expect_script_contract(")
	if has_test_base and has_run_entry_point and has_assertion:
		return 0

	push_error(
		"Sibling test must extend the test base, implement run(), and assert behavior: %s" \
		% test_path
	)
	return 1


func _collect_production_scripts(directory_path: String, production_paths: Array[String]) -> void:
	if _is_excluded_directory(directory_path):
		return

	var directory := DirAccess.open(directory_path)
	if directory == null:
		push_error("Could not inspect scripts in: %s" % directory_path)
		return

	directory.list_dir_begin()
	var entry_name := directory.get_next()
	while not entry_name.is_empty():
		if entry_name == "." or entry_name == "..":
			entry_name = directory.get_next()
			continue

		var entry_path := directory_path.path_join(entry_name)
		if directory.current_is_dir():
			_collect_production_scripts(entry_path, production_paths)
		elif entry_name.ends_with(".gd") and not entry_name.ends_with(TEST_FILE_SUFFIX):
			production_paths.append(entry_path)
		entry_name = directory.get_next()
	directory.list_dir_end()


func _is_excluded_directory(directory_path: String) -> bool:
	for excluded_path in EXCLUDED_DIRECTORIES:
		if directory_path == excluded_path or directory_path.begins_with(excluded_path + "/"):
			return true
	return false
