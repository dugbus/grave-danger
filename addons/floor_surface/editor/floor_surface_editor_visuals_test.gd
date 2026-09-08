extends "res://tests/test_case.gd"

const SUBJECT := preload("res://addons/floor_surface/editor/floor_surface_editor_visuals.gd")
const FLOOR_MAP_SCRIPT := preload("res://addons/floor_surface/floor_map.gd")
const PROFILE_SCRIPT := preload("res://addons/floor_surface/floor_elevation_profile.gd")


func run(_tree: SceneTree) -> void:
	expect_script_contract(
		SUBJECT,
		"res://addons/floor_surface/editor/floor_surface_editor_visuals.gd"
	)
	var target := Node3D.new()
	var visuals := SUBJECT.new()
	visuals.attach(target)
	expect_equal(target.get_child_count(), 3, "Editor feedback uses three transient child meshes.")
	visuals.update_footprint(
		[Vector2i(-1, 2), Vector2i.ZERO],
		2.0,
		Vector2(4.0, -3.0),
		6.0,
		Color.YELLOW,
		true
	)
	var footprint := target.get_node("_FloorSurfacePaintPreview") as MeshInstance3D
	expect(footprint.visible, "A non-empty active footprint is visible.")
	expect(is_equal_approx(footprint.position.y, 6.04), "The footprint follows a tall authored height.")
	var floor_map := FLOOR_MAP_SCRIPT.new()
	floor_map.default_present = true
	var profile := PROFILE_SCRIPT.new()
	visuals.update_elevation_overlay(floor_map, profile, 1.0, Vector2.ZERO, true)
	var overlay := target.get_node("_FloorSurfaceElevationOverlay") as MeshInstance3D
	expect(overlay.visible and overlay.mesh.get_surface_count() == 1, "The elevation overlay is populated.")
	var grid := target.get_node("_FloorSurfaceGridOverlay") as MeshInstance3D
	expect(not grid.visible, "The texture-obscuring grid guide starts hidden.")
	visuals.update_grid_overlay(floor_map, profile, 1.0, Vector2.ZERO, true)
	expect(grid.visible and grid.mesh.get_surface_count() == 1, "The optional grid guide can be shown.")
	visuals.update_grid_overlay(floor_map, profile, 1.0, Vector2.ZERO, false)
	expect(not grid.visible, "The grid guide can be hidden to inspect the floor texture.")
	visuals.detach()
	expect_equal(target.get_child_count(), 0, "Detaching removes only the transient feedback meshes.")
	target.free()
