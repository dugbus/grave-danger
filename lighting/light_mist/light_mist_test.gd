extends "res://tests/test_case.gd"

const SCENE := preload("res://lighting/light_mist/light_mist.tscn")
const MIST := preload("res://lighting/light_mist/light_mist.gd")


func run(tree: SceneTree) -> void:
	var viewport := SubViewport.new()
	viewport.own_world_3d = true
	tree.root.add_child(viewport)
	var environment := WorldEnvironment.new()
	var original := Environment.new()
	original.tonemap_exposure = 1.4
	original.glow_enabled = true
	environment.environment = original
	viewport.add_child(environment)
	var other_level := WorldEnvironment.new()
	other_level.environment = original
	var mist := SCENE.instantiate() as MIST
	mist.settings = mist.settings.duplicate() as MIST.SETTINGS_TYPE
	viewport.add_child(mist)
	mist.configure_environment(environment)
	expect(not mist.visible and not mist.is_processing(), "The authored mist component starts inactive.")
	mist.set_enabled(true)
	mist.set_process(false)
	expect(environment.environment != original, "Enabling mist creates an instance-local environment.")
	expect(environment.environment.volumetric_fog_enabled, "The native volumetric pass is enabled for this level.")
	expect(
		not original.volumetric_fog_enabled and other_level.environment == original,
		"Another level sharing the original environment remains unaffected."
	)
	expect_equal(environment.environment.tonemap_exposure, original.tonemap_exposure, "Existing exposure is preserved.")
	expect(environment.environment.glow_enabled, "Existing light bloom is retained.")
	expect_equal(
		environment.environment.volumetric_fog_density, 0.0, "Density comes from 3D noise, with no flat base layer."
	)
	expect_equal(environment.environment.volumetric_fog_emission_energy, 0.0, "The air has no self illumination.")
	expect_equal(
		environment.environment.volumetric_fog_ambient_inject, 0.0, "Ambient injection cannot wash out the dark rooms."
	)
	expect_equal(mist.shape, RenderingServer.FOG_VOLUME_SHAPE_WORLD, "The mist spans both sides of every boundary.")
	var active_environment := environment.environment
	mist.settings.fog_length = 24.0
	mist.settings.temporal_blend = 0.0
	expect_equal(active_environment.volumetric_fog_length, 24.0, "Runtime settings edits refresh the active fog range.")
	expect(
		not active_environment.volumetric_fog_temporal_reprojection_enabled,
		"A live temporal-blend edit immediately disables reprojection."
	)
	expect(environment.environment == active_environment, "Live tuning reuses the existing environment instance.")
	var old_settings := mist.settings
	var new_settings := old_settings.duplicate() as MIST.SETTINGS_TYPE
	new_settings.fog_length = 20.0
	mist.settings = new_settings
	expect_equal(active_environment.volumetric_fog_length, 20.0, "Replacing settings updates the active instance.")
	old_settings.fog_length = 48.0
	expect_equal(
		active_environment.volumetric_fog_length, 20.0, "Replaced settings are disconnected from the active mist."
	)
	if DisplayServer.get_name() != "headless":
		mist.settings.density = 0.01
		mist.settings.noise_strength = 0.5
		expect_equal(
			mist._mist_material.get_shader_parameter(&"density"),
			0.01,
			"A runtime density edit reaches the shader immediately without toggling the mist."
		)
		expect_equal(
			mist._mist_material.get_shader_parameter(&"noise_strength"), 0.5, "Noise settings also refresh immediately."
		)
	var before := mist.visual_time
	mist.advance_visual(0.5)
	expect(is_equal_approx(mist.visual_time, before + 0.5), "Noise drift uses its own presentation clock.")
	mist.set_enabled(false)
	mist.advance_visual(1.0)
	expect(
		is_equal_approx(mist.visual_time, before + 0.5) and not mist.visible,
		"Disabled mist stops drifting and drawing."
	)
	expect(environment.environment == original, "Disabling mist restores the exact authored environment.")
	mist.set_enabled(true)
	var replacement := Environment.new()
	environment.environment = replacement
	mist.set_enabled(false)
	expect(environment.environment == replacement, "Cleanup preserves an environment replaced by another owner.")
	mist.set_enabled(true)
	mist.queue_free()
	await tree.process_frame
	expect(environment.environment == replacement, "Removing the mist node restores its environment before freeing.")
	other_level.free()
	viewport.free()
	await tree.process_frame
	if DisplayServer.get_name() != "headless":
		await _test_render(tree)


func _test_render(tree: SceneTree) -> void:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(256, 256)
	viewport.own_world_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	tree.root.add_child(viewport)
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_COLOR
	environment.environment.background_color = Color.BLACK
	viewport.add_child(environment)
	var camera := Camera3D.new()
	viewport.add_child(camera)
	camera.position = Vector3(0.0, 2.0, 8.0)
	camera.look_at(Vector3(0.0, 1.0, 0.0))
	camera.current = true
	var lamp := SpotLight3D.new()
	lamp.light_color = Color(1.0, 0.65, 0.35)
	lamp.light_energy = 16.0
	lamp.spot_range = 8.0
	lamp.spot_angle = 30.0
	viewport.add_child(lamp)
	lamp.position = Vector3(-3.0, 1.0, 0.0)
	lamp.look_at(Vector3(3.0, 1.0, 0.0))
	var mist := SCENE.instantiate() as MIST
	mist.settings = mist.settings.duplicate() as MIST.SETTINGS_TYPE
	mist.settings.temporal_blend = 0.0
	viewport.add_child(mist)
	mist.configure_environment(environment)
	await _draw_frames(tree)
	var clear := viewport.get_texture().get_image()
	mist.set_enabled(true)
	mist.set_process(false)
	await _draw_frames(tree)
	var lit := viewport.get_texture().get_image()
	expect(
		_pixel_changes(clear, lit) > 100, "An actual light becomes visible in empty air through volumetric scattering."
	)
	var original_density := mist.settings.density
	mist.settings.density = original_density * 2.0
	await _draw_frames(tree)
	var denser := viewport.get_texture().get_image()
	expect(_pixel_changes(lit, denser) > 100, "Editing runtime density visibly changes the lit air without restarting.")
	mist.settings.density = original_density
	await _draw_frames(tree)
	mist.advance_visual(75.0)
	await _draw_frames(tree)
	var drifted := viewport.get_texture().get_image()
	expect(_pixel_changes(lit, drifted) > 20, "The lit mist changes as the three-dimensional density field drifts.")
	camera.position.y += 4.0
	lamp.position.y += 4.0
	await _draw_frames(tree)
	var raised := viewport.get_texture().get_image()
	expect(
		_pixel_changes(drifted, raised) > 20,
		"Identical light and camera framing samples different noise at a different world height."
	)
	mist.set_process(true)
	var before := mist.visual_time
	var was_paused := tree.paused
	tree.paused = true
	await _draw_frames(tree)
	expect_equal(mist.visual_time, before, "Scene pause freezes atmospheric drift.")
	tree.paused = was_paused
	mist.set_process(false)
	lamp.visible = false
	await _draw_frames(tree)
	var dark := viewport.get_texture().get_image()
	expect(_pixel_changes(clear, dark) < 10, "Without a light the fog does not brighten empty, unlit air.")
	viewport.free()
	await tree.process_frame


func _draw_frames(tree: SceneTree) -> void:
	for _frame in 8:
		await tree.process_frame
		await RenderingServer.frame_post_draw


func _pixel_changes(first: Image, second: Image) -> int:
	var changed := 0
	for y in first.get_height():
		for x in first.get_width():
			var a := first.get_pixel(x, y)
			var b := second.get_pixel(x, y)
			if absf(a.r - b.r) + absf(a.g - b.g) + absf(a.b - b.b) > 0.006:
				changed += 1
	return changed
