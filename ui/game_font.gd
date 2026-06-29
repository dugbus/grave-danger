class_name GDGameFont
extends RefCounted


const ALMENDRA_FONT_PATH := "res://Assets/fonts/Almendra-Bold.ttf"

static var almendra_font: FontFile


static func get_almendra_font() -> FontFile:
	if almendra_font != null:
		return almendra_font

	var font := FontFile.new()
	var load_error := font.load_dynamic_font(ALMENDRA_FONT_PATH)
	if load_error != OK:
		push_warning("Unable to load game font: %s" % ALMENDRA_FONT_PATH)
		return null

	almendra_font = font
	return almendra_font


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
