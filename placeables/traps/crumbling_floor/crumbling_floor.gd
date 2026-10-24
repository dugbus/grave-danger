@tool
extends MultiMeshInstance3D

## Support from a grounded player, zombie, skeleton, boulder or millstone starts a permanent block-by-block collapse.
const SUPPORT := preload("res://placeables/traps/crumbling_floor/crumbling_floor_support.gd")
const CONTACTS := preload("res://placeables/traps/crumbling_floor/crumbling_floor_contacts.gd")
const GEOMETRY := preload("res://placeables/traps/crumbling_floor/crumbling_floor_geometry.gd")
const DETERMINISTIC_SEED := preload("res://game/deterministic_seed.gd")
const PLACEMENT := preload("res://placeables/traps/crumbling_floor/editor/crumbling_floor_placement.gd")
const AUDIO := preload("res://game/audio.gd")
const CRACK_SOUND_PATH := "res://Assets/audio/floor-crack.mp3"

enum State { Intact, Warning, Collapsing, Collapsed }

signal state_changed(state: State)

## Snap new tiles and horizontal moves to floor cells; vertical-only adjustments remain manually authored.
@export var auto_place := true:
	set(value):
		auto_place = value
		if Engine.is_editor_hint() and is_node_ready() and _ensure_editor_placement():
			_editor_placement.pending = value
## Optional placement GridMap whose cell width and depth size this tile instead of the Floor Surface's dimensions.
@export var floor_grid_map: GridMap:
	set(value):
		floor_grid_map = value
		_refresh_preview.call_deferred()
## Floor Surface used for placement and height matching; new tiles discover it automatically when unambiguous.
@export var floor_surface: FloorSurface:
	set(value):
		floor_surface = value
		_refresh_preview.call_deferred()
		if Engine.is_editor_hint() and is_node_ready() and _ensure_editor_placement():
			_editor_placement.pending = true
## Align only the tile's height to the assigned Floor Surface; keep its X/Z position and all floor cells unchanged.
@export_tool_button("Match Floor Height") var match_floor_height: Callable = _match_floor_height
## Brief warning before the first block gives way after a grounded step.
@export_range(0.0, 10.0, 0.005, "or_greater", "suffix:s") var collapse_delay := 0.05
## Time between individual blocks falling in a shuffled order; shorter intervals tighten the escape window.
@export_range(0.01, 1.0, 0.005, "or_greater", "suffix:s") var block_release_interval := 0.015
## Seconds each falling fragment remains before cleanup; audio is independent of this lifetime.
@export_range(0.0, 30.0, 0.1, "or_greater", "suffix:s") var debris_lifetime := 3.0
## Strength of the small outward impulse applied to falling fragments.
@export_range(0.0, 5.0, 0.05, "or_greater") var debris_scatter_strength := 0.5
## Maximum starting spin on each fragment axis, in radians per second.
@export_range(0.0, 10.0, 0.1, "or_greater") var debris_angular_strength := 2.0
## Repeatable collapse order and spin; zero derives a different stable seed from each tile's scene path.
@export var fracture_seed := 0
## Optional floor finish shared by the intact flagstone and falling fragments.
@export var floor_material: Material:
	set(value):
		floor_material = value
		_refresh_preview.call_deferred()

var state := State.Intact
var tile_size := Vector3(1.0, GEOMETRY.THICKNESS, 1.0)
var _warning_elapsed := 0.0
var _collapse_elapsed := 0.0
var _released_count := 0
var _blocks: Array[AABB] = []
var _release_order: Array[int] = []
var _runtime_fracture_seed := 0
var _support := SUPPORT.new()
var _contact_monitor: CONTACTS
var _registered_body := RID()
var _active_fragments: Array[RigidBody3D] = []
var _material: Material
var _crack_sound: AudioStream
var _editor_placement: PLACEMENT
var _placement_error := ""
var _editor_history: Object

var _geometry := GEOMETRY.shared(GEOMETRY) as GEOMETRY


func _validate_property(property: Dictionary) -> void:
	# Rebuild generated batches on load; reloading a saved populated MultiMesh cannot reset its format safely.
	if property["name"] == &"multimesh":
		property["usage"] = PROPERTY_USAGE_NONE


func _enter_tree() -> void:
	if Engine.is_editor_hint():
		_ensure_editor_placement()


func _ready() -> void:
	set_notify_transform(true)
	_refresh_preview()
	set_process(Engine.is_editor_hint())
	set_physics_process(false)
	if Engine.is_editor_hint():
		if _ensure_editor_placement():
			_editor_placement.begin(self, get_tree().edited_scene_root)
	else:
		process_physics_priority = 20
		_crack_sound = load_optional_sound(CRACK_SOUND_PATH)
		_register_contact.call_deferred()


func _exit_tree() -> void:
	_disconnect_editor_history()
	_editor_placement = null
	_unregister_contact()
	_support.clear()


## Tool-script reloads can reset these fields without another tree-entry callback.
func _ensure_editor_placement() -> bool:
	var history := _editor_history if is_instance_valid(_editor_history) else PLACEMENT.get_editor_history()
	return _bind_editor_placement(history)


## Restore missing state without moving the tile or requesting a fresh placement on scene reload.
func _bind_editor_placement(history: Object) -> bool:
	if not is_inside_tree() or not is_instance_valid(history):
		return false
	if _editor_placement == null:
		_editor_placement = PLACEMENT.new()
		_editor_placement.reset(self)
	if not is_instance_valid(_editor_history) or _editor_history != history:
		_disconnect_editor_history()
		_editor_history = history
	if not _editor_history.version_changed.is_connected(_on_editor_history_changed):
		_editor_history.version_changed.connect(_on_editor_history_changed)
	return true


func _disconnect_editor_history() -> void:
	if is_instance_valid(_editor_history) and _editor_history.version_changed.is_connected(_on_editor_history_changed):
		_editor_history.version_changed.disconnect(_on_editor_history_changed)
	_editor_history = null


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_TRANSFORM_CHANGED:
			if is_inside_tree():
				_support.update_transform(global_transform)
		NOTIFICATION_DISABLED, NOTIFICATION_ENABLED, NOTIFICATION_PAUSED, NOTIFICATION_UNPAUSED:
			if is_inside_tree():
				_support.set_enabled.call_deferred(can_process())


## Register after scene construction so the shared monitor can join the tree immediately.
func _register_contact() -> void:
	if not is_inside_tree() or state != State.Intact:
		return
	var world_id := get_world_3d().get_instance_id()
	for candidate in get_tree().get_nodes_in_group(CONTACTS.MONITOR_GROUP):
		var monitor := candidate as CONTACTS
		if monitor._world_id == world_id and not monitor.is_queued_for_deletion():
			_contact_monitor = monitor
			break
	if not is_instance_valid(_contact_monitor):
		_contact_monitor = CONTACTS.new()
		_contact_monitor.configure(world_id)
		get_tree().root.add_child(_contact_monitor)
	_registered_body = _support.body
	_contact_monitor.register_body(_registered_body, _activate_from_support)


func _unregister_contact() -> void:
	if is_instance_valid(_contact_monitor) and _registered_body.is_valid():
		_contact_monitor.unregister_body(_registered_body)
	_registered_body = RID()


func _activate_from_support() -> void:
	if state != State.Intact or not can_process():
		return
	_unregister_contact()
	_randomize_release_order()
	_warning_elapsed = 0.0
	AUDIO.play_one_shot_3d(self, _crack_sound, "FloorCrack")
	_set_state(State.Warning)
	set_physics_process(true)


func _process(_delta: float) -> void:
	if not tile_size.is_equal_approx(_configured_tile_size()):
		_refresh_preview()
	if Engine.is_editor_hint():
		_process_editor_placement()


func _process_editor_placement() -> void:
	if not is_inside_tree():
		return
	var scene_root := get_tree().edited_scene_root
	if scene_root == null or scene_root == self or not scene_root.is_ancestor_of(self):
		return
	if not _ensure_editor_placement():
		return
	var dragging := (
		(
			Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
			or get_viewport().gui_is_dragging()
			or _editor_history.is_committing_action()
		)
		as bool
	)
	if not _editor_placement.should_place(self, auto_place, dragging):
		return
	var surface := floor_surface if is_instance_valid(floor_surface) else PLACEMENT.find_surface(self, scene_root)
	var result := PLACEMENT.calculate_auto_transform(self, surface)
	_placement_error = "" if (result["valid"] as bool) else result["error"] as String
	if result["valid"] as bool:
		PLACEMENT.apply_auto_in_editor(
			self, surface, result["transform"] as Transform3D, _editor_placement.undo_transform
		)
	_editor_placement.reset(self)
	update_configuration_warnings()


func _on_editor_history_changed() -> void:
	if _ensure_editor_placement():
		_editor_placement.reset(self)


func _get_configuration_warnings() -> PackedStringArray:
	return PackedStringArray([_placement_error]) if not _placement_error.is_empty() else PackedStringArray()


func _physics_process(delta: float) -> void:
	match state:
		State.Warning:
			_warning_elapsed += delta
			# Offset the batched visual only; the single intact collider stays stationary.
			_geometry.set_visual_offset(
				self,
				_blocks,
				Vector3(
					sin(_warning_elapsed * 65.0) * tile_size.x * 0.003,
					0.0,
					sin(_warning_elapsed * 79.0) * tile_size.z * 0.003
				)
			)
			if _warning_elapsed >= collapse_delay:
				_geometry.set_visual_offset(self, _blocks, Vector3.ZERO)
				_set_state(State.Collapsing)
				_release_until.call_deferred(1)
		State.Collapsing:
			_collapse_elapsed += delta
			var target_count := mini(1 + floori(_collapse_elapsed / maxf(block_release_interval, 0.01)), _blocks.size())
			if target_count > _released_count:
				_release_until.call_deferred(target_count)


## The shared loader silently skips missing audio and supports read-only MP3s before their first import.
static func load_optional_sound(path: String) -> AudioStream:
	return AUDIO.load_stream(path)


func _randomize_release_order() -> void:
	_runtime_fracture_seed = DETERMINISTIC_SEED.from_node(self, fracture_seed, &"crumbling_floor")
	var random := RandomNumberGenerator.new()
	random.seed = _runtime_fracture_seed
	_release_order.clear()
	for index in _blocks.size():
		_release_order.append(index)
	# Shuffle with a local RNG so neighboring tiles vary without changing replay behavior
	# or consuming randomness owned by player movement and other gameplay systems.
	for index in range(_release_order.size() - 1, 0, -1):
		var other := random.randi_range(0, index)
		var saved := _release_order[index]
		_release_order[index] = _release_order[other]
		_release_order[other] = saved


## Called outside the physics flush so each disappearing block loses support safely.
func _release_until(target_count: int) -> void:
	if not is_inside_tree() or state != State.Collapsing:
		return
	while _released_count < target_count:
		var index := _release_order[_released_count]
		var block := _blocks[index]
		_support.remove_block(index)
		multimesh.set_instance_transform(index, Transform3D(Basis.from_scale(Vector3.ZERO), Vector3.ZERO))
		var fragment := _geometry.release_fragment(
			self, block, _material, _runtime_fracture_seed, index, debris_scatter_strength, debris_angular_strength
		)
		_active_fragments.append(fragment)
		fragment.tree_exiting.connect(_on_fragment_exiting.bind(fragment))
		get_tree().create_timer(debris_lifetime, false, true).timeout.connect(fragment.queue_free)
		_released_count += 1
	if _released_count == _blocks.size():
		_support.clear()
		multimesh.visible_instance_count = 0
		_set_state(State.Collapsed)
		set_physics_process(false)


func _set_state(next_state: State) -> void:
	state = next_state
	state_changed.emit(state)


func _refresh_preview() -> void:
	if not is_node_ready() or state != State.Intact:
		return
	tile_size = _configured_tile_size()
	_material = _geometry.populate_visual(self, tile_size, floor_material)
	_blocks = _geometry.describe_blocks(tile_size)
	if not Engine.is_editor_hint():
		_support.configure(get_world_3d().space, get_instance_id(), global_transform, tile_size, _blocks)
		_support.set_enabled(can_process())


func _on_fragment_exiting(fragment: RigidBody3D) -> void:
	_active_fragments.erase(fragment)


func _match_floor_height() -> void:
	PLACEMENT.match_height_in_editor(self, floor_surface)


func _configured_tile_size() -> Vector3:
	if floor_grid_map != null:
		return Vector3(floor_grid_map.cell_size.x, GEOMETRY.THICKNESS, floor_grid_map.cell_size.z)
	if floor_surface != null:
		return Vector3(floor_surface.cell_size, GEOMETRY.THICKNESS, floor_surface.cell_size)
	return Vector3(1.0, GEOMETRY.THICKNESS, 1.0)
