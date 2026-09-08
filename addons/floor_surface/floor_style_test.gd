extends "res://tests/test_case.gd"

const SUBJECT := preload("res://addons/floor_surface/floor_style.gd")
const DEFAULT_STYLE := preload("res://addons/floor_surface/default_floor_style.tres")
const STONE_STYLE := preload("res://addons/floor_surface/stone_floor_style.tres")


func run(_tree: SceneTree) -> void:
	expect_script_contract(SUBJECT, "res://addons/floor_surface/floor_style.gd")
	var style := SUBJECT.new()
	expect_equal(style.validate().size(), 2, "Missing top and edge materials are actionable.")
	style.top_material = StandardMaterial3D.new()
	style.edge_material = StandardMaterial3D.new()
	expect_equal(style.validate(), [], "Configured top and edge materials pass validation.")
	style.pit_depth = 0.0
	expect_equal(
		style.validate(),
		["FloorStyle needs a positive exposed-side depth."],
		"Exposed boundaries cannot silently collapse to zero depth."
	)
	var dirt_material := DEFAULT_STYLE.top_material as StandardMaterial3D
	expect(dirt_material != null, "The default style uses a normal lit game material.")
	expect(
		dirt_material.albedo_texture.resource_path \
			== "res://Assets/environment/floors/textures/dirt_2.png",
		"The default style uses the independent FloorSurface dirt texture copy."
	)
	expect_equal(DEFAULT_STYLE.display_name, "Dirt", "The default style has a human floor name.")
	expect(DEFAULT_STYLE.edge_material != null, "The default style has an independent edge material.")
	expect(DEFAULT_STYLE.pit_bottom_material != null, "The default style has an optional pit material.")
	expect_equal(STONE_STYLE.validate(), [], "The reusable stone style is completely configured.")
	expect_equal(STONE_STYLE.display_name, "Flagstones", "The second style names its source texture.")
	expect_equal(STONE_STYLE.pit_depth, 3.0, "Stone can own a different visible pit depth.")
	var flagstones_material := STONE_STYLE.top_material as StandardMaterial3D
	expect(
		flagstones_material.albedo_texture.resource_path \
			== "res://Assets/environment/floors/textures/floor-albedo.png",
		"Flagstones use the game-owned FloorSurface albedo copy."
	)
	expect(
		flagstones_material.normal_texture.resource_path \
			== "res://Assets/environment/floors/textures/floor-normal.png",
		"Flagstones use the game-owned FloorSurface normal-map copy."
	)
	expect(
		STONE_STYLE.top_material != STONE_STYLE.edge_material \
			and STONE_STYLE.edge_material != STONE_STYLE.pit_bottom_material,
		"Stone top, edge and pit-bottom appearances are independently editable."
	)
	var changed_count: Array[int] = [0]
	style.changed.connect(func() -> void: changed_count[0] += 1)
	style.pit_depth = 2.5
	expect_equal(changed_count[0], 1, "Changing style geometry settings requests a surface rebuild.")
