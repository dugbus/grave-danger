extends "res://tests/test_case.gd"

const SUBJECT := preload("res://addons/floor_surface/editor/floor_surface_dock.gd")
const FLOOR_MAP_SCRIPT := preload("res://addons/floor_surface/floor_map.gd")
const DOCK_SCENE := preload("res://addons/floor_surface/editor/floor_surface_dock.tscn")


func run(tree: SceneTree) -> void:
	expect_script_contract(SUBJECT, "res://addons/floor_surface/editor/floor_surface_dock.gd")
	_test_ownership_guidance()
	await _test_scene_controls(tree)


func _test_ownership_guidance() -> void:
	var floor_map := FLOOR_MAP_SCRIPT.new()
	expect(
		SUBJECT.describe_map_ownership(floor_map).begins_with("Independent map"),
		"An unsaved or scene-local map is identified as independent."
	)
	floor_map.resource_local_to_scene = true
	expect(
		SUBJECT.describe_map_ownership(floor_map).contains("stored in and saved with this scene"),
		"An independent map explains how it is persisted."
	)
	expect_equal(
		SUBJECT.describe_map_ownership(null),
		"No editable FloorMap selected.",
		"A missing target has actionable ownership guidance."
	)


func _test_scene_controls(tree: SceneTree) -> void:
	var dock := DOCK_SCENE.instantiate() as SUBJECT
	tree.root.add_child(dock)
	dock.setup()
	expect_equal(dock.get_paint_mode(), SUBJECT.SHAPE_PAINTER.PaintMode.Paint, "Paint is the default operation.")
	expect_equal(dock.get_shape_mode(), SUBJECT.SHAPE_PAINTER.ShapeMode.Brush, "Brush is the default shape.")
	expect_equal(dock.get_brush_size(), 1, "The default brush affects one cell.")
	dock.rectangle_button.button_pressed = true
	dock._on_shape_mode_selected(SUBJECT.SHAPE_PAINTER.ShapeMode.Rectangle)
	expect_equal(
		dock.get_shape_mode(),
		SUBJECT.SHAPE_PAINTER.ShapeMode.Rectangle,
		"The explicit Rectangle button selects rectangle painting."
	)
	dock.set_target(null, null)
	expect(not dock.is_editing_enabled(), "Painting cannot arm without a valid target.")
	dock.queue_free()
	await tree.process_frame
