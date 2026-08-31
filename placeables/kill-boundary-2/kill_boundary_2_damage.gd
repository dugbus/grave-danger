@tool
class_name GDKillBoundary2Damage
extends Node3D

## Lethal volumes and distance-based damage driven by canonical geometry.

const LETHAL_SEGMENT := preload("res://placeables/kill-boundary-2/boundary_lethal_segment.tscn")
const FLAME_VULNERABLE_GROUP: StringName = &"flame_vulnerable"

var settings: GDKillBoundary2Settings
var geometry: GDKillBoundary2Geometry
var render_effect := GDKillBoundary2Settings.RenderEffect.Flame
var segments: Array[Area3D] = []
var touching_bodies: Array[Node3D] = []
var effects_enabled := true


func configure(
	new_settings: GDKillBoundary2Settings, new_geometry: GDKillBoundary2Geometry
) -> void:
	settings = new_settings
	geometry = new_geometry
	_ensure_count()


func set_render_effect(value: GDKillBoundary2Settings.RenderEffect) -> void:
	render_effect = value


func set_effects_enabled(value: bool) -> void:
	effects_enabled = value
	for area in segments:
		area.monitoring = value
		var collision := area.get_node(^"CollisionShape3D") as CollisionShape3D
		collision.disabled = not value
	if not value:
		touching_bodies.clear()


func apply_geometry(points: PackedVector2Array) -> void:
	if settings == null:
		return
	_ensure_count()
	for index in points.size():
		var start := points[index]
		var finish := points[(index + 1) % points.size()]
		var delta := finish - start
		var area := segments[index]
		area.position = Vector3(
			(start.x + finish.x) * 0.5,
			settings.flame_y + settings.flame_height * 0.5,
			(start.y + finish.y) * 0.5
		)
		area.rotation = Vector3(0.0, atan2(-delta.y, delta.x), 0.0)
		var collision := area.get_node(^"CollisionShape3D") as CollisionShape3D
		(collision.shape as BoxShape3D).size = Vector3(
			delta.length() + settings.flame_thickness,
			settings.flame_height,
			settings.flame_thickness
		)


func apply_damage(delta: float) -> void:
	if not effects_enabled or geometry == null or settings == null or not is_inside_tree():
		return
	for body_value in get_tree().get_nodes_in_group(FLAME_VULNERABLE_GROUP):
		var body := body_value as Node3D
		if body == null or not is_instance_valid(body):
			continue
		if (
			body.has_method(&"is_immune_to_kill_boundary")
			and bool(body.call(&"is_immune_to_kill_boundary"))
		):
			continue
		if not _is_inside_damage_height(body.global_position):
			continue
		var signed_distance := geometry.get_signed_distance_world(body.global_position)
		var outside_depth := maxf(-signed_distance, 0.0)
		var touching := (
			touching_bodies.has(body) or signed_distance <= settings.flame_damage_inner_depth
		)
		if not touching and outside_depth <= 0.0:
			continue
		var multiplier := 1.0
		if outside_depth > 0.0:
			var outside_ratio := clampf(
				outside_depth / maxf(settings.outside_damage_ramp_depth, 0.001), 0.0, 1.0
			)
			multiplier = lerpf(
				1.0, maxf(settings.max_outside_damage_multiplier, 1.0), outside_ratio
			)
		_apply_damage_to_body(
			body, settings.flame_damage_per_second * multiplier * maxf(delta, 0.0)
		)


func _apply_damage_to_body(body: Node3D, amount: float) -> void:
	var causes_fire_death := render_effect == GDKillBoundary2Settings.RenderEffect.Flame
	if body.has_method(&"apply_kill_boundary_damage"):
		body.call(&"apply_kill_boundary_damage", amount, causes_fire_death)
	elif body.has_method(&"apply_flame_damage"):
		body.call(&"apply_flame_damage", amount)
	elif body.has_method(&"die_from_flames"):
		body.call(&"die_from_flames")


func _is_inside_damage_height(world_position: Vector3) -> bool:
	if geometry == null or geometry.state_root == null:
		return false
	var local_position := geometry.state_root.global_transform.affine_inverse() * world_position
	var margin := maxf(settings.flame_damage_vertical_margin, 0.0)
	return (
		local_position.y >= settings.flame_y - margin
		and local_position.y <= settings.flame_y + settings.flame_height + margin
	)


func _ensure_count() -> void:
	if settings == null:
		return
	while segments.size() < settings.boundary_segments:
		var area := LETHAL_SEGMENT.instantiate() as Area3D
		area.name = "LethalSegment%d" % segments.size()
		area.body_entered.connect(_on_body_entered)
		area.body_exited.connect(_on_body_exited)
		add_child(area)
		segments.append(area)
	while segments.size() > settings.boundary_segments:
		var removed: Area3D = segments.pop_back()
		removed.queue_free()


func _on_body_entered(body: Node3D) -> void:
	if not touching_bodies.has(body):
		touching_bodies.append(body)


func _on_body_exited(body: Node3D) -> void:
	touching_bodies.erase(body)
