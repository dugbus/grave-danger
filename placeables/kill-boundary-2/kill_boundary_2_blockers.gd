@tool
class_name GDKillBoundary2Blockers
extends Node3D

## Player-only blocker walls driven by canonical geometry.

const BLOCKER_SEGMENT := preload("res://placeables/kill-boundary-2/boundary_blocker_segment.tscn")
const FLAME_VULNERABLE_GROUP: StringName = &"flame_vulnerable"

var settings: GDKillBoundary2Settings
var blockers: Array[StaticBody3D] = []
var blocking_enabled := true
var effects_enabled := true


func configure(new_settings: GDKillBoundary2Settings) -> void:
	settings = new_settings
	_ensure_count()


func set_blocking_enabled(value: bool) -> void:
	blocking_enabled = value
	update_enabled_state()


func set_effects_enabled(value: bool) -> void:
	effects_enabled = value
	update_enabled_state()


func apply_geometry(points: PackedVector2Array) -> void:
	if settings == null:
		return
	_ensure_count()
	var center_offset := (
		settings.flame_thickness * 0.5
		+ settings.player_blocking_outset
		+ settings.player_blocking_thickness * 0.5
	)
	for index in points.size():
		var start := points[index]
		var finish := points[(index + 1) % points.size()]
		var delta := finish - start
		var outward := Vector2(delta.y, -delta.x).normalized()
		var midpoint := (start + finish) * 0.5 + outward * center_offset
		var blocker := blockers[index]
		blocker.position = Vector3(
			midpoint.x, settings.flame_y + settings.player_blocking_height * 0.5, midpoint.y
		)
		blocker.rotation = Vector3(0.0, atan2(-delta.y, delta.x), 0.0)
		var collision := blocker.get_node(^"CollisionShape3D") as CollisionShape3D
		(collision.shape as BoxShape3D).size = Vector3(
			delta.length() + center_offset * 2.0,
			settings.player_blocking_height,
			settings.player_blocking_thickness
		)
	update_enabled_state()


func update_enabled_state() -> void:
	var disabled := not effects_enabled or not blocking_enabled or _has_dead_vulnerable_body()
	for blocker in blockers:
		var collision := blocker.get_node(^"CollisionShape3D") as CollisionShape3D
		collision.disabled = disabled


func _has_dead_vulnerable_body() -> bool:
	if not is_inside_tree():
		return false
	for body in get_tree().get_nodes_in_group(FLAME_VULNERABLE_GROUP):
		if is_instance_valid(body) and body.has_method(&"is_dead") and bool(body.call(&"is_dead")):
			return true
	return false


func _ensure_count() -> void:
	if settings == null:
		return
	while blockers.size() < settings.boundary_segments:
		var blocker := BLOCKER_SEGMENT.instantiate() as StaticBody3D
		blocker.name = "BlockerSegment%d" % blockers.size()
		add_child(blocker)
		blockers.append(blocker)
	while blockers.size() > settings.boundary_segments:
		var removed: StaticBody3D = blockers.pop_back()
		removed.queue_free()
