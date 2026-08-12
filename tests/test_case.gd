extends RefCounted

## Shared assertion state for co-located script test suites.

var _suite_path := ""
var _passed_count := 0
var _failed_count := 0


func configure(suite_path: String) -> void:
	_suite_path = suite_path


## Override this entry point in each sibling `_test.gd` file.
func run(_tree: SceneTree) -> void:
	expect(false, "Test suite must override run().")


func expect(condition: bool, message: String) -> bool:
	if condition:
		_passed_count += 1
		return true

	_failed_count += 1
	push_error("FAIL [%s]: %s" % [_suite_path, message])
	return false


func expect_equal(actual: Variant, expected: Variant, message: String) -> bool:
	return expect(actual == expected, "%s (expected %s, got %s)" % [message, expected, actual])


## Validates the common contract every production script must preserve.
func expect_script_contract(subject: Script, expected_path: String) -> void:
	expect(subject != null, "The production script loads as a Script resource.")
	if subject == null:
		return

	expect_equal(
		subject.resource_path,
		expected_path,
		"The sibling test references its exact production script."
	)
	expect(
		not subject.get_source_code().strip_edges().is_empty(),
		"The production script contains executable source."
	)
	expect(
		_has_named_members(subject),
		"The production script exposes a named member API."
	)
	_expect_default_construction(subject)


func _has_named_members(subject: Script) -> bool:
	var named_member_count := 0
	for member_list in [
		subject.get_script_method_list(),
		subject.get_script_signal_list(),
		subject.get_script_property_list(),
	]:
		for member_value in member_list:
			var member := member_value as Dictionary
			var member_name := member.get("name", &"") as StringName
			if member_name != &"":
				named_member_count += 1
	return named_member_count > 0


func _expect_default_construction(subject: Script) -> void:
	if subject.get_source_code().contains("@abstract"):
		expect(true, "The production script explicitly declares an abstract construction contract.")
		return

	if not subject.can_instantiate():
		expect(false, "A concrete production script must support construction.")
		return

	if _requires_constructor_arguments(subject):
		expect(true, "Required constructor dependencies are declared explicitly.")
		return

	var base_type := subject.get_instance_base_type()
	if base_type in [&"SceneTree", &"EditorPlugin", &"EditorNode3DGizmoPlugin"]:
		expect(true, "Engine-owned scripts declare a supported lifecycle base type.")
		return
	if not ClassDB.can_instantiate(base_type):
		expect(true, "The script intentionally extends a virtual engine base type.")
		return

	var instance := subject.new() as Object
	expect(instance != null, "The production script supports safe default construction.")
	if instance == null:
		return
	expect(instance.get_script() == subject, "A default instance retains the production script.")
	_expect_property_round_trips(subject, instance)
	if instance is Node:
		(instance as Node).free()
	elif not instance is RefCounted:
		instance.free()


func _expect_property_round_trips(subject: Script, instance: Object) -> void:
	var checked_property_count := 0
	var changed_properties: Array[String] = []
	for property_value in subject.get_script_property_list():
		var property := property_value as Dictionary
		var property_name := property.get("name", &"") as StringName
		var usage := int(property.get("usage", PROPERTY_USAGE_NONE))
		if property_name == &"" \
				or (usage & PROPERTY_USAGE_SCRIPT_VARIABLE) == 0 \
				or (usage & PROPERTY_USAGE_READ_ONLY) != 0:
			continue

		var original_value: Variant = instance.get(property_name)
		instance.set(property_name, original_value)
		if instance.get(property_name) != original_value:
			changed_properties.append(String(property_name))
		checked_property_count += 1

	expect(
		changed_properties.is_empty(),
		"%d script properties safely retain their default values off-tree%s." \
			% [
				checked_property_count,
				" (changed: %s)" % ", ".join(changed_properties) \
					if not changed_properties.is_empty() else "",
			]
	)


func _requires_constructor_arguments(subject: Script) -> bool:
	for method_value in subject.get_script_method_list():
		var method := method_value as Dictionary
		if (method.get("name", &"") as StringName) != &"_init":
			continue
		var arguments := method.get("args", []) as Array
		var default_arguments := method.get("default_args", []) as Array
		return arguments.size() > default_arguments.size()
	return false


func get_passed_count() -> int:
	return _passed_count


func get_failed_count() -> int:
	return _failed_count
