class_name GDPlayerDeathEffects
extends Node3D
## Adds brief body spasms plus cause-specific fire or face-tracked blood to the player's death.

const HEAD_LOOK := preload("res://player/player_head_look.gd")
const FACE_ANCHOR := preload("res://player/player_face_anchor.gd")
const FACE_SETTINGS := preload("res://player/player_face_settings.gd")
const DEFAULT_FACE_SETTINGS := preload("res://player/player_face_settings.tres")
const ENVIRONMENT_COLLISION_MASK := 1
const ENVIRONMENT_SPLATTER_DIAMETER := 0.72
const BLOOD_SPLATTER_DECAL := preload("res://player/blood_splatter_decal.tscn")
const BLOOD_SPLATTER_SCRIPT := preload("res://player/blood_splatter_decal.gd")

## Visual pivot rotated additively over the imported death animation.
@export_storage var visual_pivot_path: NodePath = ^"../Pivot"
## Fallback face anchor when the active character has no animated head attachment.
@export_storage var head_path: NodePath = ^"../Pivot/PlayerEffectHead"
## Imported character root whose visible meshes become charred after a fire death.
@export_storage var character_path: NodePath = ^"../Pivot/Character"
## Attention controller disabled at death so its live head turn cannot fight the final pose.
@export_storage var attention_path: NodePath = ^"../PlayerAttention"
## Shared opaque material laid over every character mesh after a fire death.
@export var blackened_material: Material = preload("res://player/fire_death_blackened_material.tres")
## Seconds before the floor mark appears beneath the settling body.
@export_range(0.0, 2.0, 0.01, "suffix:s") var environment_splatter_delay := 0.62

@onready var player := get_parent() as CharacterBody3D
@onready var visual_pivot := get_node_or_null(visual_pivot_path) as Node3D
@onready var head := get_node_or_null(head_path) as Node3D
@onready var character := get_node_or_null(character_path) as Node3D
@onready var attention := get_node_or_null(attention_path) as GDPlayerAttention
@onready var mouth_blood := %MouthBlood as GPUParticles3D
@onready var nose_blood := %NoseBlood as GPUParticles3D
@onready var left_eye_blood := %LeftEyeBlood as GPUParticles3D
@onready var right_eye_blood := %RightEyeBlood as GPUParticles3D
@onready var fire_particles := %FireParticles as GPUParticles3D
@onready var fire_light := %FireLight as OmniLight3D

var face_settings: FACE_SETTINGS = DEFAULT_FACE_SETTINGS
var head_skeleton: Skeleton3D
var head_look: HEAD_LOOK
var head_bone := -1
var head_rest_correction := Transform3D.IDENTITY
var is_playing := false
var base_pivot_rotation := Vector3.ZERO
var throe_tween: Tween
var blood_emitters: Array[GPUParticles3D] = []
var player_splatter: Node3D
var environment_splatter: Node3D
var uses_blood_effects := false


func _ready() -> void:
	process_priority = 110
	blood_emitters = [
		mouth_blood,
		nose_blood,
		left_eye_blood,
		right_eye_blood,
	]
	_cache_head_binding()
	set_process(false)


func _process(_delta: float) -> void:
	if uses_blood_effects:
		_place_blood_emitters()


## Starts the one-way death presentation without replacing the imported death animation.
func play_death_throes(death_cause: GDPlayerDeath.DeathCause) -> void:
	if is_playing:
		return

	var controller := player.get_node_or_null("PlayerAnimation") as GDPlayerAnimation
	if controller != null and controller.active_character != null:
		var animated_head := controller.active_character.find_child("DeathEffectHead", true, false) as Node3D
		if animated_head != null:
			head = animated_head
	_cache_head_binding()
	is_playing = true
	set_process(true)
	if attention != null:
		attention.stop_tracking()
	uses_blood_effects = death_cause != GDPlayerDeath.DeathCause.Fire
	if uses_blood_effects:
		_place_blood_emitters()
		_emit_blood()
		_place_player_splatter()
		_place_environment_splatter_after_settle()
		_play_twitch_sequence()
	else:
		_play_fire_death()
		_play_fire_twitch_sequence()


## Returns the mark attached to the player for tests and future presentation hooks.
func get_player_splatter() -> Node3D:
	return player_splatter


## Returns the mark attached to contacted environment geometry once the body settles.
func get_environment_splatter() -> Node3D:
	return environment_splatter


func _play_fire_death() -> void:
	if character != null:
		for descendant in character.find_children("*", "MeshInstance3D", true, false):
			var character_mesh := descendant as MeshInstance3D
			character_mesh.material_overlay = blackened_material
	if fire_particles != null:
		fire_particles.visible = true
		fire_particles.restart()
	if fire_light != null:
		fire_light.visible = true


# Resolve the selected attachment once; frame updates only read cached transforms.
func _cache_head_binding() -> void:
	face_settings = DEFAULT_FACE_SETTINGS
	if head is FACE_ANCHOR:
		var anchor := head as FACE_ANCHOR
		if anchor.face_settings != null:
			face_settings = anchor.face_settings
	head_skeleton = null
	head_look = null
	head_bone = -1
	head_rest_correction = Transform3D.IDENTITY
	if not head is BoneAttachment3D:
		return
	var attachment := head as BoneAttachment3D
	head_skeleton = attachment.get_parent() as Skeleton3D
	if head_skeleton == null:
		return
	head_bone = head_skeleton.find_bone(attachment.bone_name)
	if head_bone < 0:
		return
	head_look = head_skeleton.get_node_or_null("HeadLook") as HEAD_LOOK
	# Bone axes can differ from character axes; remove the imported rest rotation
	# while retaining all animated head movement, including the death pose.
	head_rest_correction = Transform3D(head_skeleton.get_bone_global_rest(head_bone).basis.inverse(), Vector3.ZERO)


func _face_transform() -> Transform3D:
	var rendered_head := head.global_transform
	if head_look != null and head_look.head_bone == head_bone:
		# Bone attachments may be updated before the final modifier pass.
		# Use the same final bone pose as the mesh for face effects.
		rendered_head = head_skeleton.global_transform * head_look.head_transform
	return rendered_head * head_rest_correction


func _place_blood_emitters() -> void:
	if head == null:
		return

	var face := _face_transform()
	mouth_blood.global_transform = face * Transform3D(Basis.IDENTITY, face_settings.mouth_offset)
	nose_blood.global_transform = face * Transform3D(Basis.IDENTITY, face_settings.nose_offset)
	left_eye_blood.global_transform = face * Transform3D(Basis.IDENTITY, face_settings.left_eye_offset)
	right_eye_blood.global_transform = face * Transform3D(Basis.IDENTITY, face_settings.right_eye_offset)


func _emit_blood() -> void:
	for emitter in blood_emitters:
		if emitter == null:
			continue
		emitter.visible = true
		emitter.restart()


func _place_player_splatter() -> void:
	if head == null or player_splatter != null:
		return

	var face_normal := _face_transform().basis.z.normalized()
	var face_position := _face_transform() * face_settings.splatter_offset
	player_splatter = _create_splatter(
		head,
		face_position,
		face_normal,
		BLOOD_SPLATTER_SCRIPT.SplatterTarget.Player,
		face_settings.splatter_diameter,
		-0.24
	)


func _place_environment_splatter_after_settle() -> void:
	await get_tree().create_timer(maxf(environment_splatter_delay, 0.0)).timeout
	if not is_inside_tree() or environment_splatter != null or player == null:
		return

	var ray_origin := (
		_face_transform() * face_settings.splatter_offset + Vector3.UP * 0.25
		if head != null
		else player.global_position + Vector3.UP
	)
	var query := PhysicsRayQueryParameters3D.create(
		ray_origin, ray_origin + Vector3.DOWN * 2.5, ENVIRONMENT_COLLISION_MASK
	)
	query.exclude = [player.get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return

	var surface := hit.get("collider") as Node3D
	if surface == null:
		return
	var hit_position: Vector3 = hit.get("position", Vector3.ZERO)
	var hit_normal: Vector3 = hit.get("normal", Vector3.UP)
	environment_splatter = _create_splatter(
		surface,
		hit_position + hit_normal * 0.01,
		hit_normal,
		BLOOD_SPLATTER_SCRIPT.SplatterTarget.Environment,
		ENVIRONMENT_SPLATTER_DIAMETER,
		0.31
	)


func _create_splatter(
	surface: Node3D,
	world_position: Vector3,
	surface_normal: Vector3,
	target: BLOOD_SPLATTER_SCRIPT.SplatterTarget,
	splatter_diameter: float,
	twist_radians: float
) -> BLOOD_SPLATTER_SCRIPT:
	var splatter := BLOOD_SPLATTER_DECAL.instantiate() as BLOOD_SPLATTER_SCRIPT
	surface.add_child(splatter)
	splatter.global_transform = Transform3D(_basis_from_surface_normal(surface_normal, twist_radians), world_position)
	splatter.configure_surface(target, splatter_diameter)
	return splatter


func _basis_from_surface_normal(surface_normal: Vector3, twist_radians: float) -> Basis:
	var normal := surface_normal.normalized()
	if normal.is_zero_approx():
		normal = Vector3.UP
	var x_axis := normal.cross(Vector3.FORWARD)
	if x_axis.length_squared() < 0.001:
		x_axis = normal.cross(Vector3.RIGHT)
	x_axis = x_axis.normalized()
	var z_axis := x_axis.cross(normal).normalized()
	return Basis(normal, twist_radians) * Basis(x_axis, normal, z_axis)


func _play_twitch_sequence() -> void:
	if visual_pivot == null:
		return

	_start_throe_tween()
	_append_twitch_pose(Vector3(6.0, -2.0, 8.0), 0.07)
	_append_twitch_pose(Vector3(-4.0, 1.0, -6.0), 0.09)
	throe_tween.tween_interval(0.09)
	_append_twitch_pose(Vector3(4.0, -1.0, 5.0), 0.06)
	_append_twitch_pose(Vector3(-2.0, 0.0, -3.0), 0.08)
	throe_tween.tween_interval(0.18)
	_append_twitch_pose(Vector3(2.5, 0.0, 2.0), 0.05)
	_append_twitch_pose(Vector3(-1.0, 0.0, -1.0), 0.07)
	throe_tween.tween_interval(0.16)
	_append_twitch_pose(Vector3(1.0, 0.0, 0.8), 0.05)
	_append_twitch_pose(Vector3.ZERO, 0.15)


func _play_fire_twitch_sequence() -> void:
	if visual_pivot == null:
		return

	_start_throe_tween()
	_append_twitch_pose(Vector3(18.0, -8.0, 22.0), 0.055)
	_append_twitch_pose(Vector3(-15.0, 7.0, -19.0), 0.065)
	_append_twitch_pose(Vector3(20.0, -5.0, 16.0), 0.055)
	_append_twitch_pose(Vector3(-13.0, 4.0, -16.0), 0.07)
	throe_tween.tween_interval(0.045)
	_append_twitch_pose(Vector3(16.0, -6.0, 14.0), 0.06)
	_append_twitch_pose(Vector3(-11.0, 3.0, -13.0), 0.075)
	throe_tween.tween_interval(0.06)
	_append_twitch_pose(Vector3(13.0, -4.0, 11.0), 0.06)
	_append_twitch_pose(Vector3(-9.0, 2.0, -10.0), 0.075)
	throe_tween.tween_interval(0.08)
	_append_twitch_pose(Vector3(10.0, -3.0, 8.0), 0.06)
	_append_twitch_pose(Vector3(-6.0, 1.0, -7.0), 0.085)
	throe_tween.tween_interval(0.1)
	_append_twitch_pose(Vector3(7.0, -2.0, 5.0), 0.07)
	_append_twitch_pose(Vector3(-4.0, 1.0, -4.0), 0.09)
	throe_tween.tween_interval(0.1)
	_append_twitch_pose(Vector3(4.0, 0.0, 3.0), 0.07)
	_append_twitch_pose(Vector3.ZERO, 0.18)


func _start_throe_tween() -> void:
	if throe_tween != null and throe_tween.is_valid():
		throe_tween.kill()
	base_pivot_rotation = visual_pivot.rotation
	throe_tween = create_tween()
	throe_tween.set_trans(Tween.TRANS_SINE)
	throe_tween.set_ease(Tween.EASE_IN_OUT)


func _append_twitch_pose(target_rotation_degrees: Vector3, duration: float) -> void:
	throe_tween.tween_property(
		visual_pivot,
		"rotation",
		(
			base_pivot_rotation
			+ Vector3(
				deg_to_rad(target_rotation_degrees.x),
				deg_to_rad(target_rotation_degrees.y),
				deg_to_rad(target_rotation_degrees.z)
			)
		),
		duration
	)
