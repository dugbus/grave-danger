extends FogVolume

## Light-reactive atmosphere, owned by the indoor lighting rig and independent of kill-boundary views.
const SETTINGS_TYPE := preload("res://lighting/light_mist/light_mist_settings.gd")
const DEFAULT_SETTINGS := preload("res://lighting/light_mist/light_mist_settings.tres")
const SHADER_PATH := "res://lighting/light_mist/light_mist.gdshader"

## Shared appearance controls for indoor mist; edit this resource to tune the same look across levels.
@export var settings: SETTINGS_TYPE = DEFAULT_SETTINGS:
	set(value):
		if settings == value:
			return
		_disconnect_settings()
		settings = value
		if is_inside_tree():
			_connect_settings()
			if settings == null:
				set_enabled(false)
			else:
				_refresh_settings()

var visual_time := 0.0
var _enabled := false
var _environment_node: WorldEnvironment
var _original_environment: Environment
var _mist_environment: Environment
var _mist_material: ShaderMaterial


func _ready() -> void:
	shape = RenderingServer.FOG_VOLUME_SHAPE_WORLD
	visible = false
	set_process(false)
	_connect_settings()


func configure_environment(environment_node: WorldEnvironment) -> void:
	set_enabled(false)
	_environment_node = environment_node


func set_enabled(value: bool) -> void:
	_enabled = value and is_instance_valid(_environment_node) and settings != null
	if _enabled:
		_enable_environment()
		_prepare_material()
	else:
		_restore_environment()
	visible = _enabled and _mist_material != null
	set_process(_enabled)


func _enable_environment() -> void:
	if _mist_environment != null:
		return
	_original_environment = _environment_node.environment
	_mist_environment = (
		_original_environment.duplicate() as Environment if _original_environment != null else Environment.new()
	)
	_apply_environment_settings()
	_environment_node.environment = _mist_environment


func _apply_environment_settings() -> void:
	_mist_environment.volumetric_fog_enabled = true
	# Density comes only from this noisy volume, so a uniform base layer cannot flatten the room.
	_mist_environment.volumetric_fog_density = 0.0
	_mist_environment.volumetric_fog_emission_energy = 0.0
	_mist_environment.volumetric_fog_ambient_inject = 0.0
	_mist_environment.volumetric_fog_gi_inject = 0.0
	_mist_environment.volumetric_fog_anisotropy = settings.anisotropy
	_mist_environment.volumetric_fog_length = settings.fog_length
	_mist_environment.volumetric_fog_temporal_reprojection_enabled = settings.temporal_blend > 0.0
	_mist_environment.volumetric_fog_temporal_reprojection_amount = settings.temporal_blend


func _prepare_material() -> void:
	if DisplayServer.get_name() == "headless":
		return
	if _mist_material == null:
		_mist_material = ShaderMaterial.new()
		_mist_material.shader = load(SHADER_PATH) as Shader
	_mist_material.set_shader_parameter(&"density", settings.density)
	_mist_material.set_shader_parameter(&"scattering_color", settings.albedo)
	_mist_material.set_shader_parameter(&"noise_scale", settings.noise_scale)
	_mist_material.set_shader_parameter(&"noise_strength", settings.noise_strength)
	_mist_material.set_shader_parameter(&"drift_velocity", settings.drift_velocity)
	_mist_material.set_shader_parameter(&"visual_time", visual_time)
	material = _mist_material


func _connect_settings() -> void:
	if settings != null and not settings.changed.is_connected(_refresh_settings):
		settings.changed.connect(_refresh_settings)


func _disconnect_settings() -> void:
	if settings != null and settings.changed.is_connected(_refresh_settings):
		settings.changed.disconnect(_refresh_settings)


## Runtime resource edits refresh uniforms once, without polling or recreating the environment every frame.
func _refresh_settings() -> void:
	if not _enabled or settings == null:
		return
	_apply_environment_settings()
	_prepare_material()


func _process(delta: float) -> void:
	advance_visual(delta)


## A pause-aware visual clock moves only the noise field, never the player, lights or gameplay timers.
func advance_visual(delta: float) -> void:
	if not _enabled:
		return
	visual_time += maxf(delta, 0.0)
	if _mist_material != null:
		_mist_material.set_shader_parameter(&"visual_time", visual_time)


func _restore_environment() -> void:
	# Respect a replacement environment authored by another system while the mist was active.
	if is_instance_valid(_environment_node) and _environment_node.environment == _mist_environment:
		_environment_node.environment = _original_environment
	_mist_environment = null
	_original_environment = null


func _exit_tree() -> void:
	_disconnect_settings()
	set_enabled(false)
