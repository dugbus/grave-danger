extends "res://tests/test_case.gd"

const SUBJECT := preload("res://placeables/platforms/elevator/elevator_geometry.gd")


func run(_tree: SceneTree) -> void:
	expect_script_contract(SUBJECT, "res://placeables/platforms/elevator/elevator_geometry.gd")
	var surface := FloorSurface.new()
	surface.floor_map = FloorMap.new()
	surface.floor_map.dimensions = Vector2i(3, 3)
	var style := FloorStyle.new()
	style.top_material = StandardMaterial3D.new()
	style.wall_material = StandardMaterial3D.new()
	style.world_uv_metres = 2.0
	style.wall_uv_metres = 0.5
	surface.styles.assign([style])
	var mesh := SUBJECT.build(surface, Vector3(1.5, 2.0, 1.5), 1.0, 1.0, 0.25)
	expect_equal(mesh.get_surface_count(), 2, "Top and other faces have separate material surfaces.")
	expect(mesh.surface_get_material(0) == style.top_material, "The top uses the floor's actual material.")
	expect(mesh.surface_get_material(1) == style.wall_material, "Other faces use the wall material.")
	expect_equal(mesh.get_faces().size(), 36, "Six closed quads produce twelve triangles.")
	# Godot pads each planar surface's render bounds; inspect actual geometry instead.
	var bounds := AABB(mesh.get_faces()[0], Vector3.ZERO)
	for vertex in mesh.get_faces():
		bounds = bounds.expand(vertex)
	expect(
		bounds.is_equal_approx(AABB(Vector3(-0.5, -0.25, -0.5), Vector3(1.0, 0.25, 1.0))),
		"Geometry has the floor slab's exact dimensions."
	)
	var arrays := mesh.surface_get_arrays(0)
	var uvs := arrays[Mesh.ARRAY_TEX_UV] as PackedVector2Array
	expect_equal(uvs[0], Vector2(0.5, 0.5), "Top UVs match the floor's world texture scale.")
	style.top_uv_mapping = FloorStyle.TopUvMapping.SurfaceNormalized
	var normalized := SUBJECT.build(surface, Vector3(1.5, 2.0, 1.5), 1.0, 1.0, 0.25)
	var normalized_uvs := normalized.surface_get_arrays(0)[Mesh.ARRAY_TEX_UV] as PackedVector2Array
	expect(normalized_uvs[0].is_equal_approx(Vector2.ONE / 3.0), "Normalized floor palettes preserve their mapping.")
	surface.free()
