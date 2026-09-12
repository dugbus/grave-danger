@tool
class_name FloorSurfaceGroundingEditor
extends RefCounted

## Finds and plans explicit grounding updates without coupling runtime objects to EditorPlugin.

const GROUNDING_SCRIPT := preload("res://addons/floor_surface/floor_surface_grounding.gd")
const SURFACE_SCRIPT := preload("res://addons/floor_surface/floor_surface.gd")


## Returns every grounding component in the edited scene that explicitly targets the surface.
static func find_for_surface(scene_root: Node, surface: SURFACE_SCRIPT) -> Array[GROUNDING_SCRIPT]:
	var results: Array[GROUNDING_SCRIPT] = []
	if scene_root == null or surface == null:
		return results
	_collect(scene_root, surface, results)
	return results


## Produces immutable before/after states and actionable errors for one undoable editor action.
static func plan_conform(scene_root: Node, surface: SURFACE_SCRIPT) -> Dictionary:
	var changes: Array[Dictionary] = []
	var errors: Array[String] = []
	for grounding in find_for_surface(scene_root, surface):
		var target := grounding.get_parent() as Node3D
		if target == null:
			errors.append("A grounding component has no Node3D parent.")
			continue
		var result := grounding.calculate_conform_transform()
		if not (result.get("valid", false) as bool):
			errors.append(result.get("error", "Grounding cannot be conformed.") as String)
			continue
		var before_transform := target.global_transform if target.is_inside_tree() else target.transform
		changes.append({
			"grounding": grounding,
			"before_transform": before_transform,
			"before_stale": grounding.grounding_stale,
			"after_transform": result["transform"] as Transform3D,
			"after_stale": false,
		})
	return {"changes": changes, "errors": errors}


static func _collect(
	node: Node,
	surface: SURFACE_SCRIPT,
	results: Array[GROUNDING_SCRIPT]
) -> void:
	if node is GROUNDING_SCRIPT:
		var grounding := node as GROUNDING_SCRIPT
		if grounding.get_surface() == surface:
			results.append(grounding)
	for child in node.get_children():
		_collect(child as Node, surface, results)
