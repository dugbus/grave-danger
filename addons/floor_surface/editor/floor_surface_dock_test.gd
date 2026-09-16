extends "res://tests/test_case.gd"

const SUBJECT := preload("res://addons/floor_surface/editor/floor_surface_dock.gd")
const FLOOR_MAP_SCRIPT := preload("res://addons/floor_surface/floor_map.gd")
const STYLE_SCRIPT := preload("res://addons/floor_surface/floor_style.gd")
const DOCK_SCENE := preload("res://addons/floor_surface/editor/floor_surface_dock.tscn")


func run(tree: SceneTree) -> void:
	expect_script_contract(SUBJECT, "res://addons/floor_surface/editor/floor_surface_dock.gd")
	_test_ownership_guidance()
	await _test_scene_controls(tree)
	await _test_short_dock_scrolling(tree)
	await _test_stable_readout_layout(tree)


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
	expect_equal(dock.get_edit_mode(), SUBJECT.EditMode.FloorShape, "Floor Shape is the default edit mode.")
	expect_equal(dock.get_shape_mode(), SUBJECT.SHAPE_PAINTER.ShapeMode.Brush, "Brush is the default shape.")
	expect_equal(dock.get_brush_size(), 1, "The default brush affects one cell.")
	expect(not dock.is_grid_overlay_visible(), "The optional grid guide is off by default.")
	dock.rectangle_button.button_pressed = true
	dock._on_shape_mode_selected(SUBJECT.SHAPE_PAINTER.ShapeMode.Rectangle)
	expect_equal(
		dock.get_shape_mode(),
		SUBJECT.SHAPE_PAINTER.ShapeMode.Rectangle,
		"The explicit Rectangle button selects rectangle painting."
	)
	dock.fill_button.button_pressed = true
	dock._on_shape_mode_selected(SUBJECT.SHAPE_PAINTER.ShapeMode.Fill)
	expect_equal(dock.get_shape_mode(), SUBJECT.SHAPE_PAINTER.ShapeMode.Fill, "Fill is an explicit shared painting shape.")
	expect(not dock.brush_size_option.visible, "Fill hides the unrelated brush-size control.")
	expect(
		dock.fill_button.tooltip_text.contains("always bounded"),
		"Fill hover help documents safety and matching rules without a paragraph."
	)
	dock.set_target(null, null)
	expect(not dock.is_editing_enabled(), "Painting cannot arm without a valid target.")
	dock.set_elevation_unit(0.25)
	dock.absolute_elevation.value = 24
	expect_equal(dock.elevation_readout.text, "Elevation 24 — 6.00 m", "Absolute entry shows units and metres.")
	dock.elevation_button.button_pressed = true
	dock._on_edit_mode_selected(SUBJECT.EditMode.Elevation)
	expect(dock.elevation_controls.visible, "Elevation has a direct, visible edit mode.")
	dock.sample_elevation_button.button_pressed = true
	expect_equal(
		dock.get_elevation_operation(),
		dock.ELEVATION_PAINTER.Operation.Sample,
		"Sampling is an explicit elevation operation."
	)
	dock.set_sampled_elevation(-3)
	expect_equal(dock.get_absolute_elevation(), -3, "Cursor sampling updates the absolute entry.")
	var teal_style := STYLE_SCRIPT.new()
	teal_style.display_name = "Teal"
	var stone_style := STYLE_SCRIPT.new()
	stone_style.display_name = "Stone"
	var styles: Array[STYLE_SCRIPT] = [teal_style, stone_style]
	dock.set_styles(styles)
	var target := Node.new()
	dock.set_target(target, FLOOR_MAP_SCRIPT.new())
	expect(not dock.conform_grounded_button.disabled, "A selected surface enables explicit grounding conform.")
	expect(not dock.validate_button.disabled, "A selected surface enables visible validation.")
	expect(not dock.grid_overlay_toggle.disabled, "A selected surface enables the grid guide toggle.")
	var grid_toggle_events: Array[bool] = []
	dock.grid_overlay_toggled.connect(
		func(visible: bool) -> void: grid_toggle_events.append(visible)
	)
	dock.grid_overlay_toggle.button_pressed = true
	expect(dock.is_grid_overlay_visible(), "The grid guide can be explicitly enabled.")
	expect_equal(grid_toggle_events, [true] as Array[bool], "The checkbox refreshes the editor grid immediately.")
	dock.style_button.button_pressed = true
	dock._on_edit_mode_selected(SUBJECT.EditMode.Style)
	expect(dock.style_controls.visible, "Style has a direct, visible edit mode.")
	expect_equal(dock.style_option.item_count, 2, "The palette exposes both reusable style names.")
	expect(
		dock.style_option.tooltip_text.contains("Inspector"),
		"Style hover help explains where appearance and depth are configured."
	)
	dock.style_option.select(1)
	expect_equal(dock.get_style_index(), 1, "Style selection returns the stable palette index.")
	dock.sample_style_button.button_pressed = true
	expect_equal(
		dock.get_style_operation(),
		dock.STYLE_PAINTER.Operation.Sample,
		"Style sampling is an explicit operation."
	)
	dock.set_sampled_style(0)
	expect_equal(dock.get_style_index(), 0, "Cursor sampling updates the style selector.")
	dock.transition_button.button_pressed = true
	dock._on_edit_mode_selected(SUBJECT.EditMode.Transition)
	expect(dock.transition_controls.visible, "Ramp authoring has a direct, visible edit mode.")
	expect(not dock.shape_buttons.visible, "Ramp boundary drags hide unrelated brush and rectangle controls.")
	expect(
		dock.paint_ramp_button.tooltip_text.contains(
			"flat high landing"
		),
		"Ramp hover help identifies both drag endpoints as retained flat landings."
	)
	expect_equal(
		dock.get_transition_operation(),
		dock.TRANSITION_PAINTER.Operation.PaintRamp,
		"Painting an inferred ramp is the default transition operation."
	)
	dock.rotate_ramp_button.button_pressed = true
	expect_equal(
		dock.get_transition_operation(),
		dock.TRANSITION_PAINTER.Operation.RotateRamp,
		"An existing ramp has an explicit orientation correction control."
	)
	dock.set_transition_hover(Vector2i.ONE, "Ramp", "West", "")
	expect(dock.hover_label.text.contains("low edge West"), "Ramp hover names its inferred low edge.")
	dock.set_transition_hover(Vector2i.ONE, "Ramp", "West", "Needs a high landing.")
	expect(
		not dock.hover_label.text.contains("Needs a high landing"),
		"Live validation details do not resize the dock or viewport while painting."
	)
	target.free()
	dock.queue_free()
	await tree.process_frame


func _test_short_dock_scrolling(tree: SceneTree) -> void:
	var dock := DOCK_SCENE.instantiate() as SUBJECT
	dock.size = Vector2(360, 240)
	tree.root.add_child(dock)
	dock.setup()
	for frame in 4:
		await tree.process_frame
	var scroll := dock as ScrollContainer
	var scrollbar := scroll.get_v_scroll_bar()
	expect(scrollbar.visible, "A short dock shows a vertical scrollbar for overflowing controls.")
	expect(dock.size.y <= 240.0, "The dock fits the available height instead of expanding to its content.")
	expect(
		dock.status_label.get_global_rect().position.y >= scroll.get_global_rect().end.y,
		"The bottom status initially lies below the short dock viewport."
	)
	scroll.ensure_control_visible(dock.status_label)
	await tree.process_frame
	expect(scroll.scroll_vertical > 0, "Scrolling moves the overflowing dock content.")
	expect(
		dock.status_label.get_global_rect().end.y <= scroll.get_global_rect().end.y,
		"Scrolling makes the bottom status reachable within the dock."
	)
	dock.queue_free()
	await tree.process_frame


func _test_stable_readout_layout(tree: SceneTree) -> void:
	var dock := DOCK_SCENE.instantiate() as SUBJECT
	var host := VBoxContainer.new()
	host.size = Vector2(360, 240)
	host.add_child(dock)
	tree.root.add_child(host)
	dock.setup()
	var short_style := STYLE_SCRIPT.new()
	short_style.display_name = "Stone"
	dock.set_styles([short_style] as Array[STYLE_SCRIPT])
	dock.style_button.button_pressed = true
	dock._on_edit_mode_selected(SUBJECT.EditMode.Style)
	for frame in 4:
		await tree.process_frame
	var content := dock.get_node("Content") as VBoxContainer
	var initial_minimum := dock.get_combined_minimum_size()
	var initial_content_height := content.size.y
	var detailed_message := "A lengthy authoring report with detailed cell coordinates. ".repeat(20)
	dock.set_status(detailed_message)
	dock.set_diagnostics(detailed_message + "\nSecond diagnostic line.")
	dock.set_style_hover(Vector2i(10000, -10000), 999, detailed_message)
	var long_style := STYLE_SCRIPT.new()
	long_style.display_name = detailed_message
	dock.set_styles([long_style] as Array[STYLE_SCRIPT])
	var target := Node.new()
	target.name = detailed_message.replace(".", "")
	dock.set_target(target, FLOOR_MAP_SCRIPT.new())
	for frame in 4:
		await tree.process_frame
	expect_equal(
		dock.get_combined_minimum_size(), initial_minimum,
		"Long live text cannot change the dock minimum width or height."
	)
	expect_equal(content.size.y, initial_content_height, "Long feedback cannot grow the control rows.")
	expect(dock.size.y <= host.size.y, "The dock fits an editor-like container at limited height.")
	expect(dock.get_v_scroll_bar().visible, "The dock keeps a visible vertical scrollbar in its host.")
	expect_equal(dock.status_label.tooltip_text, detailed_message, "Status hover retains the full report.")
	expect(
		dock.diagnostics_label.tooltip_text.contains("\nSecond diagnostic line."),
		"Diagnostic hover retains multiline detail without changing dock height."
	)
	expect(
		dock.edit_toggle.tooltip_text.contains("Esc") \
			and dock.edit_toggle.tooltip_text.contains("Middle/right"),
		"Painting hover help retains cancellation and navigation instructions."
	)
	expect(dock.ownership_label.tooltip_text.contains("saved with this scene"), "Ownership help stays on hover.")
	expect(
		dock.find_children("*Guidance", "Label", true, false).is_empty() \
			and dock.find_child("Instructions", true, false) == null,
		"Instruction paragraphs no longer consume dock space."
	)
	target.free()
	host.queue_free()
	await tree.process_frame
