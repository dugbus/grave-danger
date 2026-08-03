class_name GDGameFont
extends RefCounted


const ALMENDRA_FONT_PATH := "res://Assets/fonts/Almendra-Bold.ttf"


static func get_almendra_font() -> FontFile:
	var font := load(ALMENDRA_FONT_PATH) as FontFile
	if font == null:
		push_warning("Unable to load game font: %s" % ALMENDRA_FONT_PATH)
	return font


static func apply_to_label(label: Label) -> void:
	if label == null:
		return

	var font := get_almendra_font()
	if font != null:
		label.add_theme_font_override("font", font)


static func apply_to_button(button: Button) -> void:
	if button == null:
		return

	var font := get_almendra_font()
	if font != null:
		button.add_theme_font_override("font", font)


static func apply_to_line_edit(line_edit: LineEdit) -> void:
	if line_edit == null:
		return

	var font := get_almendra_font()
	if font != null:
		line_edit.add_theme_font_override("font", font)


static func apply_to_text_edit(text_edit: TextEdit) -> void:
	if text_edit == null:
		return

	var font := get_almendra_font()
	if font != null:
		text_edit.add_theme_font_override("font", font)
