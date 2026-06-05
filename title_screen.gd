extends Control


# Scene loaded when the player leaves the title screen.
const LEVEL_SELECT_SCENE := "res://level_select_screen.tscn"
const SCREEN_FADE := preload("res://screen_fade.gd")

## Image shown full-screen behind the title screen.
@export var title_texture: Texture2D
## Seconds used for the black overlay to fade out when the title screen opens.
@export var fade_in_duration := 0.8

# Prevent multiple scene changes from repeated input events.
var starting := false
var title_image: TextureRect


func _ready() -> void:
	# This runs once when the title screen enters the scene.

	_bind_title_image()
	_fade_in_title()
	set_process_unhandled_input(true)


func _unhandled_input(event: InputEvent) -> void:
	# Accept any keyboard, mouse, or joypad button press to start.

	if starting:
		return

	if event is InputEventKey and event.pressed and not event.echo:
		_start_game()
	elif event is InputEventMouseButton and event.pressed:
		_start_game()
	elif event is InputEventJoypadButton and event.pressed:
		_start_game()


func _bind_title_image() -> void:
	title_image = get_node_or_null("TitleImage") as TextureRect
	if title_image == null:
		title_image = TextureRect.new()
		title_image.name = "TitleImage"
		add_child(title_image)

	if title_texture != null:
		title_image.texture = title_texture
	title_image.set_anchors_preset(Control.PRESET_FULL_RECT)
	title_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	title_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	title_image.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _start_game() -> void:
	# Switch from the title screen to the level selection scene.

	starting = true
	get_tree().change_scene_to_file(LEVEL_SELECT_SCENE)


func _fade_in_title() -> void:
	SCREEN_FADE.fade_in(self, "TitleFade", fade_in_duration)
