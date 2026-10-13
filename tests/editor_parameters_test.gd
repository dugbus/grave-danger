extends "res://tests/test_case.gd"

## Protects the reviewed Inspector API: designers retain authoring controls while internal
## wiring keeps its serialized values and runtime state is never saved into a level.
const CONTRACT_PATH := "res://tests/editor_parameters.json"
enum PropertyRole { Designer, Stored, Runtime, Unknown }

const FLOOR_MAP := preload("res://addons/floor_surface/floor_map.gd")
const FLOOR_STYLE := preload("res://addons/floor_surface/floor_style.gd")
const FLOOR_SURFACE := preload("res://addons/floor_surface/floor_surface.gd")


func run(_tree: SceneTree) -> void:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(CONTRACT_PATH))
	if not expect(parsed is Dictionary, "The reviewed editor parameter contract can be read."):
		return
	var contract := parsed as Dictionary
	for script_path_value in contract:
		var script_path := script_path_value as String
		var subject := load("res://" + script_path) as Script
		if not expect(subject != null, "The audited script loads: " + script_path):
			continue
		var properties := _properties_by_name(subject)
		var roles := contract[script_path] as Dictionary
		for role_value in roles:
			var role := role_value as String
			var names := roles[role] as Array
			for name_value in names:
				var property_name := name_value as String
				_check_property(properties, script_path, property_name, _role_from_name(role))
	_test_hidden_floor_data_survives_duplication()
	_test_new_floor_materials_survive_scene_packing()


func _properties_by_name(subject: Script) -> Dictionary:
	var properties := {}
	for property_value in subject.get_script_property_list():
		var property := property_value as Dictionary
		properties[String(property["name"])] = property
	return properties


func _check_property(properties: Dictionary, script_path: String, property_name: String, role: PropertyRole) -> void:
	var label := script_path + ":" + property_name
	if not expect(properties.has(property_name), "The audited property still exists: " + label):
		return
	var property := properties[property_name] as Dictionary
	var usage := int(property.get("usage", PROPERTY_USAGE_NONE))
	var visible := (usage & PROPERTY_USAGE_EDITOR) != 0
	var stored := (usage & PROPERTY_USAGE_STORAGE) != 0
	match role:
		PropertyRole.Designer:
			expect(visible, "Designers can still edit " + label)
		PropertyRole.Stored:
			expect(not visible and stored, "Internal values remain serialized but hidden: " + label)
		PropertyRole.Runtime:
			expect(not visible and not stored, "Runtime state is neither shown nor serialized: " + label)
		_:
			expect(false, "Unknown role in the editor parameter contract for " + label)


func _test_hidden_floor_data_survives_duplication() -> void:
	var authored := FLOOR_MAP.new()
	authored.dimensions = Vector2i(4, 4)
	authored.set_floor_present(Vector2i.ONE, true)
	authored.set_cell_elevation(Vector2i.ONE, 7)
	var copy := authored.duplicate(true) as FLOOR_MAP
	expect(copy != null, "An authored floor resource can still be duplicated.")
	if copy == null:
		return
	expect(copy.has_floor(Vector2i.ONE), "Hidden sparse floor occupancy survives resource duplication.")
	expect_equal(copy.get_cell_elevation(Vector2i.ONE), 7, "Hidden floor elevations survive resource duplication.")


func _role_from_name(role: String) -> PropertyRole:
	match role:
		"designer":
			return PropertyRole.Designer
		"stored":
			return PropertyRole.Stored
		"runtime":
			return PropertyRole.Runtime
	return PropertyRole.Unknown


func _test_new_floor_materials_survive_scene_packing() -> void:
	var surface := FLOOR_SURFACE.new()
	var style := FLOOR_STYLE.new()
	var finish := StandardMaterial3D.new()
	finish.albedo_color = Color(0.3, 0.2, 0.1)
	style.display_name = "Designer-added floor finish"
	style.top_material = finish
	style.wall_material = finish
	style.pit_bottom_material = finish
	var palette: Array[FLOOR_STYLE] = [style]
	surface.styles = palette
	surface.floor_map = FLOOR_MAP.new()
	surface.floor_map.dimensions = Vector2i(2, 2)
	surface.floor_map.set_floor_present(Vector2i.ONE, true)
	surface.top_mesh_path = ^"AuthoredDerivedMesh"
	var packed := PackedScene.new()
	if not expect_equal(packed.pack(surface), OK, "A new floor finish can be saved with an authored floor scene."):
		surface.free()
		return
	var restored := packed.instantiate() as FLOOR_SURFACE
	if expect(restored != null, "The authored floor scene can be restored."):
		expect_equal(restored.styles.size(), 1, "The designer-added floor style remains in the palette.")
		expect_equal(restored.styles[0].top_material, finish, "The designer's floor top material is retained.")
		expect_equal(restored.styles[0].wall_material, finish, "The designer's wall material is retained.")
		expect_equal(restored.styles[0].pit_bottom_material, finish, "The designer's pit material is retained.")
		expect(restored.floor_map.has_floor(Vector2i.ONE), "Hidden floor data is still saved with the scene.")
		expect_equal(restored.top_mesh_path, ^"AuthoredDerivedMesh", "Hidden scene wiring retains its authored value.")
		restored.free()
	surface.free()
