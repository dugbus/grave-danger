extends Control


# Scene loaded when the player starts the game.
const GAME_SCENE := "res://graveyard.tscn"

# Image shown full-screen behind the title screen.
@export var title_texture: Texture2D
@export var fade_in_duration := 0.8

# Prevent multiple scene changes from repeated input events.
var starting := false


func _ready() -> void:
	# This runs once when the title screen enters the scene.

	_create_title_image()
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


func _create_title_image() -> void:
	# Create a full-screen image using the exported title texture.

	var title_image := TextureRect.new()
	title_image.name = "TitleImage"
	title_image.texture = title_texture
	title_image.set_anchors_preset(Control.PRESET_FULL_RECT)
	title_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	title_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	title_image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(title_image)


func _start_game() -> void:
	# Switch from the title screen to the playable graveyard scene.

	starting = true
	get_tree().change_scene_to_file(GAME_SCENE)


func _fade_in_title() -> void:
	var fade := ColorRect.new()
	fade.name = "TitleFade"
	fade.color = Color.BLACK
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(fade)

	var tween := create_tween()
	tween.tween_property(fade, "color:a", 0.0, fade_in_duration)
	tween.finished.connect(fade.queue_free)
