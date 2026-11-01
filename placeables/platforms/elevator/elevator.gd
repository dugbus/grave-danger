@tool
extends Node3D

## A floor-sized moving slab; the scene owns all editor-visible physics and presentation nodes.
const ROUTE := preload("res://placeables/platforms/elevator/elevator_route.gd")
const GEOMETRY := preload("res://placeables/platforms/elevator/elevator_geometry.gd")
const PASSENGERS := preload("res://placeables/platforms/elevator/elevator_passengers.gd")
const SETTINGS := preload("res://placeables/platforms/elevator/elevator_settings.gd")
const PLACEMENT := preload("res://addons/floor_surface/editor/floor_surface_tile_placement.gd")

signal landing_reached(world_height: float)
signal obstruction_reversed

## Snap new instances and horizontal moves to floor cells; vertical edits remain manually authored.
@export var auto_place := true:
	set(value):
		auto_place = value
		if Engine.is_editor_hint() and is_node_ready():
			_placement.pending = value
## Floor used to resolve cell dimensions, materials and surrounding landing heights.
@export var floor_surface: FloorSurface:
	set(value):
		floor_surface = value
		_refresh.call_deferred()
## Optional placement GridMap supplies the tile width and depth, as for crumbling floors.
@export var floor_grid_map: GridMap:
	set(value):
		floor_grid_map = value
		_refresh.call_deferred()
## Automatic shuttling with pauses, continuous shuttling, or travel started by boarding.
@export var travel_mode := ROUTE.TravelMode.AutomaticWithPauses
## In player-activated mode, run while occupied, make a return trip, or advance one landing per boarding.
@export var boarding_behaviour := ROUTE.BoardingBehaviour.WhileOccupied
## Shared game-wide speed, landing pause and slab dimensions; duplicate only for deliberate test tuning.
@export var settings: SETTINGS = preload("res://placeables/platforms/elevator/elevator_settings.tres")
## Match only the authored cell height without changing X/Z or the surrounding floor.
@export_tool_button("Match Floor Height") var match_floor_height: Callable = _match_floor_height

@onready var platform := $Platform as AnimatableBody3D
@onready var sensor := $Platform/PassengerSensor as Area3D
@onready var contents := $Platform/Contents as Node3D
@onready var slab := $Platform/Slab as MeshInstance3D
@onready var collision := $Platform/CollisionShape3D as CollisionShape3D
@onready var sensor_collision := $Platform/PassengerSensor/CollisionShape3D as CollisionShape3D

var route := ROUTE.new()
var passengers := PASSENGERS.new()
var _placement := PLACEMENT.new()
var _history: Object
var _placement_error := ""
var _observed_position := Vector3.INF
var _contents_prepared := false


func _ready() -> void:
	process_physics_priority = -10
	_refresh()
	set_process(Engine.is_editor_hint())
	set_physics_process(not Engine.is_editor_hint())
	if Engine.is_editor_hint():
		_ensure_editor_history()
		_placement.begin(self, get_tree().edited_scene_root)
	else:
		_prepare_contents.call_deferred()
		# Let bodies and sensors register before the first support/motion query.
		route.pause_remaining = settings.landing_pause


func _exit_tree() -> void:
	if is_instance_valid(_history) and _history.version_changed.is_connected(_on_history_changed):
		_history.version_changed.disconnect(_on_history_changed)
	if is_instance_valid(floor_surface) and floor_surface.floor_map != null:
		if floor_surface.floor_map.changed.is_connected(_refresh):
			floor_surface.floor_map.changed.disconnect(_refresh)
		if floor_surface.surface_rebuilt.is_connected(_on_surface_rebuilt):
			floor_surface.surface_rebuilt.disconnect(_on_surface_rebuilt)


func _refresh() -> void:
	if not is_node_ready() or not is_inside_tree() or settings == null:
		return
	if floor_surface == null:
		var scene_root := get_tree().edited_scene_root if Engine.is_editor_hint() else get_tree().current_scene
		var discovered := PLACEMENT.find_surface(self, scene_root)
		if discovered != null:
			floor_surface = discovered
	if floor_surface == null or floor_surface.floor_map == null or floor_surface.styles.is_empty():
		update_configuration_warnings()
		return
	var width := floor_grid_map.cell_size.x if floor_grid_map != null else floor_surface.cell_size
	var depth := floor_grid_map.cell_size.z if floor_grid_map != null else floor_surface.cell_size
	slab.position = Vector3.ZERO
	slab.mesh = GEOMETRY.build(floor_surface, global_position, width, depth, settings.thickness)
	var shape := collision.shape as BoxShape3D
	shape.size = Vector3(
		width - settings.collision_margin * 2.0, settings.thickness, depth - settings.collision_margin * 2.0
	)
	collision.position.y = -settings.thickness * 0.5
	var area_shape := sensor_collision.shape as BoxShape3D
	area_shape.size.x = width + settings.support_margin * 2.0
	area_shape.size.z = depth + settings.support_margin * 2.0
	var heights := get_stop_heights()
	if route.stops != heights or route.travel_mode != travel_mode or route.boarding_behaviour != boarding_behaviour:
		route.travel_mode = travel_mode
		route.boarding_behaviour = boarding_behaviour
		route.configure(heights, platform.global_position.y)
	if not floor_surface.floor_map.changed.is_connected(_refresh):
		floor_surface.floor_map.changed.connect(_refresh)
	if not floor_surface.surface_rebuilt.is_connected(_on_surface_rebuilt):
		floor_surface.surface_rebuilt.connect(_on_surface_rebuilt)
	_observed_position = global_position
	update_configuration_warnings()


## Palette replacements and floor resizing refresh the preview without restarting unchanged travel.
func _on_surface_rebuilt(_cell_count: int) -> void:
	_refresh.call_deferred()


## The same eight flat neighbours used by auto-placement define actual landing heights.
func get_stop_heights() -> Array[float]:
	var result: Array[float] = []
	if floor_surface == null or floor_surface.floor_map == null or floor_surface.elevation_profile == null:
		return result
	var origin := global_position if is_inside_tree() else PLACEMENT._world_transform(self).origin
	var cell := floor_surface.world_to_cell(origin)
	for dz in range(-1, 2):
		for dx in range(-1, 2):
			if dx == 0 and dz == 0:
				continue
			var neighbour := cell + Vector2i(dx, dz)
			if not floor_surface.floor_map.has_floor(neighbour):
				continue
			if floor_surface.floor_map.get_cell_transition(neighbour) != FloorMap.Transition.Flat:
				continue
			var height := floor_surface.elevation_profile.elevation_to_world(
				floor_surface.floor_map.get_cell_elevation(neighbour)
			)
			if not result.has(height):
				result.append(height)
	result.sort()
	return result


func _physics_process(delta: float) -> void:
	if not _contents_prepared or route.stops.size() < 2:
		return
	passengers.gather(platform, sensor, settings.support_margin)
	route.set_occupied(passengers.occupied)
	var next_height := route.propose(delta, settings.speed)
	var displacement := Vector3.UP * (next_height - route.height)
	if displacement.is_zero_approx():
		return
	if passengers.blocked(platform, displacement, settings.collision_margin):
		route.reverse()
		obstruction_reversed.emit()
		return
	platform.global_position += displacement
	passengers.carry_frozen(displacement)
	if route.accept(next_height, settings.landing_pause):
		landing_reached.emit(next_height)


## Physics items keep their scene owner but no longer inherit the slab transform as well as physics motion.
func _prepare_contents() -> void:
	_detach_physics_contents(contents)
	_contents_prepared = true


func _detach_physics_contents(node: Node) -> void:
	for child in node.get_children():
		if child is PhysicsBody3D:
			var scene_owner := child.owner
			child.reparent(get_parent(), true)
			if scene_owner != null and scene_owner.is_ancestor_of(child):
				child.owner = scene_owner
		else:
			_detach_physics_contents(child)


func _process(_delta: float) -> void:
	if not _ensure_editor_history():
		return
	var dragging := (
		(
			Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
			or get_viewport().gui_is_dragging()
			or _history.is_committing_action()
		)
		as bool
	)
	if _placement.should_place(self, auto_place, dragging):
		var surface := (
			floor_surface if floor_surface != null else PLACEMENT.find_surface(self, get_tree().edited_scene_root)
		)
		var result := PLACEMENT.calculate_auto_transform(self, surface)
		_placement_error = result.get("error", "") as String
		if result["valid"] as bool:
			PLACEMENT.apply_auto_in_editor(self, surface, result["transform"] as Transform3D, _placement.undo_transform)
		_placement.reset(self)
	if not global_position.is_equal_approx(_observed_position):
		_refresh()


func _on_history_changed() -> void:
	_placement.reset(self)


## Tool-script reloads restore editor services without resnapping an existing authored instance.
func _ensure_editor_history() -> bool:
	if is_instance_valid(_history):
		return true
	_history = PLACEMENT.get_editor_history()
	if not is_instance_valid(_history):
		return false
	if not _history.version_changed.is_connected(_on_history_changed):
		_history.version_changed.connect(_on_history_changed)
	_placement.reset(self)
	return true


func _match_floor_height() -> void:
	PLACEMENT.match_height_in_editor(self, floor_surface)


func _get_configuration_warnings() -> PackedStringArray:
	var warnings := PackedStringArray()
	if not _placement_error.is_empty():
		warnings.append(_placement_error)
	if floor_surface == null:
		warnings.append("Assign a Floor Surface to supply materials and surrounding landing heights.")
	elif get_stop_heights().size() < 2:
		warnings.append(
			"At least two distinct surrounding flat floor heights are needed; this elevator will remain stationary."
		)
	return warnings
