class_name PlayerOcclusionSilhouette
extends Node

## Adds depth-tested passes to the player's authoritative animated meshes.

const FILL_SHADER_PATH := "res://player/visibility/player_occlusion_fill.gdshader"
const MASK_SHADER_PATH := "res://player/visibility/player_occlusion_mask.gdshader"
const OUTLINE_SHADER_PATH := "res://player/visibility/player_occlusion_outline.gdshader"

## Imported character subtree within the owning Player whose meshes supply the silhouette.
@export var player_visual_root_path: NodePath = ^"../Pivot/Character"
## Enables the obstruction-only silhouette for immediate with/without comparison.
@export var visibility_enabled := true
## Dark flat fill that remains readable against pale obstructions.
@export var silhouette_fill_colour := Color(0.055, 0.16, 0.22, 1.0)
## Bright border that remains readable against dark obstructions.
@export var silhouette_outline_colour := Color(1.0, 0.78, 0.15, 1.0)
## World-space expansion used to form the bright border around the player.
@export_range(0.005, 0.15, 0.005, "or_greater", "suffix:m") var outline_width := 0.035
## Minimum world-space separation before scenery counts as being in front of the player.
@export_range(0.0, 0.2, 0.001, "or_greater", "suffix:m") var occlusion_depth_bias := 0.015

@onready var player_visual_root := get_node_or_null(player_visual_root_path) as Node3D

var _source_meshes: Array[MeshInstance3D] = []
var _source_overlays: Array[Material] = []
var _applied_overlays: Array[Material] = []
var _fill_material: ShaderMaterial
var _mask_material: ShaderMaterial
var _outline_material: ShaderMaterial


func _ready() -> void:
	_build_materials()
	if player_visual_root != null:
		_collect_source_meshes(player_visual_root)
		_build_silhouette_overlays()
	_apply_visibility()


func _exit_tree() -> void:
	_release_silhouette_overlays()


## Enables or disables the optional overlay without touching authored player materials.
func set_visibility_enabled(enabled: bool) -> void:
	visibility_enabled = enabled
	_apply_visibility()


## Returns how many authoritative player meshes receive the additional depth-only passes.
func get_silhouette_mesh_count() -> int:
	return _source_meshes.size()


## Returns whether the obstruction-only overlay is armed for depth testing.
func is_silhouette_active() -> bool:
	return visibility_enabled and not _source_meshes.is_empty()


## Returns the concise state displayed by the human-test fixture.
func get_visibility_status_name() -> String:
	if player_visual_root == null:
		return "player visuals unavailable"
	if _source_meshes.is_empty():
		return "no player meshes found"
	return "depth silhouette armed" if visibility_enabled else "disabled for comparison"


func _build_materials() -> void:
	_fill_material = ShaderMaterial.new()
	_mask_material = ShaderMaterial.new()
	_outline_material = ShaderMaterial.new()
	_mask_material.render_priority = 0
	_outline_material.render_priority = 1
	_fill_material.render_priority = 2
	_mask_material.next_pass = _outline_material
	_outline_material.next_pass = _fill_material
	if DisplayServer.get_name() == "headless":
		return
	_fill_material.shader = load(FILL_SHADER_PATH) as Shader
	_mask_material.shader = load(MASK_SHADER_PATH) as Shader
	_outline_material.shader = load(OUTLINE_SHADER_PATH) as Shader
	_fill_material.set_shader_parameter(&"silhouette_colour", silhouette_fill_colour)
	_fill_material.set_shader_parameter(&"occlusion_depth_bias", occlusion_depth_bias)
	_mask_material.set_shader_parameter(&"visible_surface_bias", occlusion_depth_bias)
	_outline_material.set_shader_parameter(&"outline_colour", silhouette_outline_colour)
	_outline_material.set_shader_parameter(&"outline_width", outline_width)
	_outline_material.set_shader_parameter(&"occlusion_depth_bias", occlusion_depth_bias)


func _collect_source_meshes(node: Node) -> void:
	if node is MeshInstance3D:
		var mesh_instance := node as MeshInstance3D
		if mesh_instance.mesh != null:
			_source_meshes.append(mesh_instance)
			_source_overlays.append(mesh_instance.material_overlay)
	for child in node.get_children():
		_collect_source_meshes(child)


func _build_silhouette_overlays() -> void:
	for source_overlay in _source_overlays:
		_applied_overlays.append(_append_silhouette_passes(source_overlay))


func _append_silhouette_passes(source_overlay: Material) -> Material:
	if source_overlay == null:
		return _mask_material
	var overlay_copy := source_overlay.duplicate(true) as Material
	var final_pass := overlay_copy
	while final_pass.next_pass != null:
		final_pass = final_pass.next_pass
	final_pass.next_pass = _mask_material
	return overlay_copy


func _apply_visibility() -> void:
	for index in _source_meshes.size():
		var source_mesh := _source_meshes[index]
		if not is_instance_valid(source_mesh):
			continue
		var source_overlay := _source_overlays[index]
		var applied_overlay := _applied_overlays[index]
		if visibility_enabled:
			if source_mesh.material_overlay == source_overlay:
				source_mesh.material_overlay = applied_overlay
		elif source_mesh.material_overlay == applied_overlay:
			source_mesh.material_overlay = source_overlay


func _release_silhouette_overlays() -> void:
	for index in _source_meshes.size():
		var source_mesh := _source_meshes[index]
		if is_instance_valid(source_mesh) \
				and source_mesh.material_overlay == _applied_overlays[index]:
			source_mesh.material_overlay = _source_overlays[index]
	_source_meshes.clear()
	_source_overlays.clear()
	_applied_overlays.clear()
