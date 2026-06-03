@tool
extends Node3D


const EDITOR_PREVIEW_LIGHT_NAME := "EditorPreviewFillLight"
const EDITOR_PREVIEW_LIGHT_LAYERS := (1 << 20) - 1

var editor_preview_environment: Environment
var previous_editor_environment: Environment


func _ready() -> void:
	if not Engine.is_editor_hint():
		queue_free()
		return

	call_deferred("_apply_editor_preview_lighting")


func _exit_tree() -> void:
	if Engine.is_editor_hint():
		_restore_editor_environment()


func _apply_editor_preview_lighting() -> void:
	if not is_inside_tree():
		return

	if editor_preview_environment == null:
		editor_preview_environment = Environment.new()

	editor_preview_environment.background_mode = Environment.BG_KEEP
	editor_preview_environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	editor_preview_environment.ambient_light_color = Color(0.86, 0.9, 1.0)
	editor_preview_environment.ambient_light_energy = 0.55

	var world := get_viewport().world_3d
	if world != null and world.environment != editor_preview_environment:
		previous_editor_environment = world.environment
		world.environment = editor_preview_environment

	var fill_light := get_node_or_null(EDITOR_PREVIEW_LIGHT_NAME) as DirectionalLight3D
	if fill_light == null:
		fill_light = DirectionalLight3D.new()
		fill_light.name = EDITOR_PREVIEW_LIGHT_NAME
		add_child(fill_light, false, Node.INTERNAL_MODE_BACK)
		_lock_editor_preview_node(fill_light)
		fill_light.owner = null

	fill_light.rotation_degrees = Vector3(-55.0, 30.0, 0.0)
	fill_light.layers = EDITOR_PREVIEW_LIGHT_LAYERS
	fill_light.light_energy = 0.18
	fill_light.shadow_enabled = false


func _restore_editor_environment() -> void:
	var viewport := get_viewport()
	if viewport == null:
		return

	var world := viewport.world_3d
	if world != null and world.environment == editor_preview_environment:
		world.environment = previous_editor_environment


func _lock_editor_preview_node(node: Node) -> void:
	node.set_meta("_edit_lock_", true)
