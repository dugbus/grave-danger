extends "res://tests/test_case.gd"

const SUBJECT := preload(
	"res://addons/floor_surface/editor/floor_surface_editor_material_preview.gd"
)


func run(_tree: SceneTree) -> void:
	expect_script_contract(
		SUBJECT,
		"res://addons/floor_surface/editor/floor_surface_editor_material_preview.gd"
	)
	var source_material := StandardMaterial3D.new()
	source_material.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	var mesh := _make_triangle_mesh(source_material)
	SUBJECT.apply_to_mesh(mesh)
	var preview_material := mesh.surface_get_material(0) as StandardMaterial3D
	expect(preview_material != source_material, "Editor readability uses a transient material copy.")
	expect_equal(
		preview_material.shading_mode,
		BaseMaterial3D.SHADING_MODE_UNSHADED,
		"The editor preview remains visible without dependable scene lighting."
	)
	expect_equal(
		source_material.shading_mode,
		BaseMaterial3D.SHADING_MODE_PER_PIXEL,
		"Runtime style lighting remains unchanged."
	)


func _make_triangle_mesh(material: Material) -> ArrayMesh:
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = PackedVector3Array([
		Vector3.ZERO,
		Vector3.RIGHT,
		Vector3.BACK,
	])
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	mesh.surface_set_material(0, material)
	return mesh
