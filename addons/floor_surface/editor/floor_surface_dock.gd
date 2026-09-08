@tool
class_name FloorSurfaceDock
extends VBoxContainer

## Presents editor-only topology, elevation and style controls for the selected FloorSurface.

const SHAPE_PAINTER := preload(
	"res://addons/floor_surface/editor/floor_surface_shape_painter.gd"
)
const ELEVATION_PAINTER := preload(
	"res://addons/floor_surface/editor/floor_surface_elevation_painter.gd"
)
const STYLE_PAINTER := preload(
	"res://addons/floor_surface/editor/floor_surface_style_painter.gd"
)
const STYLE_SCRIPT := preload("res://addons/floor_surface/floor_style.gd")

enum EditMode {
	FloorShape,
	Elevation,
	Style,
}

signal editing_toggled(enabled: bool)
signal grid_overlay_toggled(visible: bool)
signal edit_mode_changed(edit_mode: int)
signal paint_mode_changed(paint_mode: int)
signal elevation_operation_changed(operation: int)
signal absolute_elevation_changed(elevation: int)
signal style_operation_changed(operation: int)
signal style_index_changed(style_index: int)
signal shape_mode_changed(shape_mode: int)
signal brush_size_changed(brush_size: int)
signal make_unique_requested
signal save_requested

@onready var edit_toggle := %EditToggle as CheckButton
@onready var grid_overlay_toggle := %GridOverlayToggle as CheckButton
@onready var target_label := %TargetLabel as Label
@onready var ownership_label := %OwnershipLabel as Label
@onready var floor_shape_button := %FloorShapeButton as Button
@onready var elevation_button := %ElevationButton as Button
@onready var style_button := %StyleButton as Button
@onready var shape_controls := %ShapeControls as Control
@onready var elevation_controls := %ElevationControls as Control
@onready var style_controls := %StyleControls as Control
@onready var paint_mode_option := %PaintModeOption as OptionButton
@onready var elevation_readout := %ElevationReadout as Label
@onready var absolute_elevation := %AbsoluteElevation as SpinBox
@onready var set_elevation_button := %SetElevationButton as Button
@onready var raise_elevation_button := %RaiseElevationButton as Button
@onready var lower_elevation_button := %LowerElevationButton as Button
@onready var sample_elevation_button := %SampleElevationButton as Button
@onready var style_option := %StyleOption as OptionButton
@onready var paint_style_button := %PaintStyleButton as Button
@onready var sample_style_button := %SampleStyleButton as Button
@onready var brush_button := %BrushButton as Button
@onready var rectangle_button := %RectangleButton as Button
@onready var brush_size_option := %BrushSizeOption as OptionButton
@onready var hover_label := %HoverLabel as Label
@onready var status_label := %StatusLabel as Label
@onready var make_unique_button := %MakeUniqueButton as Button
@onready var save_button := %SaveButton as Button

var _configured := false
var _has_target := false
var _has_styles := false
var _elevation_unit := 0.25


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
	grid_overlay_toggle.toggled.connect(grid_overlay_toggled.emit)
	floor_shape_button.pressed.connect(_on_edit_mode_selected.bind(EditMode.FloorShape))
	elevation_button.pressed.connect(_on_edit_mode_selected.bind(EditMode.Elevation))
	style_button.pressed.connect(_on_edit_mode_selected.bind(EditMode.Style))
	paint_mode_option.item_selected.connect(_on_paint_mode_selected)
	set_elevation_button.pressed.connect(
		_on_elevation_operation_selected.bind(ELEVATION_PAINTER.Operation.SetAbsolute)
	)
	raise_elevation_button.pressed.connect(
		_on_elevation_operation_selected.bind(ELEVATION_PAINTER.Operation.RaiseOne)
	)
	lower_elevation_button.pressed.connect(
		_on_elevation_operation_selected.bind(ELEVATION_PAINTER.Operation.LowerOne)
	)
	sample_elevation_button.pressed.connect(
		_on_elevation_operation_selected.bind(ELEVATION_PAINTER.Operation.Sample)
	)
	absolute_elevation.value_changed.connect(_on_absolute_elevation_changed)
	paint_style_button.pressed.connect(
		_on_style_operation_selected.bind(STYLE_PAINTER.Operation.Paint)
	)
	sample_style_button.pressed.connect(
		_on_style_operation_selected.bind(STYLE_PAINTER.Operation.Sample)
	)
	style_option.item_selected.connect(_on_style_selected)
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
	grid_overlay_toggle.disabled = not has_target
	floor_shape_button.disabled = not has_target
	elevation_button.disabled = not has_target
	style_button.disabled = not has_target or not _has_styles
	paint_mode_option.disabled = not has_target
	brush_button.disabled = not has_target
	rectangle_button.disabled = not has_target
	brush_size_option.disabled = not has_target or rectangle_button.button_pressed
	make_unique_button.disabled = not has_target
	save_button.disabled = not has_target
	_set_elevation_buttons_disabled(not has_target)
	_set_style_controls_disabled(not has_target or not _has_styles)
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
	_refresh_mode_visibility()


## Rebuilds the named palette selector without changing any FloorStyle resource.
func set_styles(styles: Array[STYLE_SCRIPT]) -> void:
	var selected_style := get_style_index()
	style_option.clear()
	for style_index in styles.size():
		var style := styles[style_index] as STYLE_SCRIPT
		var style_name := style.display_name if style != null else "Invalid style %d" % style_index
		style_option.add_item(style_name, style_index)
	_has_styles = not styles.is_empty()
	if _has_styles:
		var selected_item := style_option.get_item_index(selected_style)
		style_option.select(selected_item if selected_item >= 0 else 0)
	style_button.disabled = not _has_target or not _has_styles
	_set_style_controls_disabled(not _has_target or not _has_styles)


## Displays the current hover footprint in map coordinates.
func set_hover(cell: Vector2i, cell_count: int) -> void:
	hover_label.text = "Cell %s — %d cell%s" % [
		cell,
		cell_count,
		"" if cell_count == 1 else "s",
	]


## Displays the hovered cell's exact integer elevation and converted physical height.
func set_elevation_hover(cell: Vector2i, cell_count: int, elevation: int) -> void:
	hover_label.text = "Cell %s — %d cell%s — %d units / %.2f m" % [
		cell,
		cell_count,
		"" if cell_count == 1 else "s",
		elevation,
		float(elevation) * _elevation_unit,
	]


## Displays the hovered cell's palette identity for either a top or a hole.
func set_style_hover(cell: Vector2i, cell_count: int, style_name: String) -> void:
	hover_label.text = "Cell %s — %d cell%s — %s" % [
		cell,
		cell_count,
		"" if cell_count == 1 else "s",
		style_name,
	]


## Clears cursor feedback when the viewport ray no longer reaches the working plane.
func clear_hover() -> void:
	hover_label.text = "Cell —"


## Shows a concise save, undo or cancellation result.
func set_status(message: String) -> void:
	status_label.text = message


## Updates unit conversion used by the elevation entry and hover label.
func set_elevation_unit(elevation_unit: float) -> void:
	_elevation_unit = maxf(elevation_unit, 0.01)
	_update_elevation_readout()


## Copies a sampled cell elevation into the absolute entry without changing the map.
func set_sampled_elevation(elevation: int) -> void:
	absolute_elevation.value = elevation
	set_elevation_button.button_pressed = true
	_on_elevation_operation_selected(ELEVATION_PAINTER.Operation.SetAbsolute)


## Copies sampled style intent into the palette selector without changing the map.
func set_sampled_style(style_index: int) -> void:
	var item_index := style_option.get_item_index(style_index)
	if item_index < 0:
		return
	style_option.select(item_index)
	paint_style_button.button_pressed = true
	_on_style_operation_selected(STYLE_PAINTER.Operation.Paint)


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


## Returns whether the optional editor guide should cover the real floor texture.
func is_grid_overlay_visible() -> bool:
	return grid_overlay_toggle != null \
		and grid_overlay_toggle.button_pressed \
		and not grid_overlay_toggle.disabled


## Returns the selected named paint mode.
func get_paint_mode() -> int:
	return paint_mode_option.get_selected_id()


## Returns whether the dock is editing occupancy or integer elevation.
func get_edit_mode() -> EditMode:
	if elevation_button.button_pressed:
		return EditMode.Elevation
	if style_button.button_pressed:
		return EditMode.Style
	return EditMode.FloorShape


## Returns the selected elevation operation.
func get_elevation_operation() -> int:
	if raise_elevation_button.button_pressed:
		return ELEVATION_PAINTER.Operation.RaiseOne
	if lower_elevation_button.button_pressed:
		return ELEVATION_PAINTER.Operation.LowerOne
	if sample_elevation_button.button_pressed:
		return ELEVATION_PAINTER.Operation.Sample
	return ELEVATION_PAINTER.Operation.SetAbsolute


## Returns the directly entered absolute integer elevation.
func get_absolute_elevation() -> int:
	return roundi(absolute_elevation.value)


## Returns whether a click paints or samples style intent.
func get_style_operation() -> STYLE_PAINTER.Operation:
	return STYLE_PAINTER.Operation.Sample \
		if sample_style_button.button_pressed else STYLE_PAINTER.Operation.Paint


## Returns the selected stable index into the FloorSurface palette.
func get_style_index() -> int:
	return style_option.get_selected_id() if style_option != null else 0


## Returns the selected named shape mode.
func get_shape_mode() -> int:
	return SHAPE_PAINTER.ShapeMode.Rectangle \
		if rectangle_button.button_pressed else SHAPE_PAINTER.ShapeMode.Brush


## Returns the selected odd brush width in cells.
func get_brush_size() -> int:
	return brush_size_option.get_selected_id()


func _on_paint_mode_selected(index: int) -> void:
	paint_mode_changed.emit(paint_mode_option.get_item_id(index))


func _on_edit_mode_selected(edit_mode: EditMode) -> void:
	_refresh_mode_visibility()
	edit_mode_changed.emit(edit_mode)


func _on_elevation_operation_selected(operation: int) -> void:
	elevation_operation_changed.emit(operation)


func _on_absolute_elevation_changed(value: float) -> void:
	_update_elevation_readout()
	absolute_elevation_changed.emit(roundi(value))


func _on_style_operation_selected(operation: STYLE_PAINTER.Operation) -> void:
	style_operation_changed.emit(operation)


func _on_style_selected(index: int) -> void:
	style_index_changed.emit(style_option.get_item_id(index))


func _on_shape_mode_selected(shape_mode: int) -> void:
	brush_size_option.disabled = not _has_target or shape_mode == SHAPE_PAINTER.ShapeMode.Rectangle
	shape_mode_changed.emit(shape_mode)


func _on_brush_size_selected(index: int) -> void:
	brush_size_changed.emit(brush_size_option.get_item_id(index))


func _refresh_mode_visibility() -> void:
	var edit_mode := get_edit_mode()
	shape_controls.visible = edit_mode == EditMode.FloorShape
	elevation_controls.visible = edit_mode == EditMode.Elevation
	style_controls.visible = edit_mode == EditMode.Style


func _set_elevation_buttons_disabled(disabled: bool) -> void:
	absolute_elevation.editable = not disabled
	set_elevation_button.disabled = disabled
	raise_elevation_button.disabled = disabled
	lower_elevation_button.disabled = disabled
	sample_elevation_button.disabled = disabled


func _set_style_controls_disabled(disabled: bool) -> void:
	style_option.disabled = disabled
	paint_style_button.disabled = disabled
	sample_style_button.disabled = disabled


func _update_elevation_readout() -> void:
	var elevation := get_absolute_elevation()
	elevation_readout.text = "Elevation %d — %.2f m" % [
		elevation,
		float(elevation) * _elevation_unit,
	]
