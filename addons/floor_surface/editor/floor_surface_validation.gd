@tool
class_name FloorSurfaceValidation
extends RefCounted

## Collects visible authoring diagnostics and prepares conservative ramp-only repairs.

const SURFACE_SCRIPT := preload("res://addons/floor_surface/floor_surface.gd")
const GROUNDING_EDITOR := preload(
	"res://addons/floor_surface/editor/floor_surface_grounding_editor.gd"
)


## Reports resource, material, slope, transform and targeted grounding problems.
static func collect(scene_root: Node, surface: SURFACE_SCRIPT) -> Array[String]:
	var diagnostics: Array[String] = []
	if surface == null:
		diagnostics.append("No FloorSurface is selected.")
		return diagnostics
	diagnostics.append_array(surface.validate_configuration())
	for grounding in GROUNDING_EDITOR.find_for_surface(scene_root, surface):
		var target := grounding.get_parent() as Node3D
		var prefix := "%s: " % (target.name if target != null else "Grounded object")
		for error in grounding.validate_grounding():
			diagnostics.append(prefix + error)
	return diagnostics


## Returns a transition snapshot with only currently invalid ramps changed to Flat.
static func plan_safe_ramp_repair(surface: SURFACE_SCRIPT) -> Dictionary:
	if surface == null or surface.floor_map == null:
		return {"before": {}, "after": {}, "repaired_cells": [] as Array[Vector2i]}
	var before := surface.floor_map.get_transition_snapshot()
	var after := before.duplicate(true)
	var transitions := after.get(
		"transition_overrides",
		{} as Dictionary[Vector2i, int]
	) as Dictionary[Vector2i, int]
	var low_edges := after.get(
		"low_edge_overrides",
		{} as Dictionary[Vector2i, int]
	) as Dictionary[Vector2i, int]
	var repaired_cells: Array[Vector2i] = []
	for cell_value in transitions.keys():
		var cell := cell_value as Vector2i
		if not surface.get_transition_error(cell).is_empty():
			transitions.erase(cell)
			low_edges.erase(cell)
			repaired_cells.append(cell)
	repaired_cells.sort_custom(_is_cell_before)
	after["transition_overrides"] = transitions
	after["low_edge_overrides"] = low_edges
	return {"before": before, "after": after, "repaired_cells": repaired_cells}


## Formats a stable report for the dock's persistent diagnostics area.
static func format_report(diagnostics: Array[String]) -> String:
	if diagnostics.is_empty():
		return "No authoring problems found."
	var lines := PackedStringArray(["%d authoring issue%s:" % [
		diagnostics.size(),
		"" if diagnostics.size() == 1 else "s",
	]])
	for diagnostic in diagnostics:
		lines.append("• %s" % diagnostic)
	return "\n".join(lines)


static func _is_cell_before(left: Vector2i, right: Vector2i) -> bool:
	return left.y < right.y or (left.y == right.y and left.x < right.x)

