@tool
extends Node3D


const GOLD_COIN_SCENE := preload("res://gold_coin.tscn")
const PREVIEW_CONTAINER_NAME := "EditorPreviewCoins"

## Total number of coins this pile will spawn.
@export_range(0, 500, 1) var coin_count := 200:
	set(value):
		coin_count = maxi(value, 0)
		_refresh_preview_when_editing()

## Radius of the circular spawn area around this node.
@export_range(0.05, 10.0, 0.05) var pile_radius := 0.5:
	set(value):
		pile_radius = maxf(value, 0.05)
		_refresh_preview_when_editing()

## Height above this node where spawned coins initially appear.
@export_range(0.0, 10.0, 0.05) var spawn_height := 1.0

## Seconds after scene start before this pile begins spawning coins.
@export_range(0.0, 300.0, 0.05) var trigger_time := 0.0

## Seconds between individual coin spawns; zero queues the whole pile at once.
@export_range(0.0, 1.0, 0.005) var spawn_interval := 0.01

## Random seed for repeatable scatter; use 0 for a different scatter each run.
@export var random_seed := 0:
	set(value):
		random_seed = value
		_refresh_preview_when_editing()

var spawn_elapsed := 0.0
var trigger_elapsed := 0.0
var spawned_coins := 0
var spawn_started := false
var spawn_all_queued := false
var rng := RandomNumberGenerator.new()
var preview_mesh: CylinderMesh


func _ready() -> void:
	if Engine.is_editor_hint():
		_refresh_editor_preview()
		return

	if random_seed == 0:
		rng.randomize()
	else:
		rng.seed = random_seed

	spawn_started = trigger_time <= 0.0
	if spawn_started and spawn_interval <= 0.0:
		_queue_spawn_all()


func get_max_coin_count() -> int:
	return coin_count


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return

	if not spawn_started:
		trigger_elapsed += delta
		if trigger_elapsed < trigger_time:
			return

		spawn_started = true

	if spawn_interval <= 0.0:
		_queue_spawn_all()
		return

	if spawned_coins >= coin_count:
		queue_free()
		return

	spawn_elapsed += delta
	while spawn_elapsed >= spawn_interval and spawned_coins < coin_count:
		spawn_elapsed -= spawn_interval
		_spawn_gold_coin()


func _queue_spawn_all() -> void:
	if spawn_all_queued:
		return

	spawn_all_queued = true
	call_deferred("_spawn_all_and_free")


func _spawn_all_and_free() -> void:
	while spawned_coins < coin_count:
		_spawn_gold_coin()
	queue_free()


func _spawn_gold_coin() -> void:
	var gold_coin := GOLD_COIN_SCENE.instantiate() as RigidBody3D
	var spawn_parent := get_parent()
	if spawn_parent == null:
		spawn_parent = get_tree().current_scene
	spawn_parent.add_child(gold_coin)
	spawned_coins += 1

	var local_offset := _random_local_spawn_offset(rng, spawn_height)
	var spawn_transform := Transform3D(
		Basis(Vector3.UP, rng.randf_range(0.0, TAU)),
		global_transform * local_offset
	)

	if gold_coin.has_method("throw_from"):
		gold_coin.throw_from(spawn_transform, Vector3.ZERO)
	else:
		gold_coin.global_transform = spawn_transform

	gold_coin.angular_velocity = Vector3(
		rng.randf_range(-2.0, 2.0),
		rng.randf_range(-2.0, 2.0),
		rng.randf_range(-2.0, 2.0)
	)


func _random_local_spawn_offset(source_rng: RandomNumberGenerator, height: float) -> Vector3:
	var angle := source_rng.randf_range(0.0, TAU)
	var radius := sqrt(source_rng.randf()) * pile_radius
	return Vector3(cos(angle) * radius, height, sin(angle) * radius)


func _refresh_preview_when_editing() -> void:
	if not Engine.is_editor_hint() or not is_inside_tree():
		return

	call_deferred("_refresh_editor_preview")


func _refresh_editor_preview() -> void:
	if not Engine.is_editor_hint() or not is_inside_tree():
		return

	var preview_container := _get_or_create_preview_container()
	for child in preview_container.get_children():
		preview_container.remove_child(child)
		child.free()

	var preview_rng := RandomNumberGenerator.new()
	if random_seed == 0:
		preview_rng.seed = 1337
	else:
		preview_rng.seed = random_seed

	for index in coin_count:
		var coin_preview := MeshInstance3D.new()
		coin_preview.name = "CoinPreview%d" % index
		coin_preview.mesh = _get_preview_mesh()
		coin_preview.transform = Transform3D(
			Basis(Vector3.UP, preview_rng.randf_range(0.0, TAU)),
			_editor_preview_offset(preview_rng, index)
		)
		preview_container.add_child(coin_preview)
		coin_preview.owner = null


func _editor_preview_offset(source_rng: RandomNumberGenerator, index: int) -> Vector3:
	var offset := _random_local_spawn_offset(source_rng, 0.0)
	var center_weight := 1.0 - clampf(Vector2(offset.x, offset.z).length() / pile_radius, 0.0, 1.0)
	offset.y = 0.018 + (center_weight * center_weight * 0.18) + (float(index % 5) * 0.012)
	return offset


func _get_or_create_preview_container() -> Node3D:
	var existing := get_node_or_null(PREVIEW_CONTAINER_NAME) as Node3D
	if existing != null:
		return existing

	var preview_container := Node3D.new()
	preview_container.name = PREVIEW_CONTAINER_NAME
	add_child(preview_container)
	preview_container.owner = null
	return preview_container


func _get_preview_mesh() -> CylinderMesh:
	if preview_mesh != null:
		return preview_mesh

	var material := StandardMaterial3D.new()
	material.albedo_color = Color(1, 0.72, 0.08, 1)
	material.metallic = 0.65
	material.roughness = 0.28
	material.emission_enabled = true
	material.emission = Color(1, 0.68, 0.06, 1)
	material.emission_energy_multiplier = 2.0

	preview_mesh = CylinderMesh.new()
	preview_mesh.material = material
	preview_mesh.top_radius = 0.08
	preview_mesh.bottom_radius = 0.08
	preview_mesh.height = 0.035
	preview_mesh.radial_segments = 32
	return preview_mesh
