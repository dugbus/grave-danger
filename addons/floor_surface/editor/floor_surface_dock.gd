@tool
class_name FloorSurfaceDock
extends VBoxContainer

## Presents the editor-only shape-painting controls for the selected FloorSurface.

const SHAPE_PAINTER := preload(
	"res://addons/floor_surface/editor/floor_surface_shape_painter.gd"
)

signal editing_toggled(enabled: bool)
signal paint_mode_changed(paint_mode: int)
signal shape_mode_changed(shape_mode: int)
signal brush_size_changed(brush_size: int)
signal make_unique_requested
signal save_requested

@onready var edit_toggle := %EditToggle as CheckButton
@onready var target_label := %TargetLabel as Label
@onready var ownership_label := %OwnershipLabel as Label
@onready var paint_mode_option := %PaintModeOption as OptionButton
@onready var brush_button := %BrushButton as Button
@onready var rectangle_button := %RectangleButton as Button
@onready var brush_size_option := %BrushSizeOption as OptionButton
@onready var hover_label := %HoverLabel as Label
@onready var status_label := %StatusLabel as Label
@onready var make_unique_button := %MakeUniqueButton as Button
@onready var save_button := %SaveButton as Button

var _configured := false
var _has_target := false


## Connects the scene-authored controls after the dock enters the editor tree.
func setup() -> void:
	if _configured:
		return
	_configured = true
	paint_mode_option.add_item("Paint floor", SHAPE_PAINTER.PaintMode.Paint)
	paint_mode_option.add_item("Erase / make hole", SHAPE_PAINTER.PaintMode.Erase)
	for brush_size in [1, 3, 5, 7, 9]:
		brush_size_option.add_item("%d × %d" % [brush_size, brush_size], brush_size)
	edit_toggle.toggled.connect(editing_toggled.emit)
	paint_mode_option.item_selected.connect(_on_paint_mode_selected)
	brush_button.pressed.connect(_on_shape_mode_selected.bind(SHAPE_PAINTER.ShapeMode.Brush))
	rectangle_button.pressed.connect(
		_on_shape_mode_selected.bind(SHAPE_PAINTER.ShapeMode.Rectangle)
	)
	brush_size_option.item_selected.connect(_on_brush_size_selected)
	make_unique_button.pressed.connect(make_unique_requested.emit)
	save_button.pressed.connect(save_requested.emit)


## Refreshes target identity, edit availability and shared-resource guidance.
func set_target(surface: Node, floor_map: Resource) -> void:
	var has_target := surface != null and floor_map != null
	_has_target = has_target
	edit_toggle.disabled = not has_target
	paint_mode_option.disabled = not has_target
	brush_button.disabled = not has_target
	rectangle_button.disabled = not has_target
	brush_size_option.disabled = not has_target or rectangle_button.button_pressed
	make_unique_button.disabled = not has_target
	save_button.disabled = not has_target
	if not has_target:
		edit_toggle.button_pressed = false
		target_label.text = "Target: select a FloorSurface"
		ownership_label.text = "No editable FloorMap selected."
		return
	target_label.text = "Target: %s" % surface.name
	ownership_label.text = describe_map_ownership(floor_map)
	make_unique_button.disabled = (
		floor_map.resource_local_to_scene or floor_map.resource_path.is_empty()
	)


## Displays the current hover footprint in map coordinates.
func set_hover(cell: Vector2i, cell_count: int) -> void:
	hover_label.text = "Cell %s — %d cell%s" % [
		cell,
		cell_count,
		"" if cell_count == 1 else "s",
	]


## Clears cursor feedback when the viewport ray no longer reaches the working plane.
func clear_hover() -> void:
	hover_label.text = "Cell —"


## Shows a concise save, undo or cancellation result.
func set_status(message: String) -> void:
	status_label.text = message


## Explains whether edits affect a shared external resource or a local unique copy.
static func describe_map_ownership(floor_map: Resource) -> String:
	if floor_map == null:
		return "No editable FloorMap selected."
	if floor_map.resource_local_to_scene or floor_map.resource_path.is_empty():
		return "Independent map — stored in and saved with this scene."
	return (
		"Shared map file — changes affect every FloorSurface using it. "
		+ "Choose Use Independent Copy to edit only this scene."
	)


## Returns whether viewport painting is currently armed.
func is_editing_enabled() -> bool:
	return edit_toggle != null and edit_toggle.button_pressed and not edit_toggle.disabled


## Returns the selected named paint mode.
func get_paint_mode() -> int:
	return paint_mode_option.get_selected_id()


## Returns the selected named shape mode.
func get_shape_mode() -> int:
	return SHAPE_PAINTER.ShapeMode.Rectangle \
		if rectangle_button.button_pressed else SHAPE_PAINTER.ShapeMode.Brush


## Returns the selected odd brush width in cells.
func get_brush_size() -> int:
	return brush_size_option.get_selected_id()


func _on_paint_mode_selected(index: int) -> void:
	paint_mode_changed.emit(paint_mode_option.get_item_id(index))


func _on_shape_mode_selected(shape_mode: int) -> void:
	brush_size_option.disabled = not _has_target or shape_mode == SHAPE_PAINTER.ShapeMode.Rectangle
	shape_mode_changed.emit(shape_mode)


func _on_brush_size_selected(index: int) -> void:
	brush_size_changed.emit(brush_size_option.get_item_id(index))
