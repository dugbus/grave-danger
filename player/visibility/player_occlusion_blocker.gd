class_name PlayerOcclusionBlocker
extends Node
## Prevents the player's through-scenery silhouette from drawing over this visual.


const BLOCKER_SHADER_PATH := "res://player/visibility/player_occlusion_blocker.gdshader"
const BLOCKER_RENDER_PRIORITY := -1

## Visual subtree whose meshes should remain in front of the occluded player silhouette.
@export var occluder_visual_root_path: NodePath = ^"../Character"
## Enables stencil blocking without changing the visual's authored materials.
@export var blocking_enabled := true

@onready var occluder_visual_root := get_node_or_null(occluder_visual_root_path) as Node3D

var _source_meshes: Array[MeshInstance3D] = []
var _source_overlays: Array[Material] = []
var _applied_overlays: Array[Material] = []
var _blocker_material: ShaderMaterial


func _ready() -> void:
	_build_material()
	if occluder_visual_root != null:
		_collect_source_meshes(occluder_visual_root)
		_build_blocker_overlays()
	_apply_blocking()


func _exit_tree() -> void:
	_release_blocker_overlays()


## Enables or disables silhouette blocking while preserving authored overlays.
func set_blocking_enabled(enabled: bool) -> void:
	blocking_enabled = enabled
	_apply_blocking()


## Returns how many visual meshes participate in silhouette blocking.
func get_blocked_mesh_count() -> int:
	return _source_meshes.size()


## Returns whether this component currently blocks the player silhouette.
func is_blocking_active() -> bool:
	return blocking_enabled and not _source_meshes.is_empty()


func _build_material() -> void:
	_blocker_material = ShaderMaterial.new()
	_blocker_material.render_priority = BLOCKER_RENDER_PRIORITY
	if DisplayServer.get_name() != "headless":
		_blocker_material.shader = load(BLOCKER_SHADER_PATH) as Shader


func _collect_source_meshes(node: Node) -> void:
	if node is MeshInstance3D:
		var mesh_instance := node as MeshInstance3D
		if mesh_instance.mesh != null:
			_source_meshes.append(mesh_instance)
			_source_overlays.append(mesh_instance.material_overlay)
	for child in node.get_children():
		_collect_source_meshes(child)


func _build_blocker_overlays() -> void:
	for source_overlay in _source_overlays:
		_applied_overlays.append(_append_blocker_pass(source_overlay))


func _append_blocker_pass(source_overlay: Material) -> Material:
	if source_overlay == null:
		return _blocker_material
	var overlay_copy := source_overlay.duplicate(true) as Material
	var final_pass := overlay_copy
	while final_pass.next_pass != null:
		final_pass = final_pass.next_pass
	final_pass.next_pass = _blocker_material
	return overlay_copy


func _apply_blocking() -> void:
	for index in _source_meshes.size():
		var source_mesh := _source_meshes[index]
		if not is_instance_valid(source_mesh):
			continue
		var source_overlay := _source_overlays[index]
		var applied_overlay := _applied_overlays[index]
		if blocking_enabled and source_mesh.material_overlay == source_overlay:
			source_mesh.material_overlay = applied_overlay
		elif not blocking_enabled and source_mesh.material_overlay == applied_overlay:
			source_mesh.material_overlay = source_overlay


func _release_blocker_overlays() -> void:
	for index in _source_meshes.size():
		var source_mesh := _source_meshes[index]
		if is_instance_valid(source_mesh) \
				and source_mesh.material_overlay == _applied_overlays[index]:
			source_mesh.material_overlay = _source_overlays[index]
	_source_meshes.clear()
	_source_overlays.clear()
	_applied_overlays.clear()
