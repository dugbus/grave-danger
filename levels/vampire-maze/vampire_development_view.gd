extends Node3D
class_name GDVampireDevelopmentView


## Level-only camera used while the development view node is visible.
@export var camera_path: NodePath = ^"Camera3D"
## Vampire-maze indoor environment whose ambient energy is raised for development.
@export var world_environment_path: NodePath = ^"../IndoorLighting/WorldEnvironment"
## Ambient energy applied only while this development view node is visible.
@export_range(0.0, 2.0, 0.01) var development_ambient_energy := 0.24

@onready var camera := get_node_or_null(camera_path) as Camera3D
@onready var world_environment := get_node_or_null(world_environment_path) as WorldEnvironment

var previous_camera: Camera3D
var indoor_environment: Environment
var original_ambient_energy := 0.0


func _enter_tree() -> void:
	var viewport := get_viewport()
	if viewport != null:
		previous_camera = viewport.get_camera_3d()


func _ready() -> void:
	visibility_changed.connect(_apply_development_visibility)
	if world_environment != null and world_environment.environment != null:
		indoor_environment = world_environment.environment.duplicate(true) as Environment
		world_environment.environment = indoor_environment
		original_ambient_energy = indoor_environment.ambient_light_energy
	_apply_development_visibility()


func _apply_development_visibility() -> void:
	var enabled := is_visible_in_tree()
	if indoor_environment != null:
		indoor_environment.ambient_light_energy = development_ambient_energy \
			if enabled else original_ambient_energy

	if camera == null:
		return
	if enabled:
		var active_camera := get_viewport().get_camera_3d()
		if active_camera != null and active_camera != camera:
			previous_camera = active_camera
		camera.make_current()
	elif camera.current:
		camera.current = false
		if is_instance_valid(previous_camera):
			previous_camera.make_current()
