@tool
extends Node3D
class_name GDFlaskBase


const DRINKING_SOUND := preload("res://Assets/audio/drinking-liquid.mp3")
const LIQUID_MATERIAL_NAME := "FlaskLiquidMaterial"
const FLASK_PROPERTIES := preload("res://collectibles/global_flask_properties.tres")

@export_group("Global Properties")
@export var global_flask_properties: GDGlobalFlaskProperties:
	get:
		return FLASK_PROPERTIES
	set(_value):
		pass
@export_group("Visuals")
@export var liquid_color := Color.WHITE:
	set(value):
		liquid_color = value
		if is_inside_tree():
			_apply_liquid_color()
@export_range(0.0, 8.0, 0.05) var liquid_emission_energy := 1.35:
	set(value):
		liquid_emission_energy = maxf(value, 0.0)
		if is_inside_tree():
			_apply_liquid_color()
@export var spin_speed := 0.9
@export var bob_height := 0.045
@export var bob_speed := 2.8
@export var collect_shrink_duration := 0.24
@export var pickup_volume_db := 8.0
@export_group("HUD")
@export var hud_effect_id: StringName = &""
@export var show_hud_countdown := false

@onready var visual: Node3D = $Visual
@onready var pickup_area: Area3D = $PickupArea

var is_being_collected := false
var elapsed := 0.0
var visual_base_y := 0.0
var candidate_bodies: Array[Node3D] = []


func _ready() -> void:
	if Engine.is_editor_hint():
		_apply_liquid_color()
		set_process(false)
		set_physics_process(false)
		return

	add_to_group("flask_pickup")
	visual_base_y = visual.position.y
	pickup_area.body_entered.connect(_on_pickup_area_body_entered)
	pickup_area.body_exited.connect(_on_pickup_area_body_exited)
	_apply_liquid_color()


func _process(delta: float) -> void:
	elapsed += delta
	visual.rotation.y += spin_speed * delta
	var bob_offset := (sin(elapsed * bob_speed) + 1.0) * 0.5 * bob_height
	visual.position.y = visual_base_y + bob_offset


func _physics_process(_delta: float) -> void:
	if is_being_collected:
		return

	for body in candidate_bodies.duplicate():
		if not is_instance_valid(body):
			candidate_bodies.erase(body)
			continue
		if _try_collect(body):
			return


func _apply_effect(_body: Node3D) -> bool:
	return false


func _get_hud_countdown_seconds() -> float:
	return 0.0


func _get_kill_boundary() -> Node:
	for boundary in get_tree().get_nodes_in_group("kill_boundary"):
		if is_instance_valid(boundary):
			return boundary

	return null


func _on_pickup_area_body_entered(body: Node3D) -> void:
	if not candidate_bodies.has(body):
		candidate_bodies.append(body)
	call_deferred("_try_collect_deferred", body)


func _on_pickup_area_body_exited(body: Node3D) -> void:
	candidate_bodies.erase(body)


func _try_collect(body: Node3D) -> bool:
	if is_being_collected:
		return false
	if body.has_method("is_dead") and body.is_dead():
		return false

	is_being_collected = true
	if _apply_effect(body):
		_show_hud_countdown(body)
		_collect()
		return true

	is_being_collected = false
	return false


func _collect() -> void:
	candidate_bodies.clear()
	remove_from_group("flask_pickup")
	set_process(false)
	_disable_pickup_area()
	_play_pickup_sound()

	var tween := create_tween()
	tween.tween_property(
		visual,
		"scale",
		Vector3.ZERO,
		maxf(collect_shrink_duration, 0.01)
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	await tween.finished
	queue_free()


func _disable_pickup_area() -> void:
	if pickup_area == null:
		return

	pickup_area.set_deferred("monitoring", false)
	pickup_area.set_deferred("monitorable", false)
	pickup_area.set_deferred("collision_layer", 0)
	pickup_area.set_deferred("collision_mask", 0)


func _play_pickup_sound() -> void:
	var audio_parent := get_tree().current_scene
	if audio_parent == null:
		audio_parent = get_parent()
	GDAudio.play_one_shot(audio_parent, DRINKING_SOUND, "FlaskPickupAudio", pickup_volume_db)


func _show_hud_countdown(body: Node3D) -> void:
	if not show_hud_countdown:
		return

	var duration := _get_hud_countdown_seconds()
	if duration <= 0.0:
		return

	var effect_id := hud_effect_id
	if effect_id == &"":
		effect_id = StringName(name)
	if body.has_method("show_flask_effect_countdown"):
		body.show_flask_effect_countdown(effect_id, liquid_color, duration)
	else:
		get_tree().call_group("active_flask_hud", "show_flask_effect", effect_id, liquid_color, duration)


func _apply_liquid_color() -> void:
	var visual_node := _get_visual_node()
	if visual_node == null:
		return

	_apply_liquid_color_to_node(visual_node)


func _apply_liquid_color_to_node(node: Node) -> void:
	if node is MeshInstance3D:
		_apply_liquid_color_to_mesh(node as MeshInstance3D)

	for child in node.get_children():
		_apply_liquid_color_to_node(child)


func _apply_liquid_color_to_mesh(mesh_instance: MeshInstance3D) -> void:
	if mesh_instance.mesh == null:
		return

	for surface_index in mesh_instance.mesh.get_surface_count():
		var surface_material := mesh_instance.get_active_material(surface_index)
		if not _is_liquid_material(surface_material):
			continue

		var color_material := surface_material.duplicate() as Material
		if color_material is BaseMaterial3D:
			var base_material := color_material as BaseMaterial3D
			base_material.albedo_color = liquid_color
			base_material.emission_enabled = true
			base_material.emission = liquid_color
			base_material.emission_energy_multiplier = liquid_emission_energy
		mesh_instance.set_surface_override_material(surface_index, color_material)


func _is_liquid_material(material: Material) -> bool:
	return material != null and material.resource_name == LIQUID_MATERIAL_NAME


func _try_collect_deferred(body: Node3D) -> void:
	if not candidate_bodies.has(body):
		return

	_try_collect(body)


func _get_visual_node() -> Node3D:
	if visual != null:
		return visual

	return get_node_or_null(^"Visual") as Node3D
