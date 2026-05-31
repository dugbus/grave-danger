@tool
extends Node3D


const PATH_PREVIEW_CONTAINER_NAME := "EditorPathPreview"
const PATH_DOT_SPACING := 0.45
const PATH_DOT_RADIUS := 0.07
const PATH_PREVIEW_Y_OFFSET := 0.08
const NEAR_FLAMES_SOUND_PATH := "res://Assets/near-the-flames.mp3"

# Child FlameBoundaryWaypoint nodes define the flame rectangle path.
@export var waypoint_parent_path: NodePath = ^"."

# When enabled, the final waypoint returns to the first one using the first
# waypoint's time/easing settings.
@export var loop := false

# How thick the flame wall is for collision purposes.
@export var flame_thickness := 0.18

# How tall the flame wall appears.
@export var flame_height := 1.15

# The height above the ground where the flames start.
@export var flame_y := 0.0

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


# The waypoint currently being moved from.
var waypoint_index := 0

# The current centre/origin of the flame rectangle.
var current_origin := Vector2.ZERO

# The current size of the flame rectangle.
var current_size := Vector2(5.0, 5.0)

# The visible flame wall objects.
var strip_meshes: Array[MeshInstance3D] = []

# The invisible collision shapes that hurt/kill things.
var strip_collisions: Array[CollisionShape3D] = []

# The material used to make the flame effect.
var flame_material: ShaderMaterial

# How long this object has been running.
var elapsed_time := 0.0

# How long we have spent on the current segment.
var segment_elapsed := 0.0

# Editor-placed waypoints used by the flame controller.
var waypoints: Array[Node] = []

# The on-screen text showing the timer.
var time_label: Label

# Looping audio that rises as the player nears the flame boundary.
var near_flame_audio_player: AudioStreamPlayer

# Bodies currently intersecting a flame strip.
var flame_touching_bodies: Array[Node3D] = []

# Last editor path state used to avoid rebuilding the preview every frame.
var editor_path_snapshot := ""


func _ready() -> void:
	# This runs once when the node enters the scene.

	if Engine.is_editor_hint():
		_refresh_editor_path_preview()
		set_process(true)
		return

	_create_flame_material()
	_create_strips()
	_create_time_label()
	_create_near_flame_audio()
	_collect_waypoints()

	if waypoints.is_empty():
		_disable_flames()
		return

	# Start using the first waypoint in the list.
	_apply_state(_get_waypoint_state(0))


func _process(_delta: float) -> void:
	if not Engine.is_editor_hint():
		return

	var snapshot := _get_editor_path_snapshot()
	if snapshot == editor_path_snapshot:
		return

	_refresh_editor_path_preview(snapshot)


func _physics_process(delta: float) -> void:
	# This runs repeatedly during the game.
	# delta is the amount of time since the previous physics frame.

	if Engine.is_editor_hint():
		return

	_update_state(delta)
	_apply_flame_heat(delta)
	_update_near_flame_audio(delta)
	_update_time_label()


func _update_state(delta: float) -> void:
	# Move and resize the flame rectangle over time.

	if waypoints.is_empty():
		_disable_flames()
		return

	elapsed_time += delta

	# If there is only one waypoint, just use that forever.
	if waypoints.size() == 1:
		_apply_state(_get_waypoint_state(0))
		return

	segment_elapsed += delta
	var next_index := _get_next_waypoint_index()

	while next_index != -1:
		var duration := _get_segment_duration(next_index)
		if segment_elapsed < duration:
			break

		segment_elapsed -= duration
		waypoint_index = next_index
		next_index = _get_next_waypoint_index()

	if next_index == -1:
		_apply_state(_get_waypoint_state(waypoints.size() - 1))
		return

	var from_state := _get_waypoint_state(waypoint_index)
	var to_state := _get_waypoint_state(next_index)

	var t := clampf(segment_elapsed / _get_segment_duration(next_index), 0.0, 1.0)
	var eased_t := _ease_segment(t, next_index)

	current_origin = from_state["origin"].lerp(to_state["origin"], eased_t)
	current_size = from_state["size"].lerp(to_state["size"], eased_t)
	_update_rect()


func _collect_waypoints() -> void:
	waypoints.clear()

	var waypoint_parent := get_node_or_null(waypoint_parent_path)
	if waypoint_parent == null:
		waypoint_parent = self

	for child in waypoint_parent.get_children():
		if child.has_method("get_flame_boundary_origin") and child.has_method("get_flame_boundary_size"):
			waypoints.append(child)


func _get_waypoint_state(index: int) -> Dictionary:
	# Read one waypoint and convert it into a consistent format.

	var waypoint := waypoints[index]
	var local_position: Vector3 = global_transform.affine_inverse() * waypoint.global_position
	return {
		"origin": Vector2(local_position.x, local_position.z),
		"size": waypoint.get_flame_boundary_size(),
		"time": float(waypoint.get("time")),
	}


func _apply_state(state: Dictionary) -> void:
	# Instantly apply one flame rectangle state.

	current_origin = state["origin"]
	current_size = state["size"]
	_update_rect()


func get_bounds_center() -> Vector3:
	return global_transform * Vector3(current_origin.x, flame_y, current_origin.y)


func get_bounds_size() -> Vector2:
	return current_size


func _get_next_waypoint_index() -> int:
	var next_index := waypoint_index + 1
	if next_index < waypoints.size():
		return next_index

	if loop:
		return 0

	return -1


func _get_segment_duration(target_index: int) -> float:
	var state := _get_waypoint_state(target_index)
	return maxf(float(state["time"]), 0.001)


func _ease_segment(t: float, target_index: int) -> float:
	var target := waypoints[target_index]
	if target.has_method("ease_value"):
		return target.ease_value(t)

	return t


func _refresh_editor_path_preview(snapshot := "") -> void:
	if not Engine.is_editor_hint() or not is_inside_tree():
		return

	_collect_waypoints()
	editor_path_snapshot = snapshot if not snapshot.is_empty() else _get_editor_path_snapshot()

	var preview_container := _get_or_create_path_preview_container()
	for child in preview_container.get_children(true):
		preview_container.remove_child(child)
		child.free()

	if waypoints.size() < 2:
		return

	var material := _create_path_preview_material()
	for index in waypoints.size() - 1:
		_add_dotted_path_segment(
			preview_container,
			_get_waypoint_preview_position(waypoints[index]),
			_get_waypoint_preview_position(waypoints[index + 1]),
			material
		)

	if loop:
		_add_dotted_path_segment(
			preview_container,
			_get_waypoint_preview_position(waypoints[waypoints.size() - 1]),
			_get_waypoint_preview_position(waypoints[0]),
			material
		)


func _get_editor_path_snapshot() -> String:
	_collect_waypoints()

	var parts: Array[String] = ["loop=%s" % loop]
	for waypoint in waypoints:
		var local_position := _get_waypoint_preview_position(waypoint)
		parts.append("%s:%.3f,%.3f,%.3f" % [waypoint.name, local_position.x, local_position.y, local_position.z])

	return "|".join(parts)


func _get_waypoint_preview_position(waypoint: Node) -> Vector3:
	var waypoint_3d := waypoint as Node3D
	if waypoint_3d == null:
		return Vector3.ZERO

	var local_position: Vector3 = global_transform.affine_inverse() * waypoint_3d.global_position
	local_position.y = flame_y + PATH_PREVIEW_Y_OFFSET
	return local_position


func _add_dotted_path_segment(parent: Node3D, start: Vector3, end: Vector3, material: Material) -> void:
	var segment := end - start
	var length := segment.length()
	if length <= 0.001:
		return

	var direction := segment / length
	var dot_count := maxi(2, int(ceil(length / PATH_DOT_SPACING)) + 1)
	for index in dot_count:
		var t := float(index) / float(dot_count - 1)
		var dot := MeshInstance3D.new()
		dot.name = "PathDot"
		dot.mesh = _create_path_dot_mesh()
		dot.material_override = material
		dot.position = start + direction * length * t
		parent.add_child(dot, false, Node.INTERNAL_MODE_BACK)
		_lock_editor_preview_node(dot)
		dot.owner = null


func _get_or_create_path_preview_container() -> Node3D:
	var existing := get_node_or_null(PATH_PREVIEW_CONTAINER_NAME) as Node3D
	if existing != null:
		return existing

	var preview_container := Node3D.new()
	preview_container.name = PATH_PREVIEW_CONTAINER_NAME
	add_child(preview_container, false, Node.INTERNAL_MODE_BACK)
	_lock_editor_preview_node(preview_container)
	preview_container.owner = null
	return preview_container


func _create_path_dot_mesh() -> SphereMesh:
	var mesh := SphereMesh.new()
	mesh.radius = PATH_DOT_RADIUS
	mesh.height = PATH_DOT_RADIUS * 2.0
	mesh.radial_segments = 8
	mesh.rings = 4
	return mesh


func _create_path_preview_material() -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = Color(1.0, 0.85, 0.12, 0.8)
	material.emission_enabled = true
	material.emission = Color(1.0, 0.55, 0.04)
	material.emission_energy_multiplier = 1.2
	return material


func _lock_editor_preview_node(node: Node) -> void:
	node.set_meta("_edit_lock_", true)


func _create_flame_material() -> void:
	# Create the visual flame material.
	# This shader makes the flame shimmer and fade like fire.

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


func _create_strips() -> void:
	# Create four flame walls:
	# front, back, left, and right.
	#
	# Each wall has:
	# - an Area3D to detect bodies entering it
	# - a CollisionShape3D for the invisible danger zone
	# - a MeshInstance3D for the visible flame strip

	for i in 4:
		var area := Area3D.new()
		area.name = "FlameArea%d" % i

		# This flame area does not physically block things.
		area.collision_layer = 0

		# It only detects bodies on collision layer 2.
		area.collision_mask = 2

		# Track bodies currently brushing a flame strip. Damage is applied
		# continuously in _apply_flame_heat().
		area.body_entered.connect(_on_flame_body_entered)
		area.body_exited.connect(_on_flame_body_exited)

		add_child(area)

		var collision := CollisionShape3D.new()
		collision.shape = BoxShape3D.new()
		area.add_child(collision)
		strip_collisions.append(collision)

		var mesh_instance := MeshInstance3D.new()
		mesh_instance.name = "FlameMesh%d" % i
		mesh_instance.mesh = QuadMesh.new()
		mesh_instance.material_override = flame_material
		area.add_child(mesh_instance)
		strip_meshes.append(mesh_instance)


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
	# Create a simple timer display on top of the screen.

	var canvas_layer := CanvasLayer.new()
	canvas_layer.layer = 20
	add_child(canvas_layer)

	time_label = Label.new()
	time_label.position = Vector2(16.0, 12.0)

	# Make the timer text readable.
	time_label.add_theme_font_size_override("font_size", 22)
	time_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.55))
	time_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.85))
	time_label.add_theme_constant_override("shadow_offset_x", 2)
	time_label.add_theme_constant_override("shadow_offset_y", 2)

	canvas_layer.add_child(time_label)


func _update_time_label() -> void:
	# Update the on-screen timer text.

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
	var local_position: Vector3 = global_transform.affine_inverse() * world_position
	var offset := Vector2(local_position.x - current_origin.x, local_position.z - current_origin.y)
	var half_size := current_size * 0.5
	return minf(half_size.x - absf(offset.x), half_size.y - absf(offset.y))


func _get_outside_flame_depth(world_position: Vector3) -> float:
	var local_position: Vector3 = global_transform.affine_inverse() * world_position
	var offset := Vector2(local_position.x - current_origin.x, local_position.z - current_origin.y)
	var half_size := current_size * 0.5
	var outside := Vector2(maxf(absf(offset.x) - half_size.x, 0.0), maxf(absf(offset.y) - half_size.y, 0.0))
	return outside.length()


func _disable_flames() -> void:
	visible = false
	set_physics_process(false)

	for collision in strip_collisions:
		collision.disabled = true


func _update_rect() -> void:
	# Rebuild the four flame strips so that they match current_origin and current_size.
	#
	# The rectangle is represented as four separate walls:
	# - north/front edge
	# - south/back edge
	# - west/left edge
	# - east/right edge

	var half_x := current_size.x * 0.5
	var half_z := current_size.y * 0.5

	# Convert the 2D rectangle position into a 3D centre point.
	var center := Vector3(current_origin.x, flame_y + flame_height * 0.5, current_origin.y)

	var strip_specs: Array[Dictionary] = [
		# Front edge.
		{"position": center + Vector3(0.0, 0.0, -half_z), "collision_size": Vector3(current_size.x, flame_height, flame_thickness), "visual_size": Vector2(current_size.x, flame_height), "rotation": 0.0},

		# Back edge.
		{"position": center + Vector3(0.0, 0.0, half_z), "collision_size": Vector3(current_size.x, flame_height, flame_thickness), "visual_size": Vector2(current_size.x, flame_height), "rotation": 0.0},

		# Left edge.
		{"position": center + Vector3(-half_x, 0.0, 0.0), "collision_size": Vector3(flame_thickness, flame_height, current_size.y), "visual_size": Vector2(current_size.y, flame_height), "rotation": PI * 0.5},

		# Right edge.
		{"position": center + Vector3(half_x, 0.0, 0.0), "collision_size": Vector3(flame_thickness, flame_height, current_size.y), "visual_size": Vector2(current_size.y, flame_height), "rotation": PI * 0.5},
	]

	# Apply each strip's position, collision size, visual size, and rotation.
	for i in strip_specs.size():
		var spec: Dictionary = strip_specs[i]

		var area := strip_collisions[i].get_parent() as Area3D
		area.position = spec["position"]

		(strip_collisions[i].shape as BoxShape3D).size = spec["collision_size"]
		(strip_meshes[i].mesh as QuadMesh).size = spec["visual_size"]
		strip_meshes[i].rotation = Vector3(0.0, spec["rotation"], 0.0)

func _on_flame_body_entered(body: Node3D) -> void:
	if not flame_touching_bodies.has(body):
		flame_touching_bodies.append(body)


func _on_flame_body_exited(body: Node3D) -> void:
	flame_touching_bodies.erase(body)
