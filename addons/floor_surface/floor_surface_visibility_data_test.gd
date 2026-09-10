extends "res://tests/test_case.gd"

const SUBJECT := preload("res://addons/floor_surface/floor_surface_visibility_data.gd")
const SURFACE_SCENE := preload("res://addons/floor_surface/floor_surface.tscn")
const MAP_SCRIPT := preload("res://addons/floor_surface/floor_map.gd")
const PROFILE_SCRIPT := preload("res://addons/floor_surface/floor_elevation_profile.gd")
const STYLE := preload("res://addons/floor_surface/default_floor_style.tres")


func run(tree: SceneTree) -> void:
	expect_script_contract(
		SUBJECT,
		"res://addons/floor_surface/floor_surface_visibility_data.gd"
	)
	var surface := SURFACE_SCENE.instantiate() as FloorSurface
	var floor_map := MAP_SCRIPT.new()
	floor_map.minimum_cell = Vector2i(-1, 2)
	floor_map.dimensions = Vector2i(3, 1)
	floor_map.default_present = true
	floor_map.set_floor_present(Vector2i.ZERO + Vector2i(0, 2), false)
	floor_map.set_cell_elevation(Vector2i(-1, 2), 0)
	floor_map.set_cell_elevation(Vector2i(1, 2), 4)
	surface.floor_map = floor_map
	surface.elevation_profile = PROFILE_SCRIPT.new()
	surface.elevation_profile.elevation_unit = 0.25
	surface.styles = [STYLE]
	tree.root.add_child(surface)
	await tree.process_frame

	var data := SUBJECT.new()
	expect(data.rebuild(surface), "A configured surface produces visibility data.")
	expect_equal(data.dimensions, Vector2i(3, 1), "Texture dimensions match authored bounds.")
	expect_equal(data.minimum_cell, Vector2i(-1, 2), "Texture origin retains signed map cells.")
	expect(data.get_encoded_cell(Vector2i(-1, 2)).r > 0.5, "Present cells encode occupancy.")
	expect(data.get_encoded_cell(Vector2i(0, 2)).r < 0.5, "Holes encode empty occupancy.")
	expect(
		is_equal_approx(data.get_encoded_cell(Vector2i(1, 2)).g, 1.0),
		"Flat cell height is encoded in world metres."
	)
	expect(data.preview_texture != null, "A human-readable elevation preview accompanies GPU data.")
	var rebuilds_before := data.rebuild_count
	await tree.process_frame
	expect_equal(data.rebuild_count, rebuilds_before, "Static terrain does not rebuild data per frame.")
	surface.queue_free()
	await tree.process_frame
