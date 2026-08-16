extends "res://tests/test_case.gd"

const SUBJECT := preload("res://inventory/key.gd")
const SUBJECT_PATH := "res://inventory/key.gd"
const SUBJECT_SCENE := preload("res://inventory/key.tscn")


func run(_tree: SceneTree) -> void:
	expect_script_contract(SUBJECT, SUBJECT_PATH)
	var key := SUBJECT_SCENE.instantiate() as RigidBody3D
	var key_mesh := key.get_node("KeyModel/Torus") as MeshInstance3D
	var preview_material := key_mesh.get_surface_override_material(0) \
		as StandardMaterial3D
	expect(
		preview_material != null \
			and preview_material.emission_enabled \
			and preview_material.albedo_color.r > preview_material.albedo_color.b,
		"The gold key keeps its bright authored material in editor previews."
	)
	expect(
		key.get_node_or_null(^"EditorGateKeyMarker") == null,
		"The gold key remains unobstructed by editor-only locator text."
	)
	key.free()
