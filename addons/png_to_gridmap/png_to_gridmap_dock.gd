@tool
class_name PNGToGridMapDock
extends VBoxContainer

## Presents the PNG-to-GridMap workflow in the editor and translates user choices into typed signals.
## The dock owns interface state while leaving project and scene changes to the plugin services.

const AutotileAlternativeResource := preload("res://addons/png_to_gridmap/png_to_gridmap_autotile_alternative.gd")

signal load_png_selected(path: String)
signal export_png_path_selected(path: String)
signal run_requested(operation_id: int)
signal repair_gridmap_requested
signal create_floor_requested
signal floor_material_selected(path: String)
signal refresh_requested
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
var _auto_repair_check: CheckBox
var _floor_material_option: OptionButton
var _advanced_button: Button
var _advanced_container: VBoxContainer
var _configuration_popup: PopupPanel
var _png_path_label: Label
var _mesh_library_path_edit: LineEdit
var _floor_materials_folder_edit: LineEdit
var _rows_container: VBoxContainer
var _outputs_section_label: Label
var _output_label: Label
var _output_png_button_row: HFlowContainer
var _validation_label: RichTextLabel
var _png_open_dialog: EditorFileDialog
var _png_save_dialog: EditorFileDialog
var _import_warning_dialog: ConfirmationDialog
var _overwrite_warning_dialog: ConfirmationDialog
var _mesh_library_dialog: EditorFileDialog
var _floor_materials_folder_dialog: EditorFileDialog


## Builds the dock and binds it to the current settings resource.
func setup(title_text: String, settings: Resource, ui_state: Dictionary) -> void:
	_settings = settings
	name = "PNG to GridMap"
	_build_main_scroll(title_text)
	_build_operation()
	_build_inputs()
	_build_advanced()
	_build_floor_controls()
	_build_configuration_popup()
	_build_outputs()
	_build_footer()
	_build_dialogs()
	_apply_ui_state(ui_state)
	_apply_editor_tooltips(self)


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


## Rebuilds the floor material dropdown from the globally configured folder.
func set_floor_material_paths(paths: Array[String]) -> void:
	_floor_material_option.clear()
	_floor_material_option.add_item("No floor material selected")
	_floor_material_option.set_item_metadata(0, "")
	for path in paths:
		_floor_material_option.add_item(path.get_file().get_basename().capitalize())
		_floor_material_option.set_item_metadata(_floor_material_option.item_count - 1, path)
		_floor_material_option.set_item_tooltip(_floor_material_option.item_count - 1, path)
	_select_option_by_metadata(_floor_material_option, String(_settings.floor_material_path))


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
	_import_warning_dialog.dialog_text = (
		"Some colours are unassigned and will be skipped:\n\n- %s\n\nContinue import?"
		% "\n- ".join(warnings)
	)
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
	_content_container.add_child(_section("Level Settings"))
	var configuration_button := Button.new()
	configuration_button.text = "Configure Wall Tiles and Colours"
	configuration_button.pressed.connect(func() -> void:
		var popup_height := roundi(get_viewport_rect().size.y * 0.8)
		_configuration_popup.popup_centered(Vector2i(560, popup_height))
	)
	_content_container.add_child(configuration_button)
	_advanced_button = Button.new()
	_advanced_button.text = "More Level Settings"
	_advanced_button.toggle_mode = true
	_advanced_button.toggled.connect(func(value: bool) -> void:
		_advanced_container.visible = value
		operation_changed.emit(_operation_option.get_selected_id(), value)
	)
	_content_container.add_child(_advanced_button)
	_advanced_container = VBoxContainer.new()
	_advanced_container.visible = false
	_content_container.add_child(_advanced_container)
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
	_auto_repair_check = CheckBox.new()
	_auto_repair_check.text = "Auto repair"
	_auto_repair_check.toggled.connect(func(value: bool) -> void:
		_settings.auto_repair = value
		settings_changed.emit()
	)
	_advanced_container.add_child(_auto_repair_check)


## Builds the floor material selector populated from the configured material folder.
func _build_floor_controls() -> void:
	_content_container.add_child(_section("Floor GridMap"))
	_floor_material_option = OptionButton.new()
	_floor_material_option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_floor_material_option.item_selected.connect(func(index: int) -> void:
		floor_material_selected.emit(String(_floor_material_option.get_item_metadata(index)))
	)
	_content_container.add_child(_floor_material_option)


## Builds the global wall configuration popup and its scrollable mapping list.
func _build_configuration_popup() -> void:
	_configuration_popup = PopupPanel.new()
	_configuration_popup.title = "Wall Tile and Colour Configuration"
	add_child(_configuration_popup)
	var popup_content := VBoxContainer.new()
	popup_content.custom_minimum_size = Vector2(520, 560)
	_configuration_popup.add_child(popup_content)
	var library_row := HBoxContainer.new()
	library_row.add_child(_label("Wall pieces file"))
	_mesh_library_path_edit = LineEdit.new()
	_mesh_library_path_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_mesh_library_path_edit.text_submitted.connect(_set_mesh_library_path)
	_mesh_library_path_edit.focus_exited.connect(func() -> void:
		_set_mesh_library_path(_mesh_library_path_edit.text)
	)
	library_row.add_child(_mesh_library_path_edit)
	var library_browse_button := Button.new()
	library_browse_button.text = "Browse"
	library_browse_button.pressed.connect(func() -> void: _mesh_library_dialog.popup_file_dialog())
	library_row.add_child(library_browse_button)
	popup_content.add_child(library_row)
	var folder_row := HBoxContainer.new()
	folder_row.add_child(_label("Floor materials folder"))
	_floor_materials_folder_edit = LineEdit.new()
	_floor_materials_folder_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_floor_materials_folder_edit.text_submitted.connect(func(value: String) -> void:
		_set_floor_materials_folder(value)
	)
	_floor_materials_folder_edit.focus_exited.connect(func() -> void:
		_set_floor_materials_folder(_floor_materials_folder_edit.text)
	)
	folder_row.add_child(_floor_materials_folder_edit)
	var folder_browse_button := Button.new()
	folder_browse_button.text = "Browse"
	folder_browse_button.pressed.connect(func() -> void: _floor_materials_folder_dialog.popup_file_dialog())
	folder_row.add_child(folder_browse_button)
	popup_content.add_child(folder_row)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	popup_content.add_child(scroll)
	_rows_container = VBoxContainer.new()
	_rows_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_rows_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.add_child(_rows_container)
	var close_button := Button.new()
	close_button.text = "Close"
	close_button.pressed.connect(_configuration_popup.hide)
	popup_content.add_child(close_button)


## Builds output path controls.
func _build_outputs() -> void:
	_outputs_section_label = _section("Output")
	_content_container.add_child(_outputs_section_label)
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
	_validation_label.custom_minimum_size = Vector2(0, 84)
	_validation_label.fit_content = false
	_validation_label.scroll_active = true
	_validation_label.bbcode_enabled = false
	add_child(_validation_label)
	add_child(_button_row([
		["Run", func() -> void: run_requested.emit(_operation_option.get_selected_id())],
		["Repair Gridmap", func() -> void: repair_gridmap_requested.emit()],
		["Create Floor", func() -> void: create_floor_requested.emit()],
	]))


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
	_mesh_library_dialog = EditorFileDialog.new()
	_mesh_library_dialog.file_mode = EditorFileDialog.FILE_MODE_OPEN_FILE
	_mesh_library_dialog.access = EditorFileDialog.ACCESS_RESOURCES
	_mesh_library_dialog.filters = PackedStringArray(["*.tres,*.res ; Godot resource files"])
	_mesh_library_dialog.file_selected.connect(_set_mesh_library_path)
	add_child(_mesh_library_dialog)
	_floor_materials_folder_dialog = EditorFileDialog.new()
	_floor_materials_folder_dialog.file_mode = EditorFileDialog.FILE_MODE_OPEN_DIR
	_floor_materials_folder_dialog.access = EditorFileDialog.ACCESS_RESOURCES
	_floor_materials_folder_dialog.dir_selected.connect(_set_floor_materials_folder)
	add_child(_floor_materials_folder_dialog)


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
	_auto_repair_check.button_pressed = _settings.auto_repair
	_select_option_by_metadata(_floor_material_option, String(_settings.floor_material_path))
	_mesh_library_path_edit.text = _settings.mesh_library_path
	_floor_materials_folder_edit.text = _settings.floor_materials_folder
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
		_apply_editor_tooltips(empty)
		return
	for key in _colour_order:
		var row := _colour_row(key)
		_rows_container.add_child(row)
		_apply_editor_tooltips(row)


## Applies a user-entered MeshLibrary path to the shared wall configuration.
func _set_mesh_library_path(value: String) -> void:
	var path := value.strip_edges()
	_mesh_library_path_edit.text = path
	if path == _settings.mesh_library_path:
		return
	mesh_library_selected.emit(path)


## Applies a user-entered folder to the shared floor-material choices.
func _set_floor_materials_folder(value: String) -> void:
	var path := value.strip_edges()
	_floor_materials_folder_edit.text = path
	if path == _settings.floor_materials_folder:
		return
	_settings.floor_materials_folder = path
	settings_changed.emit()


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
	title.text = "%s  %s px" % [
		mapping.display_name if mapping.display_name != "" else "#" + key,
		_detected_colours[key]["count"],
	]
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
		content.add_child(_autotile_connectivity_group_row(mapping))
		content.add_child(_variant_row(mapping, PNGToGridMapAutotile.VARIANT_SOLO, "Solo"))
		content.add_child(_variant_row(mapping, PNGToGridMapAutotile.VARIANT_END, "End"))
		content.add_child(_variant_row(mapping, PNGToGridMapAutotile.VARIANT_CORNER, "Corner"))
		content.add_child(_variant_row(mapping, PNGToGridMapAutotile.VARIANT_TEE, "Tee"))
		content.add_child(_variant_row(mapping, PNGToGridMapAutotile.VARIANT_CROSS, "Cross"))
		content.add_child(_autotile_alternatives(mapping))
	return panel


## Builds the optional group field used to connect compatible autotile mappings.
func _autotile_connectivity_group_row(mapping: Resource) -> Control:
	var row := HBoxContainer.new()
	row.add_child(_label("Connects with"))
	var group := LineEdit.new()
	group.placeholder_text = "Configured variants"
	group.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	group.text = mapping.autotile_connectivity_group
	group.tooltip_text = (
		"Blank connects equivalent variant configurations. "
		+ "Matching groups connect different mappings as one tile type."
	)
	group.text_changed.connect(func(value: String) -> void:
		mapping.autotile_connectivity_group = value.strip_edges()
		mapping_changed.emit()
	)
	row.add_child(group)
	return row


## Builds repeatable decorative alternatives that participate in repair connectivity.
func _autotile_alternatives(mapping: Resource) -> Control:
	var content := VBoxContainer.new()
	var header := HBoxContainer.new()
	var label := _label("Placed alternatives")
	label.tooltip_text = "These pieces count as this tile type and are preserved only while their configured joins match."
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(label)
	var add_button := Button.new()
	add_button.text = "Add"
	add_button.pressed.connect(func() -> void:
		mapping.autotile_alternatives.append(AutotileAlternativeResource.new())
		_rebuild_colour_rows()
		mapping_changed.emit()
	)
	header.add_child(add_button)
	content.add_child(header)
	for alternative: Resource in mapping.autotile_alternatives:
		content.add_child(_autotile_alternative_row(mapping, alternative))
	return content


## Builds item, connection-shape, rotation, and removal controls for one alternative.
func _autotile_alternative_row(mapping: Resource, alternative: Resource) -> Control:
	var row := HBoxContainer.new()
	var item := OptionButton.new()
	item.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	item.add_item(UNASSIGNED_TEXT)
	item.set_item_metadata(0, "")
	for item_ref in _available_item_refs:
		item.add_item(String(_available_item_display_names.get(item_ref, item_ref)))
		item.set_item_metadata(item.item_count - 1, item_ref)
	_select_option_by_metadata(item, String(_available_item_ref_aliases.get(alternative.item_ref, alternative.item_ref)))
	item.item_selected.connect(func(index: int) -> void:
		alternative.item_ref = String(item.get_item_metadata(index))
		mapping_changed.emit()
	)
	row.add_child(item)

	var shape := OptionButton.new()
	for shape_spec: Array in [
		["Solo", AutotileAlternativeResource.ConnectionShape.SOLO],
		["End", AutotileAlternativeResource.ConnectionShape.END],
		["Straight", AutotileAlternativeResource.ConnectionShape.STRAIGHT],
		["Corner", AutotileAlternativeResource.ConnectionShape.CORNER],
		["Tee", AutotileAlternativeResource.ConnectionShape.TEE],
		["Cross", AutotileAlternativeResource.ConnectionShape.CROSS],
	]:
		shape.add_item(String(shape_spec[0]), int(shape_spec[1]))
		shape.set_item_metadata(shape.item_count - 1, int(shape_spec[1]))
	_select_option_by_metadata(shape, int(alternative.connection_shape))
	shape.item_selected.connect(func(index: int) -> void:
		alternative.connection_shape = int(shape.get_item_metadata(index))
		mapping_changed.emit()
	)
	row.add_child(shape)

	var rotation := OptionButton.new()
	for offset in 4:
		rotation.add_item(str(offset), offset)
		rotation.set_item_metadata(rotation.item_count - 1, offset)
	_select_option_by_metadata(rotation, int(alternative.rotation_offset))
	rotation.item_selected.connect(func(index: int) -> void:
		alternative.rotation_offset = int(rotation.get_item_metadata(index))
		mapping_changed.emit()
	)
	row.add_child(rotation)

	var remove_button := Button.new()
	remove_button.text = "Remove"
	remove_button.pressed.connect(func() -> void:
		mapping.autotile_alternatives.erase(alternative)
		_rebuild_colour_rows()
		mapping_changed.emit()
	)
	row.add_child(remove_button)
	return row


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
		_outputs_section_label.visible = true
		_output_label.visible = true
		_output_label.text = "Output PNG: %s" % _default_export_path
		_output_png_button_row.visible = true
	else:
		_outputs_section_label.visible = false
		_output_label.visible = false
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


## Creates a wrapping row of buttons that does not impose a wide editor dock.
func _button_row(specs: Array) -> HFlowContainer:
	var row := HFlowContainer.new()
	for spec in specs:
		var button := Button.new()
		button.text = spec[0]
		button.pressed.connect(spec[1])
		row.add_child(button)
	return row


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


## Gives every visible editor field a plain-language explanation when hovered.
func _apply_editor_tooltips(root: Control) -> void:
	if root.tooltip_text == "":
		root.tooltip_text = _tooltip_for_control(root)
	for child in root.get_children():
		if child is Control:
			_apply_editor_tooltips(child)


## Returns concise level-editor guidance for common dock controls.
func _tooltip_for_control(control: Control) -> String:
	var visible_text := ""
	if control is Label:
		visible_text = (control as Label).text
	elif control is Button:
		visible_text = (control as Button).text
	elif control is LineEdit:
		visible_text = (control as LineEdit).placeholder_text
	match visible_text:
		"Load PNG": return "Choose the picture that describes this level's layout."
		"Refresh": return "Look again for level pictures, GridMaps, wall pieces, and floor materials."
		"GridMap": return "Choose which collection of placed pieces this tool should use."
		"GridMap name": return "Name the new collection of placed pieces that will be created."
		"MeshLibrary": return "Choose the set of wall pieces available for this level."
		"Configure Wall Tiles and Colours":
			return (
				"Choose which wall piece each picture colour represents. "
				+ "These choices are shared across levels."
			)
		"More Level Settings": return "Show or hide less commonly changed choices for this level."
		"Cell size": return "Set the width and depth of each square in the level."
		"Auto repair":
			return (
				"After you finish painting, automatically fit wall ends, corners, "
				+ "and junctions to their neighbours."
			)
		"Floor GridMap": return "Choose the look of the floor created beneath the picture."
		"Wall pieces file": return "Choose the shared file containing the wall pieces used by picture colours."
		"Floor materials folder": return "Choose the shared folder whose floor finishes appear in the floor list."
		"Browse": return "Choose this location from the project."
		"Close": return "Close these shared wall and colour choices."
		"Choose PNG": return "Choose where the picture made from the GridMap will be saved."
		"Run": return "Carry out the selected import or export."
		"Repair Gridmap": return "Update connected wall pieces so corners, ends, and junctions fit their neighbours."
		"Create Floor": return "Create or rebuild a floor beneath every painted square in the picture."
		"Autotile": return "Use neighbouring squares to choose ends, corners, and junctions automatically."
		"Add": return "Add another decorative wall piece that can stand in for this colour."
		"Remove": return "Remove this decorative wall-piece choice."
	if control is OptionButton:
		return "Choose one of the available options."
	if control is LineEdit:
		return "Enter the project location to use, or choose it with Browse."
	if control is SpinBox:
		return "Adjust this level setting."
	if control is ColorRect:
		return "This is the colour found in the level picture."
	if control is RichTextLabel:
		return "Shows what is ready, what succeeded, or what still needs attention."
	if visible_text != "":
		return visible_text
	return "Part of the PNG to GridMap level-building controls."
