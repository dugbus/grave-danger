extends Control
class_name GDTitleScreen


# Scene loaded when the player leaves the title screen.
const LEVEL_SELECT_SCENE := "res://ui/screens/level_select_screen.tscn"
const SCREEN_FADE := preload("res://ui/screens/screen_fade.gd")
const SCENE_LOADER_SCRIPT := preload("res://autoload/scene_loader.gd")

## Optional image shown full-screen when this screen uses a static backdrop.
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
	_precache_first_transition()
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
	# Cinematic title scenes supply their own backdrop in the editor.
	if title_texture == null:
		return
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

	var frontend_audio: Node = get_node_or_null("/root/FrontendAudio")
	if frontend_audio != null:
		frontend_audio.call("play_select")
	starting = true
	var scene_loader := get_node_or_null("/root/SceneLoader") as SCENE_LOADER_SCRIPT
	var change_error := await scene_loader.change_scene_to_file(LEVEL_SELECT_SCENE) \
		if scene_loader != null else get_tree().change_scene_to_file(LEVEL_SELECT_SCENE)
	if change_error != OK:
		starting = false
		push_error("Could not open Level Select: %s" % error_string(change_error))


func _precache_first_transition() -> void:
	# Godot's project-wide parser runs the main scene for --check-only but exits immediately.
	if "--check-only" in OS.get_cmdline_args():
		return
	var scene_loader := get_node_or_null("/root/SceneLoader") as SCENE_LOADER_SCRIPT
	if scene_loader == null:
		return
	# Prepare only the immediate destination. Level Select owns gameplay precaching
	# after it is visible, keeping large level dependency graphs off this transition.
	scene_loader.request_scene(LEVEL_SELECT_SCENE)


func _fade_in_title() -> void:
	SCREEN_FADE.fade_in(self, "TitleFade", fade_in_duration)
