@tool
class_name FloorSurfaceGrounding
extends Node

## Conforms its Node3D parent to an authoritative FloorSurface on explicit request.

const SURFACE_SCRIPT := preload("res://addons/floor_surface/floor_surface.gd")

enum GroundingMode {
	Upright,
	AlignNormal,
	Absolute,
}

## FloorSurface sampled below the parent's authored X/Z position.
@export_node_path("FloorSurface") var surface_path: NodePath:
	set(value):
		_disconnect_surface()
		surface_path = value
		_connect_surface()
		update_configuration_warnings()
## Upright preserves vertical orientation, Align Normal follows slopes, and Absolute never moves.
@export var grounding_mode := GroundingMode.Upright:
	set(value):
		grounding_mode = value
		update_configuration_warnings()
## World-up distance retained above the sampled floor height during every conform.
@export var height_offset := 0.0
## Deliberate world-space heading retained when Upright or Align Normal is conformed repeatedly.
@export_range(-PI, PI, 0.001, "radians_as_degrees") var heading_radians := 0.0
## Editor-visible warning state set when the supporting FloorSurface changes after conforming.
@export var grounding_stale := true:
	set(value):
		grounding_stale = value
		update_configuration_warnings()

var _connected_surface: SURFACE_SCRIPT


func _ready() -> void:
	_connect_surface()
	update_configuration_warnings()


func _exit_tree() -> void:
	_disconnect_surface()


## Returns the explicitly assigned typed FloorSurface, or null when the path is unresolved.
func get_surface() -> SURFACE_SCRIPT:
	if surface_path.is_empty():
		return null
	return get_node_or_null(surface_path) as SURFACE_SCRIPT


## Calculates a conform transform without mutating the parent.
func calculate_conform_transform() -> Dictionary:
	var target := get_parent() as Node3D
	if target == null:
		return {"valid": false, "error": "Grounding must be a child of a Node3D."}
	var current_transform := target.global_transform if target.is_inside_tree() else target.transform
	if grounding_mode == GroundingMode.Absolute:
		return {"valid": true, "transform": current_transform}
	var surface := get_surface()
	if surface == null:
		return {"valid": false, "error": "Grounding needs a valid FloorSurface path."}
	var sample_position := current_transform.origin
	var sample := surface.sample_surface(sample_position)
	if not sample.valid:
		return {
			"valid": false,
			"error": "No floor exists below %s (cell %s)." % [target.name, sample.cell],
		}
	var up := Vector3.UP
	if grounding_mode == GroundingMode.AlignNormal:
		up = sample.surface_normal.normalized()
	var forward := Vector3.FORWARD.rotated(Vector3.UP, heading_radians)
	forward = (forward - up * forward.dot(up)).normalized()
	if forward.is_zero_approx():
		forward = Vector3.FORWARD
	var right := forward.cross(up).normalized()
	var scale := current_transform.basis.get_scale()
	var conformed_basis := Basis(right * scale.x, up * scale.y, -forward * scale.z)
	var conformed_origin := current_transform.origin
	conformed_origin.y = sample.world_height + height_offset
	return {
		"valid": true,
		"transform": Transform3D(conformed_basis, conformed_origin),
	}


## Applies a transform and stale flag; this named method is also used by editor undo/redo.
func apply_grounding_state(new_transform: Transform3D, stale: bool) -> void:
	var target := get_parent() as Node3D
	if target == null:
		return
	if target.is_inside_tree():
		target.global_transform = new_transform
	else:
		target.transform = new_transform
	grounding_stale = stale


## Explicitly conforms the parent, returning false without moving it over holes or missing data.
func conform() -> bool:
	var result := calculate_conform_transform()
	if not (result.get("valid", false) as bool):
		update_configuration_warnings()
		return false
	apply_grounding_state(result["transform"] as Transform3D, false)
	return true


## Reports missing dependencies, absent support and stale placement in the Inspector.
func validate_grounding() -> Array[String]:
	var errors: Array[String] = []
	var result := calculate_conform_transform()
	if not (result.get("valid", false) as bool):
		errors.append(result.get("error", "Grounding cannot be conformed.") as String)
		return errors
	if grounding_mode != GroundingMode.Absolute and grounding_stale:
		errors.append("Supporting floor changed; use Conform Grounded Objects in the Floor Surface dock.")
	return errors


func _get_configuration_warnings() -> PackedStringArray:
	return PackedStringArray(validate_grounding())


func _connect_surface() -> void:
	if not is_inside_tree():
		return
	var surface := get_surface()
	if surface == _connected_surface:
		return
	_disconnect_surface()
	_connected_surface = surface
	if _connected_surface != null \
			and not _connected_surface.surface_rebuilt.is_connected(_on_surface_rebuilt):
		_connected_surface.surface_rebuilt.connect(_on_surface_rebuilt)


func _disconnect_surface() -> void:
	if _connected_surface != null \
			and _connected_surface.surface_rebuilt.is_connected(_on_surface_rebuilt):
		_connected_surface.surface_rebuilt.disconnect(_on_surface_rebuilt)
	_connected_surface = null


func _on_surface_rebuilt(_cell_count: int) -> void:
	if grounding_mode != GroundingMode.Absolute:
		grounding_stale = true
