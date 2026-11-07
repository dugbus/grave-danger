extends "res://tests/test_case.gd"

const SCENE := preload("res://placeables/kill_boundary/kill_boundary.tscn")


func run(tree: SceneTree) -> void:
	var level := load("res://levels/1/level.tscn") as PackedScene
	var state := level.get_state()
	var found := false
	for index in state.get_node_count():
		if state.get_node_name(index) == &"KillBoundary3D":
			for property_index in state.get_node_property_count(index):
				if state.get_node_property_name(index, property_index) == &"render_effect":
					found = state.get_node_property_value(index, property_index) == GDKillBoundary3D.RenderEffect.Sepia
	expect(found, "Level 1 selects Sepia on its existing kill boundary, with no independent region.")
	var root := Node3D.new()
	var region := _boundary(Vector2(4.0, 10.0))
	var actor := CharacterBody3D.new()
	actor.add_to_group(&"player")
	root.add_child(actor)
	root.add_child(region)
	tree.root.add_child(root)
	await tree.process_frame
	var view := region.get_node(^"SepiaMode/View")
	expect(actor in view.contacts.players, "The view registers the real level's player after ready.")
	expect(
		view.get_node(^"TimeVeil") is MeshInstance3D, "The mode authors its procedural veil as an editable visual node."
	)
	actor.position.y = 5.0
	await tree.process_frame
	await tree.process_frame
	expect(
		is_equal_approx(view.veil._player_height, 5.0),
		"The real player drives the veil height even with a static boundary."
	)
	actor.position.y = -2.0
	await tree.process_frame
	await tree.process_frame
	expect(is_equal_approx(view.veil._player_height, -2.0), "Descending and falling also update the tracked height.")
	var spawned := RigidBody3D.new()
	spawned.add_to_group(&"inventory_pickup")
	root.add_child(spawned)
	await tree.process_frame
	expect(spawned in view.contacts.bodies, "Late-spawned rewards join contact filtering before collection.")
	expect(not spawned.freeze, "Late registration preserves rigid-body simulation.")
	var survivor := _boundary(Vector2(4.0, 10.0))
	root.add_child(survivor)
	region.queue_free()
	await tree.process_frame
	await tree.process_frame
	expect(
		survivor.get_node(^"SepiaMode/View")._active,
		"Removing the leading region hands the remaining view to its survivor."
	)
	actor.queue_free()
	await tree.process_frame
	await tree.process_frame
	expect(
		not survivor.get_node(^"SepiaMode/View/TimeVeil")._follow_player_height,
		"A removed player releases height tracking."
	)
	root.free()
	await tree.process_frame
	if DisplayServer.get_name() != "headless":
		await _test_render(tree)
		await _test_background(tree)


# Flow: Real pixels establish the partial-body split and background reveal that headless tests cannot.
func _test_render(tree: SceneTree) -> void:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(512, 512)
	viewport.own_world_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	tree.root.add_child(viewport)
	var root := Node3D.new()
	viewport.add_child(root)
	var floor_mesh := _add_box(root, Vector3(0.0, -0.6, 0.0), Color.GREEN, false)
	floor_mesh.scale = Vector3(10.0, 0.1, 10.0)
	_add_box(root, Vector3.ZERO, Color.RED, false)
	_add_box(root, Vector3(2.0, 0.0, 0.0), Color.BLUE, true)
	_add_box(root, Vector3(-2.0, 0.0, 0.0), Color.BLUE, true)
	var glass := _add_box(root, Vector3(-2.0, 0.0, 2.0), Color(0.0, 0.0, 1.0, 0.4), true)
	(glass.material_override as StandardMaterial3D).transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_add_box(root, Vector3(1.0, 0.0, -2.0), Color.WHITE, false)
	_add_box(root, Vector3(3.0, 0.0, -2.0), Color.BLACK, false)
	_add_box(root, Vector3(2.0, 0.0, -3.5), Color(0.5, 0.5, 0.5), false)
	_add_box(root, Vector3(1.0, 0.0, 2.0), Color.BLUE, false)
	_add_box(root, Vector3(3.0, 0.0, 2.0), Color.GREEN, false)
	var region := _boundary(Vector2(4.0, 10.0))
	region.position.x = 2.0
	root.add_child(region)
	var camera := Camera3D.new()
	root.add_child(camera)
	camera.position = Vector3(0.0, 8.0, 8.0)
	camera.look_at(Vector3.ZERO)
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 8.0
	camera.current = true
	for _frame in 12:
		await tree.process_frame
		await RenderingServer.frame_post_draw
	var pixels := viewport.get_texture().get_image()
	var left := _sample(pixels, camera, Vector3(-0.3, 0.5, 0.0))
	var right := _sample(pixels, camera, Vector3(0.3, 0.5, 0.0))
	var concealed := _sample(pixels, camera, Vector3(2.0, 0.5, 0.0))
	var translucent := _sample(pixels, camera, Vector3(-2.0, 0.5, 2.0))
	var exposed := _sample(pixels, camera, Vector3(-2.0, 0.5, 0.0))
	expect(left.r > 0.8 and left.g < 0.2, "The coloured half of one model retains its red material.")
	expect(right.r > right.g + 0.3 and right.g > 0.1, "The aged half keeps its red hue with visibly faded contrast.")
	expect(
		concealed.g > concealed.r + 0.2 and concealed.g > concealed.b + 0.2,
		"Hidden geometry reveals the green scenery in aged colour, without black holes."
	)
	expect(exposed.b > 0.8 and exposed.r < 0.2, "The threat outside sepia remains blue and visible.")
	expect(
		translucent.b > 0.3 and translucent.g > 0.3,
		"Transparent exposed materials keep blending rather than turning into cutouts."
	)
	var paper := _sample_swatch(pixels, camera, Vector3(1.0, 0.5, -2.0))
	var ink := _sample_swatch(pixels, camera, Vector3(3.0, 0.5, -2.0))
	var midtone := _sample_swatch(pixels, camera, Vector3(2.0, 0.5, -3.5))
	expect(
		paper.r > paper.b and paper.r - paper.b < 0.15,
		"Neutral highlights receive a gentle paper cast while staying close to white."
	)
	expect(
		absf(midtone.r - midtone.b) < 0.1,
		"Neutral midtones stay nearly neutral rather than being converted to photographic brown."
	)
	expect(
		ink.r >= 0.1 and ink.r < 0.25 and absf(ink.r - ink.b) < 0.08,
		"Black surfaces lift to a faded, almost neutral print black."
	)
	expect(paper.r > midtone.r and midtone.r > ink.r, "The photograph keeps the source's light-to-dark ordering.")
	var blue := _sample_swatch(pixels, camera, Vector3(1.0, 0.5, 2.0))
	var green := _sample_swatch(pixels, camera, Vector3(3.0, 0.5, 2.0))
	expect(
		blue.b > blue.r + 0.25 and blue.b > blue.g + 0.25, "Blue material remains clearly blue in the aged photograph."
	)
	expect(
		green.g > green.r + 0.25 and green.g > green.b + 0.25,
		"Green material remains clearly green in the aged photograph."
	)
	await _test_print_stability(tree, viewport, region, camera)
	region.sepia_inverted = true
	for _frame in 4:
		await tree.process_frame
		await RenderingServer.frame_post_draw
	pixels = viewport.get_texture().get_image()
	left = _sample(pixels, camera, Vector3(-0.3, 0.5, 0.0))
	right = _sample(pixels, camera, Vector3(0.3, 0.5, 0.0))
	var inside_threat := _sample(pixels, camera, Vector3(2.0, 0.5, 0.0))
	var outside_threat := _sample(pixels, camera, Vector3(-2.0, 0.5, 0.0))
	expect(
		left.g > 0.1 and right.r > 0.8 and right.g < 0.2,
		"Inversion swaps both halves of the crossing model without moving geometry."
	)
	expect(
		inside_threat.b > 0.8 and inside_threat.r < 0.2, "An inverted boundary shows threats in its coloured interior."
	)
	expect(
		outside_threat.g > outside_threat.r + 0.2 and outside_threat.g > outside_threat.b + 0.2,
		"An inverted boundary conceals exterior threats and reveals aged-colour scenery."
	)
	_add_box(root, Vector3(-3.0, 0.0, 0.0), Color.BLUE, true)
	for _frame in 4:
		await tree.process_frame
		await RenderingServer.frame_post_draw
	pixels = viewport.get_texture().get_image()
	var late := _sample(pixels, camera, Vector3(-3.0, 0.5, 0.0))
	expect(late.r > late.b, "Late-spawned threats receive the cached inverted mask.")
	region.sepia_inverted = false
	region.position.x = -2.0
	for _frame in 3:
		await tree.process_frame
		await RenderingServer.frame_post_draw
	pixels = viewport.get_texture().get_image()
	left = _sample(pixels, camera, Vector3(-0.3, 0.5, 0.0))
	right = _sample(pixels, camera, Vector3(0.3, 0.5, 0.0))
	expect(
		left.r > left.g and left.g > left.b and right.g < 0.2,
		"Moving the kill boundary moves its enclosed sepia half, leaving the new exterior coloured."
	)
	viewport.free()
	await tree.process_frame


# Flow: With no depth, the camera ray meets each actual boundary's height to identify the photo side.
func _test_background(tree: SceneTree) -> void:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(512, 512)
	viewport.own_world_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	tree.root.add_child(viewport)
	var root := Node3D.new()
	viewport.add_child(root)
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_COLOR
	environment.environment.background_color = Color.BLACK
	root.add_child(environment)
	_add_box(root, Vector3.ZERO, Color.BLACK, false)
	var region := _boundary(Vector2(6.0, 6.0))
	root.add_child(region)
	var camera := Camera3D.new()
	root.add_child(camera)
	camera.current = true
	camera.size = 12.0
	camera.fov = 60.0
	var projections: Array[Camera3D.ProjectionType] = [Camera3D.PROJECTION_PERSPECTIVE, Camera3D.PROJECTION_ORTHOGONAL]
	for projection in projections:
		camera.projection = projection
		camera.position = Vector3(0.0, 8.0, 8.0)
		camera.look_at(Vector3.ZERO)
		region.position = Vector3.ZERO
		region.bounds_size = Vector2(6.0, 6.0)
		region.sepia_inverted = false
		await _draw_frames(tree)
		region.get_node(^"SepiaMode/View/TimeVeil").set_active(false)
		await _draw_frames(tree)
		var pixels := viewport.get_texture().get_image()
		var empty := _sample_swatch(pixels, camera, Vector3(2.0, 0.0, 0.0))
		var solid := _sample_swatch(pixels, camera, Vector3(0.0, 0.5, 0.0))
		var exterior := _sample_swatch(pixels, camera, Vector3(4.0, 0.0, 0.0))
		expect(empty.r > 0.15, "Empty map-edge background on the photo side receives the raised print black point.")
		expect(
			absf(empty.r - solid.r) < 0.08,
			"Empty background and black geometry share the same photographic black point."
		)
		expect(
			exterior.r < 0.02 and exterior.g < 0.02 and exterior.b < 0.02,
			"Empty background outside the photo footprint keeps its original black."
		)
		region.sepia_inverted = true
		await _draw_frames(tree)
		pixels = viewport.get_texture().get_image()
		empty = _sample_swatch(pixels, camera, Vector3(2.0, 0.0, 0.0))
		exterior = _sample_swatch(pixels, camera, Vector3(4.0, 0.0, 0.0))
		expect(
			empty.r < 0.02 and exterior.r > 0.15, "Inversion also swaps the treatment of depthless background pixels."
		)
		region.sepia_inverted = false
		region.position.x = 3.0
		await _draw_frames(tree)
		pixels = viewport.get_texture().get_image()
		var old_side := _sample_swatch(pixels, camera, Vector3(-2.0, 0.0, 0.0))
		var new_side := _sample_swatch(pixels, camera, Vector3(4.0, 0.0, 0.0))
		expect(
			old_side.r < 0.02 and new_side.r > 0.15,
			"Moving the real perimeter moves the photograph over empty map edges."
		)
		camera.position = Vector3(3.0, 10.0, 9.0)
		camera.look_at(Vector3(1.0, 0.0, 0.0))
		region.position.y = 1.5
		await _draw_frames(tree)
		pixels = viewport.get_texture().get_image()
		var raised := _sample_swatch(pixels, camera, Vector3(4.5, 1.5, -2.7))
		expect(
			raised.r > 0.15, "Camera changes and raised boundaries retain the correct projected background footprint."
		)
	region.bounds_size = Vector2(2.0, 2.0)
	region.position = Vector3(-3.0, 0.0, 0.0)
	var elevated := _boundary(Vector2(2.0, 2.0))
	elevated.position = Vector3(3.0, 2.0, 0.0)
	root.add_child(elevated)
	camera.position = Vector3(0.0, 8.0, 8.0)
	camera.look_at(Vector3.ZERO)
	await _draw_frames(tree)
	var union_pixels := viewport.get_texture().get_image()
	var low := _sample_swatch(union_pixels, camera, Vector3(-3.0, 0.0, 0.0))
	var high := _sample_swatch(union_pixels, camera, Vector3(3.0, 2.0, 0.0))
	expect(
		low.r > 0.15 and high.r > 0.15,
		"Different boundaries project depthless pixels at their own independent heights."
	)
	viewport.free()
	await tree.process_frame


func _test_print_stability(tree: SceneTree, viewport: SubViewport, region: GDKillBoundary3D, camera: Camera3D) -> void:
	var view := region.get_node(^"SepiaMode/View")
	view.set_process(false)
	view.veil.set_process(false)
	await _draw_frames(tree)
	var before := viewport.get_texture().get_image()
	var perimeter := region.get_boundary_world_points()
	await _draw_frames(tree)
	await _draw_frames(tree)
	var after := viewport.get_texture().get_image()
	expect_equal(
		_patch_changes(before, after, camera, Vector3(2.0, 0.5, -3.5)),
		0,
		"The print stays steady over time, with no moving scratches or exposure flicker."
	)
	expect_equal(
		_patch_changes(before, after, camera, Vector3(-0.3, 0.5, 0.0)),
		0,
		"The original coloured half also remains steady."
	)
	expect_equal(
		region.get_boundary_world_points(), perimeter, "The photographic grade cannot move the boundary geometry."
	)
	var default_ink := _sample_swatch(after, camera, Vector3(3.0, 0.5, -2.0))
	var default_strength: float = view._composite_material.get_shader_parameter(&"photo_strength")
	view._composite_material.set_shader_parameter(&"photo_strength", 1.0)
	await _draw_frames(tree)
	var full := viewport.get_texture().get_image()
	var full_ink := _sample_swatch(full, camera, Vector3(3.0, 0.5, -2.0))
	expect(
		default_ink.r < full_ink.r - 0.025,
		"The restrained default restores deeper blacks than the full-strength print."
	)
	view._composite_material.set_shader_parameter(&"photo_strength", 0.0)
	await _draw_frames(tree)
	var clear := viewport.get_texture().get_image()
	var left := _sample(clear, camera, Vector3(-0.3, 0.5, 0.0))
	var right := _sample(clear, camera, Vector3(0.3, 0.5, 0.0))
	expect(
		absf(left.r - right.r) + absf(left.g - right.g) + absf(left.b - right.b) < 0.01,
		"Zero photo strength preserves the source colour exactly across the split model."
	)
	view._composite_material.set_shader_parameter(&"photo_strength", default_strength)
	view.set_process(true)


func _draw_frames(tree: SceneTree) -> void:
	for _frame in 4:
		await tree.process_frame
		await RenderingServer.frame_post_draw


func _patch_changes(before: Image, after: Image, camera: Camera3D, position: Vector3) -> int:
	var point := Vector2i(camera.unproject_position(position))
	var changes := 0
	for y in range(point.y - 6, point.y + 7):
		for x in range(point.x - 6, point.x + 7):
			var a := before.get_pixel(x, y)
			var b := after.get_pixel(x, y)
			if absf(a.r - b.r) + absf(a.g - b.g) + absf(a.b - b.b) > 0.012:
				changes += 1
	return changes


func _add_box(root: Node, position: Vector3, color: Color, threat: bool) -> MeshInstance3D:
	var actor := Node3D.new()
	actor.position = position
	if threat:
		actor.add_to_group(&"enemy")
	var mesh := MeshInstance3D.new()
	mesh.mesh = BoxMesh.new()
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = color
	mesh.material_override = material
	actor.add_child(mesh)
	root.add_child(actor)
	return mesh


# Average the fine paper texture when checking the underlying print grade.
func _sample_swatch(pixels: Image, camera: Camera3D, position: Vector3) -> Color:
	var center := Vector2i(camera.unproject_position(position))
	var color := Color(0.0, 0.0, 0.0, 0.0)
	for y in range(center.y - 3, center.y + 4):
		for x in range(center.x - 3, center.x + 4):
			color += pixels.get_pixel(x, y)
	return color / 49.0


func _sample(pixels: Image, camera: Camera3D, position: Vector3) -> Color:
	var point := Vector2i(camera.unproject_position(position))
	return pixels.get_pixelv(point)


func _boundary(size: Vector2) -> GDKillBoundary3D:
	var boundary := SCENE.instantiate() as GDKillBoundary3D
	boundary.boundary_animation = Animation.new()
	boundary.autoplay_boundary_animation = false
	boundary.bounds_size = size
	boundary.render_effect = boundary.RenderEffect.Sepia
	return boundary
