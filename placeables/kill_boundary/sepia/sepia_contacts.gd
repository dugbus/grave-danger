extends Node

## Player-only collision filtering. All other body contacts and simulation clocks stay intact.
const REGION := preload("res://placeables/kill_boundary/sepia/sepia_boundary_mode.gd")

var players: Array[PhysicsBody3D] = []
var bodies: Array[PhysicsBody3D] = []
var _ignored: Dictionary[PhysicsBody3D, Array] = {}


func _ready() -> void:
	process_physics_priority = -1000


func register_player(player: PhysicsBody3D) -> void:
	if player in players:
		return
	players.append(player)
	var leaving := _unregister_player.bind(player)
	if not player.tree_exiting.is_connected(leaving):
		player.tree_exiting.connect(leaving, CONNECT_ONE_SHOT)


func _unregister_player(player: PhysicsBody3D) -> void:
	# Remove typed dictionary keys before the body is freed; even iterating a freed key is invalid.
	if _ignored.has(player):
		for body in _ignored[player]:
			if is_instance_valid(body):
				player.remove_collision_exception_with(body as PhysicsBody3D)
		_ignored.erase(player)
	players.erase(player)


func register_body(body: PhysicsBody3D) -> void:
	if body not in bodies:
		bodies.append(body)


func _physics_process(_delta: float) -> void:
	for player in players:
		if not is_instance_valid(player):
			continue
		if not _ignored.has(player):
			_ignored[player] = []
		var ignored := _ignored[player]
		for body in bodies:
			if not is_instance_valid(body) or body == player:
				continue
			var excluded := not REGION.allows_interaction(player, body.global_position)
			if excluded and body not in ignored and body not in player.get_collision_exceptions():
				player.add_collision_exception_with(body)
				ignored.append(body)
			elif not excluded and body in ignored:
				player.remove_collision_exception_with(body)
				ignored.erase(body)


func _exit_tree() -> void:
	reset()


func reset() -> void:
	set_physics_process(false)
	for player in _ignored:
		if not is_instance_valid(player):
			continue
		for body in _ignored[player]:
			if is_instance_valid(body):
				player.remove_collision_exception_with(body as PhysicsBody3D)
	_ignored.clear()
	bodies.clear()
	players.clear()
