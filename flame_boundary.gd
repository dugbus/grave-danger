extends Node3D


# A list of rectangle states.
# Each state says:
# - where the flame rectangle starts from
# - how wide and deep it is
# - what time it should reach that state
@export var level_states: Array[Dictionary] = [
	{"origin": Vector2(0.0, 0.0), "xsize": 5.0, "ysize": 5.0, "time": 0.0},
	{"origin": Vector2(1.5, 0.75), "xsize": 10.0, "ysize": 10.0, "time": 8.0},
	{"origin": Vector2(-12.0, 1.5), "xsize": 4.5, "ysize": 5.5, "time": 16.0},
	{"origin": Vector2(-8.0, -2.5), "xsize": 7.0, "ysize": 7.0, "time": 32.0},
]

# How thick the flame wall is for collision purposes.
@export var flame_thickness := 0.18

# How tall the flame wall appears.
@export var flame_height := 1.15

# The height above the ground where the flames start.
@export var flame_y := 0.0


# Which timed state we are currently between.
var state_index := 0

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

# The on-screen text showing the timer.
var time_label: Label


func _ready() -> void:
	# This runs once when the node enters the scene.

	_create_flame_material()
	_create_strips()
	_create_time_label()

	if level_states.is_empty():
		_disable_flames()
		return

	# Start using the first state in the list.
	_apply_state(_get_state(0))


func _physics_process(delta: float) -> void:
	# This runs repeatedly during the game.
	# delta is the amount of time since the previous physics frame.

	_update_state(delta)
	_update_time_label()


func _update_state(delta: float) -> void:
	# Move and resize the flame rectangle over time.

	if level_states.is_empty():
		_disable_flames()
		return

	elapsed_time += delta

	# If there is only one state, just use that forever.
	if level_states.size() == 1:
		_apply_state(_get_state(0))
		return

	# If we have gone past the final timed state,
	# stay fixed at the final state.
	var last_state := _get_state(level_states.size() - 1)
	if elapsed_time >= last_state["time"]:
		_apply_state(last_state)
		return

	# Find the two states we are currently between.
	for i in range(level_states.size() - 1):
		var from_state := _get_state(i)
		var to_state := _get_state(i + 1)

		# Skip this pair if the current time is not between them.
		if elapsed_time < from_state["time"] or elapsed_time > to_state["time"]:
			continue

		# Work out how far we are between the two states.
		# 0.0 means at the first state.
		# 1.0 means at the second state.
		var duration := maxf(to_state["time"] - from_state["time"], 0.001)
		var t := clampf((elapsed_time - from_state["time"]) / duration, 0.0, 1.0)

		# Smoothly blend the flame rectangle position and size.
		current_origin = from_state["origin"].lerp(to_state["origin"], t)
		current_size = from_state["size"].lerp(to_state["size"], t)

		state_index = i

		# Apply the new rectangle to the visible flames and collisions.
		_update_rect()
		return


func _get_state(index: int) -> Dictionary:
	# Read one state from level_states and convert it into a consistent format.
	# This also provides safe default values if a field is missing.

	var state := level_states[index]
	return {
		"origin": state.get("origin", Vector2.ZERO),
		"size": Vector2(float(state.get("xsize", 5.0)), float(state.get("ysize", 5.0))),
		"time": float(state.get("time", 0.0)),
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

		# When something enters the flame area,
		# call _on_flame_body_entered().
		area.body_entered.connect(_on_flame_body_entered)

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
		area.global_position = spec["position"]

		(strip_collisions[i].shape as BoxShape3D).size = spec["collision_size"]
		(strip_meshes[i].mesh as QuadMesh).size = spec["visual_size"]
		strip_meshes[i].rotation = Vector3(0.0, spec["rotation"], 0.0)

func _on_flame_body_entered(body: Node3D) -> void:
	# This runs when a body enters one of the flame collision areas.
	#
	# If that body has a function called die_from_flames(),
	# call it. This lets player/enemy objects decide what dying means.

	if body.has_method("die_from_flames"):
		body.die_from_flames()
