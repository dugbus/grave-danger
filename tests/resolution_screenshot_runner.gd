extends SceneTree

## Captures representative UI scenes through resolution-sized off-screen viewports.

const DEFAULT_OUTPUT_ROOT := "res://screenshots"
const PREVIEW_WINDOW_SIZE := Vector2i(960, 540)
const FRAMES_BEFORE_CAPTURE := 3
const DEFAULT_RESOLUTIONS: Array[Vector2i] = [
	Vector2i(960, 540),
	Vector2i(1280, 720),
	Vector2i(1366, 768),
	Vector2i(1440, 900),
	Vector2i(1920, 1080),
	Vector2i(2560, 1080),
	Vector2i(1512, 982),
	Vector2i(3024, 1964),
	Vector2i(3840, 2160),
]
const DEFAULT_SCENES: Array[String] = [
	"res://ui/screens/title_screen.tscn",
	"res://ui/screens/level_select_screen.tscn",
	"res://ui/frontend/settings.tscn",
	"res://ui/frontend/shop.tscn",
	"res://ui/screens/win_screen.tscn",
	"res://ui/screens/lose_screen.tscn",
]
const TREASURE_TYPES: Array[StringName] = [
	&"gold_coin",
	&"gold_bar",
	&"diamond",
	&"ruby",
	&"sapphire",
	&"emerald",
	&"amethyst",
]

var output_root := DEFAULT_OUTPUT_ROOT
var resolutions: Array[Vector2i] = DEFAULT_RESOLUTIONS.duplicate()
var scene_paths: Array[String] = DEFAULT_SCENES.duplicate()
var capture_viewport: SubViewport
var preview_rect: TextureRect
var detached_scene_loader: Node


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var argument_error := _parse_arguments(OS.get_cmdline_user_args())
	if argument_error != OK:
		quit(argument_error)
		return

	_configure_windowed_preview()
	_configure_autoloads_for_capture()
	_create_capture_viewport()

	var failure_count := 0
	for resolution in resolutions:
		var resolution_directory := output_root.path_join("%dx%d" % [resolution.x, resolution.y])
		var directory_error := DirAccess.make_dir_recursive_absolute(
			ProjectSettings.globalize_path(resolution_directory)
		)
		if directory_error != OK:
			push_error(
				(
					"Could not create screenshot directory %s: %s"
					% [resolution_directory, error_string(directory_error)]
				)
			)
			failure_count += scene_paths.size()
			continue

		capture_viewport.size = resolution
		for scene_path in scene_paths:
			var capture_error: Error = await _capture_scene(scene_path, resolution_directory)
			if capture_error != OK:
				failure_count += 1

	_cleanup()
	if failure_count > 0:
		push_error("Resolution screenshots finished with %d failed captures." % failure_count)
		quit(1)
		return

	print(
		(
			"Captured %d UI screenshots in %s"
			% [resolutions.size() * scene_paths.size(), ProjectSettings.globalize_path(output_root)]
		)
	)
	quit()


func _parse_arguments(arguments: PackedStringArray) -> Error:
	for argument in arguments:
		if argument.begins_with("--resolutions="):
			var resolution_error := _parse_resolutions(argument.trim_prefix("--resolutions="))
			if resolution_error != OK:
				return resolution_error
		elif argument.begins_with("--scenes="):
			var scene_error := _parse_scenes(argument.trim_prefix("--scenes="))
			if scene_error != OK:
				return scene_error
		elif argument.begins_with("--output="):
			output_root = argument.trim_prefix("--output=").trim_suffix("/")
			if not output_root.begins_with("res://") and not output_root.begins_with("user://"):
				push_error("Screenshot output must begin with res:// or user://.")
				return ERR_INVALID_PARAMETER
		else:
			push_error("Unknown resolution test option: %s" % argument)
			return ERR_INVALID_PARAMETER
	return OK


func _parse_resolutions(value: String) -> Error:
	var parsed_resolutions: Array[Vector2i] = []
	for entry in value.split(",", false):
		var dimensions := entry.strip_edges().to_lower().split("x", false)
		if (
			dimensions.size() != 2
			or not dimensions[0].is_valid_int()
			or not dimensions[1].is_valid_int()
		):
			push_error("Invalid resolution: %s" % entry)
			return ERR_INVALID_PARAMETER
		var resolution := Vector2i(int(dimensions[0]), int(dimensions[1]))
		if resolution.x <= 0 or resolution.y <= 0:
			push_error("Resolution dimensions must be positive: %s" % entry)
			return ERR_INVALID_PARAMETER
		parsed_resolutions.append(resolution)

	if parsed_resolutions.is_empty():
		push_error("At least one resolution is required.")
		return ERR_INVALID_PARAMETER
	resolutions = parsed_resolutions
	return OK


func _parse_scenes(value: String) -> Error:
	var parsed_scenes: Array[String] = []
	for entry in value.split(",", false):
		var scene_path := entry.strip_edges()
		if not scene_path.begins_with("res://") or not scene_path.ends_with(".tscn"):
			push_error("UI scene paths must use res:// and end with .tscn: %s" % scene_path)
			return ERR_INVALID_PARAMETER
		if not ResourceLoader.exists(scene_path, "PackedScene"):
			push_error("UI scene does not exist: %s" % scene_path)
			return ERR_DOES_NOT_EXIST
		parsed_scenes.append(scene_path)

	if parsed_scenes.is_empty():
		push_error("At least one UI scene is required.")
		return ERR_INVALID_PARAMETER
	scene_paths = parsed_scenes
	return OK


func _configure_windowed_preview() -> void:
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_size(PREVIEW_WINDOW_SIZE)
	get_root().size = PREVIEW_WINDOW_SIZE


func _configure_autoloads_for_capture() -> void:
	var game_settings := get_root().get_node_or_null(^"GameSettings") as GDGameSettings
	if game_settings != null:
		game_settings.persistence_enabled = false
		game_settings.set_music_volume_percent(GDGameSettings.DEFAULT_VOLUME_PERCENT)
		game_settings.set_sound_effect_volume_percent(GDGameSettings.DEFAULT_VOLUME_PERCENT)

	var level_selection := get_root().get_node_or_null(^"LevelSelection") as GDLevelSelection
	if level_selection != null:
		level_selection.persistence_enabled = false

	# UI scenes use SceneLoader only to pre-cache their next destination. Detaching it
	# keeps a layout capture from loading gameplay levels in the background.
	detached_scene_loader = get_root().get_node_or_null(^"SceneLoader")
	if detached_scene_loader != null:
		get_root().remove_child(detached_scene_loader)


func _create_capture_viewport() -> void:
	capture_viewport = SubViewport.new()
	capture_viewport.name = "ResolutionCaptureViewport"
	capture_viewport.disable_3d = true
	capture_viewport.transparent_bg = false
	capture_viewport.render_target_clear_mode = SubViewport.CLEAR_MODE_ALWAYS
	capture_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	get_root().add_child(capture_viewport)

	preview_rect = TextureRect.new()
	preview_rect.name = "ResolutionCapturePreview"
	preview_rect.texture = capture_viewport.get_texture()
	preview_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	preview_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	preview_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	get_root().add_child(preview_rect)


func _capture_scene(scene_path: String, resolution_directory: String) -> Error:
	_prepare_representative_state(scene_path)
	var packed_scene := load(scene_path) as PackedScene
	if packed_scene == null:
		push_error("Could not load UI scene: %s" % scene_path)
		return ERR_CANT_OPEN

	var scene_instance := packed_scene.instantiate()
	_disable_scene_fade(scene_instance)
	capture_viewport.add_child(scene_instance)
	if scene_instance is Control:
		var root_control := scene_instance as Control
		root_control.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	for frame_index in FRAMES_BEFORE_CAPTURE:
		await process_frame
	RenderingServer.force_draw()
	await process_frame

	var image := capture_viewport.get_texture().get_image()
	var screenshot_path := resolution_directory.path_join(
		"%s.png" % scene_path.get_file().get_basename()
	)
	var save_error := image.save_png(ProjectSettings.globalize_path(screenshot_path))
	if save_error == OK:
		print(
			"Captured %s at %dx%d" % [scene_path, capture_viewport.size.x, capture_viewport.size.y]
		)
	else:
		push_error("Could not save %s: %s" % [screenshot_path, error_string(save_error)])

	capture_viewport.remove_child(scene_instance)
	scene_instance.free()
	await process_frame
	return save_error


func _prepare_representative_state(scene_path: String) -> void:
	var level_selection := get_root().get_node_or_null(^"LevelSelection") as GDLevelSelection
	if level_selection != null:
		level_selection.reset_progress()
		var wallet: Dictionary = {}
		for treasure_type in TREASURE_TYPES:
			wallet[String(treasure_type)] = 3
		level_selection.treasure_wallet = wallet

	if not scene_path.ends_with("win_screen.tscn") and not scene_path.ends_with("lose_screen.tscn"):
		return

	var result_stats := get_root().get_node_or_null(^"ResultStats") as GDResultStats
	if result_stats == null:
		return
	result_stats.begin_attempt(100)
	for treasure_type in TREASURE_TYPES:
		result_stats.add_treasure(treasure_type, 10, 1)


func _disable_scene_fade(scene_instance: Node) -> void:
	for property_data in scene_instance.get_property_list():
		var property_name := StringName(property_data.get("name", ""))
		if property_name == &"fade_duration" or property_name == &"fade_in_duration":
			scene_instance.set(property_name, 0.0)


func _cleanup() -> void:
	if is_instance_valid(preview_rect):
		preview_rect.queue_free()
	if is_instance_valid(capture_viewport):
		capture_viewport.queue_free()
	if is_instance_valid(detached_scene_loader):
		get_root().add_child(detached_scene_loader)
