extends "res://tests/test_case.gd"

const SUBJECT := preload("res://placeables/text_trigger/text_trigger.gd")
const SUBJECT_PATH := "res://placeables/text_trigger/text_trigger.gd"
const SCENE := preload("res://placeables/text_trigger/text_trigger.tscn")
const BOUNDARY := preload("res://placeables/kill_boundary/kill_boundary.tscn")


func run(tree: SceneTree) -> void:
	expect_script_contract(SUBJECT, SUBJECT_PATH)
	if DisplayServer.get_name() != "headless":
		await _test_photo_overlay(tree, false, false)
		await _test_photo_overlay(tree, true, false)
		await _test_photo_overlay(tree, false, true)


# Flow: Exercise the actual lit TextMesh and its dimmer against the real photo compositor.
func _test_photo_overlay(tree: SceneTree, pauses: bool, enemy_child: bool) -> void:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(512, 320)
	viewport.own_world_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	tree.root.add_child(viewport)
	var root := Node3D.new()
	viewport.add_child(root)
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_COLOR
	environment.environment.background_color = Color(0.02, 0.04, 0.08)
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_energy = 0.0
	root.add_child(environment)
	var camera := Camera3D.new()
	root.add_child(camera)
	camera.position = Vector3(0.0, 6.0, 8.0)
	camera.look_at(Vector3.ZERO)
	camera.current = true
	var boundary := BOUNDARY.instantiate() as GDKillBoundary3D
	boundary.boundary_animation = Animation.new()
	boundary.autoplay_boundary_animation = false
	boundary.bounds_size = Vector2(100.0, 100.0)
	boundary.render_effect = GDKillBoundary3D.RenderEffect.Sepia
	root.add_child(boundary)
	await _draw_frames(tree)
	var view := boundary.get_node(^"SepiaMode/View")
	view.set_process(false)
	view.veil.set_active(false)
	view.composite.visible = false
	var parent := root
	if enemy_child:
		parent = Node3D.new()
		parent.add_to_group(&"enemy")
		root.add_child(parent)
	var trigger := SCENE.instantiate() as GDTextTrigger
	trigger.heading = "READ THIS"
	trigger.text = "Keep the message clear."
	trigger.camera_distance = 4.0
	trigger.viewport_y_offset = 0.0
	trigger.text_opacity = 1.0
	trigger.light_sweep_speed = 0.0
	trigger.pause_game_with_text = pauses
	parent.add_child(trigger)
	await _draw_frames(tree)
	var empty := viewport.get_texture().get_image()
	trigger._show_text()
	trigger._process(0.25)
	trigger.set_process(false)
	if pauses:
		# The native Continue button is CanvasLayer UI; compare the 3D text without covering its pixels.
		trigger.pause_layer.visible = false
	await _draw_frames(tree)
	var baseline := viewport.get_texture().get_image()
	expect(
		trigger.heading_text_mesh_instance.material_override == trigger.heading_text_material,
		"Screen heading material is never adapted as an enemy's concealed world geometry."
	)
	expect(trigger.text_light not in view._lights, "The dedicated text light is independent of concealed enemy lights.")
	var mask := _glyph_pixels(empty, baseline)
	expect(mask.size() > 100, "The real trigger displays visible heading and body glyphs before world grading.")
	view.composite.visible = true
	await _draw_frames(tree)
	var graded := viewport.get_texture().get_image()
	var same := 0
	for pixel in mask:
		if _difference(baseline.get_pixelv(pixel), graded.get_pixelv(pixel)) < 0.015:
			same += 1
	expect(
		same > mask.size() * 0.95,
		"The photo pass preserves the rendered text's colour, shape and light shading, including while paused."
	)
	expect(
		_difference(empty.get_pixel(8, 310), graded.get_pixel(8, 310)) > 0.03,
		"World/background grading remains visible behind the text."
	)
	if pauses:
		trigger.heading_text_mesh_instance.visible = false
		trigger.body_text_mesh_instance.visible = false
		trigger.dim_overlay_mesh_instance.visible = false
		await _draw_frames(tree)
		var undimmed := viewport.get_texture().get_image()
		trigger.dim_overlay_mesh_instance.visible = true
		await _draw_frames(tree)
		var dimmed := viewport.get_texture().get_image()
		expect(
			dimmed.get_pixel(8, 310).r < undimmed.get_pixel(8, 310).r * 0.85,
			"The paused message dims the already-graded world rather than being overwritten by the photo."
		)
	trigger._hide_text()
	if enemy_child:
		await _test_flask_overlay(tree, viewport, parent, view)
	viewport.free()
	await tree.process_frame


func _test_flask_overlay(tree: SceneTree, viewport: SubViewport, parent: Node3D, view: Node) -> void:
	view.composite.visible = false
	await _draw_frames(tree)
	var empty := viewport.get_texture().get_image()
	var flask := GDFlaskEffectText.new()
	flask.camera_distance = 4.0
	flask.viewport_y_offset = 0.0
	flask.text_opacity = 1.0
	flask.light_sweep_speed = 0.0
	parent.add_child(flask)
	flask.show_flask_effect(&"health_flask", Color(0.2, 0.65, 1.0), 20.0)
	flask._process(0.4)
	flask.set_process(false)
	await _draw_frames(tree)
	var baseline := viewport.get_texture().get_image()
	var mask := _glyph_pixels(empty, baseline)
	expect(mask.size() > 100, "A late flask message remains visible under a concealed actor parent.")
	expect(flask.material_override == flask.text_material, "Flask text keeps its own HUD material.")
	expect(flask.text_light not in view._lights, "Flask illumination is independent of concealed actor lights.")
	view.composite.visible = true
	await _draw_frames(tree)
	var graded := viewport.get_texture().get_image()
	var same := 0
	for pixel in mask:
		if _difference(baseline.get_pixelv(pixel), graded.get_pixelv(pixel)) < 0.015:
			same += 1
	expect(same > mask.size() * 0.95, "The photo compositor also preserves the shared flask message renderer.")


func _draw_frames(tree: SceneTree) -> void:
	for _frame in 6:
		await tree.process_frame
		await RenderingServer.frame_post_draw


func _glyph_pixels(empty: Image, with_text: Image) -> Array[Vector2i]:
	var pixels: Array[Vector2i] = []
	for y in range(75, 245):
		for x in range(30, 482):
			var color := with_text.get_pixel(x, y)
			if color.r > 0.3 and _difference(empty.get_pixel(x, y), color) > 0.2:
				pixels.append(Vector2i(x, y))
	return pixels


func _difference(first: Color, second: Color) -> float:
	return absf(first.r - second.r) + absf(first.g - second.g) + absf(first.b - second.b)
