extends "res://tests/test_case.gd"

const LEVEL := preload("res://levels/four-towers/level.tscn")
const DOCK := preload("res://addons/floor_surface/editor/floor_surface_dock.tscn")
const ShapePainter := preload("res://addons/floor_surface/editor/floor_surface_shape_painter.gd")
const StylePainter := preload("res://addons/floor_surface/editor/floor_surface_style_painter.gd")
const Picker := preload("res://addons/floor_surface/editor/floor_surface_picker.gd")
const PlacementGrid := preload("res://addons/floor_surface/floor_surface_placement_gridmap.gd")
const Alignment := preload("res://addons/floor_surface/floor_surface_grid_alignment.gd")


func run(tree: SceneTree) -> void:
	var level := LEVEL.instantiate()
	var surface := level.get_node(^"FloorSurface") as FloorSurface
	var grid := level.get_node(^"PlacementGridMap") as PlacementGrid
	expect(grid != null, "Four Towers uses floor-aware native GridMap painting.")
	expect(
		grid.follow_floor and grid.get_node(grid.floor_surface_path) == surface,
		"GridMap strokes sample this level's own FloorSurface by default."
	)
	expect(is_equal_approx(grid.cell_size.y, 0.01), "The brush can represent slope heights to centimetre precision.")
	expect(Alignment.is_aligned(surface, grid), "The editable floor and placement grid share horizontal coordinates.")
	var authored_map := surface.floor_map
	var authored_shape := authored_map.get_shape_snapshot()
	var authored_elevations := authored_map.get_elevation_snapshot()
	# The editor's level is free to gain slopes, holes, and new bounds. Exercise
	# brush behavior on a scratch map instead of enforcing the template's starting layout.
	surface.floor_map = FloorMap.new()
	surface.floor_map.dimensions = Vector2i(32, 32)
	surface.floor_map.default_present = true
	tree.root.add_child(level)
	await tree.process_frame
	var dock := DOCK.instantiate() as FloorSurfaceDock
	tree.root.add_child(dock)
	dock.setup()
	dock.set_styles(surface.styles)
	dock.set_target(surface, surface.floor_map)
	dock.edit_toggle.button_pressed = true
	expect(dock.is_editing_enabled(), "The authored floor enables viewport painting.")
	expect_equal(dock.style_option.item_count, 2, "Four Towers offers two named floor types.")
	expect_equal(dock.style_option.get_item_text(0), "Dirt", "The initial floor has a visible dirt texture.")
	expect_equal(dock.style_option.get_item_text(1), "Flagstones", "The palette includes textured flagstones.")
	expect(not dock.style_button.disabled, "Floor type editing is available for this scene.")
	var painter := ShapePainter.new()
	var brush_cell := Vector2i(32, 16)
	var pick_origin := Vector3(
		surface.world_origin_xz.x + (float(brush_cell.x) + 0.5) * surface.cell_size,
		10,
		surface.world_origin_xz.y + (float(brush_cell.y) + 0.5) * surface.cell_size
	)
	var hit := Picker.pick_world_position(pick_origin, Vector3.DOWN, surface) as Vector3
	expect_equal(surface.world_to_cell(hit), brush_cell, "The brush can pick empty ground outside the starting floor.")
	painter.begin(surface.floor_map, ShapePainter.PaintMode.Paint)
	painter.apply_cells(ShapePainter.brush_footprint(brush_cell, 1, surface.floor_map, false))
	painter.finish()
	expect(surface.has_floor(brush_cell), "A brush stroke adds floor outside the initial square.")
	var rectangle := ShapePainter.rectangle_footprint(Vector2i(33, 16), Vector2i(34, 17), surface.floor_map, false)
	painter.begin(surface.floor_map, ShapePainter.PaintMode.Paint)
	painter.apply_cells(rectangle)
	var edit := painter.finish()
	for cell in rectangle:
		expect(surface.has_floor(cell), "Rectangle painting creates each previously absent floor cell.")
	expect_equal(surface.get_generated_cell_count(), 1029, "Painting rebuilds the visible floor geometry.")
	expect(surface.collision_shape.shape != null, "The painted floor retains physical collision.")
	surface.floor_map.apply_shape_snapshot(edit["before"] as Dictionary)
	expect(not surface.has_floor(Vector2i(34, 17)), "Undo removes the new rectangle.")
	surface.floor_map.apply_shape_snapshot(edit["after"] as Dictionary)
	expect(surface.has_floor(Vector2i(34, 17)), "Redo restores the rectangle.")
	dock.style_option.select(1)
	var style_painter := StylePainter.new()
	style_painter.begin(surface.floor_map, dock.get_style_index())
	style_painter.apply_cells(rectangle)
	style_painter.finish()
	expect_equal(surface.floor_map.get_cell_style(Vector2i(34, 17)), 1, "The chosen floor type paints onto new tiles.")
	expect_equal(
		surface.floor_map.get_cell_style(Vector2i(16, 16)), 0, "Changing a floor type leaves other tiles alone."
	)
	expect_equal(authored_map.get_shape_snapshot(), authored_shape, "Editor checks preserve the authored floor shape.")
	expect_equal(
		authored_map.get_elevation_snapshot(), authored_elevations, "Editor checks preserve the authored slope heights."
	)
	dock.free()
	level.free()
