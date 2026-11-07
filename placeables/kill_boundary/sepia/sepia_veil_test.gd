extends "res://tests/test_case.gd"

const VEIL := preload("res://placeables/kill_boundary/sepia/sepia_veil.gd")
const SETTINGS := preload("res://placeables/kill_boundary/sepia/sepia_boundary_settings.tres")


func run(tree: SceneTree) -> void:
	var parent := Node3D.new()
	parent.position = Vector3(11.0, 3.0, -7.0)
	parent.rotation.y = 0.7
	parent.scale = Vector3.ONE * 2.0
	var veil := VEIL.new()
	parent.add_child(veil)
	tree.root.add_child(parent)
	veil.set_process(false)
	var perimeter := PackedVector3Array(
		[Vector3(-2.0, 0.3, 0.0), Vector3(2.0, 0.3, 0.0), Vector3(2.0, 0.3, -4.0), Vector3(-2.0, 0.3, -4.0)]
	)
	veil.set_perimeters([perimeter])
	veil.set_active(true)
	veil.set_process(false)
	expect(
		veil.global_transform == Transform3D.IDENTITY,
		"World-space points are not transformed twice by boundary parents."
	)
	expect_equal(veil._vertices.size(), 24, "Every canonical edge, including the closing edge, has two triangles.")
	for index in perimeter.size():
		expect_equal(veil._vertices[index * 6], perimeter[index], "Each segment starts on the actual perimeter.")
		expect_equal(
			veil._vertices[index * 6 + 1], perimeter[(index + 1) % 4], "Each segment ends on its next canonical point."
		)
		expect_equal(
			veil._vertices[index * 6 + 2],
			perimeter[index] + Vector3.UP * SETTINGS.veil_height,
			"The top is a vertical extrusion, with no horizontal displacement of the edge."
		)
	expect(veil._uvs[2].y == 1.0 and veil._uvs[0].y == 0.0, "The shader's height fade runs from base to top.")
	var original_mesh := veil.mesh
	for index in perimeter.size():
		perimeter[index] += Vector3(30.0, 2.0, 1.0)
	veil.set_perimeters([perimeter])
	expect(veil.mesh == original_mesh, "Animated boundaries reuse the existing mesh resource.")
	expect_equal(veil._vertices[0], perimeter[0], "An in-place update follows the new world perimeter.")
	expect(veil.custom_aabb.has_point(perimeter[0]), "Culling bounds follow large translations and vertical movement.")
	var canonical_vertices := veil._vertices.duplicate()
	veil.set_player_height(12.0)
	expect(
		veil.custom_aabb.has_point(Vector3(perimeter[0].x, 13.5, perimeter[0].z)),
		"Culling includes the elevated opacity band even far above the original wall."
	)
	veil.set_player_height(-8.0)
	expect(
		veil.custom_aabb.has_point(Vector3(perimeter[0].x, -8.0, perimeter[0].z)),
		"A falling player can take the band below the boundary base."
	)
	expect_equal(veil._vertices, canonical_vertices, "Tracking height changes neither the perimeter nor its mesh data.")
	veil.clear_player_height()
	expect(
		(
			not veil._follow_player_height
			and not veil.custom_aabb.has_point(Vector3(perimeter[0].x, -8.0, perimeter[0].z))
		),
		"With no player the veil restores the authored base-height bounds."
	)
	var before := veil.visual_time
	veil.advance_visual(0.5)
	expect(is_equal_approx(veil.visual_time, before + 0.5), "Noise has a separate, explicitly advanced visual clock.")
	veil.set_active(false)
	veil.advance_visual(1.0)
	expect(
		is_equal_approx(veil.visual_time, before + 0.5) and not veil.visible,
		"Leaving Sepia hides and stops its visual effect."
	)
	perimeter.remove_at(3)
	veil.set_perimeters([perimeter])
	expect_equal(veil._vertices.size(), 18, "Topology changes rebuild the same mesh with the new exact point count.")
	veil.set_perimeters([])
	expect(veil.mesh.get_surface_count() == 0 and not veil.visible, "Removing all boundaries leaves no stale curtain.")
	parent.free()
	await tree.process_frame
	if DisplayServer.get_name() != "headless":
		await _test_render(tree)


func _test_render(tree: SceneTree) -> void:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(256, 256)
	viewport.own_world_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	tree.root.add_child(viewport)
	var world := WorldEnvironment.new()
	world.environment = Environment.new()
	world.environment.background_mode = Environment.BG_COLOR
	world.environment.background_color = Color.BLACK
	viewport.add_child(world)
	var camera := Camera3D.new()
	viewport.add_child(camera)
	camera.position = Vector3(0.0, 0.9, 6.0)
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 5.0
	camera.current = true
	var veil := VEIL.new()
	viewport.add_child(veil)
	var perimeter := PackedVector3Array([Vector3(-2.0, 0.0, 0.0), Vector3(2.0, 0.0, 0.0), Vector3(0.0, 0.0, -3.0)])
	veil.set_perimeters([perimeter])
	veil.set_active(true)
	veil.set_process(false)
	await _draw_frames(tree)
	var first := viewport.get_texture().get_image()
	veil.advance_visual(4.0)
	await _draw_frames(tree)
	var second := viewport.get_texture().get_image()
	var changed := _pixel_changes(first, second)
	expect(changed > 100, "Procedural noise visibly morphs while its geometry stays still.")
	expect_equal(veil._vertices[0], perimeter[0], "Shader animation never moves the real perimeter.")
	veil.set_active(false)
	await _draw_frames(tree)
	var absent := viewport.get_texture().get_image()
	expect(_pixel_changes(second, absent) > 1000, "The translucent veil is plainly visible against a dark room.")
	veil.set_active(true)
	veil.set_process(false)
	for index in perimeter.size():
		perimeter[index].x += 20.0
	veil.set_perimeters([perimeter])
	await _draw_frames(tree)
	var moved := viewport.get_texture().get_image()
	expect(_pixel_changes(moved, absent) == 0, "Dynamic vertex uploads move the rendered veil off its old location.")
	camera.position.x = 20.0
	await _draw_frames(tree)
	var followed := viewport.get_texture().get_image()
	expect(
		_pixel_changes(followed, absent) > 1000,
		"Updated culling bounds keep the moved veil visible to a following camera."
	)
	# Use the same framing relative to the player to compare opacity at different elevations.
	veil.set_player_height(6.0)
	camera.position.y = 6.9
	await _draw_frames(tree)
	var elevated := viewport.get_texture().get_image()
	expect(_pixel_changes(elevated, absent) > 1000, "The veil remains visible alongside a raised player.")
	camera.position.y = 0.9
	await _draw_frames(tree)
	var ground := viewport.get_texture().get_image()
	expect(_pixel_changes(ground, absent) < 10, "Opacity leaves ground level when the player is above it.")
	veil.set_player_height(-6.0)
	camera.position.y = -5.1
	await _draw_frames(tree)
	var falling := viewport.get_texture().get_image()
	expect(_pixel_changes(falling, absent) > 1000, "Opacity also follows a player falling below the base.")
	veil.clear_player_height()
	await _draw_frames(tree)
	var cleared := viewport.get_texture().get_image()
	expect(_pixel_changes(cleared, absent) == 0, "Removing the tracked player restores the base curtain.")
	viewport.free()
	await tree.process_frame


func _draw_frames(tree: SceneTree) -> void:
	for _frame in 4:
		await tree.process_frame
		await RenderingServer.frame_post_draw


func _pixel_changes(first: Image, second: Image) -> int:
	var changed := 0
	for y in first.get_height():
		for x in first.get_width():
			var a := first.get_pixel(x, y)
			var b := second.get_pixel(x, y)
			if absf(a.r - b.r) + absf(a.g - b.g) + absf(a.b - b.b) > 0.025:
				changed += 1
	return changed
