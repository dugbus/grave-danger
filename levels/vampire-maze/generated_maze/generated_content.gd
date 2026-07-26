@tool
class_name GDGeneratedDungeonContent
extends Node3D

## Instances the reusable gameplay scenes described by a generated content plan.

signal bat_noise_triggered(noise_position: Vector3)
signal vampire_layout_landmarks_changed(layout_landmarks: Array[Dictionary])
signal level_completed

const PLANNER_SCRIPT := preload("res://levels/vampire-maze/generated_maze/generated_content_planner.gd")
const LOCKABLE_PASSAGE_SCRIPT := preload("res://placeables/lockables/lockable_hinged_passage.gd")
const TREASURE_PILE_SCENE := preload("res://placeables/treasure/treasure_pile.tscn")
const TREASURE_COFFIN_SCENE := preload(
    "res://placeables/treasure_deposit/treasure_deposit_coffin.tscn"
)
const LOCKED_DOOR_SCENE := preload("res://placeables/lockables/locked_door.tscn")
const LOCKED_GATE_SCENE := preload("res://placeables/lockables/locked_gate.tscn")
const GOLD_KEY_SCENE := preload("res://inventory/key.tscn")
const SILVER_KEY_SCENE := preload("res://inventory/silver_key.tscn")
const BAT_NOISE_SCENE := preload(
    "res://levels/vampire-maze/generated_maze/generated_bat_noise.tscn"
)
const TREASURE_TYPES: Array[StringName] = [
    &"gold_coin",
    &"diamond",
    &"ruby",
    &"sapphire",
    &"emerald",
    &"amethyst",
    &"gold_bar",
]
const DOOR_WIDTH_SCALE := 1.36

var _last_plan: Dictionary = {}
var _player: Node3D
var _vampire: PhysicsBody3D
var _floor_grid_map: GridMap
var _vampire_collision_bodies: Array[PhysicsBody3D] = []
var _end_gate: Node3D
var _exit_staircase: Node3D


## Replaces this node's generated children with the supplied deterministic plan.
func regenerate_content(
    floor_cells: Dictionary,
    maze_result: Dictionary,
    seed_value: int,
    floor_grid_map: GridMap,
    configuration: Resource,
    player: Node3D,
    vampire: PhysicsBody3D
) -> Dictionary:
    _clear_generated_children()
    _player = player
    _vampire = vampire
    _floor_grid_map = floor_grid_map
    if floor_grid_map == null:
        return {"errors": ["Generated content requires the maze floor GridMap."]}

    var planner: RefCounted = PLANNER_SCRIPT.new()
    var plan := planner.call(
        &"build_plan",
        floor_cells,
        maze_result.get("player_cell") as Vector3i,
        maze_result.get("vampire_cell") as Vector3i,
        maze_result.get("end_gate_cell") as Vector3i,
        Vector2i(
            int(maze_result.get("width", 0)),
            int(maze_result.get("height", 0))
        ),
        seed_value,
        configuration
    ) as Dictionary
    _last_plan = plan
    if not (plan.get("errors", []) as Array).is_empty():
        return plan

    _end_gate = _instance_end_gate(maze_result.get("end_gate_spawn") as Transform3D)
    _exit_staircase = _end_gate.get_node_or_null("ProceduralStaircase") as Node3D \
        if _end_gate != null else null
    _instance_doors(plan.get("doors", []) as Array, floor_grid_map)
    _instance_keys(plan.get("keys", []) as Array, floor_grid_map)
    _instance_coffins(plan.get("coffins", []) as Array, floor_grid_map, seed_value)
    _instance_treasure_caches(
        plan.get("treasure_caches", []) as Array,
        floor_grid_map,
        seed_value
    )
    _instance_bat_nests(plan.get("bat_nests", []) as Array, floor_grid_map)
    vampire_layout_landmarks_changed.emit(get_vampire_layout_landmarks())
    return plan


## Returns the latest data-first plan for minimap tooling, tests, and runtime configuration.
func get_last_plan() -> Dictionary:
    return _last_plan.duplicate(true)


## Returns the exit instantiated by the latest generated content pass.
func get_end_gate() -> Node3D:
    return _end_gate


## Returns the reusable staircase and guarded completion trigger owned by the current gate.
func get_exit_staircase() -> Node3D:
    return _exit_staircase


## Returns generated solid bodies ignored only by the current vampire.
func get_vampire_collision_bodies() -> Array[PhysicsBody3D]:
    return _vampire_collision_bodies.duplicate()


## Makes generated scene roots persistent and their instanced children editable.
func make_generated_children_editable() -> int:
    var persistent_root_count := 0
    if not Engine.is_editor_hint() or not is_inside_tree():
        return persistent_root_count
    var edited_scene_root := get_tree().edited_scene_root
    if edited_scene_root == null:
        return persistent_root_count
    for child in get_children():
        if not _assign_editor_owner(child):
            continue
        persistent_root_count += 1
        if not child.scene_file_path.is_empty():
            edited_scene_root.set_editable_instance(child, true)
    return persistent_root_count


## Returns world-space objectives the vampire knows before the hunt begins.
func get_vampire_layout_landmarks() -> Array[Dictionary]:
    var known_landmarks: Array[Dictionary] = []
    if _floor_grid_map == null or _last_plan.is_empty():
        return known_landmarks

    _append_plan_landmarks(
        known_landmarks,
        _last_plan.get("treasure_caches", []) as Array,
        &"treasure_pile"
    )
    _append_key_landmarks(
        known_landmarks,
        _last_plan.get("keys", []) as Array
    )
    _append_plan_landmarks(
        known_landmarks,
        _last_plan.get("coffins", []) as Array,
        &"coffin"
    )
    _append_plan_landmarks(
        known_landmarks,
        _last_plan.get("doors", []) as Array,
        &"locked_door"
    )
    if is_instance_valid(_end_gate):
        known_landmarks.append({
            "id": &"end_gate",
            "kind": &"end_gate",
            "position": _end_gate.global_position,
        })
    return known_landmarks


func _exit_tree() -> void:
    _clear_vampire_collision_exceptions()


func _clear_generated_children() -> void:
    _clear_vampire_collision_exceptions()
    _end_gate = null
    _exit_staircase = null
    for child in get_children():
        if Engine.is_editor_hint() and child.owner != null:
            child.owner = null
        remove_child(child)
        child.free()


func _append_plan_landmarks(
    known_landmarks: Array[Dictionary],
    placements: Array,
    kind: StringName
) -> void:
    for index in placements.size():
        var placement := placements[index] as Dictionary
        var cell := placement["cell"] as Vector2i
        known_landmarks.append({
            "id": StringName("%s_%02d" % [kind, index + 1]),
            "kind": kind,
            "position": _world_position_for_cell(_floor_grid_map, cell),
        })


func _append_key_landmarks(
    known_landmarks: Array[Dictionary],
    placements: Array
) -> void:
    for index in placements.size():
        var placement := placements[index] as Dictionary
        var item_type := placement["item_type"] as StringName
        var kind := &"gold_key" if item_type == &"key" else &"silver_key"
        var cell := placement["cell"] as Vector2i
        known_landmarks.append({
            "id": StringName("%s_%02d" % [kind, index + 1]),
            "kind": kind,
            "position": _world_position_for_cell(_floor_grid_map, cell),
        })


func _instance_end_gate(spawn_transform: Transform3D) -> Node3D:
    var end_gate := LOCKED_GATE_SCENE.instantiate() as Node3D
    if end_gate == null:
        return null
    end_gate.name = "GeneratedLockedGate"
    end_gate.set(
        &"key_requirement",
        LOCKABLE_PASSAGE_SCRIPT.KeyRequirement.GoldKey
    )
    end_gate.set(&"starts_locked", true)
    end_gate.set(&"completes_level", true)
    end_gate.transform = global_transform.affine_inverse() * spawn_transform
    _add_generated_child(end_gate)
    end_gate.connect(&"level_completed", _on_exit_staircase_completed)
    return end_gate


func _on_exit_staircase_completed() -> void:
    level_completed.emit()


func _instance_doors(
    placements: Array,
    floor_grid_map: GridMap
) -> void:
    for index in placements.size():
        var placement := placements[index] as Dictionary
        var door := LOCKED_DOOR_SCENE.instantiate() as Node3D
        if door == null:
            continue
        door.name = "GeneratedLockedDoor%02d" % [index + 1]
        door.set(
            &"key_requirement",
            LOCKABLE_PASSAGE_SCRIPT.KeyRequirement.SilverKey
        )
        door.set(&"starts_locked", true)

        var first_cell := placement["cell"] as Vector2i
        var second_cell := placement["paired_cell"] as Vector2i
        var first_position := _world_position_for_cell(floor_grid_map, first_cell)
        var second_position := _world_position_for_cell(floor_grid_map, second_cell)
        var travel_direction := placement["travel_direction"] as Vector2i
        var angle := PI * 0.5 if travel_direction.x != 0 else 0.0
        var door_basis := Basis(Vector3.UP, angle).scaled(Vector3(DOOR_WIDTH_SCALE, 1.0, 1.0))
        var door_transform := Transform3D(
            door_basis,
            (first_position + second_position) * 0.5
        )
        door.transform = global_transform.affine_inverse() * door_transform
        _add_generated_child(door)
        _add_vampire_collision_exceptions(door)


func _instance_keys(placements: Array, floor_grid_map: GridMap) -> void:
    for index in placements.size():
        var placement := placements[index] as Dictionary
        var item_type := placement["item_type"] as StringName
        var key_scene := GOLD_KEY_SCENE if item_type == &"key" else SILVER_KEY_SCENE
        var key := key_scene.instantiate() as Node3D
        if key == null:
            continue
        key.name = "Generated%sKey%02d" % ["Gold" if item_type == &"key" else "Silver", index + 1]
        _add_generated_child(key)
        var cell := placement["cell"] as Vector2i
        key.global_position = _world_position_for_cell(floor_grid_map, cell) + Vector3.UP * 0.08


func _instance_coffins(
    placements: Array,
    floor_grid_map: GridMap,
    seed_value: int
) -> void:
    for index in placements.size():
        var placement := placements[index] as Dictionary
        var coffin := TREASURE_COFFIN_SCENE.instantiate() as Node3D
        if coffin == null:
            continue
        coffin.name = "GeneratedTreasureCoffin%02d" % [index + 1]
        _add_generated_child(coffin)
        _add_vampire_collision_exceptions(coffin)
        var cell := placement["cell"] as Vector2i
        coffin.global_position = _world_position_for_cell(floor_grid_map, cell)
        coffin.rotation.y = float(posmod(seed_value + index, 4)) * PI * 0.5


func _instance_treasure_caches(
    placements: Array,
    floor_grid_map: GridMap,
    seed_value: int
) -> void:
    for index in placements.size():
        var placement := placements[index] as Dictionary
        var pile := TREASURE_PILE_SCENE.instantiate() as Node3D
        if pile == null:
            continue
        pile.name = "GeneratedTreasureCache%02d" % [index + 1]
        pile.set(&"random_seed", seed_value + index * 977)
        var counts := placement["counts"] as Dictionary
        for item_type in TREASURE_TYPES:
            pile.call(&"set_treasure_count", item_type, int(counts.get(item_type, 0)))
        _add_generated_child(pile)
        var cell := placement["cell"] as Vector2i
        pile.global_position = _world_position_for_cell(floor_grid_map, cell) + Vector3.UP * 0.12


func _instance_bat_nests(placements: Array, floor_grid_map: GridMap) -> void:
    for index in placements.size():
        var placement := placements[index] as Dictionary
        var bat_noise := BAT_NOISE_SCENE.instantiate() as Node3D
        if bat_noise == null:
            continue
        bat_noise.name = "GeneratedBatNoise%02d" % [index + 1]
        if bat_noise.has_signal(&"noise_triggered"):
            bat_noise.connect(&"noise_triggered", _on_bat_noise_triggered)
        _add_generated_child(bat_noise)
        var cell := placement["cell"] as Vector2i
        bat_noise.global_position = _world_position_for_cell(floor_grid_map, cell) + Vector3.UP * 1.6


func _world_position_for_cell(floor_grid_map: GridMap, cell: Vector2i) -> Vector3:
    return floor_grid_map.to_global(floor_grid_map.map_to_local(Vector3i(cell.x, 0, cell.y)))


func _add_generated_child(node: Node) -> void:
    add_child(node)
    # Live editor previews remain transient. Freeze Generated Level assigns
    # scene ownership once regeneration has stopped, avoiding SceneTree order
    # churn while old preview nodes are replaced.


func _assign_editor_owner(node: Node) -> bool:
    if not Engine.is_editor_hint() or not is_inside_tree():
        return false
    var edited_scene_root := get_tree().edited_scene_root
    if edited_scene_root == null \
            or (edited_scene_root != node and not edited_scene_root.is_ancestor_of(node)):
        return false
    node.owner = edited_scene_root
    return node.owner == edited_scene_root


func _add_vampire_collision_exceptions(root: Node) -> void:
    if _vampire == null:
        return
    for collision_body in _get_physics_bodies(root):
        if _vampire_collision_bodies.has(collision_body):
            continue
        _vampire.add_collision_exception_with(collision_body)
        collision_body.add_collision_exception_with(_vampire)
        _vampire_collision_bodies.append(collision_body)


func _clear_vampire_collision_exceptions() -> void:
    if is_instance_valid(_vampire):
        for collision_body in _vampire_collision_bodies:
            if not is_instance_valid(collision_body):
                continue
            _vampire.remove_collision_exception_with(collision_body)
            collision_body.remove_collision_exception_with(_vampire)
    _vampire_collision_bodies.clear()


func _get_physics_bodies(root: Node) -> Array[PhysicsBody3D]:
    var found: Array[PhysicsBody3D] = []
    _collect_physics_bodies(root, found)
    return found


func _collect_physics_bodies(root: Node, found: Array[PhysicsBody3D]) -> void:
    if root is PhysicsBody3D:
        found.append(root as PhysicsBody3D)
    for child in root.get_children():
        _collect_physics_bodies(child, found)


func _on_bat_noise_triggered(noise_origin: Vector3) -> void:
    var target_position := _player.global_position if _player != null else noise_origin
    bat_noise_triggered.emit(target_position)
