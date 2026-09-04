extends "res://tests/test_case.gd"

const SUBJECT := preload("res://ui/frontend/frontend_screen.gd")
const SUBJECT_PATH := "res://ui/frontend/frontend_screen.gd"


func run(tree: SceneTree) -> void:
	expect_script_contract(SUBJECT, SUBJECT_PATH)
	_expect_project_viewport_stretch()
	await _expect_root_window_uses_project_stretch(tree)
	await _expect_subviewport_layout_tracks_viewport_size(tree)
	await _expect_embedded_layout_uses_local_size(tree)


func _expect_project_viewport_stretch() -> void:
	expect_equal(
		ProjectSettings.get_setting("display/window/stretch/mode", ""),
		"canvas_items",
		"Frontend screens use Godot's root canvas scaling."
	)
	expect_equal(
		ProjectSettings.get_setting("display/window/stretch/aspect", ""),
		"keep",
		"Frontend screens preserve the 16:9 design aspect with letterboxing."
	)


func _expect_root_window_uses_project_stretch(tree: SceneTree) -> void:
	var screen := _create_screen(Vector2(320.0, 180.0))
	var screen_container := screen.get_node(^"ScreenContainer") as Control
	tree.root.add_child(screen)
	await tree.process_frame
	screen._sync_screen_container()

	expect(
		screen_container.scale.is_equal_approx(Vector2.ONE)
			and screen_container.position.is_equal_approx(Vector2.ZERO)
			and screen_container.size.is_equal_approx(Vector2(1920.0, 1080.0)),
		"A root-window frontend leaves whole-screen scaling to Godot's project stretch."
	)
	screen.queue_free()
	await tree.process_frame


func _expect_subviewport_layout_tracks_viewport_size(tree: SceneTree) -> void:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(1280, 720)
	var screen := _create_screen(Vector2(320.0, 180.0))
	var screen_container := screen.get_node(^"ScreenContainer") as Control
	viewport.add_child(screen)
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	tree.root.add_child(viewport)
	await tree.process_frame
	await tree.process_frame

	expect(
		screen_container.scale.is_equal_approx(Vector2(2.0 / 3.0, 2.0 / 3.0))
			and screen_container.position.is_equal_approx(Vector2.ZERO),
		"A SubViewport screen settles to the viewport size on its deferred layout pass."
	)

	# Screenshot scenes can expose a pre-layout local size. The SubViewport remains
	# the authoritative scale source for these embedded resolution tests.
	screen.size = Vector2(320.0, 180.0)
	screen._sync_screen_container()
	expect(
		screen_container.scale.is_equal_approx(Vector2(2.0 / 3.0, 2.0 / 3.0))
			and screen_container.position.is_equal_approx(Vector2.ZERO),
		"A SubViewport screen ignores a stale pre-layout root size."
	)
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	viewport.size = Vector2i(2560, 1080)
	await tree.process_frame
	await tree.process_frame
	expect(
		screen_container.scale.is_equal_approx(Vector2.ONE)
			and screen_container.position.is_equal_approx(Vector2(320.0, 0.0)),
		"A SubViewport screen relays out after its viewport size changes."
	)
	viewport.queue_free()
	await tree.process_frame


func _expect_embedded_layout_uses_local_size(tree: SceneTree) -> void:
	var preview_host := Control.new()
	var screen := _create_screen(Vector2(960.0, 540.0))
	var screen_container := screen.get_node(^"ScreenContainer") as Control
	preview_host.add_child(screen)
	tree.root.add_child(preview_host)
	await tree.process_frame
	screen._sync_screen_container()

	expect(
		screen_container.scale.is_equal_approx(Vector2(0.5, 0.5))
			and screen_container.position.is_equal_approx(Vector2.ZERO),
		"An embedded frontend gallery preview continues to use its local card size."
	)
	preview_host.queue_free()
	await tree.process_frame


func _create_screen(screen_size: Vector2) -> GDFrontendScreen:
	var screen := SUBJECT.new() as GDFrontendScreen
	screen.size = screen_size
	var screen_container := Control.new()
	screen_container.name = "ScreenContainer"
	screen_container.size = Vector2(1920.0, 1080.0)
	screen.add_child(screen_container)
	return screen
