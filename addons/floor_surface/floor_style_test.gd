extends "res://tests/test_case.gd"

const SUBJECT := preload("res://addons/floor_surface/floor_style.gd")
const DEFAULT_STYLE := preload("res://addons/floor_surface/default_floor_style.tres")


func run(_tree: SceneTree) -> void:
	expect_script_contract(SUBJECT, "res://addons/floor_surface/floor_style.gd")
	var style := SUBJECT.new()
	expect_equal(style.validate_flat_top().size(), 1, "A missing flat-top material is actionable.")
	style.top_material = StandardMaterial3D.new()
	expect_equal(style.validate_flat_top(), [], "A configured top material passes M2 validation.")
	style.pit_depth = 0.0
	expect_equal(
		style.validate_flat_top(),
		["FloorStyle needs a positive exposed-side depth."],
		"Exposed boundaries cannot silently collapse to zero depth."
	)
	var debug_material := DEFAULT_STYLE.top_material as ShaderMaterial
	expect(debug_material != null, "The M2 playground style has a dedicated debug material.")
	expect(
		debug_material.shader.code.contains("render_mode unshaded"),
		"The M2 grid remains visible independently of scene lighting."
	)
