@tool
class_name PNGToGridMapDock
extends VBoxContainer

signal load_png_selected(path: String)
signal export_png_path_selected(path: String)
signal run_requested(operation_id: int)
signal refresh_requested
signal new_settings_requested
signal operation_changed(operation_id: int, advanced_visible: bool)
signal mesh_library_selected(path: String)
signal gridmap_selected(path: String)
signal settings_changed
signal mapping_changed

const OPERATION_IMPORT := 0
const OPERATION_EXPORT := 1
const UNASSIGNED_TEXT := "Unassigned"

var _settings: Resource
var _detected_colours := {}
var _colour_order: Array[String] = []
var _available_item_refs: Array[String] = []
var _available_item_display_names := {}
var _available_item_ref_aliases := {}
var _default_export_path := "res://gridmap_export.png"

var _content_container: VBoxContainer
var _operation_option: OptionButton
var _target_gridmap_option: OptionButton
var _mesh_library_option: OptionButton
var _gridmap_name_label: Label
var _gridmap_name_edit: LineEdit
var _cell_size_spin: SpinBox
var _center_check: CheckBox
var _flip_y_check: CheckBox
var _ignore_transparent_check: CheckBox
var _advanced_button: Button
var _advanced_container: VBoxContainer
var _png_path_label: Label
var _mesh_library_label: Label
var _rows_container: VBoxContainer
var _output_label: Label
var _output_png_button_row: HBoxContainer
var _validation_label: RichTextLabel
var _png_open_dialog: EditorFileDialog
var _png_save_dialog: EditorFileDialog
var _import_warning_dialog: ConfirmationDialog
var _overwrite_warning_dialog: ConfirmationDialog


## Builds the dock and binds it to the current settings resource.
func setup(title_text: String, settings: Resource, ui_state: Dictionary) -> void:
	_settings = settings
	name = "PNG to GridMap"
	custom_minimum_size = Vector2(430, 0)
	_build_main_scroll(title_text)
	_build_operation()
	_build_inputs()
	_build_advanced()
	_build_colour_mappings()
	_build_outputs()
	_build_footer()
	_build_dialogs()
	_apply_ui_state(ui_state)


## Updates the settings resource that UI controls should edit.
func set_settings(settings: Resource) -> void:
	_settings = settings
	_update_controls_from_settings()


## Updates the PNG path label and detected colour rows.
func set_png_state(path: String, detected_colours: Dictionary, colour_order: Array[String]) -> void:
	_detected_colours = detected_colours
	_colour_order = colour_order
	_png_path_label.text = path if path != "" else "No PNG loaded"
	_png_path_label.tooltip_text = _png_path_label.text
	_rebuild_colour_rows()


## Rebuilds the GridMap dropdown from edited-scene paths.
func set_gridmap_paths(paths: Array[String]) -> void:
	var previous := String(_settings.target_gridmap_path)
	_target_gridmap_option.clear()
	_target_gridmap_option.add_item("None - create new GridMap")
	_target_gridmap_option.set_item_metadata(0, "")
	for path in paths:
		_target_gridmap_option.add_item(path)
		_target_gridmap_option.set_item_metadata(_target_gridmap_option.item_count - 1, path)
	_select_option_by_metadata(_target_gridmap_option, previous)
	_update_gridmap_name_visibility()


## Rebuilds the MeshLibrary dropdown from project resource paths.
func set_mesh_library_paths(paths: Array[String]) -> void:
	_mesh_library_option.clear()
	_mesh_library_option.add_item("No MeshLibrary selected")
	_mesh_library_option.set_item_metadata(0, "")
	for path in paths:
		_mesh_library_option.add_item(path.get_file().get_basename())
		_mesh_library_option.set_item_metadata(_mesh_library_option.item_count - 1, path)
		_mesh_library_option.set_item_tooltip(_mesh_library_option.item_count - 1, path)
	_select_option_by_metadata(_mesh_library_option, String(_settings.mesh_library_path))


## Sets MeshLibrary item refs used by colour mapping dropdowns.
func set_available_items(refs: Array[String], display_names: Dictionary, aliases: Dictionary) -> void:
	_available_item_refs = refs
	_available_item_display_names = display_names
	_available_item_ref_aliases = aliases
	_rebuild_colour_rows()


## Updates output path text and export-specific controls.
func set_output_path(path: String) -> void:
	_default_export_path = path
	_update_output_label()


## Renders validation or success text in the fixed footer.
func set_validation_text(text: String) -> void:
	_validation_label.text = text


## Shows import warnings and asks whether the user wants to continue.
func show_import_warning(warnings: Array[String], confirmed: Callable) -> void:
	_disconnect_signal_callables(_import_warning_dialog.confirmed)
	_import_warning_dialog.confirmed.connect(confirmed, CONNECT_ONE_SHOT)
	_import_warning_dialog.dialog_text = "Some colours are unassigned and will be skipped:\n\n- %s\n\nContinue import?" % "\n- ".join(warnings)
	_import_warning_dialog.popup_centered()


## Shows export overwrite confirmation before allowing a write to an existing PNG.
func show_overwrite_warning(path: String, confirmed: Callable) -> void:
	_disconnect_signal_callables(_overwrite_warning_dialog.confirmed)
	_overwrite_warning_dialog.confirmed.connect(confirmed, CONNECT_ONE_SHOT)
	_overwrite_warning_dialog.dialog_text = "Overwrite existing PNG?\n\n%s" % path
	_overwrite_warning_dialog.popup_centered()


## Disconnects all callables currently connected to a signal.
func _disconnect_signal_callables(signal_ref: Signal) -> void:
	for connection in signal_ref.get_connections():
		signal_ref.disconnect(connection["callable"])


## Builds the scrollable main content area.
func _build_main_scroll(title_text: String) -> void:
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	_content_container = VBoxContainer.new()
	_content_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.add_child(_content_container)
	var title := Label.new()
	title.text = title_text
	title.add_theme_font_size_override("font_size", 18)
	_content_container.add_child(title)


## Builds the operation selector controls.
func _build_operation() -> void:
	_content_container.add_child(_section("Operation"))
	_operation_option = OptionButton.new()
	_operation_option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_operation_option.add_item("Import PNG to GridMap", OPERATION_IMPORT)
	_operation_option.add_item("Export GridMap to PNG", OPERATION_EXPORT)
	_operation_option.item_selected.connect(func(_index: int) -> void:
		_update_output_label()
		operation_changed.emit(_operation_option.get_selected_id(), _advanced_button.button_pressed)
	)
	_content_container.add_child(_operation_option)


## Builds PNG, GridMap, and MeshLibrary input controls.
func _build_inputs() -> void:
	_content_container.add_child(_section("Inputs"))
	_content_container.add_child(_button_row([
		["Load PNG", func() -> void: _png_open_dialog.popup_file_dialog()],
		["Refresh", func() -> void: refresh_requested.emit()],
	]))
	_png_path_label = _path_label("No PNG loaded")
	_content_container.add_child(_png_path_label)
	_content_container.add_child(_label("GridMap"))
	_target_gridmap_option = OptionButton.new()
	_target_gridmap_option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_target_gridmap_option.item_selected.connect(func(index: int) -> void:
		var path := String(_target_gridmap_option.get_item_metadata(index))
		_settings.target_gridmap_path = NodePath(path)
		_update_gridmap_name_visibility()
		gridmap_selected.emit(path)
	)
	_content_container.add_child(_target_gridmap_option)
	_gridmap_name_label = _label("GridMap name")
	_content_container.add_child(_gridmap_name_label)
	_gridmap_name_edit = LineEdit.new()
	_gridmap_name_edit.text_changed.connect(func(value: String) -> void:
		_settings.gridmap_name = value
		settings_changed.emit()
	)
	_content_container.add_child(_gridmap_name_edit)
	_content_container.add_child(_label("MeshLibrary"))
	_mesh_library_option = OptionButton.new()
	_mesh_library_option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_mesh_library_option.item_selected.connect(func(index: int) -> void:
		var path := String(_mesh_library_option.get_item_metadata(index))
		_settings.mesh_library_path = path
		mesh_library_selected.emit(path)
	)
	_content_container.add_child(_mesh_library_option)


## Builds advanced settings controls.
func _build_advanced() -> void:
	_content_container.add_child(_section("Configuration"))
	_advanced_button = Button.new()
	_advanced_button.text = "Advanced"
	_advanced_button.toggle_mode = true
	_advanced_button.toggled.connect(func(value: bool) -> void:
		_advanced_container.visible = value
		operation_changed.emit(_operation_option.get_selected_id(), value)
	)
	_content_container.add_child(_advanced_button)
	_advanced_container = VBoxContainer.new()
	_advanced_container.visible = false
	_content_container.add_child(_advanced_container)
	_advanced_container.add_child(_button_row([["New Settings", func() -> void: new_settings_requested.emit()]]))
	_mesh_library_label = _path_label("No MeshLibrary resource")
	_advanced_container.add_child(_mesh_library_label)
	var grid := GridContainer.new()
	grid.columns = 2
	_advanced_container.add_child(grid)
	grid.add_child(_label("Cell size"))
	_cell_size_spin = SpinBox.new()
	_cell_size_spin.min_value = 0.01
	_cell_size_spin.max_value = 1024.0
	_cell_size_spin.step = 0.01
	_cell_size_spin.value_changed.connect(func(value: float) -> void:
		_settings.cell_size = _normalize_cell_size(value)
		settings_changed.emit()
	)
	grid.add_child(_cell_size_spin)
	_center_check = _check("Centre Gridmap at Origin", "center_cells")
	_flip_y_check = _check("Rotate PNG 180 degrees to world -Z", "flip_y_to_world_negative_z")
	_ignore_transparent_check = _check("Ignore fully transparent pixels", "ignore_fully_transparent")


## Builds the colour mapping row container.
func _build_colour_mappings() -> void:
	_content_container.add_child(_section("Colour Mappings"))
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 320)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_content_container.add_child(scroll)
	_rows_container = VBoxContainer.new()
	_rows_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_rows_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.add_child(_rows_container)


## Builds output path controls.
func _build_outputs() -> void:
	_content_container.add_child(_section("Outputs"))
	_output_label = _path_label("Output: choose inputs first")
	_content_container.add_child(_output_label)
	_output_png_button_row = _button_row([["Choose PNG", func() -> void:
		_png_save_dialog.current_path = _default_export_path
		_png_save_dialog.popup_file_dialog()
	]])
	_content_container.add_child(_output_png_button_row)


## Builds fixed validation and run controls.
func _build_footer() -> void:
	add_child(HSeparator.new())
	_validation_label = RichTextLabel.new()
	_validation_label.custom_minimum_size = Vector2(0, 120)
	_validation_label.fit_content = true
	_validation_label.bbcode_enabled = false
	add_child(_validation_label)
	add_child(_button_row([["Run", func() -> void: run_requested.emit(_operation_option.get_selected_id())]]))


## Builds hidden file dialogs owned by the dock.
func _build_dialogs() -> void:
	_png_open_dialog = _file_dialog(EditorFileDialog.FILE_MODE_OPEN_FILE)
	_png_open_dialog.file_selected.connect(func(path: String) -> void: load_png_selected.emit(path))
	add_child(_png_open_dialog)
	_png_save_dialog = _file_dialog(EditorFileDialog.FILE_MODE_SAVE_FILE)
	_png_save_dialog.file_selected.connect(func(path: String) -> void: export_png_path_selected.emit(path))
	add_child(_png_save_dialog)
	_import_warning_dialog = ConfirmationDialog.new()
	_import_warning_dialog.title = "Import with Warnings?"
	add_child(_import_warning_dialog)
	_overwrite_warning_dialog = ConfirmationDialog.new()
	_overwrite_warning_dialog.title = "Overwrite PNG?"
	add_child(_overwrite_warning_dialog)


## Applies saved operation and Advanced visibility state.
func _apply_ui_state(ui_state: Dictionary) -> void:
	_select_option_by_id(_operation_option, int(ui_state.get("operation_id", OPERATION_IMPORT)))
	var advanced_visible := bool(ui_state.get("advanced_visible", false))
	_advanced_button.set_pressed_no_signal(advanced_visible)
	_advanced_container.visible = advanced_visible


## Copies settings values into their matching controls.
func _update_controls_from_settings() -> void:
	_gridmap_name_edit.text = _settings.gridmap_name
	_cell_size_spin.value = _normalize_cell_size(_settings.cell_size)
	_center_check.button_pressed = _settings.center_cells
	_flip_y_check.button_pressed = _settings.flip_y_to_world_negative_z
	_ignore_transparent_check.button_pressed = _settings.ignore_fully_transparent
	_mesh_library_label.text = _settings.mesh_library_path if _settings.mesh_library_path != "" else "No MeshLibrary resource"
	_update_gridmap_name_visibility()
	_update_output_label()


## Rebuilds all colour mapping rows from detected colours.
func _rebuild_colour_rows() -> void:
	for child in _rows_container.get_children():
		child.queue_free()
	if _colour_order.is_empty():
		var empty := Label.new()
		empty.text = "Load a PNG to detect colours."
		_rows_container.add_child(empty)
		return
	for key in _colour_order:
		_rows_container.add_child(_colour_row(key))


## Builds a display row for one detected colour.
func _colour_row(key: String) -> Control:
	var mapping := _mapping_for_key(key)
	var panel := PanelContainer.new()
	var content := VBoxContainer.new()
	panel.add_child(content)
	var header := HBoxContainer.new()
	content.add_child(header)
	var swatch := ColorRect.new()
	swatch.color = mapping.colour
	swatch.custom_minimum_size = Vector2(34, 22)
	header.add_child(swatch)
	var title := Label.new()
	title.text = "%s  %s px" % [mapping.display_name if mapping.display_name != "" else "#" + key, _detected_colours[key]["count"]]
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	var autotile := CheckBox.new()
	autotile.text = "Autotile"
	autotile.button_pressed = mapping.autotile_enabled
	autotile.toggled.connect(func(value: bool) -> void:
		mapping.autotile_enabled = value
		if value:
			PNGToGridMapAutotile.auto_fill_mapping_variants(mapping, _available_item_refs)
		_rebuild_colour_rows()
		mapping_changed.emit()
	)
	header.add_child(autotile)
	content.add_child(_variant_row(mapping, PNGToGridMapAutotile.VARIANT_BASE, "Base"))
	if mapping.autotile_enabled:
		content.add_child(_variant_row(mapping, PNGToGridMapAutotile.VARIANT_SOLO, "Solo"))
		content.add_child(_variant_row(mapping, PNGToGridMapAutotile.VARIANT_END, "End"))
		content.add_child(_variant_row(mapping, PNGToGridMapAutotile.VARIANT_CORNER, "Corner"))
		content.add_child(_variant_row(mapping, PNGToGridMapAutotile.VARIANT_TEE, "Tee"))
		content.add_child(_variant_row(mapping, PNGToGridMapAutotile.VARIANT_CROSS, "Cross"))
	return panel


## Builds one item/rotation selector row for a mapping variant.
func _variant_row(mapping: Resource, variant: String, text: String) -> Control:
	var row := HBoxContainer.new()
	row.add_child(_label(text))
	var option := OptionButton.new()
	option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	option.add_item(UNASSIGNED_TEXT)
	option.set_item_metadata(0, "")
	for item_ref in _available_item_refs:
		option.add_item(String(_available_item_display_names.get(item_ref, item_ref)))
		option.set_item_metadata(option.item_count - 1, item_ref)
	_select_option_by_metadata(option, _mapping_variant_ref(mapping, variant))
	option.item_selected.connect(func(index: int) -> void:
		PNGToGridMapAutotile.set_variant_ref_for_mapping(mapping, variant, String(option.get_item_metadata(index)))
		if variant == PNGToGridMapAutotile.VARIANT_BASE:
			PNGToGridMapAutotile.clear_derived_variant_refs(mapping)
			PNGToGridMapAutotile.auto_fill_mapping_variants(mapping, _available_item_refs)
			_rebuild_colour_rows()
		mapping_changed.emit()
	)
	row.add_child(option)
	var rotation := OptionButton.new()
	for offset in 4:
		rotation.add_item(str(offset), offset)
		rotation.set_item_metadata(rotation.item_count - 1, offset)
	_select_option_by_metadata(rotation, PNGToGridMapAutotile.rotation_offset_for_mapping(mapping, variant))
	rotation.item_selected.connect(func(index: int) -> void:
		PNGToGridMapAutotile.set_rotation_offset_for_mapping(mapping, variant, int(rotation.get_item_metadata(index)))
		mapping_changed.emit()
	)
	row.add_child(rotation)
	return row


## Finds a colour mapping resource by colour key.
func _mapping_for_key(key: String) -> Resource:
	for mapping in _settings.color_mappings:
		if PNGToGridMapImageGrid.colour_key(mapping.colour) == key:
			return mapping
	return null


## Resolves a mapping variant ref through currently available item aliases.
func _mapping_variant_ref(mapping: Resource, variant: String) -> String:
	var ref := PNGToGridMapAutotile.variant_ref_for_mapping(mapping, variant)
	return String(_available_item_ref_aliases.get(ref, ref))


## Shows the GridMap name field only when creating a new GridMap.
func _update_gridmap_name_visibility() -> void:
	var show_name := String(_settings.target_gridmap_path) == ""
	_gridmap_name_label.visible = show_name
	_gridmap_name_edit.visible = show_name


## Updates output text and export-path button visibility for the operation.
func _update_output_label() -> void:
	if _operation_option.get_selected_id() == OPERATION_EXPORT:
		_output_label.text = "Output PNG: %s" % _default_export_path
		_output_png_button_row.visible = true
	else:
		_output_label.text = "Output GridMap: %s" % (_settings.gridmap_name if String(_settings.target_gridmap_path) == "" else String(_settings.target_gridmap_path))
		_output_png_button_row.visible = false


## Creates a standard section heading label.
func _section(text: String) -> Label:
	var label := _label(text)
	label.add_theme_font_size_override("font_size", 14)
	return label


## Creates a standard compact label.
func _label(text: String) -> Label:
	var label := Label.new()
	label.text = text
	return label


## Creates a path-style label with clipping and tooltip mirroring.
func _path_label(text: String) -> Label:
	var label := _label(text)
	label.clip_text = true
	label.tooltip_text = text
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return label


## Creates a horizontal row of buttons from label/callable pairs.
func _button_row(specs: Array) -> HBoxContainer:
	var row := HBoxContainer.new()
	for spec in specs:
		var button := Button.new()
		button.text = spec[0]
		button.pressed.connect(spec[1])
		row.add_child(button)
	return row


## Creates a checkbox bound to a boolean settings property.
func _check(text: String, property: String) -> CheckBox:
	var check := CheckBox.new()
	check.text = text
	check.toggled.connect(func(value: bool) -> void:
		_settings.set(property, value)
		settings_changed.emit()
	)
	_advanced_container.add_child(check)
	return check


## Creates a PNG file dialog using the standard filter.
func _file_dialog(mode: EditorFileDialog.FileMode) -> EditorFileDialog:
	var dialog := EditorFileDialog.new()
	dialog.file_mode = mode
	dialog.access = EditorFileDialog.ACCESS_FILESYSTEM
	dialog.filters = PackedStringArray(["*.png ; PNG images"])
	return dialog


## Selects an OptionButton item by metadata value.
func _select_option_by_metadata(option: OptionButton, target: Variant) -> void:
	for index in option.item_count:
		if option.get_item_metadata(index) == target:
			option.select(index)
			return
	option.select(0)


## Selects an OptionButton item by integer item id.
func _select_option_by_id(option: OptionButton, target_id: int) -> void:
	for index in option.item_count:
		if option.get_item_id(index) == target_id:
			option.select(index)
			return


## Rounds cell-size values to avoid unwanted floating-point drift in saved profiles.
func _normalize_cell_size(value: float) -> float:
	return round(value * 1000.0) / 1000.0
