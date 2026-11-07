extends "res://tests/test_case.gd"

const MATERIALS := preload("res://placeables/kill_boundary/sepia/sepia_materials.gd")


func run(_tree: SceneTree) -> void:
	var original := "shader_type spatial;\nvoid fragment() { ALBEDO = vec3(0.5); }"
	var adapted := MATERIALS.inject_mask(original)
	expect(adapted.contains("ALBEDO = vec3(0.5);"), "Custom material behaviour survives clipping injection.")
	expect(adapted.contains("INV_VIEW_MATRIX * vec4(VERTEX"), "Clipping uses each visible surface position.")
	expect(adapted.find("discard") < adapted.find("ALBEDO ="), "Hidden geometry is discarded before colouring.")
	expect_equal(original.count("discard"), 0, "The source shader remains untouched.")
	var vertex_only := "shader_type spatial;\nvoid vertex() { VERTEX.y += 0.1; }"
	expect(
		MATERIALS.inject_mask(vertex_only).contains("void fragment()"), "Vertex-only effects get a clipping fragment."
	)
