extends Node3D
class_name GDHealthFlask

const DRINKING_SOUND := preload("res://Assets/audio/drinking-liquid.mp3")
const HEAL_PERCENT_SETTING := "gameplay/health_flask_heal_percent"
const DEFAULT_HEAL_PERCENT := 25.0
const HEAL_DURATION := 2.0

@export var spin_speed := 0.9
@export var bob_height := 0.045
@export var bob_speed := 2.8
@export var collect_shrink_duration := 0.24
@export var pickup_volume_db := 8.0

@onready var visual: Node3D = $Visual
@onready var pickup_area: Area3D = $PickupArea

var is_being_collected := false
var elapsed := 0.0
var visual_base_y := 0.0
var candidate_bodies: Array[Node3D] = []


func _ready() -> void:
	add_to_group("health_flask")
	visual_base_y = visual.position.y
	pickup_area.body_entered.connect(_on_pickup_area_body_entered)
	pickup_area.body_exited.connect(_on_pickup_area_body_exited)


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


func _on_pickup_area_body_entered(body: Node3D) -> void:
	if not candidate_bodies.has(body):
		candidate_bodies.append(body)
	_try_collect(body)


func _on_pickup_area_body_exited(body: Node3D) -> void:
	candidate_bodies.erase(body)


func _try_collect(body: Node3D) -> bool:
	if is_being_collected or not body.has_method("try_collect_health_flask"):
		return false

	var heal_percent := float(ProjectSettings.get_setting(HEAL_PERCENT_SETTING, DEFAULT_HEAL_PERCENT))
	if body.try_collect_health_flask(self, heal_percent, HEAL_DURATION):
		_collect()
		return true

	return false


func _collect() -> void:
	is_being_collected = true
	candidate_bodies.clear()
	remove_from_group("health_flask")
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

	pickup_area.monitoring = false
	pickup_area.monitorable = false
	pickup_area.collision_layer = 0
	pickup_area.collision_mask = 0


func _play_pickup_sound() -> void:
	var sound_player := AudioStreamPlayer.new()
	sound_player.name = "HealthPotionAudio"
	sound_player.stream = DRINKING_SOUND
	sound_player.volume_db = pickup_volume_db
	sound_player.finished.connect(sound_player.queue_free)

	var audio_parent := get_tree().current_scene
	if audio_parent == null:
		audio_parent = get_parent()
	audio_parent.add_child(sound_player)
	sound_player.play()
