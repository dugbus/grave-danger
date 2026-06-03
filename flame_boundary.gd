@tool
extends Node3D
class_name FlameBoundary


const EDITOR_PREVIEW_CONTAINER_NAME := "EditorPreview"
const MOVEMENT_PATH_NAME := "MovementPath"
const BOUNDARY_CENTER_NAME := "BoundaryCenter"
const ANIMATION_PLAYER_NAME := "AnimationPlayer"
const NEAR_FLAMES_SOUND_PATH := "res://Assets/near-the-flames.mp3"

@export_group("Motion")
@export var path_follow_path: NodePath = ^"MovementPath/BoundaryCenter":
	set(value):
		path_follow_path = value
		_sync_boundary()

@export var animation_player_path: NodePath = ^"AnimationPlayer"
@export var animation_name := "flame_boundary"
@export var play_animation_on_start := true

@export_group("Boundary")
@export var bounds_size := Vector2(8.0, 8.0):
	set(value):
		bounds_size = Vector2(maxf(value.x, 0.1), maxf(value.y, 0.1))
		_sync_boundary()

@export_range(0.01, 5.0, 0.01) var flame_thickness := 0.18:
	set(value):
		flame_thickness = maxf(value, 0.01)
		_sync_boundary()

@export_range(0.05, 10.0, 0.05) var flame_height := 1.15:
	set(value):
		flame_height = maxf(value, 0.05)
		_sync_boundary()

@export var flame_y := 0.0:
	set(value):
		flame_y = value
		_sync_boundary()

@export_group("Flame Damage")
@export var flame_damage_per_second := 35.0
@export var flame_damage_inner_depth := 0.35
@export var lethal_flame_depth := 0.8

@export_group("Near Flame Audio")
@export var near_flame_audio_distance := 4.0
@export var near_flame_audio_min_db := -45.0
@export var near_flame_audio_max_db := 8.0
@export_range(0.1, 3.0, 0.05) var near_flame_audio_curve := 0.45
@export var near_flame_audio_lag := 8.0

@export_group("HUD")
@export var show_timer := true


var strip_areas: Array[Area3D] = []
var strip_collisions: Array[CollisionShape3D] = []
var strip_meshes: Array[MeshInstance3D] = []
var preview_meshes: Array[MeshInstance3D] = []
var flame_touching_bodies: Array[Node3D] = []

var flame_material: ShaderMaterial
var preview_material: StandardMaterial3D
var elapsed_time := 0.0
var time_label: Label
var near_flame_audio_player: AudioStreamPlayer


func _ready() -> void:
	_ensure_boundary_nodes()
	_configure_path_follow()
	_create_flame_material()

	if Engine.is_editor_hint():
		_ensure_editor_preview()
		_sync_boundary()
		set_process(true)
		return

	_create_strips()
	if show_timer:
		_create_time_label()
	_create_near_flame_audio()
	_play_start_animation()
	_sync_boundary()


func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		_sync_boundary()


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return

	elapsed_time += delta
	_sync_boundary()
	_apply_flame_heat(delta)
	_update_near_flame_audio(delta)
	_update_time_label()


func get_bounds_center() -> Vector3:
	if not is_inside_tree():
		return position + Vector3(0.0, flame_y, 0.0)

	return _get_center_node().global_transform * Vector3(0.0, flame_y, 0.0)


func get_bounds_transform() -> Transform3D:
	if not is_inside_tree():
		return Transform3D(global_basis, get_bounds_center())

	var bounds_transform := _get_center_node().global_transform
	bounds_transform.origin = bounds_transform * Vector3(0.0, flame_y, 0.0)
	return bounds_transform


func get_bounds_size() -> Vector2:
	return bounds_size


func get_bounds_height() -> float:
	return flame_height


func _play_start_animation() -> void:
	if not play_animation_on_start:
		return

	var animation_player := get_node_or_null(animation_player_path) as AnimationPlayer
	if animation_player == null or not animation_player.has_animation(animation_name):
		return

	#animation_player.play(animation_name)


func _ensure_boundary_nodes() -> void:
	var path := get_node_or_null(MOVEMENT_PATH_NAME) as Path3D
	if path == null:
		path = Path3D.new()
		path.name = MOVEMENT_PATH_NAME
		path.curve = _create_default_curve()
		add_child(path)
		_set_authored_owner(path)
	elif path.curve == null:
		path.curve = _create_default_curve()

	var center := path.get_node_or_null(BOUNDARY_CENTER_NAME) as PathFollow3D
	if center == null:
		center = PathFollow3D.new()
		center.name = BOUNDARY_CENTER_NAME
		path.add_child(center)
		_set_authored_owner(center)

	center.rotation_mode = 0
	center.loop = true

	var animation_player := get_node_or_null(ANIMATION_PLAYER_NAME) as AnimationPlayer
	if animation_player == null:
		animation_player = AnimationPlayer.new()
		animation_player.name = ANIMATION_PLAYER_NAME
		add_child(animation_player)
		_set_authored_owner(animation_player)

	_ensure_default_animation(animation_player)


func _set_authored_owner(node: Node) -> void:
	if not Engine.is_editor_hint():
		return

	var edited_scene_root := get_tree().edited_scene_root
	if edited_scene_root != null and (edited_scene_root == self or edited_scene_root.is_ancestor_of(self)):
		node.owner = edited_scene_root
	elif owner != null:
		node.owner = owner
	else:
		node.owner = self


func _create_default_curve() -> Curve3D:
	var curve := Curve3D.new()
	curve.add_point(Vector3.ZERO)
	curve.add_point(Vector3(4.0, 0.0, 0.0))
	return curve


func _ensure_default_animation(animation_player: AnimationPlayer) -> void:
	if animation_player.has_animation(animation_name):
		return

	var library: AnimationLibrary
	if animation_player.has_animation_library(""):
		library = animation_player.get_animation_library("")
	else:
		library = AnimationLibrary.new()
		animation_player.add_animation_library("", library)

	if library.has_animation(animation_name):
		return

	library.add_animation(animation_name, _create_default_animation())


func _create_default_animation() -> Animation:
	var animation := Animation.new()
	animation.resource_name = animation_name
	animation.length = 8.0
	animation.loop_mode = Animation.LOOP_LINEAR

	var progress_track := animation.add_track(Animation.TYPE_VALUE)
	animation.track_set_path(progress_track, NodePath("%s/%s:progress_ratio" % [MOVEMENT_PATH_NAME, BOUNDARY_CENTER_NAME]))
	animation.track_insert_key(progress_track, 0.0, 0.0)
	animation.track_insert_key(progress_track, animation.length, 1.0)

	var size_track := animation.add_track(Animation.TYPE_VALUE)
	animation.track_set_path(size_track, NodePath(".:bounds_size"))
	animation.track_insert_key(size_track, 0.0, bounds_size)
	animation.track_insert_key(size_track, animation.length, bounds_size)
	return animation


func _configure_path_follow() -> void:
	var path_follow := get_node_or_null(path_follow_path) as PathFollow3D
	if path_follow == null:
		return

	path_follow.rotation_mode = 0
	path_follow.loop = true


func _get_center_node() -> Node3D:
	var center := get_node_or_null(path_follow_path) as Node3D
	if center != null:
		return center

	return self


func _create_flame_material() -> void:
	var shader := Shader.new()
	shader.code = """
shader_type spatial;
render_mode unshaded, blend_add, cull_disabled;

uniform vec4 ember_color : source_color = vec4(1.0, 0.16, 0.01, 0.58);
uniform vec4 flame_color : source_color = vec4(1.0, 0.92, 0.12, 0.88);

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(
		mix(hash(i + vec2(0.0, 0.0)), hash(i + vec2(1.0, 0.0)), u.x),
		mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x),
		u.y
	);
}

void fragment() {
	float vertical = UV.y;
	float edge_fade = smoothstep(0.0, 0.14, vertical) * (1.0 - smoothstep(0.86, 1.0, vertical));
	float lick = noise(vec2(UV.x * 7.0, vertical * 3.0 - TIME * 2.6));
	float tongue = smoothstep(0.22, 0.92, lick + vertical * 0.32);
	vec3 color = mix(ember_color.rgb, flame_color.rgb, tongue);
	ALBEDO = color;
	EMISSION = color * (3.2 + tongue * 3.8);
	ALPHA = edge_fade * mix(ember_color.a, flame_color.a, tongue);
}
"""

	flame_material = ShaderMaterial.new()
	flame_material.shader = shader


func _create_preview_material() -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = Color(1.0, 0.52, 0.04, 0.55)
	material.emission_enabled = true
	material.emission = Color(1.0, 0.4, 0.02)
	material.emission_energy_multiplier = 1.0
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return material


func _ensure_editor_preview() -> void:
	if not Engine.is_editor_hint() or not is_inside_tree():
		return

	preview_material = _create_preview_material()
	var preview_container := _get_or_create_editor_preview_container()
	if preview_meshes.is_empty():
		for child in preview_container.get_children(true):
			preview_container.remove_child(child)
			child.queue_free()

	while preview_meshes.size() < 5:
		var mesh_instance := MeshInstance3D.new()
		mesh_instance.name = "Preview%d" % preview_meshes.size()
		mesh_instance.material_override = preview_material
		preview_container.add_child(mesh_instance, false, Node.INTERNAL_MODE_BACK)
		_lock_editor_preview_node(mesh_instance)
		mesh_instance.owner = null
		preview_meshes.append(mesh_instance)

	for i in 4:
		preview_meshes[i].mesh = QuadMesh.new()

	var center_mesh := SphereMesh.new()
	center_mesh.radius = 0.18
	center_mesh.height = 0.36
	preview_meshes[4].mesh = center_mesh


func _get_or_create_editor_preview_container() -> Node3D:
	var center := _get_center_node()
	var existing := center.get_node_or_null(EDITOR_PREVIEW_CONTAINER_NAME) as Node3D
	if existing != null:
		return existing

	var preview_container := Node3D.new()
	preview_container.name = EDITOR_PREVIEW_CONTAINER_NAME
	center.add_child(preview_container, false, Node.INTERNAL_MODE_BACK)
	_lock_editor_preview_node(preview_container)
	preview_container.owner = null
	return preview_container


func _lock_editor_preview_node(node: Node) -> void:
	node.set_meta("_edit_lock_", true)


func _create_strips() -> void:
	var center := _get_center_node()

	for i in 4:
		var area := Area3D.new()
		area.name = "FlameArea%d" % i
		area.collision_layer = 0
		area.collision_mask = 2
		area.body_entered.connect(_on_flame_body_entered)
		area.body_exited.connect(_on_flame_body_exited)
		center.add_child(area)
		strip_areas.append(area)

		var collision := CollisionShape3D.new()
		collision.name = "FlameCollision%d" % i
		collision.shape = BoxShape3D.new()
		area.add_child(collision)
		strip_collisions.append(collision)

		var mesh_instance := MeshInstance3D.new()
		mesh_instance.name = "FlameMesh%d" % i
		mesh_instance.mesh = QuadMesh.new()
		mesh_instance.material_override = flame_material
		area.add_child(mesh_instance)
		strip_meshes.append(mesh_instance)


func _sync_boundary() -> void:
	if not is_inside_tree():
		return

	if Engine.is_editor_hint():
		if preview_meshes.size() < 5:
			_ensure_editor_preview()
		_update_preview_rect()
		return

	if strip_collisions.size() == 4 and strip_meshes.size() == 4:
		_update_runtime_rect()


func _update_preview_rect() -> void:
	if preview_meshes.size() < 5:
		return

	var no_collisions: Array[CollisionShape3D] = []
	_apply_rect_to_meshes(preview_meshes, no_collisions)
	preview_meshes[4].position = Vector3(0.0, flame_y + 0.18, 0.0)


func _update_runtime_rect() -> void:
	_apply_rect_to_meshes(strip_meshes, strip_collisions)


func _apply_rect_to_meshes(meshes: Array[MeshInstance3D], collisions: Array[CollisionShape3D]) -> void:
	var half_x := bounds_size.x * 0.5
	var half_z := bounds_size.y * 0.5
	var center := Vector3(0.0, flame_y + flame_height * 0.5, 0.0)

	var strip_specs: Array[Dictionary] = [
		{"position": center + Vector3(0.0, 0.0, -half_z), "collision_size": Vector3(bounds_size.x, flame_height, flame_thickness), "visual_size": Vector2(bounds_size.x, flame_height), "rotation": 0.0},
		{"position": center + Vector3(0.0, 0.0, half_z), "collision_size": Vector3(bounds_size.x, flame_height, flame_thickness), "visual_size": Vector2(bounds_size.x, flame_height), "rotation": 0.0},
		{"position": center + Vector3(-half_x, 0.0, 0.0), "collision_size": Vector3(flame_thickness, flame_height, bounds_size.y), "visual_size": Vector2(bounds_size.y, flame_height), "rotation": PI * 0.5},
		{"position": center + Vector3(half_x, 0.0, 0.0), "collision_size": Vector3(flame_thickness, flame_height, bounds_size.y), "visual_size": Vector2(bounds_size.y, flame_height), "rotation": PI * 0.5},
	]

	for i in 4:
		var spec: Dictionary = strip_specs[i]
		var mesh_instance := meshes[i]
		(mesh_instance.mesh as QuadMesh).size = spec["visual_size"]
		mesh_instance.rotation = Vector3(0.0, spec["rotation"], 0.0)

		if collisions.is_empty():
			mesh_instance.position = spec["position"]
			continue

		var collision := collisions[i]
		var area := collision.get_parent() as Area3D
		area.position = spec["position"]
		mesh_instance.position = Vector3.ZERO
		(collision.shape as BoxShape3D).size = spec["collision_size"]


func _create_near_flame_audio() -> void:
	var stream := load(NEAR_FLAMES_SOUND_PATH) as AudioStream
	if stream == null:
		return

	near_flame_audio_player = AudioStreamPlayer.new()
	near_flame_audio_player.name = "NearFlameAudio"
	var loop_stream := stream.duplicate() as AudioStream
	if loop_stream is AudioStreamMP3:
		(loop_stream as AudioStreamMP3).loop = true
	near_flame_audio_player.stream = loop_stream
	near_flame_audio_player.volume_db = near_flame_audio_min_db
	add_child(near_flame_audio_player)
	near_flame_audio_player.play()


func _create_time_label() -> void:
	var canvas_layer := CanvasLayer.new()
	canvas_layer.name = "FlameTimerLayer"
	canvas_layer.layer = 20
	add_child(canvas_layer)

	time_label = Label.new()
	time_label.name = "FlameTimerLabel"
	time_label.position = Vector2(16.0, 48.0)
	time_label.add_theme_font_size_override("font_size", 22)
	time_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.55))
	time_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.85))
	time_label.add_theme_constant_override("shadow_offset_x", 2)
	time_label.add_theme_constant_override("shadow_offset_y", 2)

	canvas_layer.add_child(time_label)


func _update_time_label() -> void:
	if time_label != null:
		time_label.text = "Time %.1fs" % elapsed_time


func _apply_flame_heat(delta: float) -> void:
	for body in get_tree().get_nodes_in_group("flame_vulnerable"):
		if not body is Node3D:
			continue

		var body_3d := body as Node3D
		if not is_instance_valid(body_3d):
			continue

		var outside_depth := _get_outside_flame_depth(body_3d.global_position)
		if outside_depth >= lethal_flame_depth:
			if body_3d.has_method("drain_flame_energy"):
				body_3d.drain_flame_energy()
			elif body_3d.has_method("die_from_flames"):
				body_3d.die_from_flames()
			continue

		var touching_flames := flame_touching_bodies.has(body_3d)
		if not touching_flames and outside_depth <= 0.0:
			var inside_edge_distance := _get_inside_edge_distance(body_3d.global_position)
			touching_flames = inside_edge_distance <= flame_damage_inner_depth

		if not touching_flames and outside_depth <= 0.0:
			continue

		var damage_multiplier := 1.0
		if outside_depth > 0.0:
			damage_multiplier += clampf(outside_depth / maxf(lethal_flame_depth, 0.001), 0.0, 1.0)

		if body_3d.has_method("apply_flame_damage"):
			body_3d.apply_flame_damage(flame_damage_per_second * damage_multiplier * delta)
		elif body_3d.has_method("die_from_flames"):
			body_3d.die_from_flames()


func _update_near_flame_audio(delta: float) -> void:
	if near_flame_audio_player == null:
		return

	var closest_distance := INF
	for body in get_tree().get_nodes_in_group("flame_vulnerable"):
		if not body is Node3D:
			continue

		var body_3d := body as Node3D
		if not is_instance_valid(body_3d):
			continue

		closest_distance = minf(closest_distance, _get_distance_to_flames(body_3d.global_position))

	var target_volume := near_flame_audio_min_db
	if closest_distance < INF:
		var closeness := 1.0 - clampf(closest_distance / maxf(near_flame_audio_distance, 0.001), 0.0, 1.0)
		closeness = pow(closeness, near_flame_audio_curve)
		target_volume = lerpf(near_flame_audio_min_db, near_flame_audio_max_db, closeness)

	var t := 1.0 - exp(-near_flame_audio_lag * delta)
	near_flame_audio_player.volume_db = lerpf(near_flame_audio_player.volume_db, target_volume, t)


func _get_distance_to_flames(world_position: Vector3) -> float:
	var outside_depth := _get_outside_flame_depth(world_position)
	if outside_depth > 0.0:
		return 0.0

	return maxf(_get_inside_edge_distance(world_position), 0.0)


func _get_inside_edge_distance(world_position: Vector3) -> float:
	var local_position: Vector3 = _get_center_node().global_transform.affine_inverse() * world_position
	var half_size := bounds_size * 0.5
	return minf(half_size.x - absf(local_position.x), half_size.y - absf(local_position.z))


func _get_outside_flame_depth(world_position: Vector3) -> float:
	var local_position: Vector3 = _get_center_node().global_transform.affine_inverse() * world_position
	var half_size := bounds_size * 0.5
	var outside := Vector2(maxf(absf(local_position.x) - half_size.x, 0.0), maxf(absf(local_position.z) - half_size.y, 0.0))
	return outside.length()


func _on_flame_body_entered(body: Node3D) -> void:
	if not flame_touching_bodies.has(body):
		flame_touching_bodies.append(body)


func _on_flame_body_exited(body: Node3D) -> void:
	flame_touching_bodies.erase(body)
