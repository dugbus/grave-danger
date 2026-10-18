extends Node

## One monitor per physics world checks player and rolling-stone support; untouched tiles have no callbacks or areas.
const GEOMETRY := preload("res://placeables/traps/crumbling_floor/crumbling_floor_geometry.gd")
const MONITOR_GROUP := &"crumbling_floor_contacts"
const FLOOR_COLLISION_MASK := GEOMETRY.PhysicsLayer.Floor
# Tiny footprint samples handle block seams without activating tiles during an airborne crossing.
const SUPPORT_OFFSETS: Array[Vector2] = [
	Vector2.ZERO,
	Vector2(0.025, 0.025),
	Vector2(-0.025, 0.025),
	Vector2(0.025, -0.025),
	Vector2(-0.025, -0.025),
]

var _world_id := 0
var _callbacks: Dictionary[RID, Callable] = {}
var _players: Array[CharacterBody3D] = []
var _rolling_bodies: Array[RollingRock] = []
var _query := PhysicsRayQueryParameters3D.new()


func configure(world_id: int) -> void:
	_world_id = world_id
	_query.collision_mask = FLOOR_COLLISION_MASK
	process_physics_priority = 10


func register_body(body: RID, activate: Callable) -> void:
	_callbacks[body] = activate


func unregister_body(body: RID) -> void:
	_callbacks.erase(body)
	if _callbacks.is_empty():
		set_physics_process(false)
		queue_free()


func _ready() -> void:
	add_to_group(MONITOR_GROUP)
	get_tree().node_added.connect(_on_node_added)
	get_tree().node_removed.connect(_on_node_removed)
	for node in get_tree().get_nodes_in_group(&"player"):
		_track_player(node.get_instance_id())
	for node in get_tree().get_nodes_in_group(&"pushable"):
		_track_rolling_body(node.get_instance_id())


func _on_node_added(node: Node) -> void:
	if node is CharacterBody3D:
		# Groups declared in _ready are available after node_added, not during it.
		_track_player.call_deferred(node.get_instance_id())
	elif node is RollingRock:
		_track_rolling_body.call_deferred(node.get_instance_id())


func _track_player(instance_id: int) -> void:
	var player := instance_from_id(instance_id) as CharacterBody3D
	if not is_instance_valid(player) or not player.is_inside_tree() or not player.is_in_group(&"player"):
		return
	if player.get_world_3d().get_instance_id() == _world_id and not _players.has(player):
		_players.append(player)


func _on_node_removed(node: Node) -> void:
	if node is CharacterBody3D:
		_players.erase(node as CharacterBody3D)
	elif node is RollingRock:
		_rolling_bodies.erase(node as RollingRock)


func _track_rolling_body(instance_id: int) -> void:
	var body := instance_from_id(instance_id) as RollingRock
	if not is_instance_valid(body) or not body.is_inside_tree():
		return
	if body.get_world_3d().get_instance_id() == _world_id and not _rolling_bodies.has(body):
		_rolling_bodies.append(body)


func _physics_process(_delta: float) -> void:
	for player in _players:
		if (
			not is_instance_valid(player)
			or not player.can_process()
			or not player.is_on_floor()
			or player.velocity.dot(player.up_direction) > 0.01
		):
			continue
		_check_support(player)
	for body in _rolling_bodies:
		if is_instance_valid(body) and body.can_process() and not body.freeze:
			_check_rolling_support(body)


## Real support contacts account for the sphere or cylinder footprint without triggering from nearby overlap.
func _check_rolling_support(body: RollingRock) -> void:
	var state := PhysicsServer3D.body_get_direct_state(body.get_rid())
	if state == null:
		return
	for index in state.get_contact_count():
		var normal := state.transform.basis * state.get_contact_local_normal(index)
		if normal.normalized().dot(Vector3.UP) <= 0.65:
			continue
		var activate := _callbacks.get(state.get_contact_collider(index), Callable()) as Callable
		if activate.is_valid():
			activate.call()


func _check_support(player: CharacterBody3D) -> void:
	for offset in SUPPORT_OFFSETS:
		var foot := player.global_position + player.global_basis.x * offset.x + player.global_basis.z * offset.y
		_query.from = foot + player.up_direction * 0.08
		_query.to = foot - player.up_direction * 0.12
		var hit := player.get_world_3d().direct_space_state.intersect_ray(_query)
		var normal := hit.get("normal", Vector3.ZERO) as Vector3
		if normal.dot(player.up_direction) <= 0.65:
			continue
		var body := hit.get("rid", RID()) as RID
		var activate := _callbacks.get(body, Callable()) as Callable
		if activate.is_valid():
			activate.call()


func _exit_tree() -> void:
	_callbacks.clear()
	_players.clear()
	_rolling_bodies.clear()
